
/*
EXECUTE [dbo].[GetBatchReverse] 1,90
select * from ChangeBatches order by ChangeBatchKey desc
select * from ChangeBatchRecords order by ChangeBatchKey desc
select * from changehistory where changekey in ('166850','166851') order by changehistorykey desc
select * from changes where changekey in ('166850','166851') order by maxchangehistorykey desc
*/

ALTER PROCEDURE [dbo].[GetBatchReverse](
 @USERKEY BIGINT
, @CBK BIGINT      
)
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY
DECLARE @VarErrorMessage varchar(max)

/*****************************************************************
--Few Local Variables
*****************************************************************/
DECLARE @VarCBK BIGINT		SET @VarCBK=@CBK 
DECLARE @VarUSERKEY BIGINT	SET @VarUSERKEY=@USERKEY
DECLARE @NOW DATETIME	    SET @NOW= GetDate() 
/******************************************************************************************************* 
--TO HANDLE MULTIPLE VALUES FOR A PARAMETER (here CBK) [Replacing SPLIT_VARIABLE Fn]
*******************************************************************************************************/
DECLARE @VarDelimiter varchar(2) SET @VarDelimiter = ','
DECLARE @VarRecords varchar(max) SET @VarRecords = '('+REPLACE(@VarCBK,@VarDelimiter,'),(')+')'
---
CREATE TABLE #CBK (value varchar(50));
DECLARE @sql nvarchar (max) 
if @VarRecords is null SET @SQL = 'insert into #CBK values (NULL)'
ELSE
SET @SQL = 'insert into #CBK values' +@VarRecords
---
EXEC sp_executesql @sql

/**********************************************
--Find Records to be Reversed
***********************************************/
SELECT ChangeKey
       ,ChangeHistoryKey
       ,DeleteOnReversal
 INTO #temp_CBR
 FROM dbo.ChangeBatchRecords 
 WHERE ChangeBatchKey IN (SELECT value from #CBK)
---select * from ChangeBatchRecords  

/********************************************************************
--Delete records from dbo.ChangeHistory and dbo.Changes
         ----in case 'DeleteOnReversal'=1----
*********************************************************************/  
DELETE FROM dbo.ChangeHistory 
WHERE ChangeHistoryKey IN (SELECT ChangeHistoryKey
                            FROM #temp_CBR
                            WHERE DeleteOnReversal = 1)
   
 DELETE FROM dbo.Changes 
 WHERE ChangeKey IN (SELECT ChangeKey
                     FROM #temp_CBR
                     WHERE DeleteOnReversal = 1)
  
/********************************************************************************
--Assigning UserKey,DateTimeChanged & Notes in dbo.ChangeHistory
                ----in Case Delete on Reversal =0----
*********************************************************************************/   
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
   SELECT CH.ChangeKey
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
       ,@USERKEY										   AS UserKey
       ,@NOW                                               AS DateTimeChanged
       ,'Reversal of batch ' + CAST(@CBK AS varchar(10))   AS Notes
       ,CH.Deleted
 FROM dbo.ChangeHistory AS CH INNER JOIN (SELECT Ch.ChangeKey
                                                ,Max(CH.ChangeHistoryKey) AS MCHK 
                                            FROM dbo.ChangeHistory AS CH INNER JOIN #temp_CBR AS CBR
                                            ON CH.ChangeKey = CBR.ChangeKey
                                            AND CBR.DeleteOnReversal = 0
                                            AND CH.ChangeHistoryKey < CBR.ChangeHistoryKey
                                            Group BY CH.ChangeKey) AS NMCH
   ON CH.ChangeKey = NMCH.ChangeKey
  AND CH.ChangeHistoryKey = NMCH.MCHK
  
 /***********************************************************
 --Updating dbo.Changes with 'Delete' flag as 0
   In case we are Reversing 'DELETE' event
 ***********************************************************/
 UPDATE dbo.Changes
 SET Deleted = 0
 FROM dbo.Changes AS C INNER JOIN dbo.ChangeBatchRecords AS CBR
  ON C.ChangeKey = CBR.ChangeKey
  AND CBR.DeleteOnReversal = 0
  INNER JOIN dbo.ChangeBatches AS CB
  ON CBR.ChangeBatchKey = CB.ChangeBatchKey
  AND CB.EventType = 'Delete'
 
 /***************************************************
 --Updating dbo.Changes with MaxChangeHistoryKey
 ***************************************************/
  UPDATE dbo.Changes 
  SET MaxChangeHistoryKey = MCH.MCHK
  FROM dbo.Changes AS C INNER JOIN (SELECT ChangeKey
                                          ,Max(ChangeHistoryKey) AS MCHK
                                    FROM dbo.ChangeHistory 
                                    Group BY ChangeKey) AS MCH
   ON C.ChangeKey = MCH.ChangeKey
  
 /******************************************************
 --Update column:Active of dbo.ChangeBatches
 ******************************************************/
 UPDATE dbo.ChangeBatches
 SET Active = 0
 WHERE ChangeBatchKey IN (SELECT value from #CBK)
 
 /************************
--Dropping Temp Tables
************************/
DROP TABLE #CBK
DROP TABLE #temp_CBR
END TRY


BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
     -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error occurred while performing Batch Update/Delete process'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END
END CATCH

SET NOCOUNT OFF
END
