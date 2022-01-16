USE [ITF_Obfuscated_Final]
GO
/****** Object:  StoredProcedure [dbo].[GetProvidersByKey]    Script Date: 10-17-2016 17:59:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetProvidersByKey]
@StateKey bigint,
@ProviderCategoryKey int
AS
BEGIN TRY

DECLARE @VarErrorMessage varchar(max)
-------------------------------------------------------
DECLARE @VarStateKey varchar(20)
SET @VarStateKey = @StateKey
DECLARE @VarProviderCategoryKey varchar(20)
SET @VarProviderCategoryKey=@ProviderCategoryKey
-------------------------------------------------------

    SELECT ph.ProviderKey AS [Provider Key]
           ,ph.ProviderName AS [Provider Name]
           ,ph.ProviderId AS [Provider ID]
           ,ph.MedicareId AS [Medicare ID]
           ,sy.SystemName AS [system]
           ,st.StateName AS [Physical State]
           ,CASE
               WHEN ph.Active = 1
               THEN 'TRUE'
               ELSE 'FALSE'
           END AS [Active]
           ,CASE
               WHEN ph.ShowInOutput = 1
               THEN 'TRUE'
               ELSE 'FALSE'
           END AS [ShowInOutput]
           ,pt.ProviderType AS [Provider Type]
           ,CASE
               WHEN ph.Evergreen = 1
               THEN 'TRUE'
               ELSE 'FALSE'
           END AS [Evergreen]
           ,h.HSAName AS [HSA]
           ,c.LastName + ' ' + c.FirstName AS [Contractor]
           ,d.LastName + ' ' + d.FirstName AS [Director]
           ,ph.ICAP
           ,ph.Zipcode
           ,ph.Bucket
           ,co.CountyName AS [County]
           --ROW_NUMBER() OVER(PARTITION BY ProviderKey ORDER BY ProviderHistoryKey DESC) AS rownum,
           --ProviderCategory
    FROM dbo.ProviderHistory AS ph
		 INNER JOIN dbo.Providers AS p  
		 ON ph.ProviderKey=p.ProviderKey
		 AND ph.ProviderHistoryKey=p.MaxProviderHistoryKey
         LEFT JOIN dbo.Systems AS sy ON ph.SystemKey = sy.SystemKey
         LEFT JOIN dbo.States AS st ON ph.PhysicalStateKey = st.StateKey
         LEFT JOIN dbo.ProviderTypes AS pt ON ph.ProviderTypeKey = pt.ProviderTypeKey
         LEFT JOIN dbo.HSAs AS h ON ph.HSAKey = h.HSAKey
         LEFT JOIN dbo.Contractors AS c ON ph.ContractorKey = c.ContractorKey
         LEFT JOIN dbo.ProviderCategories AS pc ON pt.ProviderCategoryKey = pc.ProviderCategoryKey
         LEFT JOIN dbo.Contractors AS d ON ph.DirectorKey = d.ContractorKey
         LEFT JOIN dbo.ZipToCounty AS ZC ON ph.Zipcode = ZC.ZipCode
         LEFT JOIN dbo.Counties AS Co ON ZC.CountyKey = Co.CountyKey

		 WHERE st.StateKey = @VarStateKey
         AND pc.ProviderCategoryKey = @VarProviderCategoryKey
END TRY 

BEGIN CATCH


IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving records for providers. @StateKey=' + @VarStateKey + ', @ProviderCategoryKey=' + @VarProviderCategoryKey	
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END

END CATCH
