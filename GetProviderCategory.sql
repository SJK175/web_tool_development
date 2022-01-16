USE [ITF_Obfuscated]
GO

/****** Object:  StoredProcedure [dbo].[GetProviderCategory]    Script Date: 10-04-2016 17:14:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetProviderCategory]
AS
BEGIN TRY	

SET NOCOUNT ON	 

DECLARE @VarErrorMessage varchar(max)

SELECT DISTINCT ProviderCategoryKey, ProviderCategory FROM ProviderCategory

END TRY	

BEGIN CATCH

IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving Provider Category.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END

END CATCH

SET NOCOUNT OFF
GO


