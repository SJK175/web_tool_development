/*
EXECUTE [dbo].[GetCapReportData]
@BKey='2',
@StateKey='49',
@AsOfDate='2016-01-04',
@BackYears=1,
@ForwardYears=4,
@OutputTable = BaseData_BDE3AF7BE53B49F18E0B6D8772A2F985
*/




alter PROCEDURE [dbo].[GetCapReportData](
@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears int
, @ForwardYears int
, @OutputTable nvarchar(200) 
)

AS
BEGIN

DECLARE @VarOutputTable varchar(200)
SET @VarOutputTable = @OutputTable

DECLARE @sql nvarchar(max)
SET @sql = 'SELECT StateName
      ,[Grouping]
      ,ProductType
      ,CustomerSegment
      ,[Year]
      ,[Month]
      ,YearMonth
      ,sum(Total) AS Total
FROM (SELECT S.StateName
      ,CASE 
       WHEN P.ProviderId IN (''0P0'',''0T2'',''0DF'',''0GL'',''0UL'',''69U'',''7KJ'',''0ZH'',''0YP'',''1CP'',''0ZM'',''0T7'',''0LY'',''0LZ'',''0EY'',
       ''1BS'',''1CL'',''0EZ'',''0GH'',''0YC'',''0DR'',''0SY'',''0CJ'',''0HQ'',''0YW'',''0HA'',''0T4'',''ACG'',''0K3'',''0AW'') THEN ''ICAP PMG Jan 2011''
       ELSE                         ''NON ICAP PMG''
       END AS [Grouping]
       ,PrT.ProductTypeName      AS [ProductType]
       ,CASE 
       WHEN C.CustomerSegmentName IN (''Gaurantee'',''Capitation'') THEN ''POS''
       ELSE C.CustomerSegmentName
       END                      AS [CustomerSegment]
       ,T.[Year]
       ,T.[Month]
       ,Cast(T.[Year] AS char(4)) + CASE WHEN T.[Month] < 10 THEN ''-0'' ELSE ''-'' END + Cast(T.[Month] AS varchar(2)) AS YearMonth
       ,T.Allowed AS Total
       FROM ' + @VarOutputTable + ' AS T INNER JOIN dbo.States AS S 
       ON T.StateKey = S.StateKey
       INNER JOIN dbo.vwCurrentProviders AS P
       ON T.ProviderKey = P.ProviderKey
       AND P.Active = 1
       LEFT JOIN dbo.Products AS Pr
       ON T.ProductKey = Pr.ProductKey
       INNER JOIN dbo.ProductTypes AS PrT
       ON Pr.ProductTypeKey = PrT.ProductTypeKey
       INNER JOIN dbo.CustomerSegments AS C
       ON T.CustomerSegmentKey = C.CustomerSegmentKey
WHERE P.ShowInOutput = 1
        AND P.Active = 1
        AND Pr.Active = 1) AS SQ
WHERE CustomerSegment IN (''Large Group'',''Small Group'',''Individual'')
Group BY StateName
      ,[Grouping]
      ,ProductType
      ,CustomerSegment
      ,[Year]
      ,[Month]
      ,YearMonth
 
union
 
SELECT StateName
      ,[Grouping]
      ,ProductType
      ,''SG+LG+Ind+POS''            AS CustomerSegment
      ,[Year]
      ,[Month]
      ,YearMonth
      ,sum(Total) AS Total
FROM (SELECT S.StateName
     ,CASE 
      WHEN P.ProviderId IN (''0P0'',''0T2'',''0DF'',''0GL'',''0UL'',''69U'',''7KJ'',''0ZH'',''0YP'',''1CP'',''0ZM'',''0T7'',''0LY'',''0LZ'',''0EY'',
      ''1BS'',''1CL'',''0EZ'',''0GH'',''0YC'',''0DR'',''0SY'',''0CJ'',''0HQ'',''0YW'',''0HA'',''0T4'',''ACG'',''0K3'',''0AW'') THEN ''ICAP PMG Jan 2011''
      ELSE                         ''NON ICAP PMG''
      END AS [Grouping]
      ,PrT.ProductTypeName      AS [ProductType]
      ,T.[Year]
       ,T.[Month]
       ,Cast(T.[Year] AS char(4)) + CASE WHEN T.[Month] < 10 THEN ''-0'' ELSE ''-'' END + Cast(T.[Month] AS varchar(2)) AS YearMonth
       ,T.Allowed AS Total
       FROM ' + @VarOutputTable + ' AS T INNER JOIN dbo.States AS S 
       ON T.StateKey = S.StateKey
       INNER JOIN dbo.vwCurrentProviders AS P
       ON T.ProviderKey = P.ProviderKey
       AND P.Active = 1
       LEFT JOIN dbo.Products AS Pr
       ON T.ProductKey = Pr.ProductKey
       INNER JOIN dbo.ProductTypes AS PrT
       ON Pr.ProductTypeKey = PrT.ProductTypeKey
       INNER JOIN dbo.CustomerSegments AS C
       ON T.CustomerSegmentKey = C.CustomerSegmentKey
WHERE P.ShowInOutput = 1
        AND P.Active = 1
        AND Pr.Active = 1) AS SQ
Group BY StateName
      ,[Grouping]
      ,ProductType
      ,[Year]
      ,[Month]
      ,YearMonth
 
 
ORDER BY StateName
      ,[Grouping]
      ,ProductType
      ,CustomerSegment
      ,[Year]
      ,[Month]'

execute sp_executesql @sql
select @sql


/*
set @sql = 'DROP table ' + @VarOutputTable
exec sp_executesql @sql 
*/

END
