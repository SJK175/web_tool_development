USE [ITF_Obfuscated]
GO

/****** Object:  StoredProcedure [dbo].[InsertMessageLog]    Script Date: 10-04-2016 17:16:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertMessageLog]
@msg varchar(max)

AS
BEGIN
SET NOCOUNT ON 
        
        INSERT INTO [dbo].[MessageLog]
        (
		   Msg
		  ,STOREROC_NM
		  ,CRE_DT 
        )
        VALUES
        (
			 @msg
		  ,ERROR_PROCEDURE()
		  ,GETDATE()  
        );
    
SET NOCOUNT OFF    
END
GO


