




USE [ITF_Obfuscated_Final]
GO
/****** Object:  StoredProcedure [dbo].[RevertTrend]    Script Date: 10-12-2016 17:10:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--drop procedure [dbo].[RevertTrend]
CREATE PROCEDURE dbo.RevertTrendV2
 @ChangeKey bigint
,@ChangeHistoryKey bigint

AS
BEGIN TRY
SET NOCOUNT ON;

/********************************************************************************************
 DECLARING VARIABLES
********************************************************************************************/
DECLARE @VarErrorMessage varchar(max)
DECLARE @HoldChangeHistoryKey bigint
DECLARE @VarChangeKey bigint
	SET @VarChangeKey=@ChangeKey
DECLARE @VarChangeHistoryKey bigint
	SET @VarChangeHistoryKey=@ChangeHistoryKey

/***********************************************************************************************
 STEP 01: INSERTING A NEW ROW IN CHANGEHISTORY (BASED ON SELECTED CHANGEKEY & CHANGEHISTORYKEY)
*************************************************************************************************/
INSERT INTO dbo.ChangeHistory
(
--ChangeHistoryKey   /*This will be incremented automatically*/
 ChangeKey
,ProviderKey
,ChangeDateKey
,ProductGroupNameKey
,PlaceOfServiceGroupNameKey
,ServiceGroupNameKey /*Newly added*/
,QHIPValue
,QHIPRatio
,FixedValue
,FixedRatio
,ChargedValue
,ChargedRatio
,Closed
,ChangeTypeKey
,UserKey
,HistoryTimeStamp
,DateTimeChanged
,Notes
,Deleted
)
VALUES
(
 @VarChangeKey
,(select ProviderKey from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey) 
,(select ChangeDateKey from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey) 
,(select ProductGroupNameKey from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey) 
,(select PlaceOfServiceGroupNameKey from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey) 
,(select ServiceGroupNameKey from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey)  /*Newly added*/
,(select QHIPValue from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey) 
,(select QHIPRatio from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey) 
,(select FixedValue from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey) 
,(select FixedRatio from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey) 
,(select ChargedValue from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey)
,(select ChargedRatio from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey)
,(select Closed from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey)
--,(select ChangeTypeKey from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey)
,2   /*Edit*/
,(select UserKey from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey)
,NULL
,GetDate()
,(select Notes from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey)
,(select Deleted from ChangeHistory where ChangeHistoryKey=@VarChangeHistorykey)
)

/*****************************************************************************************
 STEP 02: UPDATING 'CHANGES' BY NEWLY CREATED CHANGEHISTORYKEY FOR THE GIVEN CHANGEKEY
******************************************************************************************/
SET @HoldChangeHistoryKey=SCOPE_IDENTITY()

UPDATE dbo.Changes
SET MaxChangeHistoryKey=@HoldChangeHistoryKey
WHERE ChangeKey=@VarChangeKey
SET NOCOUNT OFF;
END TRY

/*******************************************
 CATCH BLOCK
*******************************************/
BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
     -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error occurred when reverting a record.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END
END CATCH




