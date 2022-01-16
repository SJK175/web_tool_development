
/*****************************
--SPLIT POS--
*****************************/

/* --FOR TESTING--
select distinct ch.changekey from changehistory ch
Inner Join Changes c on ch.ChangeKey=c.ChangeKey
where PlaceOfServiceGroupNameKey in ('3')

select * from PlaceOfServiceGroupNames
select * from changehistory where changekey=170525
select * from changehistory order by datetimechanged desc

--EXECUTE [dbo].[BatchSplitPOS_testing] 1,170525
*/


CREATE PROCEDURE [dbo].[BatchSplitPOS] (
@USERKEY BIGINT 
,@ChangeKey varchar(max)
)

AS
BEGIN

SET NOCOUNT ON

BEGIN TRY
DECLARE @VarErrorMessage varchar(max)   

--DECLARE @USERKEY BIGINT  SET @USERKEY=1
--DECLARE @CBK BIGINT  SET @CBK=5
DECLARE @MULTIPLIER BIGINT
SET @MULTIPLIER=10000

DECLARE @NOW Datetime
SET @NOW= GETDATE()
--DECLARE @ChangeKey varchar(max) SET @ChangeKey= '170485,167737'

/************************************************************************** 
--TO HANDLE MULTIPLE VALUES FOR A PARAMETER WITHOUT SPLIT_VARIABLE FUNCTION
***************************************************************************/
-- @ChangeKey
DECLARE @VarDelimiter varchar(2)
SET @VarDelimiter = ','
DECLARE @VarRecords varchar(max)
SET @VarRecords = '('+REPLACE(@ChangeKey,@VarDelimiter,'),(')+')'
---
CREATE TABLE #ChangeKey (value varchar(50));
DECLARE @sql nvarchar (max) 
if @VarRecords is null SET @SQL = 'insert into #ChangeKey values (NULL)'
ELSE
SET @SQL = 'insert into #ChangeKey values' +@VarRecords
---
EXEC sp_executesql @sql

/***********************************************************
--Split Query
***********************************************************/
/* STEP01:  CREATE a new batch */
INSERT INTO dbo.ChangeBatches(UserKey, EventTimeStamp, EventName, EventType, EventDescription, Active)
VALUES (@USERKEY, GetDate(), 'EVENTNAME_BatchSplitPOS','EVENTTYPE_BatchSplitPOS','EVENTDESCRIPTION_BatchSplitPOS', 1)
DECLARE @VarChangeBatchKey BIGINT
SET @VarChangeBatchKey = SCOPE_IDENTITY()
--select * from changebatches order by ChangeBatchkey desc
----------------------------------------------------
/* STEP 02: Find the records to be split */
if object_id('tempdb..#temp_Records') is NOT null drop TABLE #temp_Records;
SELECT C.ChangeKey
       ,CH.ChangeHistoryKey 
       ,CH.PlaceOfServiceGroupNameKey
 INTO #temp_Records
 FROM dbo.Changes AS C INNER JOIN dbo.ChangeHistory AS CH
   ON C.ChangeKey = CH.ChangeKey
  AND C.MaxChangeHistoryKey = CH.ChangeHistoryKey
  --INNER JOIN dbo.SplitVariable(@ChangeKey,',') as e ON C.ChangeKey = e.Value OR @ChangeKey IS NULL
  INNER JOIN #ChangeKey as e ON C.ChangeKey = e.value OR @ChangeKey IS NULL
  --select * from #temp_records
------------------------------------------------------
 /* STEP 03: Find the individual POS Group Name Keys */
  if object_id('tempdb..#temp_SplitPOS') is NOT null drop TABLE #temp_SplitPOS;
  SELECT POSG.PlaceOfServiceGroupNameKey   AS GroupedNameKey
       ,POSGN.PlaceOfServiceGroupNameKey  AS SplitGroupNameKey
 INTO #temp_SplitPOS
 FROM dbo.PlaceOfServiceGroups AS POSG 
 INNER JOIN dbo.PlaceOfServices AS POS
 ON POSG.PlaceOfServiceKey = POS.PlaceOfServiceKey
 INNER JOIN dbo.PlaceOfServiceGroupNames AS POSGN
 ON POS.PlaceOfService = POSGN.PLaceOfServiceGroupName
 AND POSGN.Single = 1
 --select * from #temp_SplitPOS
 ---------------------------------------------------------
 /* STEP04: merge the records with the split POS */
 if object_id('tempdb..#temp_Merged') is NOT null drop TABLE #temp_Merged;
 SELECT R.ChangeKey
       ,R.ChangeHistoryKey 
       ,SPOS.SplitGroupNameKey AS PlaceOfServiceGroupNameKey
       ,0                      AS First_POSGN
       ,0                      AS NewChangeKey
       ,0                      AS NewMaxChangeHistoryKey
 INTO #temp_Merged
 FROM #temp_Records AS R 
 INNER JOIN #temp_SplitPOS AS SPOS
 ON R.PlaceOfServiceGroupNameKey = SPOS.GroupedNameKey
--select * from #temp_Merged
 ------------------------------------------------------------
/* STEP05: indentify which was is the first POSGN, that one gets the original record */
 UPDATE #temp_Merged
 SET First_POSGN = 1, NewChangeKey = A.ChangeKey
 FROM #temp_Merged AS A INNER JOIN (SELECT ChangeKey
                                          ,ChangeHistoryKey
                                          ,Min(PlaceOfServiceGroupNameKey) AS First_POSGNK
                                    FROM #temp_Merged
                                    group BY ChangeKey, ChangeHistoryKey) AS B
   ON A.ChangeKey = B.ChangeKey
  AND A.ChangeHistoryKey = B.ChangeHistoryKey
  AND A.PlaceOfServiceGroupNameKey = B.First_POSGNK
---select * from #temp_merged

-------------------------------------------------------------------
/* STEP 06: CREATE new change records for the non-first POSGN */
INSERT INTO dbo.Changes (Statekey
                           ,ProviderKey
                           ,MaxChangeHistoryKey
                           ,Deleted
                           ,Notes)
 SELECT Statekey
       ,ProviderKey
       ,(C.ChangeKey * @MULTIPLIER) + M.PlaceOfServiceGroupNameKey AS MaxChangeHistoryKey
       ,Deleted
       ,Notes
 FROM dbo.Changes AS C INNER JOIN #temp_Merged AS M
   ON C.ChangeKey = M.ChangeKey
  AND M.First_POSGN = 0
--select * from changes order by changekey desc
-----------------------------------------------------------------
/* STEP 07: Record the NewChangeKey IN the merged TABLE */
 UPDATE #temp_Merged
 SET NewChangeKey = C.ChangeKey
 FROM #temp_Merged AS M INNER JOIN dbo.Changes AS C
   ON M.ChangeKey = cast(C.MaxChangeHistoryKey / @MULTIPLIER AS bigint)
  AND M.PlaceOfServiceGroupNameKey = C.MaxChangeHistoryKey - cast(C.MaxChangeHistoryKey / @MULTIPLIER AS bigint) * @MULTIPLIER
  --select * from #temp_merged
------------------------------------------------------------------
/* STEP 08 : record new changes IN the ChangeBatchRecords TABLE */
 INSERT INTO dbo.ChangeBatchRecords (ChangeBatchKey, ChangeKey, ChangeHistoryKey, DeleteOnReversal)
 SELECT @VarChangeBatchKey                                               AS ChangeBatchKey
       ,M.NewChangeKey                                                   AS ChangeKey
       ,0                                                                AS ChangeHistoryKey
       ,CASE WHEN M.ChangeKey = M.NewChangeKey THEN 0 ELSE 1  END        AS DeleteOnReversal
 FROM #temp_Merged AS M
 ---select * from dbo.ChangeBatchRecords order by ChangebatchRecordKey desc
---------------------------------------------------------------------
/* STEP09: copy the existing change history records for the new change records 
 INSERT INTO dbo.ChangeHistory (ChangeKey
                               ,ProviderKey
                               ,ChangeDateKey
                               ,ProductGroupNameKey
                               ,PlaceOfServiceGroupNameKey
                               ,QHIPValue
                               ,QHIPRatio
                               ,FixedValue
                               ,FixedRatio
                               ,ChargedValue
                               ,ChargedRatio
                               ,Closed
                               ,ChangeTypeKey
                               ,UserKey
                               ,DateTimeChanged
                               ,Notes
                               ,Deleted)
 SELECT C.ChangeKey    /*** SJK: in orginal code c.changekey was taken***/
       ,CH.ProviderKey 
       ,CH.ChangeDateKey
       ,CH.ProductGroupNameKey
       ,CH.PlaceOfServiceGroupNameKey
       ,CH.QHIPValue
       ,CH.QHIPRatio
       ,CH.FixedValue
       ,CH.FixedRatio
       ,CH.ChargedValue
       ,CH.ChargedRatio
       ,CH.Closed
       ,CH.ChangeTypeKey
       ,CH.UserKey
       ,CH.DateTimeChanged
       ,CH.Notes
       ,CH.Deleted
 FROM 
 (
 SELECT * FROM
 (SELECT *,ROW_NUMBER() OVER (PARTITION BY ChangeKey ORDER BY ChangeHistoryKey desc) as rw 
 FROM dbo.ChangeHistory)iq1
 WHERE rw=1
 )AS CH    /***SJK: this portion is added to restrict 'changekeys with old changehistorykeys'***/ 
 
  INNER JOIN 
  (SELECT ChangeKey
  ,NewChangeKey
  FROM #temp_Merged
  WHERE ChangeKey <> NewChangeKey) AS C
  
  ON CH.ChangeKey = C.ChangeKey 
  ---select * from changehistory order by changehistorykey desc
------------------------------------------------------------------------------------------
/* STEP 10: record new ChangeHistory IN the ChangeBatchRecords TABLE **/
 
 INSERT INTO dbo.ChangeBatchRecords (ChangeBatchKey, ChangeKey, ChangeHistoryKey, DeleteOnReversal)
 SELECT @VarChangeBatchKey                AS ChangeBatchKey
       ,CH.ChangeKey                      AS ChangeKey
       ,CH.ChangeHistoryKey               AS ChangeHistoryKey
       ,1                                 AS DeleteOnReversal
 FROM dbo.ChangeHistory AS CH
 WHERE CH.ChangeKey IN (SELECT ChangeKey 
                        FROM dbo.ChangeBatchRecords
                        WHERE ChangeBatchKey = @VarChangeBatchKey
                          AND DeleteOnReversal = 1)  ***/
 --select * from dbo.ChangeBatchRecords order by ChangebatchRecordKey desc
-------------------------------------------------------------------------------------------
 /*STEP 11: split the pos to the records */
 INSERT INTO dbo.ChangeHistory (ChangeKey
                               ,ProviderKey
                               ,ChangeDateKey
                               ,ProductGroupNameKey
                               ,PlaceOfServiceGroupNameKey
                               ,QHIPValue
                               ,QHIPRatio
                               ,FixedValue
                               ,FixedRatio
                               ,ChargedValue
                               ,ChargedRatio
                               ,Closed
                               ,ChangeTypeKey
                               ,UserKey
                               ,DateTimeChanged
                               ,Notes
                               ,Deleted)
 
 SELECT M.NewChangeKey                AS ChangeKey
       ,CH.ProviderKey
       ,CH.ChangeDateKey
       ,CH.ProductGroupNameKey
       ,M.PlaceOfServiceGroupNameKey  AS PlaceOfServiceGroupNameKey
       ,CH.QHIPValue
       ,CH.QHIPRatio
       ,CH.FixedValue
       ,CH.FixedRatio
       ,CH.ChargedValue
       ,CH.ChargedRatio
       ,CH.Closed
       ,3                             AS ChangeTypeKey     /* Split POS */
       ,@USERKEY                      AS UserKey
       ,@NOW                          AS DateTimeChanged
       ,'EVENTNAME_BatchSplitPOS'     AS Notes
       ,CH.Deleted
 FROM #temp_Merged AS M 
 INNER JOIN dbo.ChangeHistory AS CH
 ON M.ChangeHistoryKey = CH.ChangeHistoryKey
 --select * from changehistory order by changehistorykey desc
 ---------------------------------------------------------------------------------

 /* STEP 12: Save the New Max Change History Key */
 UPDATE #temp_Merged
 SET NewMaxChangeHistoryKey = CH.ChangeHistoryKey
 FROM dbo.ChangeHistory AS CH INNER JOIN #temp_Merged AS M
   ON CH.ChangeKey                  = M.NewChangeKey
  AND CH.PlaceOfServiceGroupNameKey = M.PlaceOFServiceGroupNameKey
  AND CH.DateTimeChanged            = @NOW
  ---select * from #temp_Merged

  -------------------------------------------------------------------------------------
   /* STEP 13: record new ChangeHistory IN the ChangeBatchRecords TABLE */
 INSERT INTO dbo.ChangeBatchRecords (ChangeBatchKey, ChangeKey, ChangeHistoryKey, DeleteOnReversal)
 SELECT @VarChangeBatchKey                            AS ChangeBatchKey
       ,M.NewChangeKey                                 AS ChangeKey
       ,M.NewMaxChangeHistoryKey                       AS ChangeHistoryKey
       ,CASE WHEN M.First_POSGN = 1 THEN 0 ELSE 1 END  AS DeleteOnReversal
       FROM #temp_Merged AS M
	   ---select * from dbo.ChangeBatchRecords order by ChangebatchRecordKey desc

---------------------------------------------------------------
	   /* STEP 14: UPDATE the max change history keys */
 UPDATE dbo.Changes 
 SET MaxChangeHistoryKey = CH.MCHK
 FROM dbo.Changes AS C INNER JOIN (SELECT ChangeKey 
                                         ,Max(ChangeHistoryKey) AS MCHK
                                   FROM dbo.ChangeHistory
                                   group BY ChangeKey) AS CH
   ON C.ChangeKey = CH.ChangeKey

-------------------------------------------------------------------------------------
 
 /*STEP 15: Clear all temp tables*/
 if object_id('tempdb..#temp_Values')   is NOT null drop TABLE #temp_Values;
 if object_id('tempdb..#temp_Records')  is NOT null drop TABLE #temp_Records;
 if object_id('tempdb..#temp_SplitPOS') is NOT null drop TABLE #temp_SplitPOS;
 if object_id('tempdb..#temp_Merged')   is NOT null drop TABLE #temp_Merged;
  if object_id('tempdb..#temp_Merged')   is NOT null drop TABLE #ChangeKey;


-----------------------------------------------------------------------------------
END TRY
BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
     -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error occurred while performing Batch Split Place Of Service.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END
END CATCH

SET NOCOUNT OFF
END








