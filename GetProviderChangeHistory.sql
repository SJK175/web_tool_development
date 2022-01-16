USE [ITF_Obfuscated]
GO

/****** Object:  StoredProcedure [dbo].[GetProviderChangeHistory]    Script Date: 10-04-2016 17:15:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetProviderChangeHistory]
@ProviderKey bigint
AS
BEGIN TRY

DECLARE @VarErrorMessage varchar(max)

---------------------------------------
DECLARE @VarProviderKey bigint;
SET @VarProviderKey = @ProviderKey;
---------------------------------------

SELECT ph.ProviderHistoryKey AS [History Key],
       ph.ProviderName AS [Provider Name],
       ph.ProviderId AS [Provider ID],
       pt.ProviderType AS [Provider Type],
       sy.SystemName AS [System],
       st.StateName AS [Physical State],
       ph.MedicareId AS [Medicare ID],
       ph.NPI,
       CASE
           WHEN ph.ShowInOutput = 1
           THEN 'TRUE'
           ELSE 'FALSE'
       END AS [ShowInOutput],
       CASE
           WHEN ph.Active = 1
           THEN 'TRUE'
           ELSE 'FALSE'
       END AS [Active],
       CASE
           WHEN ph.Evergreen = 1
           THEN 'TRUE'
           ELSE 'FALSE'
       END AS [Evergreen],
       h.HSAName AS [HSAname],
       c.LastName + ' ' + c.FirstName AS [Contractor],
       ph.Contracted,
       ph.ICAP,
       ph.Bucket,
       d.LastName + ' ' + d.FirstName AS [Director],
       ph.Zipcode,
       ph.TimeStamp,
       us.FirstName + ' ' + us.LastName AS [User]
FROM dbo.ProviderHistory AS ph
     LEFT JOIN dbo.Systems AS sy ON ph.SystemKey = sy.SystemKey
     LEFT JOIN dbo.States AS st ON ph.PhysicalStateKey = st.StateKey
     LEFT JOIN dbo.ProviderTypes AS pt ON ph.ProviderTypeKey = pt.ProviderTypeKey
     LEFT JOIN dbo.HSAs AS h ON ph.HSAKey = h.HSAKey
     LEFT JOIN dbo.Contractors AS c ON ph.ContractorKey = c.ContractorKey
     LEFT JOIN dbo.ProviderCategory AS pc ON pt.ProviderCategoryKey = pc.ProviderCategoryKey
     LEFT JOIN dbo.Users AS us ON ph.UserKey = us.UserKey
     LEFT JOIN dbo.Contractors AS d ON ph.DirectorKey = d.ContractorKey
WHERE ph.ProviderKey = @VarProviderKey;
--END
END TRY

BEGIN CATCH


IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving records for providers. @ProviderKey=' + @VarProviderKey	
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END

END CATCH
GO


