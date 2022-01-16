/* TrendComparisons */

/*
EXECUTE [dbo].[GetTrendComparisons]
@tempBaseDataCompareTable = TempBaseDataCompareTableA9F5E6D3DFCF4321B87AD56A2DD3A68C
,@Rank = 1

*/

USE [ITF_Obfuscated_Final]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetTrendComparisons](
@tempBaseDataCompareTable nvarchar (250)
,@Rank BigInt
)

AS
BEGIN

DECLARE @VarOutputTable varchar(250)
SET @VarOutputTable = 'BaseData_A9F5E6D3DFCF4321B87AD56A2DD3A68C'


DECLARE @VarTrendComparisonsTable varchar(200)
SET @VarTrendComparisonsTable = @tempBaseDataCompareTable

DECLARE @sql nvarchar(max)
SET @sql = 'SELECT Metric
       ,StateName AS [State]
       ,ProviderName AS [Provider]
       ,[Value]
       ,[Order]
       ,[Rank]
       ,[Year]
 FROM (
 SELECT ''Dollar_1'' AS Metric
       ,StateName
       ,ProviderName
       ,ProviderId
       ,D_1        AS [Value]
       ,[Order]
       ,[Rank]
       ,[Year]
 FROM (SELECT StateName, ProviderName, ProviderId, [Year], D_1, 1 AS [Order], 
 ROW_NUMBER() over (ORDER BY D_1 desc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
      ' WHERE D_1 > 0
  
       union
  
       SELECT StateName, ProviderName, ProviderId, [Year], D_1, 0 AS [Order], ROW_NUMBER() over (ORDER BY D_1 asc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
      ' WHERE D_1 < 0) AS SQ
 WHERE [Rank] <= 1
  
  
 union
  
 SELECT ''Dollar_2'' AS Metric
       ,StateName
       ,ProviderName
       ,ProviderId
       ,D_2        AS [Value]
       ,[Order]
       ,[Rank]
       ,[Year]
 FROM (SELECT StateName, ProviderName, ProviderId, [Year], D_2, 1 AS [Order], ROW_NUMBER() over (ORDER BY D_2 desc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
       ' WHERE D_2 > 0
  
       union
  
       SELECT StateName, ProviderName, ProviderId, [Year], D_2, 0 AS [Order], ROW_NUMBER() over (ORDER BY D_2 asc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
       ' WHERE D_2 < 0) AS SQ
 WHERE [Rank] <= 1
  
 union
  
 SELECT ''Dollar_3'' AS Metric
       ,StateName
       ,ProviderName
       ,ProviderId
       ,D_3        AS [Value]
       ,[Order]
       ,[Rank]
       ,[Year]
 FROM (SELECT StateName, ProviderName, ProviderId, [Year], D_3, 1 AS [Order], ROW_NUMBER() over (ORDER BY D_3 desc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
       ' WHERE D_3 > 0
  
       union
  
       SELECT StateName, ProviderName, ProviderId, [Year], D_3, 0 AS [Order], ROW_NUMBER() over (ORDER BY D_3 asc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
       ' WHERE D_3 < 0) AS SQ
 WHERE [Rank] <= 1
  
 union
  
 -------------------
 -- BY percentage --
 -------------------
 SELECT ''Percent_1'' AS Metric
       ,StateName
       ,ProviderName
       ,ProviderId
       ,P_1        AS [Value]
       ,[Order]
       ,[Rank]
       ,[Year]
 FROM (SELECT StateName, ProviderName, ProviderId, [Year], P_1, 1 AS [Order], ROW_NUMBER() over (ORDER BY P_1 desc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
       ' WHERE P_1 > 0
  
       union
  
       SELECT StateName, ProviderName, ProviderId, [Year], P_1, 0 AS [Order], ROW_NUMBER() over (ORDER BY P_1 asc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
       ' WHERE P_1 < 0) AS SQ
 WHERE [Rank] <= 1
  
 union
  
 SELECT ''Percent_2'' AS Metric
       ,StateName
       ,ProviderName
       ,ProviderId
       ,P_2        AS [Value]
       ,[Order]
       ,[Rank]
       ,[Year]
 FROM (SELECT StateName, ProviderName, ProviderId, [Year], P_2, 1 AS [Order], ROW_NUMBER() over (ORDER BY P_2 desc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
       ' WHERE P_2 > 0
  
       union
  
       SELECT StateName, ProviderName, ProviderId, [Year], P_2, 0 AS [Order], ROW_NUMBER() over (ORDER BY P_2 asc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
       ' WHERE P_2 < 0) AS SQ
 WHERE [Rank] <= 1
  
 union
  
 SELECT ''Percent_3'' AS Metric
       ,StateName
       ,ProviderName
       ,ProviderId
       ,P_3        AS [Value]
       ,[Order]
       ,[Rank]
       ,[Year]
 FROM (SELECT StateName, ProviderName, ProviderId, [Year], P_3, 1 AS [Order], ROW_NUMBER() over (ORDER BY P_3 desc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
       ' WHERE P_3 > 0
  
       union
  
       SELECT StateName, ProviderName, ProviderId, [Year], P_3, 0 AS [Order], ROW_NUMBER() over (ORDER BY P_3 asc) AS [Rank]
       FROM ' + @VarTrendComparisonsTable +
       ' WHERE P_3 < 0) AS SQ
 WHERE [Rank] <= 1) AS SQ
  
  
 ORDER BY Metric, [Order] desc, [Rank]'

 EXECUTE sp_executesql @sql
 SELECT @sql

 --SET @sql = N'select * from ' + @VarTrendComparisonsTable
 --EXECUTE sp_executesql @sql


 END
 

/* select * from dbo.TempBaseDataCompareTableA9F5E6D3DFCF4321B87AD56A2DD3A68C */
