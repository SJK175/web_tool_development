CREATE PROCEDURE [dbo].[AddHSA]
@StateKey bigint	
,@HSAName varchar(30)
AS
BEGIN TRY	  

SET NOCOUNT ON	

DECLARE @VarStateKey bigint
DECLARE @VarHSAName varchar(256)

DECLARE @VarErrorMessage varchar(max)

SET	@VarStateKey	= @StateKey	
SET	@VarHSAName	= @HSAName	

INSERT	INTO	dbo.HSAs
(
    --HSAKey - this column value is auto-generated
    StateKey,
    HSAName
)
VALUES
(
    -- HSAKey - bigint
    @VarStateKey	, -- StateKey - bigint
    @VarHSAName	 -- HSAName - varchar
)	

END TRY 

BEGIN CATCH


IF @@ERROR <> 0 
    BEGIN
     -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error occurred inserting a record in HSAs. @StateKey=' + @VarStateKey + ', @HSAName=' + @VarHSAName
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END
END CATCH
