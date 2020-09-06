CREATE PROCEDURE [dbo].[AddSystem]
@SystemName varchar(100)
, @StateKey bigint	
AS
BEGIN TRY	

SET NOCOUNT	ON	

DECLARE @VarSystemName varchar(100)
SET @VarSystemName	= @SystemName	

DECLARE @VarStateKey bigint	
SET @VarStateKey	= @StateKey	

DECLARE @VarErrorMessage varchar(max)

INSERT INTO dbo.Systems
(
    --SystemKey - this column value is auto-generated
    SystemName,
    StateKey
)
VALUES
(
    -- SystemKey - bigint
    @VarSystemName	, -- SystemName - varchar
    @VarStateKey -- StateKey - bigint
)	

SET NOCOUNT OFF 

END TRY

BEGIN CATCH


IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 
	'An error occurred inserting a record in dbo.Systems. @SystemName=' + @VarSystemName + ', @StateKey=' + @VarStateKey	
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END

END CATCH
