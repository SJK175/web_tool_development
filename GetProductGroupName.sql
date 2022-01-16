USE [ITF_Obfuscated_Final]
GO
/****** Object:  StoredProcedure [dbo].[ProductGroupName]    Script Date: 10-14-2016 18:00:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ProductGroupName]
@StateKey Bigint
AS

BEGIN TRY	
SET NOCOUNT ON

DECLARE @VarErrorMessage varchar(max)
DECLARE @varStateKey bigint
SET @varStateKey=@Statekey

select distinct ProductGroupName 
from ProductGroupNames
where StateKey=@VarStateKey
END TRY	

BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving productgroupname.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END
END CATCH
SET NOCOUNT OFF
