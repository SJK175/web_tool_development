

USE [ITF_Obfuscated]
GO
/****** Object:  StoredProcedure [dbo].[GetSystem]    Script Date: 10-12-2016 18:03:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetSystem]
@StateKey bigint
AS
BEGIN

BEGIN TRY	
SET NOCOUNT ON
DECLARE @VarErrorMessage varchar(max)
DECLARE @VarStateKey bigint
	SET @VarStateKey=@StateKey

SELECT DISTINCT SystemKey, SystemName FROM dbo.Systems
WHERE StateKey =@VarStateKey
END TRY	

BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving SystemName.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
	END
	END CATCH

SET NOCOUNT OFF
END



	
