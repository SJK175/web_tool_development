
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[AddEditTrendV2]
 @ChangeKey bigint
,@ProviderKey bigint
--,@ChangeDateKey bigint
,@DateDate date 
,@ProductGroupNameKey bigint
,@PlaceOfServiceGroupNameKey bigint
,@ServiceGroupNameKey bigint
,@QHIPValue decimal(10,5)
,@QHIPRatio decimal(10,5)
,@FixedValue decimal(10,5)
,@FixedRatio decimal(10,5)
,@ChargedValue decimal(10,5)
,@ChargedRatio decimal(10,5)
,@Closed smallint
,@Deleted int
,@StateKey bigint
,@Edit bit
,@LineOfBusinessKey int

AS
BEGIN TRY
SET NOCOUNT ON;
DECLARE @VarErrorMessage varchar(max)
DECLARE @VarChangeKey bigint
/*IF @Edit=1 @VarChangeKey=@ChangeKey
ELSE @VarChangeKey=Auto incremented value*/

DECLARE @VarProviderKey bigint
SET @VarProviderKey=@ProviderKey
/*DECLARE @VarChangeDateKey bigint
SET @VarChangeDateKey=@ChangeDateKey*/
DECLARE @VarDateDate date
SET @VarDateDate=@DateDate
DECLARE @VarProductGroupNameKey bigint
SET @VarProductGroupNameKey=@ProductGroupNameKey
DECLARE @VarPlaceOfServiceGroupNameKey bigint
SET @VarPlaceOfServiceGroupNameKey=@PlaceOfServiceGroupNameKey
DECLARE @VarServiceGroupNameKey bigint
SET @VarServiceGroupNameKey = @ServiceGroupNameKey   
DECLARE @VarQHIPValue decimal(10,5)
SET @VarQHIPValue=@QHIPValue
DECLARE @VarQHIPRatio decimal(10,5)
SET @VarQHIPRatio=@QHIPRatio
DECLARE @VarFixedValue decimal(10,5)
SET @VarFixedValue=@FixedValue
DECLARE @VarFixedRatio decimal(10,5)
SET @VarFixedRatio=@FixedRatio
DECLARE @VarChargedValue decimal(10,5)
SET @VarChargedValue=@ChargedValue
DECLARE @VarChargedRatio decimal(10,5)
SET @VarChargedRatio=@ChargedRatio
DECLARE @VarClosed smallint
SET @VarClosed=@Closed
DECLARE @VarDeleted int
SET @VarDeleted=@Deleted
DECLARE @VarStateKey bigint
SET @VarStateKey=@StateKey
DECLARE @VarLineOfBusinessKey int
SET @VarLineOfBusinessKey=@LineOfBusinessKey
DECLARE @VarEdit bit
SET @VarEdit=@Edit

/********************ADD MODE*******************/
IF @VarEdit=0   -- Add mode
    BEGIN

	   /*STEP01: Inserting Value into 'Changes'*/
	   INSERT INTO dbo.Changes
	   (
	    --ChangeKey  /*This will be incremented automatically*/
	    Statekey
	   ,ProviderKey
	   ,MaxChangeHistoryKey
	   ,Deleted
	   ,Notes
	   ,LineOfBusinessKey
	   )
	   VALUES
	   (
	    --@ChangeKey
	    @VarStateKey
	   ,@VarProviderKey
	   ,-1
	   ,@VarDeleted
	   ,NULL	 
	   ,@VarLineOfBusinessKey
	   )

	   SET @VarChangeKey=SCOPE_IDENTITY();
    END

/**********************Edit Mode************************************/
ELSE	   
    BEGIN	  
	   SET @VarChangeKey  = ISNULL(@ChangeKey, 0)
    END 
--END Insert into Change
-- START Insert into ChangeHistory
IF @VarChangeKey <> 0 -- If Change Key as sent by UI is a valid one
    BEGIN
	   INSERT INTO dbo.ChangeHistory
	   (
	   --ChangeHistoryKey   /*This will be incremented automatically*/
	    ChangeKey
	   ,ProviderKey
	   ,ChangeDateKey
	   ,ProductGroupNameKey
	   ,PlaceOfServiceGroupNameKey
	   ,ServiceGroupNameKey
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
	   ,@VarProviderKey
	   ,(SELECT DateKey from dbo.Dates where DateDate=@DateDate)
	   ,@VarProductGroupNameKey
	   ,@VarPlaceOfServiceGroupNameKey
	   ,@VarServiceGroupNameKey   
	   ,@VarQHIPValue
	   ,@VarQHIPRatio
	   ,@VarFixedValue
	   ,@VarFixedRatio
	   ,@VarChargedValue
	   ,@VarChargedRatio
	   ,@VarClosed
	   ,CASE WHEN	@Edit=0 THEN 1 ELSE 2 END -- 1=Original and 2=Edited
	   ,NULL	 
	   ,NULL
	   ,GetDate()
	   ,NULL	 
	   ,@VarDeleted 
	   )

	   -- declare variable to hold last inserted change history key
	   DECLARE @VarChangeHistoryKey bigint
	   -- Get the last inserted identity - ChangeHistoryKey
	   SET @VarChangeHistoryKey = SCOPE_IDENTITY()

	   -- Set MaxChangeHistoryKey (in Change) = last inserted ChangeHistoryKey
	   UPDATE dbo.Changes
	   SET MaxChangeHistoryKey=@VarChangeHistoryKey
	   WHERE ChangeKey=@VarChangeKey 
    END

ELSE
BEGIN TRY
RAISERROR ('Change key is zero',16,1); 	
END TRY
BEGIN CATCH
EXEC	dbo.InsertErrorLog
END CATCH
SET NOCOUNT OFF;
END TRY



BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
     -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error occurred when editing/adding a record.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END
END CATCH
