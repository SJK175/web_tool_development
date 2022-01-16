
USE [ITF_Obfuscated]
GO
/****** Object:  StoredProcedure [dbo].[GetContractorDirector]    Script Date: 10-12-2016 18:06:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetContractorDirector]
 @StateKey bigint
,@RoleKey bigint
/*RoleKey=1 for Contractor & RoleKey=2 for Director*/
AS
BEGIN
BEGIN TRY	
SET NOCOUNT ON
DECLARE @VarErrorMessage varchar(max)
DECLARE @VarRoleKey bigint
	SET @VarRoleKey=@RoleKey
DECLARE @VarStateKey bigint
	SET @VarStateKey=@StateKey
select distinct contractorkey, Firstname+' '+Lastname from Contractors
where rolekey=@RoleKey 
AND StateKey=@StateKey 
SET NOCOUNT OFF
END TRY	

BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving Contractor or Director.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
	END
	END CATCH

SET NOCOUNT OFF
END
