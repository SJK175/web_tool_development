ALTER PROCEDURE  [dbo].[AddEditProvider]
@ProviderCategoryKey int
,@ProviderName varchar(255)
,@ProviderId varchar(50)
,@MedicareId varchar(50)
,@SystemKey int
,@StateKey varchar(50)
,@Active bit
,@ShowInOutput bit
,@ProviderTypeKey bigint
,@Evergreen bit
,@HSAKey bigint
,@ContractorKey bigint = 0
,@DirectorKey bigint = 0
,@ICAP bit
,@ZipCode char(5)
,@Bucket bit
,@Edit bit
,@ProviderKey bigint
AS 
BEGIN TRY

SET NOCOUNT ON;

DECLARE @VarErrorMessage varchar(max)

-- declare variable to hold last inserted provider key
-- For edit, set this variable from @ProviderKey as passed by parameter
DECLARE @VarProviderKey int  

DECLARE @VarProviderCategoryKey int 
SET @VarProviderCategoryKey	= @ProviderCategoryKey	

DECLARE @VarProviderName varchar(255)
SET @VarProviderName	= @ProviderName	

DECLARE @VarProviderId varchar(50)
SET @VarProviderId	= @ProviderId	

DECLARE @VarMedicareId varchar(50)
SET @VarMedicareId	= @MedicareId	

DECLARE @VarSystemKey int
SET	@VarSystemKey	= @SystemKey	

DECLARE @VarStateKey int
SET @VarStateKey	= @StateKey	

DECLARE @VarActive bit
SET @VarActive	= @Active	

DECLARE @VarShowInOutput bit
SET @VarShowInOutput	= @ShowInOutput	

DECLARE @VarProviderTypeKey int
SET @VarProviderTypeKey	= @ProviderTypeKey	

DECLARE @VarEvergreen bit
SET @VarEvergreen	= @Evergreen	

DECLARE @VarHSAKey int
SET @VarHSAKey	= @HSAKey	

DECLARE @VarContractorKey int
SET @VarContractorKey	= ISNULL(@ContractorKey,0)	

DECLARE @varDirectorKey bigint
SET @varDirectorKey	= ISNULL(@DirectorKey,0)	

DECLARE @VarICAP bit
SET @VarICAP	= @ICAP	

DECLARE @VarZipCode char(5)
SET @VarZipCode	= @ZipCode	

DECLARE @VarBucket bit
SET @VarBucket	= @Bucket	

DECLARE @VarEdit bit
SET @VarEdit	= @Edit	


IF @VarEdit = 0 -- Add mode
    BEGIN   
	   -- Insert into Providers - set MaxProviderHistoryKey as -1 
	   INSERT INTO dbo.Providers
	   (
		  --ProviderKey - this column value is auto-generated
		  ProviderCategoryKey,
		  StateKey,
		  MaxProviderHistoryKey
	   )
	   VALUES
	   (
		  -- ProviderKey - bigint
		  @VarProviderCategoryKey , -- ProviderCategoryKey - bigint
		  @VarStateKey	, -- StateKey - bigint
		  -1 -- MaxProviderHistoryKey - bigint
	   )   

	   -- Get the last inserted identity - ProviderKey
	   SET @VarProviderKey	= SCOPE_IDENTITY();
    END	
ELSE	-- Edit mode   
    BEGIN
    /*
	   SELECT @VarProviderKey = p.ProviderKey
	   FROM dbo.Providers p
		  INNER JOIN dbo.ProviderHistory ph ON ph.ProviderKey = p.ProviderKey
	   WHERE ph.ProviderName = @VarProviderName;
    */
	   SET @VarProviderKey  = ISNULL(@ProviderKey,0) 
    END 

IF @VarProviderKey	<> 0 -- if provider key is a valid one
	BEGIN	
		-- Insert into ProviderHistory
		INSERT INTO dbo.ProviderHistory
		(
			--ProviderHistoryKey - this column value is auto-generated
			ProviderKey,
			ProviderName,
			ProviderId,
			ProviderTypeKey,
			SystemKey,
			PhysicalStateKey,
			LocationKey,
			MedicareId,
			NPI,
			ShowInOutput,
			Active,
			Evergreen,
			HSAKey,
			ContractorKey,
			Contracted,
			ICAP,
			Bucket,
			DirectorKey,
			Zipcode,
			TimeStamp,
			UserKey
		)
		VALUES
		(
			-- ProviderHistoryKey - bigint
			@VarProviderKey , -- ProviderKey - bigint
			@VarProviderName    , -- ProviderName - varchar
			@VarProviderId	, -- ProviderId - varchar
			@VarProviderTypeKey, -- ProviderTypeKey - bigint
			@VarSystemKey	 , -- SystemKey - bigint
			@VarStateKey	, -- PhysicalStateKey - bigint
			0, -- LocationKey - bigint
			@VarMedicareId	, -- MedicareId - varchar
			'', -- NPI - varchar
			@VarShowInOutput    , -- ShowInOutput - bit
			@VarActive	 , -- Active - bit
			@Evergreen	 , -- Evergreen - bit
			@HSAKey	  , -- HSAKey - bigint
			@VarContractorKey	, -- ContractorKey - bigint
			0, -- Contracted - bit
			@VarICAP	 , -- ICAP - bit
			@Bucket , -- Bucket - bit
			@varDirectorKey	, -- DirectorKey - bigint
			@VarZipCode , -- Zipcode - char
			GETDATE()	 , -- TimeStamp - datetime
			0 -- UserKey - bigint
		)   

		-- declare variable to hold last inserted provider history key
		DECLARE @VarProviderHistoryKey bigint	
		-- Get the last inserted identity - ProviderHistoryKey
		SET @VarProviderHistoryKey = SCOPE_IDENTITY()  

		-- Set MaxProviderHistoryKey (in provider) = last inserted ProviderHistoryKey
		UPDATE dbo.Providers SET MaxProviderHistoryKey = @VarProviderHistoryKey WHERE ProviderKey = @VarProviderKey

	END	
ELSE	-- If provider key is zero raise an error
	BEGIN TRY
           RAISERROR	('Provider key is zero', -- Message text.
               16, -- Severity.
               1 -- State.
               ); 	
    END TRY
    BEGIN CATCH
        EXEC	dbo.InsertErrorLog
    END CATCH		
		 
SET NOCOUNT OFF
END TRY

BEGIN CATCH

IF @@ERROR <> 0 
    BEGIN
     -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error occurred inserting a record in Provider or ProverHistory.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END
END CATCH
