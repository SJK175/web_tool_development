
USE [ITF_Obfuscated]
GO
/****** Object:  StoredProcedure [dbo].[GetHSA]    Script Date: 10-12-2016 18:04:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetHSA]
@StateKey bigint
AS
BEGIN

BEGIN TRY	
SET NOCOUNT ON
DECLARE @VarErrorMessage varchar(max)
DECLARE @VarStateKey bigint
	SET @VarStateKey=@StateKey
SELECT DISTINCT HSAKey, HSAName FROM dbo.HSAs
WHERE StateKey=@VarStateKey
END TRY	

BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving HSA.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
	END
	END CATCH

SET NOCOUNT OFF
END

