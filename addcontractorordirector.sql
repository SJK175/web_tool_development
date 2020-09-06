CREATE PROCEDURE [dbo].[AddContractorOrDirector]
(
@RoleKey int
,@StateKey bigint	
,@FirstName varchar(50)
,@LastName varchar(50)
,@PhoneNumber varchar(15)
,@Email varchar(100)
,@Director varchar(100) = NULL	
)
AS
BEGIN TRY	

SET NOCOUNT ON 

DECLARE @VarErrorMessage varchar(max)

DECLARE @VarRoleKey int
SET @VarRoleKey	= @RoleKey

DECLARE @VarStateKey bigint
SET @VarStateKey = @StateKey	

DECLARE @VarFirstName varchar(50)
SET @VarFirstName = @FirstName	

DECLARE @VarLastName varchar(50)
SET @VarLastName = @LastName	

DECLARE @VarPhoneNumber varchar(15)
SET @VarPhoneNumber	= @PhoneNumber	

DECLARE	@VarEmail varchar(100)
SET @VarPhoneNumber	= @PhoneNumber	

DECLARE @VarDirector varchar(100)
SET @VarDirector = @Director	



insert into Contractors
(
--ContractorKey
RoleKey
,StateKey
,FirstName
,LastName
,PhoneNumber
,Email
,Director
)
VALUES	
(
@VarRoleKey	
,@VarStateKey	
,@VarFirstName	
,@VarLastName	
,@VarPhoneNumber		
,@VarEmail	
,@VarDirector	
)

END TRY	

BEGIN CATCH

IF @@ERROR <> 0 
    BEGIN
     -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error occurred inserting a record in Contrator.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END
END CATCH
