

/*****************************
--SPLIT PRODUCT--
*****************************/

/* --FOR TESTING--
select distinct ProductGroupNameKey,ProductGroupName from ProductGroupNames
select * from ProductGroupNames where single =0
select * from ProductGroups
select * from Products
--
select CH.ChangeKey from changehistory ch
Inner Join Changes c 
on ch.ChangeKey=c.ChangeKey 
where ProductGroupNameKey in ('79')
--
select * from PlaceOfServiceGroupNames
select * from changehistory where changekey=170470
select * from changehistory order by datetimechanged desc

--EXECUTE [dbo].[BatchSplitProduct_testing] 1,'170470'
*/


CREATE PROCEDURE [dbo].[BatchSplitProduct](
@USERKEY BIGINT
,@ChangeKey varchar(max)
)

AS
BEGIN
SET NOCOUNT ON

BEGIN TRY
DECLARE @VarErrorMessage varchar(max)   
DECLARE @NOW DATETIME SET @NOW = GETDATE()
DECLARE @VarUSERKEY BIGINT SET  @VarUSERKEY = @USERKEY
DECLARE @VarChangeKey varchar(max) SET  @VarChangeKey = @ChangeKey
DECLARE @MULTIPLIER BIGINT SET @MULTIPLIER = 10000
DECLARE @VarChangeBatchKey BIGINT --SET to SCOPE_IDENTITY (see below)
/**************************************************************************** 
--TO HANDLE MULTIPLE VALUES FOR A PARAMETER WITHOUT SPLIT_VARIABLE FUNCTION
*****************************************************************************/
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
EXEC sp_executesql @sql

/***********************************************************
--Split Query
***********************************************************/
/* CREATE a new batch */
INSERT INTO dbo.ChangeBatches(UserKey, EventTimeStamp, EventName, EventType, EventDescription, Active)
VALUES (@VarUSERKEY, @NOW, 'EVENTNAME_BatchSplitProduct','EVENTTYPE_BatchSplitProduct','EVENTDESCRIPTION_BatchSplitProduct', 1)
SET @VarChangeBatchKey = SCOPE_IDENTITY()
 ----------------------------------------------------------- 
/* STEP 02: Find the records to be split */

 if object_id('tempdb..#temp_Records') is NOT null drop TABLE #temp_Records;
 SELECT C.ChangeKey
       ,C.StateKey
       ,CH.ChangeHistoryKey 
       ,CH.ProductGroupNameKey
 INTO #temp_Records
 FROM dbo.Changes AS C INNER JOIN dbo.ChangeHistory AS CH
   ON C.ChangeKey = CH.ChangeKey
  AND C.MaxChangeHistoryKey = CH.ChangeHistoryKey
  --INNER JOIN dbo.SplitVariable(@VarChangeKey,',') as e ON C.ChangeKey = e.Value OR @VarChangeKey IS NULL
  INNER JOIN #ChangeKey as e ON C.ChangeKey = e.value OR @VarChangeKey IS NULL

----------------------------------------------------------------
  /* STEP 03: Find the individual Product Group Name Keys */
if object_id('tempdb..#temp_SplitProduct') is NOT null drop TABLE #temp_SplitProduct;
 SELECT PG.ProductGroupNameKey   AS GroupedNameKey
       ,PGN.ProductGroupNameKey  AS SplitGroupNameKey
       ,P.StateKey
 INTO #temp_SplitProduct
 FROM dbo.ProductGroups AS PG INNER JOIN dbo.Products AS P
   ON PG.ProductKey = P.ProductKey
                                       INNER JOIN dbo.ProductGroupNames AS PGN
   ON P.ProductName = PGN.ProductGroupName
  AND P.StateKey = PGN.StateKey
  AND PGN.Single = 1
 --select * from #temp_SplitProduct

---------------------------------------------------------
 /* STEP04: merge the records with the split Product */
 if object_id('tempdb..#temp_Merged') is NOT null drop TABLE #temp_Merged;
 SELECT R.ChangeKey
       ,R.ChangeHistoryKey 
       ,SP.SplitGroupNameKey AS ProductGroupNameKey
       ,0                      AS First_PGN
       ,0                      AS NewChangeKey
       ,0                      AS NewMaxChangeHistoryKey
 INTO #temp_Merged
 FROM #temp_Records AS R INNER JOIN #temp_SplitProduct AS SP
   ON R.ProductGroupNameKey = SP.GroupedNameKey
  AND R.StateKey = SP.StateKey
 --select * from #temp_Merged
 
----------------------------------------------------------------------------------------
/* STEP05: indentify which was is the first PGNK, that one gets the original record */
 UPDATE #temp_Merged
 SET First_PGN = 1, NewChangeKey = A.ChangeKey
 FROM #temp_Merged AS A INNER JOIN (SELECT ChangeKey
                                          ,ChangeHistoryKey
                                          ,Min(ProductGroupNameKey) AS First_PGNK
                                    FROM #temp_Merged
                                    group BY ChangeKey, ChangeHistoryKey) AS B
   ON A.ChangeKey = B.ChangeKey
  AND A.ChangeHistoryKey = B.ChangeHistoryKey
  AND A.ProductGroupNameKey = B.First_PGNK
 ---select * from #temp_merged

-------------------------------------------------------------------
/* STEP 06: CREATE new change records for the non-first PGN */
INSERT INTO dbo.Changes (Statekey
                           ,ProviderKey
                           ,MaxChangeHistoryKey
                           ,Deleted
                           ,Notes)
 SELECT Statekey
       ,ProviderKey
       ,(C.ChangeKey * @MULTIPLIER) + M.ProductGroupNameKey AS MaxChangeHistoryKey
       ,Deleted
       ,Notes
 FROM dbo.Changes AS C INNER JOIN #temp_Merged AS M
   ON C.ChangeKey = M.ChangeKey
  AND M.First_PGN = 0
 --select * from changes order by changekey desc

-----------------------------------------------------------------
/* STEP 07: Record the NewChangeKey IN the merged TABLE */
 UPDATE #temp_Merged
 SET NewChangeKey = C.ChangeKey
 FROM #temp_Merged AS M INNER JOIN dbo.Changes AS C
   ON M.ChangeKey = cast(C.MaxChangeHistoryKey / @MULTIPLIER AS bigint)
  AND M.ProductGroupNameKey = C.MaxChangeHistoryKey - cast(C.MaxChangeHistoryKey / @MULTIPLIER AS bigint) * @MULTIPLIER
--select * from #temp_merged

--------------------------------------------------------------------
/* STEP 08 : Record new changes IN the ChangeBatchRecords TABLE */
 INSERT INTO dbo.ChangeBatchRecords (ChangeBatchKey, ChangeKey, ChangeHistoryKey, DeleteOnReversal)
 SELECT @VarChangeBatchKey                                                             AS ChangeBatchKey
       ,M.NewChangeKey                                                   AS ChangeKey
       ,0                                                                AS ChangeHistoryKey
       ,CASE WHEN M.ChangeKey = M.NewChangeKey THEN 0 ELSE 1  END        AS DeleteOnReversal
 FROM #temp_Merged AS M
 ---select * from dbo.ChangeBatchRecords order by ChangebatchRecordKey desc


------------------------------------------------------------------------------------
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
 SELECT C.ChangeKey
       ,CH.Providerkey
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
 --FROM dbo.ChangeHistory AS CH 

  FROM 
 (
 SELECT * FROM
 (SELECT *,ROW_NUMBER() OVER (PARTITION BY ChangeKey ORDER BY ChangeHistoryKey desc) as rw 
 FROM dbo.ChangeHistory)iq1
 WHERE rw=1
 )AS CH    /***NOTE*** : this portion is added to restrict 'changekeys with old changehistorykeys'***/  
 
 INNER JOIN (SELECT ChangeKey
                   ,NewChangeKey
                    FROM #temp_Merged
                    WHERE ChangeKey <> NewChangeKey) AS C
   ON CH.ChangeKey = C.ChangeKey 
 
 
 
  ---select * from changehistory order by changehistorykey desc
------------------------------------------------------------------------------------------
/* STEP 10: record new ChangeHistory IN the ChangeBatchRecords TABLE **/

 /* record new ChangeHistory IN the ChangeBatchRecords TABLE */
 INSERT INTO dbo.ChangeBatchRecords (ChangeBatchKey, ChangeKey, ChangeHistoryKey, DeleteOnReversal)
 SELECT @VarChangeBatchKey                              AS ChangeBatchKey
       ,CH.ChangeKey                      AS ChangeKey
       ,CH.ChangeHistoryKey               AS ChangeHistoryKey
       ,1                                 AS DeleteOnReversal
 FROM dbo.ChangeHistory AS CH
 WHERE CH.ChangeKey IN (SELECT ChangeKey 
                        FROM dbo.ChangeBatchRecords
                        WHERE ChangeBatchKey = @VarChangeBatchKey
                          AND DeleteOnReversal = 1) **/
 --select * from dbo.ChangeBatchRecords order by ChangebatchRecordKey desc
-------------------------------------------------------------------------------------------
 /*STEP 11: split the product to the records */
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
       ,M.ProductGroupNameKey         AS ProductGroupNameKey
       ,CH.PlaceOfServiceGroupNameKey
       ,CH.QHIPValue
       ,CH.QHIPRatio
       ,CH.FixedValue
       ,CH.FixedRatio
       ,CH.ChargedValue
       ,CH.ChargedRatio
       ,CH.Closed
       ,4                             AS ChangeTypeKey     /* Split Product */
       ,@VarUSERKEY                      AS UserKey
       ,@NOW                         AS DateTimeChanged
       ,'EVENTNAME_BatchSplitProduct'                 AS Notes
       ,CH.Deleted
 FROM #temp_Merged AS M INNER JOIN dbo.ChangeHistory AS CH
   ON M.ChangeHistoryKey = CH.ChangeHistoryKey
 --select * from changehistory order by changehistorykey desc
 ---------------------------------------------------------------------------------
/* STEP 12: Save the New Max Change History Key */
 UPDATE #temp_Merged
 SET NewMaxChangeHistoryKey = CH.ChangeHistoryKey
 FROM dbo.ChangeHistory AS CH INNER JOIN #temp_Merged AS M
   ON CH.ChangeKey                  = M.NewChangeKey
  AND CH.ProductGroupNameKey = M.ProductGroupNameKey
  AND CH.DateTimeChanged            = @NOW
 -------------------------------------------------------------------------------------
/* STEP 13: record new ChangeHistory IN the ChangeBatchRecords TABLE */
 INSERT INTO dbo.ChangeBatchRecords (ChangeBatchKey, ChangeKey, ChangeHistoryKey, DeleteOnReversal)
 SELECT @VarChangeBatchKey                                           AS ChangeBatchKey
       ,M.NewChangeKey                                 AS ChangeKey
       ,M.NewMaxChangeHistoryKey                       AS ChangeHistoryKey
       ,CASE WHEN M.First_PGN = 1 THEN 0 ELSE 1 END    AS DeleteOnReversal
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
------------------------------------------------------------------------------------------------------------------------- 
/*STEP 15: CLEAN UP ANY TEMPORARY TABLES */
 if object_id('tempdb..#temp_Values')   is NOT null drop TABLE #temp_Values;
 if object_id('tempdb..#temp_Records')  is NOT null drop TABLE #temp_Records;
 if object_id('tempdb..#temp_SplitProduct') is NOT null drop TABLE #temp_SplitProduct;
 if object_id('tempdb..#temp_Merged')   is NOT null drop TABLE #temp_Merged;
 if object_id('tempdb.. #ChangeKey')   is NOT null drop TABLE  #ChangeKey;

END TRY
BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
     -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error occurred while performing Batch Split Product.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END
END CATCH

SET NOCOUNT OFF
END
