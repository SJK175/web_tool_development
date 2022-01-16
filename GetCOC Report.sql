/*
EXECUTE GetCOCReport
@OutputTable='BaseData_D8FDC660990945F89957FD8AC933160B',
@BudgetYear=2015,
@BKey='3',
@StateKey='49',
@AsOfDate='2016-01-01',
@BackYears=1,
@ExtraYear=2017
*/


ALTER PROCEDURE GetCOCReport
(
@OutputTable nvarchar(200)
,@BudgetYear varchar(12)
,@Bkey varchar(12)
,@StateKey varchar(max)
,@AsOfdate date
,@BackYears int
,@ExtraYear varchar(12)
)
AS
BEGIN
/*************************************
--Local Variables--
*************************************/
DECLARE @VarOutputTable varchar(250)
SET @VarOutputTable = @OutputTable

DECLARE @VarBudgetYear varchar(12)
SET @VarBudgetYear=@BudgetYear

DECLARE @sql1 nvarchar (max)


/**********************************************************************
Inserting physical table data into a temp table for further use
***********************************************************************/
SET @sql1='SELECT * FROM ' + @VarOutputTable + ' AS A' 
CREATE TABLE #TempBaseData (
        StateKey bigint,
        ProviderKey bigint,
        ProductKey bigint,
        PlaceOfServiceKey bigint,
        CustomerSegmentKey bigint,
        InsuredTypeKey bigint,
        HIX int,
        [Year] int,
        [Month] int,
        ChangeDate date,
        [TimeStamp] datetime,
        Base decimal(15, 5),
        Allowed decimal(15, 5),
        Total decimal(15, 5),
        QHIPPortion decimal(15, 5),
        FixedPortion decimal(15, 5),
        ChargedPortion decimal(15, 5),
        Closed int,
        ChangePresent int,
        Position int
    )
INSERT INTO #TempBaseData
EXECUTE sp_executesql @sql1

/************************************************************
--Creatint two Temp table and inserting data into them
using #TempBaseData & StateBase (function)
************************************************************/
---[TEMP TABLE 01]
CREATE TABLE #temp_COCSummary (BudgetYear        int NOT NULL
                           ,AsOfDate          date NULL
                           ,StateKey          bigint NOT NULL
                           ,ProviderKey       bigint NOT NULL
                           ,ProductKey        bigint NOT NULL
                           ,PlaceOfServiceKey bigint NOT NULL
                           ,ChangeDate        date
                           ,[TimeStamp]       datetime
                           ,DealStatus        varchar(8) NOT NULL
                           ,Base              decimal(38,2) NULL
                           ,Allowed           numeric(38,4) NULL
                           ,FixedPortion      decimal(38,4)
                           ,ChargedPortion    decimal(38,4)
                           ,QHIPPortion       decimal(38,4))
  
CREATE CLUSTERED INDEX [idx_YPPP] ON #temp_COCSummary (BudgetYear, ProviderKey, ProductKey, PlaceOfServiceKey)
CREATE nonclustered index [idx_PPP] ON #temp_COCSummary (ProviderKey,ProductKey,PlaceOfServiceKey)

INSERT INTO #temp_COCSummary
SELECT @VarBudgetYear AS BudgetYear
        ,SB.SetDate AS AsOfDate
        ,A.StateKey
        ,A.ProviderKey
        ,A.ProductKey
        ,A.PlaceOfServiceKey
        ,A.ChangeDate
        ,A.[TimeStamp]
        ,CASE 
           WHEN A.Closed = 1 THEN 'Signed' 
           ELSE                   'Unsigned' 
         END                                        AS DealStatus
        ,Sum(Base)            AS Base
        ,sum(Allowed)         AS Allowed
        ,Sum(FixedPortion)    AS FixedPortion
        ,Sum(ChargedPortion)  AS ChargedPortion
        ,Sum(QHIPPortion)     AS QHIPPortion
  --INTO #temp_COCSummary
  FROM #TempBaseData AS A 
  INNER JOIN 
  (select * from dbo.Statebase(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS SB
    ON A.StateKey = SB.StateKey
  GROUP BY SB.SetDate
          ,A.StateKey
          ,A.ProviderKey
          ,A.ProductKey
          ,A.PlaceOfServiceKey
          ,A.ChangeDate
          ,A.[TimeStamp]
          ,CASE 
             WHEN A.Closed = 1 THEN 'Signed' 
             ELSE                   'Unsigned' 
           END

---[TEMP TABLE 02]
CREATE TABLE #temp_COCSummary_IS (BudgetYear        int NOT null
                                     ,ProviderKey       bigint NOT null
                                     ,ProductKey        bigint NOT null
                                     ,PlaceOfServiceKey bigint NOT null
                                     ,InsuredTypeKey    bigint NOT null
                                     ,Percentage        decimal(5,4))
  
CREATE clustered index [idx_b] ON #temp_COCSummary_IS (BudgetYear)
CREATE index [idx_PPPI] ON #temp_COCSummary_IS (ProviderKey, ProductKey, PlaceOfServiceKey, InsuredTypeKey)

INSERT INTO #temp_COCSummary_IS
SELECT @VarBudgetYear
        ,IT.ProviderKey
        ,IT.ProductKey
        ,IT.PlaceOfServiceKey
        ,IT.InsuredTypeKey
        ,CASE 
           WHEN T.Total = 0 THEN 0
           ELSE IT.IT_Total / T.Total
         END                             AS Percentage
 
 --INTO #temp_COCSummary_IS
 FROM (SELECT ProviderKey
              ,ProductKey
              ,PlaceOfServiceKey
              ,InsuredTypeKey
              ,Sum(Base)            AS IT_Total
        FROM #TempBaseData AS B 
  INNER JOIN 
  (select * from dbo.Statebase(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS SB
          ON B.StateKey = SB.StateKey
         AND B.[Year] = SB.[BaseYear]
        group BY ProviderKey
                ,ProductKey
                ,PlaceOfServiceKey
                ,InsuredTypeKey) AS IT 
				INNER JOIN (SELECT ProviderKey
                                                         ,ProductKey
                                                         ,PlaceOfServiceKey
                                                         ,Sum(Base)         AS Total
                                                   FROM  #TempBaseData AS B 
  INNER JOIN 
  (select * from dbo.Statebase(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS SB
                                                     ON B.StateKey = SB.StateKey
                                                    AND B.[Year] = SB.[BaseYear]
                                                   group BY ProviderKey
                                                           ,ProductKey
                                                           ,PlaceOfServiceKey) AS T
    ON IT.ProviderKey       = T.ProviderKey
   AND IT.ProductKey        = T.ProductKey
   AND IT.PlaceOfServiceKey = T.PlaceOfServiceKey 
  --ORDER BY 1,2,3,4
   

/***************************************************
--Find out if the extra year should be displayed-- 
creating #temp_ExtraYear
****************************************************/
SELECT @budgetYear AS BudgetYear
,@ExtraYear AS ExtraYear
,'{SHOW}' AS Show 
INTO #temp_ExtraYear

/****************************************************
--Build the monthly trends-- 
creating #temp_MonthlyTrends
****************************************************/
SELECT A.BudgetYear
       ,A.AsOfDate
       ,A.StateKey
       ,A.ProviderKey
       ,A.ProductKey
       ,A.PlaceOfServiceKey
       ,A.ChangeDate
       ,A.[TimeStamp]
       ,A.DealStatus
       ,A.Base          AS BaseDollars
       ,CASE 
          WHEN B.StateKey is null THEN CASE
                                         WHEN (A.Allowed - (A.FixedPortion + A.ChargedPortion + A.QHIPPortion)) = 0 THEN 0
                                         ELSE (A.Allowed / (A.Allowed - (A.FixedPortion + A.ChargedPortion + A.QHIPPortion))) -1
                                       END
          WHEN B.Allowed = 0 THEN 0
          ELSE (A.Allowed / B.Allowed) -1
        END AS MonthlyTrend
 INTO #temp_MonthlyTrends
 FROM #temp_COCSummary AS A 
 LEFT OUTER JOIN #temp_COCSummary AS B
   ON A.BudgetYear            = B.BudgetYear       
  AND A.ProviderKey           = B.ProviderKey      
  AND A.ProductKey            = B.ProductKey       
  AND A.PlaceOfServiceKey     = B.PlaceOfServiceKey  
  AND A.ChangeDate            = dateadd(mm,1,B.ChangeDate)
 --ORDER BY 1,4,5,6,7

/************************************************************
 --Merge budget with actual--
 creating #temp_BudgetWithActual
************************************************************/
  SELECT Budget.BudgetYear 
       ,Budget.AsOfDate
       ,Budget.StateKey
       ,Budget.ProviderKey
       ,Budget.ProductKey
       ,Budget.PlaceOfServiceKey
       ,Budget.ChangeDate
       ,Budget.[TimeStamp]         AS BudgetTimestamp
       ,Actual.[TimeStamp]         AS ActualTimestamp
       ,Actual.BaseDollars
       ,Budget.DealStatus          AS BudgetDealStatus
       ,Budget.MonthlyTrend        AS BudgetMonthlyTrend
       ,Actual.DealStatus          AS ActualDealStatus
       ,Actual.MonthlyTrend        AS ActualMonthlyTrend
 INTO #temp_BudgetWithActual
 FROM #temp_MonthlyTrends AS Budget 
 INNER JOIN #temp_MonthlyTrends AS Actual
   ON Budget.BudgetYear <> 0 /* makes sure only budget data goes to the budget TABLE alias */
  --AND Actual.BudgetYear =  0 /* makes sure only actual data goes to the budget TABLE alias [??] */
  AND Budget.ProviderKey       = Actual.ProviderKey      
  AND Budget.ProductKey        = Actual.ProductKey       
  AND Budget.PlaceOfServiceKey = Actual.PlaceOfServiceKey
  AND Budget.ChangeDate        = Actual.ChangeDate  
 WHERE Year(Budget.ChangeDate) Between Budget.BudgetYear AND Budget.BudgetYear + 1
 --ORDER BY 1,4,5,6,7 

 /************************************************
 --Find the cumulative Trends--
 cretaing #temp_BudgetWithActual_CI
 ************************************************/
 SELECT B.BudgetYear 
       ,B.AsOfDate
       ,B.StateKey
       ,B.ProviderKey
       ,B.ProductKey
       ,B.PlaceOfServiceKey
       ,B.ChangeDate
       ,B.BudgetTimeStamp
       ,B.ActualTimeStamp
       ,B.BaseDollars
       ,B.BudgetDealStatus
       ,B.BudgetMonthlyTrend
       ,(SELECT isnull(POWER(10.00000000, SUM(LOG10(1+ (CI.BudgetMonthlyTrend)))) - 1,0)
         FROM #temp_BudgetWithActual AS CI
         WHERE CI.BudgetYear        = B.BudgetYear
           AND CI.ProviderKey       = B.ProviderKey
           AND CI.ProductKey        = B.ProductKey
           AND CI.PlaceOfServiceKey = B.PlaceOfServiceKey
           AND CI.ChangeDate between C.MinChangeDate AND B.ChangeDate)      AS BudgetCumulativeTrend
       ,ActualDealStatus
       ,ActualMonthlyTrend
       ,(SELECT isnull(POWER(10.00000000, SUM(LOG10(1+ (CI.ActualMonthlyTrend)))) - 1,0)
         FROM #temp_BudgetWithActual AS CI
         WHERE CI.BudgetYear        = B.BudgetYear
           AND CI.ProviderKey       = B.ProviderKey
           AND CI.ProductKey        = B.ProductKey
           AND CI.PlaceOfServiceKey = B.PlaceOfServiceKey
           AND CI.ChangeDate between C.MinChangeDate AND B.ChangeDate)      AS ActualCumulativeTrend
 INTO #temp_BudgetWithActual_CI
 FROM #temp_BudgetWithActual AS B 
 INNER JOIN 
 (SELECT BudgetYear
                                                    ,ProviderKey
                                                    ,ProductKey
                                                    ,PlaceOfServiceKey
                                                    ,Min(ChangeDate)    AS MinChangeDate
                                              FROM #temp_BudgetWithActual
                                              WHERE Year(ChangeDate) >= BudgetYear
                                              group BY BudgetYear
                                                      ,ProviderKey
                                                      ,ProductKey
                                                      ,PlaceOfServiceKey) AS C
   ON B.BudgetYear        = C.BudgetYear
  AND B.ProviderKey       = C.ProviderKey
  AND B.ProductKey        = C.ProductKey
  AND B.PlaceOfServiceKey = C.PlaceOfServiceKey
 --ORDER BY 1,4,5,6,7

/***********************************************************
--find the first change event if its IN the budget year--
creating #temp_FirstTrendEvent
***********************************************************/
SELECT BudgetYear
       ,ProviderKey
       ,StateKey
       ,ProductKey
       ,PlaceOfServiceKey
       ,ChangeDate                             AS SavingsStartDate
       ,dateadd(d,-1,dateadd(yy,1,ChangeDate)) AS SavingsEndDate
 INTO #temp_FirstTrendEvent
 FROM (SELECT BudgetYear
             ,ProviderKey
             ,StateKey
             ,ProductKey
             ,PlaceOfServiceKey
             ,ChangeDate
             ,rank() over (Partition BY BudgetYear, ProviderKey, StateKey, ProductKey, PlaceOfServiceKey ORDER BY BudgetYear, ProviderKey, StateKey, ProductKey, PlaceOfServiceKey, ChangeDate) AS [Rank]
       FROM #temp_BudgetWithActual_CI
       WHERE Year(ChangeDate) = BudgetYear
         AND BudgetMonthlyTrend <> 0) AS SQ
 WHERE [Rank] = 1

/*****************************************
--Find the Savings--
creating #temp_Savings
******************************************/
SELECT A.BudgetYear
       ,A.AsOfDate
       ,A.StateKey
       ,A.ProviderKey
       ,A.ProductKey
       ,A.PlaceOfServiceKey
       ,A.ChangeDate
       ,A.BudgetTimestamp
       ,A.ActualTimestamp
       ,A.BaseDollars
       ,A.BudgetDealStatus
       ,A.BudgetMonthlyTrend
       ,CASE 
          WHEN Year(A.ChangeDate) < A.BudgetYear THEN A.BaseDollars / (1 + A.BudgetMonthlyTrend)
          ELSE A.BaseDollars * (A.BudgetCumulativeTrend + 1)
        END      AS BudgetTrendedAllowed
       ,A.ActualDealStatus
       ,A.ActualMonthlyTrend
       ,CASE
          WHEN Year(A.ChangeDate) < A.BudgetYear THEN A.BaseDollars / (1 + A.ActualMonthlyTrend)
          ELSE A.BaseDollars * (A.ActualCumulativeTrend + 1)
        END      AS ActualTrendedAllowed
       ,CASE 
          WHEN A.ChangeDate Between B.SavingsStartDate AND B.SavingsEndDate THEN 1
          ELSE                                                                   0
        END      AS SavingsEligible
 INTO #temp_Savings
 FROM #temp_BudgetWithActual_CI AS A 
 LEFT OUTER JOIN #temp_FirstTrendEvent AS B
   ON A.BudgetYear        = B.BudgetYear
  AND A.ProviderKey       = B.ProviderKey
  AND A.ProductKey        = B.ProductKey
  AND A.PlaceOfServiceKey = B.PlaceOfServiceKey
  AND A.ChangeDate between B.SavingsStartDate AND B.SavingsEndDate

/********************************************************************
--build the previous month trend allowed to give the monthly trends--
creating #temp_SavingsWithPrevious
********************************************************************/
SELECT A.BudgetYear
       ,A.AsOfDate
       ,A.StateKey
       ,A.ProviderKey
       ,A.ProductKey
       ,A.PlaceOfServiceKey
       ,A.ChangeDate
       ,A.BudgetTimestamp
       ,A.ActualTimestamp
       ,A.BaseDollars
       ,A.BudgetDealStatus
       ,A.BudgetTrendedAllowed
       ,A.BudgetMonthlyTrend
       ,CASE 
          WHEN B.BudgetYear is null THEN A.BudgetTrendedAllowed / (1 + A.BudgetMonthlyTrend)
          ELSE B.BudgetTrendedAllowed
        END  AS PreviousMonthBudgetTrendedAllowed
       ,A.ActualDealStatus
       ,A.ActualTrendedAllowed
       ,A.ActualMonthlyTrend                                                     
       ,CASE 
          WHEN B.BudgetYear is null THEN A.ActualTrendedAllowed / (1 + A.ActualMonthlyTrend)
          ELSE B.ActualTrendedAllowed  
        END                                                      AS PreviousMonthActualTrendedAllowed
       ,A.SavingsEligible
 INTO #temp_SavingsWithPrevious
 FROM #temp_Savings AS A 
 LEFT OUTER JOIN #temp_Savings AS B
   ON A.BudgetYear         = B.BudgetYear
  AND A.ProviderKey        = B.ProviderKey
  AND A.ProductKey         = B.ProductKey 
  AND A.PlaceOfServiceKey  = B.PlaceOfServiceKey
  AND A.ChangeDate = dateadd(mm,1,B.ChangeDate)

/*********************************************************
--Creating #temp_SWP_PlusInsured
*********************************************************/
SELECT SWP.BudgetYear
       ,SWP.AsOfDate
       ,SWP.StateKey
       ,SWP.ProviderKey
       ,SWP.ProductKey
       ,SWP.PlaceOfServiceKey
       ,CIS.InsuredTypeKey
       ,SWP.ChangeDate
       ,SWP.BudgetTimestamp
       ,SWP.ActualTimestamp
       ,SWP.BaseDollars                        * CIS.Percentage AS BaseDollars
       ,SWP.BudgetDealStatus
       ,SWP.BudgetTrendedAllowed               * CIS.Percentage AS BudgetTrendedAllowed
       ,SWP.BudgetMonthlyTrend
       ,SWP.PreviousMonthBudgetTrendedAllowed  * CIS.Percentage AS PreviousMonthBudgetTrendedAllowed
       ,SWP.ActualDealStatus
       ,SWP.ActualTrendedAllowed               * CIS.Percentage AS ActualTrendedAllowed
       ,SWP.ActualMonthlyTrend
       ,SWP.PreviousMonthActualTrendedAllowed  * CIS.Percentage AS PreviousMonthActualTrendedAllowed
       ,SWP.SavingsEligible
 INTO #temp_SWP_PlusInsured
 FROM #temp_SavingsWithPrevious AS SWP 
 INNER JOIN #temp_COCSummary_IS  AS CIS
  ON 
  --CIS.BudgetYear         = 0   /* current */
  --AND 
  SWP.ProviderKey        = CIS.ProviderKey
  AND 
  SWP.ProductKey         = CIS.ProductKey
  AND 
  SWP.PlaceOfServiceKey  = CIS.PlaceOfServiceKey

/************************************************************
--Creating Final table--
************************************************************/
SELECT A.BudgetYear
       ,S.StateName
       ,P.ProviderName
       ,PT.ProviderType 
       ,Pr.ProductName
       ,POS.PlaceOfService
       ,IT.InsuredType
       ,A.ChangeDate
       ,A.BudgetTimestamp
       ,A.ActualTimestamp                 AS [TimeStamp]
       ,A.AsOfDate
       ,A.BudgetTrendedAllowed
       ,A.PreviousMonthBudgetTrendedAllowed
       ,A.ActualTrendedAllowed
       ,A.PreviousMonthActualTrendedAllowed
       ,EY.Show
       ,CASE 
          WHEN A.SavingsEligible = 0                               THEN 0
          WHEN YEAR(A.ChangeDate) = A.BudgetYear                   THEN A.BudgetTrendedAllowed - A.ActualTrendedAllowed
          WHEN ISNULL(A.ActualTimeStamp,'2100.01.01') > A.AsOfDate THEN A.BudgetTrendedAllowed - A.ActualTrendedAllowed
          ELSE                                        0
        END             AS SavingsDollars
 INTO #TempFinalTable
 FROM #temp_SWP_PlusInsured AS A 
 LEFT OUTER JOIN #temp_ExtraYear AS EY
   ON A.BudgetYear = EY.BudgetYear
  AND Year(A.ChangeDate) = EY.ExtraYear
                   INNER JOIN dbo.States AS S
   ON A.StateKey = S.StateKey
                   INNER JOIN dbo.vwCurrentProviders AS P
   ON A.ProviderKey = P.ProviderKey
                   INNER JOIN dbo.ProviderTypes AS PT
   ON P.ProviderTypeKey = PT.ProviderTypeKey 
                   INNER JOIN dbo.Products AS Pr
   ON A.ProductKey = Pr.ProductKey
                   INNER JOIN dbo.PlaceOfServices AS POS
   ON A.PlaceOfServiceKey = POS.PlaceOfServiceKey
                   INNER JOIN dbo.InsuredTypes AS IT
   ON A.InsuredTypeKey = IT.InsuredTypeKey
 WHERE (EY.Show is null or EY.Show = 'Yes')

--======================================
select * from  #TempFinalTable
DROP TABLE #temp_COCSummary
DROP TABLE #tempbasedata
DROP TABLE #temp_COCSummary_IS

END
