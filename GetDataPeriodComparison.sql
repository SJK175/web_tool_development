USE [ITF_Obfuscated_Subhajit]
GO
/****** Object:  StoredProcedure [dbo].[GetDataPeriodComparison]    Script Date: 12-06-2016 17:29:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
 EXECUTE GetPeriodComparison
 @BKey='3'
,@StateKey='49'
,@AsOfDate='2016-01-01'
,@BackYears=1
,@ForwardYears=4
,@PERIOD_1_START='2014-07-01'
,@PERIOD_1_END='2014-12-31'
,@PERIOD_2_START='2015-07-01'
,@PERIOD_2_END='2015-12-31'
,@OutputTable_BD = OUTPUT
,@OutputTable_P = OUTPUT

*/

ALTER PROCEDURE  [dbo].[GetDataPeriodComparison]
(
  @BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears AS int
, @ForwardYears AS int
, @PERIOD_1_START date
, @PERIOD_1_END date
, @PERIOD_2_START date
, @PERIOD_2_END date
, @OutputTable_BD AS nvarchar(250) OUTPUT
, @OutputTable_P AS nvarchar(250) OUTPUT
)
AS
BEGIN

/*************************************************
--Creating BaseData and PrecursorData 
*************************************************/
DECLARE @BaseDataTbl as nvarchar(250)
DECLARE @PrecursorTbl as nvarchar(250)
EXECUTE [dbo].[GetBaseData] @BKey,@stateKey,@AsOfDate,@BackYears,@ForwardYears,@OutputTable_BD output
SET @BaseDataTbl=@OutputTable_BD
EXECUTE [dbo].[CreateTempPrecursor] @BKey,@stateKey,@AsOfDate,@BackYears,@ForwardYears,@BaseDataTbl,@OutputTable_P output 
SET @PrecursorTbl=@OutputTable_P

/*************************************
--Period Comparison Report
*************************************/
----------PART-01
CREATE TABLE #temp_TimePeriods (PeriodNumber int, StartDate date, EndDate date);
INSERT INTO #temp_TimePeriods (PeriodNumber, StartDate, EndDate) 
VALUES   (1,@PERIOD_1_START,@PERIOD_1_END)
        ,(2,@PERIOD_2_START,@PERIOD_2_END)


----------PART-02
DECLARE @sql nvarchar (max)
SET @SQL='SELECT O.StateKey
        ,O.ProviderKey
        ,O.ProductKey
        ,O.PlaceOfServiceKey
        ,O.CustomerSegmentKey
        ,O.InsuredTypeKey
        ,O.[Year]
        ,O.[Month]
        ,O.[YearMonth]
        ,''Period'' + cast(TP.PeriodNumber AS varchar(5)) + ''  '' + ''['' + cast(TP.StartDate AS varchar(10)) + ''] - ['' + cast(TP.EndDate AS varchar(10)) + '']'' AS Period
        ,O.Closed 
        ,Sum(O.Allowed) AS Allowed       
  --INTO #temp_OutputPeriod
  FROM ' + @PrecursorTbl + ' AS O INNER JOIN #temp_TimePeriods AS TP
    ON cast((O.YearMonth + ''-01'') AS date) between TP.StartDate AND TP.EndDate
  group BY O.StateKey
          ,O.ProviderKey
          ,O.ProductKey
          ,O.PlaceOfServiceKey
          ,O.CustomerSegmentKey
          ,O.InsuredTypeKey
          ,O.[Year]
          ,O.[Month]
          ,O.[YearMonth]
          ,TP.PeriodNumber
          ,''Period'' + cast(TP.PeriodNumber AS varchar(5)) + ''  '' + ''['' + cast(TP.StartDate AS varchar(10)) + ''] - ['' + cast(TP.EndDate AS varchar(10)) + '']''
          ,O.Closed'

CREATE TABLE #temp_OutputPeriod
(
StateKey bigint
,ProviderKey bigint
,ProductKey bigint
,PlaceOfServiceKey bigint
,CustomerSegmentKey bigint
,InsuredTypeKey bigint
,[Year] int
,[Month] int
,[YearMonth] varchar(20)
,period varchar(250)
,closed int
,allowed decimal(15,5)
)
INSERT INTO #temp_OutputPeriod
EXEC sp_executesql @sql


----------PART-03
SELECT A.Period
      ,A.YearMonth
      ,row_number() over (Partition BY period  ORDER BY Yearmonth) AS MonthNumber
INTO #temp_MonthNumbers
FROM (SELECT Distinct Period ,YearMonth FROM #temp_OutputPeriod) AS A


----------PART-04 (Displaing Data)
SELECT S.StateName 
      ,P.ProviderName
      ,P.ProviderId
      ,P.MedicareId
      ,PT.ProviderType                
      ,Pr.ProductName         
      ,POS.PlaceOfService  
      ,CS.CustomerSegmentName
      ,IT.InsuredType  
      ,MN.MonthNumber
      ,A.Period
      ,A.Closed 
      ,A.Allowed
FROM #temp_OutputPeriod AS A 
INNER JOIN #temp_MonthNumbers AS MN
  ON A.Period = MN.Period
  AND A.YearMonth = MN.YearMonth
INNER JOIN dbo.States AS S
  ON A.StateKey = S.StateKey
INNER JOIN dbo.vwCurrentProviders AS P
  ON A.ProviderKey = P.ProviderKey
LEFT OUTER JOIN dbo.ProviderTypes AS PT
  ON P.ProviderTypeKey = PT.ProviderTypeKey
INNER JOIN dbo.Products AS Pr
  ON A.ProductKey = Pr.ProductKey
INNER JOIN dbo.PlaceOfServices AS POS
  ON A.PlaceOfServiceKey = POS.PlaceOfServiceKey
INNER JOIN dbo.CustomerSegments AS CS
  ON A.CustomerSegmentKey = CS.CustomerSegmentKey
INNER JOIN dbo.InsuredTypes AS IT
  ON A.InsuredTypeKey = IT.InsuredTypeKey
ORDER BY 1,2,6,7,8,9,10

/***************************************
--Dropping Temp Tables
****************************************/
DROP TABLE #temp_MonthNumbers
DROP TABLE #temp_OutputPeriod
DROP TABLE #temp_TimePeriods

/****************************************
--Dropping physical tables those were
created in intermidiate steps.
****************************************/
set @sql = 'DROP table ' + @BaseDataTbl
exec sp_executesql @sql
set @sql = 'DROP table ' + @PrecursorTbl
exec sp_executesql @sql

END
