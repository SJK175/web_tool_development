USE [ITF_Obfuscated]
GO

/****** Object:  StoredProcedure [dbo].[InsertErrorLog]    Script Date: 10-04-2016 17:16:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertErrorLog]
AS
BEGIN
SET NOCOUNT ON 
        
    INSERT INTO [dbo].[ErrorLog]
    (
	    ErrorNumber 
	   ,ErrorDescription 
	   ,ErrorProcedure 
	   ,ErrorState 
	   ,ErrorSeverity 
	   ,ErrorLine 
	   ,ErrorTime 
    )
    VALUES
    (
	    ERROR_NUMBER()
	   ,ERROR_MESSAGE()
	   ,ERROR_PROCEDURE()
	   ,ERROR_STATE()
	   ,ERROR_SEVERITY()
	   ,ERROR_LINE()
	   ,GETDATE()  
    );
    
SET NOCOUNT OFF    
END
GO


