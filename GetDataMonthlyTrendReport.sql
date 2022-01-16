

/*
EXECUTE [dbo].[GetDataMonthlyTrendReport]
@BKey='2',
@StateKey='49',
@AsOfDate='2016-01-04',
@BackYears=1,
@ForwardYears=4,
@OutputTable_BD =OUTPUT
*/

ALTER PROCEDURE [dbo].[GetDataMonthlyTrendReport](
@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears int
, @ForwardYears int
, @OutputTable_BD nvarchar(200) Output
)

AS
BEGIN

DECLARE @BaseDataTbl varchar(200)
EXECUTE [dbo].[GetBaseData] @BKey,@stateKey,@AsOfDate,@BackYears,@ForwardYears,@OutputTable_BD output
SET @BaseDataTbl = @OutputTable_BD 

DECLARE @sql nvarchar(max)
SET @sql = 'SELECT S.StateName
      ,P.ProviderName
      ,P.ProviderId
      ,Pr.ProductName
      ,PrT.ProductTypeName
      ,PT.ProviderType
      ,Pl.PlaceOfService
      ,C.CustomerSegmentName
      ,IT.InsuredType
      ,Sy.SystemName
      ,T.[Year]
      ,T.[Month]
      ,Cast(T.[Year] AS char(4)) + CASE WHEN T.[Month] < 10 THEN ''-0'' ELSE ''-'' END + Cast(T.[Month] AS varchar(2)) AS YearMonth
      ,T.QHIPPortion
      ,T.FixedPortion
      ,T.ChargedPortion
      ,T.Total
      ,T.Allowed
FROM ' + @BaseDataTbl + ' AS T INNER JOIN dbo.States AS S 
  ON T.StateKey = S.StateKey
                     INNER JOIN dbo.vwCurrentProviders AS P
  ON T.ProviderKey = P.ProviderKey
 AND P.Active = 1
                     LEFT JOIN dbo.ProviderTypes AS PT
  ON P.ProviderTypeKey = PT.ProviderTypeKey
                     INNER JOIN dbo.Products AS Pr
  ON T.ProductKey = Pr.ProductKey
                     INNER JOIN dbo.ProductTypes AS PrT
  ON Pr.ProductTypeKey = PrT.ProductTypeKey
                     INNER JOIN dbo.PlaceOfServices AS Pl
  ON T.PlaceOfServiceKey = Pl.PlaceOfServiceKey
                     LEFT OUTER JOIN dbo.CustomerSegments AS C
  ON T.CustomerSegmentKey = C.CustomerSegmentKey
                     LEFT OUTER JOIN dbo.Systems AS Sy 
  ON P.SystemKey = Sy.SystemKey
                     LEFT OUTER JOIN dbo.InsuredTypes AS IT
  ON T.InsuredTypeKey = IT.InsuredTypeKey
WHERE P.ShowInOutput = 1
  AND P.Active = 1
  AND Pr.Active = 1
ORDER BY StateName
        ,ProviderName
        ,ProviderId
        ,ProductName
        ,ProductTypeName
        ,PlaceOfService
        ,CustomerSegmentName
        ,[Year]
        ,[Month]'

EXECUTE sp_executesql @sql

/****************************************
--Dropping physical tables those were
created in intermidiate steps.
****************************************/
set @sql = 'DROP table ' + @BaseDataTbl
exec sp_executesql @sql


END
