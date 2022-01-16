USE [ITF_Obfuscated]
GO

/****** Object:  StoredProcedure [dbo].[GetStates]    Script Date: 10-04-2016 17:15:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetStates]
AS
BEGIN TRY	

SET NOCOUNT ON

DECLARE @VarErrorMessage varchar(max)

SELECT DISTINCT StateKey, StateName FROM dbo.states
WHERE Statekey<>0

END TRY	

BEGIN CATCH

IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving states.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END

END CATCH

SET NOCOUNT OFF

GO


