USE [ITF_Obfuscated_Final]
GO
/****** Object:  StoredProcedure [dbo].[PlaceOfServiceGroupName]    Script Date: 10-14-2016 17:59:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[PlaceOfServiceGroupName]
AS
BEGIN TRY	
SET NOCOUNT ON
DECLARE @VarErrorMessage varchar(max)

select distinct PlaceOfServiceGroupName
from PlaceOfServiceGroupNames

END TRY	
BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving placeofservicegroupname.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END
END CATCH
SET NOCOUNT OFF
