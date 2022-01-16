
/* --FOR TESTING--
select * from ChangeHistory where changekey in ('166850','166851')
order by ChangeHistoryKey desc
---
select distinct changekey from ChangeHistory
select * from changes where changekey in ('166850','166851')
select * from changebatches order by ChangeBatchKey desc
---
 EXECUTE GetBatchUpdateOrDelete 
 @UserKey=1
,@ChangeKey= '166850,166851'
,@QHIPRATIO =0.33334
,@FIXEDRATIO =0.33334
,@CHARGEDRATIO =0.33334
,@Update=0
*/

ALTER PROCEDURE GetBatchUpdateOrDelete
(
----------------------------------------------------------
/*Note: Following parameters will hold the changed values 
 which may be NULL if no change is required*/
----------------------------------------------------------
 @CHANGEDATEKEY Bigint=null
,@PRODUCTGROUPNAMEKEY Bigint =null
,@PLACEOFSERVICEGROUPNAMEKEY Bigint =null
,@QHIPVALUE Decimal(10,5) = null
,@QHIPRATIO Decimal(10,5) =null
,@FIXEDVALUE Decimal(10,5) =null
,@FIXEDRATIO Decimal(10,5) =null
,@CHARGEDVALUE Decimal(10,5) =null
,@CHARGEDRATIO Decimal(10,5) =null
,@CLOSED Smallint =null
---------------------------------------------------------
,@UserKey Bigint
,@ChangeKey Varchar(max)
,@Update bit 
---Update=1 implies 'update' else 'delete'
)
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY
DECLARE @VarErrorMessage varchar(max)  
/*******************************************************************************************************************
--Declaring local variables that will hold the parameters' values
*******************************************************************************************************************/
DECLARE @VARCHANGEDATEKEY Bigint  SET @VARCHANGEDATEKEY=@CHANGEDATEKEY
DECLARE @VARPRODUCTGROUPNAMEKEY Bigint  SET @VARPRODUCTGROUPNAMEKEY=@PRODUCTGROUPNAMEKEY
DECLARE @VARPLACEOFSERVICEGROUPNAMEKEY Bigint  SET @VARPLACEOFSERVICEGROUPNAMEKEY=@PLACEOFSERVICEGROUPNAMEKEY
DECLARE @VARQHIPVALUE Decimal(10,5) SET @VARQHIPVALUE=@QHIPVALUE
DECLARE @VARQHIPRATIO Decimal(10,5) SET @VARQHIPRATIO=@QHIPRATIO
DECLARE @VARFIXEDVALUE Decimal(10,5) SET @VARFIXEDVALUE=@FIXEDVALUE
DECLARE @VARFIXEDRATIO Decimal(10,5) SET @VARFIXEDRATIO=@FIXEDRATIO
DECLARE @VARCHARGEDVALUE Decimal(10,5) SET @VARCHARGEDVALUE=@CHARGEDVALUE
DECLARE @VARCHARGEDRATIO Decimal(10,5) SET @VARCHARGEDRATIO=@CHARGEDRATIO
DECLARE @VARCLOSED Smallint SET @VARCLOSED=@CLOSED
DECLARE @VARUserKey Bigint SET @VARUserKey=@UserKey
DECLARE @VARChangeKey Varchar(max) SET @VARChangeKey=@ChangeKey
DECLARE @VARUPDATE bit SET @VARUPDATE=@Update
/******************************************************************************************************* 
--TO HANDLE MULTIPLE VALUES FOR A PARAMETER (here ChangeKey) [Replacing SPLIT_VARIABLE Fn]
*******************************************************************************************************/
DECLARE @VarDelimiter varchar(2) SET @VarDelimiter = ','
DECLARE @VarRecords varchar(max) SET @VarRecords = '('+REPLACE(@VARChangeKey,@VarDelimiter,'),(')+')'
---
CREATE TABLE #ChangeKey (value varchar(50));
DECLARE @sql nvarchar (max) 
if @VarRecords is null SET @SQL = 'insert into #ChangeKey values (NULL)'
ELSE
SET @SQL = 'insert into #ChangeKey values' +@VarRecords
---
EXEC sp_executesql @sql

/***************************************************************************
STEP-01: Inserting values into dbo.ChangeBatches
Note: In dbo.ChangeBatches we have a column named ChangeBatchKey for
which identity-increment=1
****************************************************************************/
IF @VARUPDATE=1
BEGIN
INSERT INTO dbo.ChangeBatches 
(UserKey, EventTimeStamp, EventName, EventType, EventDescription, Active)
VALUES (@VARUserKey,GETDATE(),'Update Process','update','no description',1)
END

ELSE
BEGIN
INSERT INTO dbo.ChangeBatches 
(UserKey, EventTimeStamp, EventName, EventType, EventDescription, Active)
VALUES (@VARUserKey,GETDATE(),'Delete Process','delete','no description',1)
END

--------------------------------------------------------------------------
/*Note: SCOPE_IDENTITY() ensures we have the latest auto-incremented
field (here,ChangeBatchKey) into the local variable @VarChangeBatchKey.
Will use it in STEP-04 in this Stored Procedure*/
--------------------------------------------------------------------------
DECLARE @VarChangeBatchKey bigint
SET @VarChangeBatchKey=SCOPE_IDENTITY()

/****************************************************************************
STEP-02: Inserting values into dbo.ChangeHistory
Note: In dbo.ChangeHistory we have a column named ChangeHistoryKey for
which identity-increment=1
****************************************************************************/
INSERT INTO dbo.ChangeHistory 
(ChangeKey
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
,CASE WHEN @VARCHANGEDATEKEY IS NULL THEN CH.ChangeDateKey ELSE @CHANGEDATEKEY END
,CASE WHEN @VARPRODUCTGROUPNAMEKEY IS NULL THEN CH.ProductGroupNameKey ELSE @PRODUCTGROUPNAMEKEY END
,CASE WHEN @VARPLACEOFSERVICEGROUPNAMEKEY IS NULL THEN CH.PlaceOfServiceGroupNameKey  ELSE @PLACEOFSERVICEGROUPNAMEKEY END
,CASE WHEN @VARQHIPVALUE IS NULL THEN CH.QHIPValue ELSE @QHIPVALUE END
,CASE WHEN @VARQHIPRATIO IS NULL THEN CH.QHIPRatio ELSE @QHIPRATIO END
,CASE WHEN @VARFIXEDVALUE IS NULL THEN CH.FixedValue ELSE @FIXEDVALUE END
,CASE WHEN @VARFIXEDRATIO IS NULL THEN CH.FixedRatio ELSE @FIXEDRATIO END
,CASE WHEN @VARCHARGEDVALUE IS NULL THEN CH.ChargedValue ELSE @CHARGEDVALUE END
,CASE WHEN @VARCHARGEDRATIO IS NULL THEN CH.ChargedRatio ELSE @CHARGEDRATIO END
,CASE WHEN @VARCLOSED IS NULL THEN CH.Closed ELSE @CLOSED END
,CASE WHEN @VARUPDATE=1 THEN 2 ELSE 5 END AS ChangeTypeKey
,@VARUserKey  AS UserKey
,GETDATE() AS DateTimeChanged
,CASE WHEN @VARUPDATE=1 THEN 'Update Process' ELSE 'DELETE Process' END AS Notes
,CASE WHEN @VARUPDATE=1 THEN CH.Deleted ELSE 1 END AS Deleted
FROM dbo.ChangeHistory AS CH 
INNER JOIN dbo.[Changes] AS C
ON CH.ChangeHistoryKey = C.MaxChangeHistoryKey
INNER JOIN  #ChangeKey as sv 
ON C.ChangeKey = sv.Value OR @VARChangeKey IS NULL

/**************************************************************************
STEP-03: Updating MaxchangeHistoryKey for a ChangeKey in dbo.Changes
For Delete function, column 'DELETE' should be leveled as 1
**************************************************************************/
 IF @VARUPDATE=0
 BEGIN
 UPDATE dbo.Changes
 SET Deleted = 1 
 WHERE ChangeKey IN (SELECT value FROM #ChangeKey)
 END
 -----
 UPDATE dbo.[Changes]
 SET MaxChangeHistoryKey = MCH.MCHK
 FROM dbo.[Changes] AS C 
 INNER JOIN 
 (SELECT ChangeKey
 ,MAX(ChangeHistoryKey) AS MCHK
 FROM dbo.ChangeHistory AS ch
 INNER JOIN  #ChangeKey as sv 
 ON ch.ChangeKey = sv.Value OR @VARChangeKey IS NULL
 GROUP BY ChangeKey) AS MCH
 ON C.ChangeKey = MCH.ChangeKey
 
 /*****************************************************
 STEP-04: Updating dbo.ChangeBatchRecords
 *****************************************************/
 INSERT INTO dbo.ChangeBatchRecords 
 (ChangeBatchKey
 ,ChangeKey
 ,ChangeHistoryKey
 ,DeleteOnReversal)
 SELECT 
  @VarChangeBatchKey AS ChangeBatchKey
 ,C.ChangeKey AS ChangeKey
 ,C.MaxChangeHistoryKey AS ChangeHistoryKey
 ,0 AS DeleteOnReversal
 FROM dbo.Changes AS c 
 INNER JOIN  #ChangeKey as sv 
 ON c.ChangeKey = sv.Value OR @VARChangeKey IS NULL

/***********************
--Dropping Temp Tables
************************/
DROP TABLE #ChangeKey
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

