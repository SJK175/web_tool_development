

USE [ITF_Obfuscated_Final]
GO
/****** Object:  StoredProcedure [dbo].[GetProviderType]    Script Date: 10-13-2016 19:02:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetProviderType]
AS
BEGIN

BEGIN TRY	
SET NOCOUNT ON
DECLARE @VarErrorMessage varchar(max)
SELECT DISTINCT ProviderTypeKey, ProviderType FROM dbo.ProviderTypes
WHERE ProviderTypeKey<>0
END TRY	

BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving provider type.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
	END
	END CATCH

SET NOCOUNT OFF
END
