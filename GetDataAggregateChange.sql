
/*
EXECUTE [dbo].[GetDataAggregateChange]
@BKey='1',
@StateKey='49',
@AsOfDate='2016-01-04',
@BackYears=0,
@ForwardYears=4,
@OutputTable_BD =output 
*/

CREATE PROCEDURE [dbo].[GetDataAggregateChange](
@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears int
, @ForwardYears int
, @OutputTable_BD nvarchar(200) output
)

AS
BEGIN

/******************************************************
--Executing BaseData SP & creating BaseData
******************************************************/
DECLARE @BaseDataTbl as nvarchar(250)
EXECUTE [dbo].[GetBaseData] @BKey,@stateKey,@AsOfDate,@BackYears,@ForwardYears,@OutputTable_BD output
SET @BaseDataTbl=@OutputTable_BD

/*****************************************
--Creating two temp tables
*****************************************/
--DECLARE @VarOutputTable varchar(250)
--SET @VarOutputTable = @OutputTable_BD

---Temp Table 01
SELECT S.StateName
     ,CE.ProviderKey
     ,CE.ProductKey
     ,CE.PlaceOfServiceKey
     ,CE.Closed
     ,D.DateYear
     ,D.DateMonth
     ,ROW_NUMBER() OVER (PARTITION BY S.StateName, CE.ProviderKey, CE.ProductKey, CE.PlaceOfServiceKey, D.DateYear ORDER BY D.DateDate asc) AS IncItem
INTO  #VarOutputTableA
FROM (select * from dbo.ChangesExpanded (@Bkey,@StateKey ,cast(@AsOfDate as varchar(10)),cast(@BackYears as varchar(10)) )) AS CE 
INNER JOIN dbo.Dates AS D
ON CE.ChangeDateKey = D.Datekey
INNER JOIN dbo.States AS S
ON CE.StateKey = S.StateKey
WHERE CE.StateKey IN (SELECT StateKey 
FROM  (select * from dbo.Statebase(@Bkey,@StateKey,cast(@AsOfDate as varchar(10)),cast(@BackYears as varchar(10)) )) as tSB)
 /*and ((1+CE.QHIP_RV) * (1+CE.Fixed_RV) * (1+CE.Charged_RV))-1 <> 0 */

---Temp Table-02
CREATE TABLE #VarOutputTableB
(
StateName varchar(50)
,ProviderKey  bigint
,ProductKey  bigint
,PlaceOfServiceKey  bigint
,DateYear int
,DateMonth int
,Total decimal(38,5)
)

DECLARE @sql_b nvarchar(max)
SET @sql_b =  'Select S.StateName
     ,T.ProviderKey
     ,T.ProductKey
     ,T.PlaceOfServiceKey
     ,T.[Year]               AS DateYear
     ,T.[Month]              AS DateMonth
     ,sum(T.Allowed)         AS Total
FROM ' + @BaseDataTbl + ' AS T 
INNER JOIN dbo.States AS S
ON T.StateKey = S.Statekey
WHERE T.StateKey IN (SELECT StateKey FROM  (select * from dbo.Statebase(''' + @Bkey + ''',''' + @StateKey + ''',''' + cast(@AsOfDate as varchar(10)) + ''',' + cast(@BackYears as varchar(10)) + ')) as tSB)
Group BY S.StateName
      ,T.ProviderKey
      ,T.ProductKey
      ,T.PlaceOfServiceKey
      ,T.[Year]
      ,T.[Month]'

INSERT INTO #VarOutputTableB
EXEC sp_executesql @sql_b

/**********************************************
--Query for Final Report of Aggregate change
**********************************************/

SELECT S.StateName
      ,P.ProviderName
      ,P.ProviderId
      ,Pr.ProductName
      ,POS.PlaceOfService
      ,CASE WHEN A.Closed = 1 THEN 'Yes' ELSE 'No' END AS Signed
      ,cast(a.DateYear AS varchar(4)) + '-' + CASE WHEN a.DateMonth < 10 THEN '0' 
	   ELSE '' END + CAST(a.datemonth AS varchar(2)) AS YearMonth
      ,b.Total  AS CurrentTotal
      ,CASE  
         WHEN c.Total IS null THEN b.Total
         ELSE c.Total
       END AS PreviousTotal
      ,D.YearTotal / E.MaxIncs AS TotalAllowed
FROM #VarOutputTableA  AS a 
INNER JOIN #VarOutputTableB AS b
  ON a.ProviderKey       = b.ProviderKey
 AND a.ProductKey        = b.ProductKey
 AND a.PlaceOfServiceKey = b.PlaceOfServiceKey
 AND a.DateYear          = b.DateYear
 AND a.DateMonth         = b.DateMonth
                  LEFT OUTER JOIN #VarOutputTableB AS c
  ON a.ProviderKey       = c.ProviderKey
 AND a.ProductKey        = c.ProductKey
 AND a.PlaceOfServiceKey = c.PlaceOfServiceKey
 AND CASE 
       WHEN a.DateMonth = 1 AND c.DateMonth = 12 AND a.DateYear - 1 = c.DateYear          THEN 1
       WHEN a.DateMonth > 1 AND a.DateMonth - 1 = c.DateMonth AND a.DateYear = c.DateYear THEN 1
       ELSE 0
     END = 1
                  INNER JOIN (SELECT ProviderKey
                                    ,ProductKey
                                    ,PlaceOfServiceKey
                                    ,DateYear
                                    ,sum(Total)        AS YearTotal
                              FROM #VarOutputTableB 
                              Group BY ProviderKey
                                      ,ProductKey
                                      ,PlaceOfServiceKey
                                      ,DateYear) AS D
  ON a.ProviderKey       = D.ProviderKey
 AND a.ProductKey        = D.ProductKey
 AND a.PlaceOfServiceKey = D.PlaceOfServiceKey 
 AND a.DateYear          = D.DateYear   
                                   INNER JOIN (SELECT ProviderKey
                                                     ,ProductKey
                                                     ,PlaceOfServiceKey
                                                     ,DateYear
                                                     ,Max(IncItem) AS MaxIncs
                                               FROM #VarOutputTableA 
                                               group BY ProviderKey 
                                                       ,ProductKey
                                                       ,PlaceOfServiceKey
                                                       ,DateYear) AS E
  ON a.ProviderKey       = E.ProviderKey
 AND a.ProductKey        = E.ProductKey
 AND a.PlaceOfServiceKey = E.PlaceOfServiceKey 
 AND a.DateYear          = E.DateYear                
                                   INNER JOIN dbo.vwCurrentProviders AS P
  ON A.ProviderKey = P.Providerkey
 AND P.Active = 1 
                                   INNER JOIN dbo.Products AS Pr
  ON A.ProductKey  = Pr.ProductKey
                                   INNER JOIN dbo.PlaceOfServices AS POS
  ON A.PlaceOfServiceKey = POS.PlaceOfServiceKey
                                   INNER JOIN dbo.States AS S
  ON P.Statekey = S.Statekey
ORDER BY 1,2,3,4,5,6

/****************************************
--Dropping physical tables those were
created in intermidiate steps.
****************************************/
DECLARE @sql nvarchar(max)
set @sql = 'DROP table ' + @BaseDataTbl
exec sp_executesql @sql

END
