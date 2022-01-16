USE [ITF_Obfuscated_Final]
GO
/****** Object:  StoredProcedure [dbo].[StProc_SPPPMonths_MonthlyChanges]    Script Date: 10-28-2016 18:55:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* 
EXECUTE dbo.StProc_SPPPMonths_MonthlyChanges '3','30','2016-09-12',1,4
DROP PROCEDURE dbo.StProc_SPPPMonths_MonthlyChanges 
*/


ALTER PROCEDURE [dbo].[StProc_SPPPMonths_MonthlyChanges] 
  (@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears AS int
, @ForwardYears AS int)

AS
BEGIN

/**************************************************************
Inserting SP_ChangesExpanded_With_Missing_Prov data into
a temp table for further use in this stored procedure.
**************************************************************/    
	CREATE TABLE #ChangesExpanded
	(
        StateKey bigint,
        ProviderKey bigint,
        ChangeDateKey bigint,
        ChangeDate date,
        [TimeStamp] datetime,
        ProductKey bigint,
        PlaceOfServiceKey bigint,
        QHIPValue decimal(10, 5),
        QHIPRatio decimal(10, 5),
        FixedValue decimal(10, 5),
        FixedRatio decimal(10, 5),
        ChargedValue decimal(10, 5),
        ChargedRatio decimal(10, 5),
        Closed smallint
    )
	INSERT INTO #ChangesExpanded
	select * from dbo.FnChangesExpanded_With_Missing_Prov (@Bkey, @StateKey, @AsOfdate, @BackYears)
	--EXECUTE dbo.StProc_ChangesExpanded_With_Missing_Prov @Bkey, @StateKey, @AsOfdate, @BackYears
	
/*************************************************************
Creating another temp table #MonthlyChanges which will  
finally hold this stored procedure's data
*************************************************************/	
	CREATE TABLE #MonthlyChanges (
        StateKey bigint,
        ProviderKey bigint,
        ProductKey bigint,
        PlaceOfServiceKey bigint,
        DateDate date,
        DateYear int,
        DateMonth tinyint,
        [TimeStamp] datetime,
        QHIPValue decimal(10, 5),
        QHIPRatio decimal(10, 5),
        FixedValue decimal(10, 5),
        FixedRatio decimal(10, 5),
        ChargedValue decimal(10, 5),
        ChargedRatio decimal(10, 5),
        QHIPCharged smallint,
        QHIP_RV decimal(10, 5),
        Fixed_RV decimal(10, 5),
        Charged_RV decimal(10, 5),
        Closed smallint
    )
/*******************************
Grab the analysis months
*******************************/
;WITH CTE_SPPPMonths as
        (SELECT
            X.StateKey,
            X.ProviderKey,
            X.ProductKey,
            X.PlaceOfServiceKey,
            D.DateDate,
            D.DateYear,
            D.DateMonth

        FROM dbo.Dates AS D
        INNER JOIN (SELECT DISTINCT
            C.StateKey,
            C.ProviderKey,
            C.ProductKey,
            C.PlaceOfServiceKey,
            S.StartYear
        FROM #ChangesExpanded AS C
        INNER JOIN (SELECT
            *
        FROM dbo.StateBase(@BKey, @stateKey, @AsOfDate, @BackYears)) AS S
            ON C.StateKey = S.StateKey) AS X
            ON D.DateYear BETWEEN (X.StartYear - @BackYears) AND (X.StartYear + @ForwardYears)
            AND D.DateDay = 1
			)
/***************************************************
Inserting data into #MonthlyChanges
***************************************************/
    INSERT INTO #MonthlyChanges
        SELECT
            M.StateKey,
            M.ProviderKey,
            M.ProductKey,
            M.PlaceOfServiceKey,
            M.DateDate,
            M.DateYear,
            M.DateMonth,
            CE.[TimeStamp],
            ISNULL(CE.QHIPValue, 0) AS QHIPValue,
            ISNULL(CE.QHIPRatio, 0) AS QHIPRatio,
            ISNULL(CE.FixedValue, 0) AS FixedValue,
            ISNULL(CE.FixedRatio, 0) AS FixedRatio,
            ISNULL(CE.ChargedValue, 0) AS ChargedValue,
            ISNULL(CE.ChargedRatio, 0) AS ChargedRatio,
            CASE
                WHEN CE.StateKey IS NULL THEN 0
                WHEN CE.QHIPRatio = 1 THEN 1
                ELSE 0
            END AS QHIPCharged,
            ISNULL(CE.QHIPValue * CE.QHIPRatio, 0) AS QHIP_RV,
            ISNULL(CE.FixedValue * CE.FixedRatio, 0) AS Fixed_RV,
            ISNULL(CE.ChargedValue * CE.ChargedRatio, 0) AS Charged_RV,
            ISNULL(CE.Closed, 0) AS Closed

        FROM CTE_SPPPMonths AS M
        LEFT OUTER JOIN #ChangesExpanded AS CE

            ON M.Statekey = CE.Statekey
            AND M.ProviderKey = CE.ProviderKey
            AND M.ProductKey = CE.ProductKey
            AND M.PlaceOfServiceKey = CE.PlaceOfServiceKey
            AND M.DateDate = CE.ChangeDate
        ORDER BY M.Statekey
        , M.ProviderKey
        , M.ProductKey
        , M.PlaceOfServiceKey
        , M.DateDate

/******************************INDEX**************************************************************/
--CREATE INDEX idx_SPPP ON #MonthlyChanges (StateKey, ProviderKey, ProductKey, PlaceOfServiceKey)
      
/******************************************************
Showing data of #MonthlyChanges & Droping both the
temp tables created in this stored procedure
*******************************************************/
SELECT * FROM #MonthlyChanges
DROP TABLE #MonthlyChanges
DROP TABLE #ChangesExpanded

END
