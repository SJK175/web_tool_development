USE [ITF_Obfuscated_Subhajit]
GO
/****** Object:  StoredProcedure [dbo].[StProc_BASEDATA]    Script Date: 12-05-2016 12:30:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
EXECUTE [dbo].[GetBaseData]
@BKey='3',
@StateKey='49',
@AsOfDate='2016-01-01',
@BackYears=1,
@ForwardYears=4,
@OutputTable =OUTPUT
*/

CREATE PROCEDURE [dbo].[GetBaseData] (@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears AS int
, @ForwardYears AS int
, @OutputTable_BD AS nvarchar(250) OUTPUT)

AS
BEGIN

    /************************************************************************
    Inserting data from stored procedure: StProc_SPPPMonths_MonthlyChanges
    into a temp table to use that to make "MonthlyChangesExp"
    ************************************************************************/

    CREATE TABLE #tempMonthlyChanges (
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
    CREATE NONCLUSTERED INDEX idx1 ON #tempMonthlyChanges (StateKey, ProviderKey, ProductKey, PlaceOfServiceKey)
    INSERT INTO #tempMonthlyChanges
    EXECUTE dbo.StProc_SPPPMonths_MonthlyChanges @Bkey,
                                                 @StateKey,
                                                 @AsOfdate,
                                                 @BackYears,
                                                 @ForwardYears

    /************************************************************************
    We create "MonthlyChangesExp" data using "MonthlyChanges" data and two
    other functions and will put that in a temp table: #MonthlyChangesExp
    ************************************************************************/
    CREATE TABLE #MonthlyChangesExp (
        Statekey bigint,
        ProviderKey bigint,
        ProductKey bigint,
        PlaceOfServiceKey bigint,
        CustomerSegmentKey bigint,
        InsuredTypeKey bigint,
        HIX int,
        DateDate date,
        DateYear int,
        DateMonth int,
        [TimeStamp] datetime,
        QHIPValue decimal(12, 5),
        QHIPRatio decimal(12, 5),
        FixedValue decimal(12, 5),
        FixedRatio decimal(12, 5),
        ChargedValue decimal(12, 5),
        ChargedRatio decimal(12, 5),
        ChangePresent int,
        QHIPCharged int,
        QHIP_RV decimal(12, 5),
        Fixed_RV decimal(12, 5),
        Charged_RV decimal(12, 5),
        Closed int,
        BaseAllowed decimal(15, 5),
        AdjustedAllowed decimal(15, 5),
        IsBaseYear int,
        Position int
    )
    CREATE NONCLUSTERED INDEX idx1 ON #MonthlyChangesExp (ProviderKey)
    CREATE NONCLUSTERED INDEX idx2 ON #MonthlyChangesExp (Position)

    INSERT INTO #MonthlyChangesExp
        SELECT
            CM.Statekey,
            CM.ProviderKey,
            CM.ProductKey,
            CM.PlaceOfServiceKey,
            CE.CustomerSegmentKey,
            CE.InsuredTypeKey,
            CE.HIX,
            CM.DateDate,
            CM.DateYear,
            CM.DateMonth,
            CM.[TimeStamp],
            CM.QHIPValue,
            CM.QHIPRatio,
            CM.FixedValue,
            CM.FixedRatio,
            CM.ChargedValue,
            CM.ChargedRatio,
            CASE
                WHEN CM.QHIP_RV = 0 AND
                    CM.Fixed_RV = 0 AND
                    CM.Charged_RV = 0 THEN 0
                ELSE 1
            END AS ChangePresent,
            CM.QHIPCharged,
            CM.QHIP_RV,
            CM.Fixed_RV,
            CM.Charged_RV,
            CM.Closed,
            CE.BaseAllowed,
            CAST(0 AS decimal(15, 5)) AS AdjustedAllowed,
            CASE
                WHEN CM.DateYear = SB.BaseYear THEN 1
                ELSE 0
            END AS IsBaseYear,
            ROW_NUMBER() OVER (PARTITION BY CM.Statekey, CM.ProviderKey, CM.ProductKey, CM.PlaceOfServiceKey, CE.CustomerSegmentKey, CE.InsuredTypeKey, CE.HIX
            ORDER BY CM.Statekey, CM.ProviderKey, CM.ProductKey, CM.PlaceOfServiceKey, CE.CustomerSegmentKey, CE.InsuredTypeKey, CE.HIX, CM.DateDate) - SB.PositionOffset AS Position

        --FROM (SELECT * FROM dbo.FnSPPPMonths_MonthlyChanges (@Bkey, @StateKey, @AsOfdate, @BackYears, @ForwardYears)) AS CM
        FROM #tempMonthlyChanges AS CM
        INNER JOIN (SELECT
            *
        FROM dbo.fnClaimsExperience_With_MissingProvider(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS CE
            ON CM.StateKey = CE.StateKey
            AND CM.ProviderKey = CE.ProviderKey
            AND CM.ProductKey = CE.ProductKey
            AND CM.PlaceOfServiceKey = CE.PlaceOfServiceKey

        INNER JOIN (SELECT
            *
        FROM dbo.Statebase(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS SB
            ON CM.StateKey = SB.StateKey
        ORDER BY CM.DateDate

    /********************************************************************
    Here we used "MonthlyChangesExp" data to create "BaseChange" data
    and put that into another temp table: #BaseChange
    *********************************************************************/
    CREATE TABLE #BaseChange (
        StateKey bigint,
        ProviderKey bigint,
        ProductKey bigint,
        PlaceOfServiceKey bigint,
        CustomerSegmentKey bigint,
        InsuredTypeKey bigint,
        HIX int,
        AdjustmentFactor decimal(15, 5)
    )
    CREATE NONCLUSTERED INDEX idx1 ON #BaseChange (ProviderKey)

    ;
    WITH cte_B
    AS (SELECT
        Statekey,
        ProviderKey,
        ProductKey,
        PlaceOfServiceKey,
        CustomerSegmentKey,
        InsuredTypeKey,
        HIX,
        Position,
        BaseAllowed,
        CAST((CASE
            WHEN QHIP_RV = 0 THEN 0
            ELSE QHIP_RV +
                ((QHIP_RV * (1 + Fixed_RV)) - QHIP_RV) +
                CASE
                    WHEN QHIPCharged = 0 THEN 0
                    ELSE ((QHIP_RV * (1 + Charged_RV)) - QHIP_RV)
                END
        END * BaseAllowed) +
        (Fixed_RV * BaseAllowed) +
        (Charged_RV * BaseAllowed) +
        BaseAllowed AS decimal(12, 2)) AS Total,
        Fixed_RV AS RunningFixed_RV,
        Charged_RV AS RunningCharged_RV
    FROM #MonthlyChangesExp
    WHERE Position = 1

    UNION ALL

    SELECT
        A.Statekey,
        A.ProviderKey,
        A.ProductKey,
        A.PlaceOfServiceKey,
        A.CustomerSegmentKey,
        A.InsuredTypeKey,
        A.HIX,
        A.Position,
        A.BaseAllowed,
        CAST((CASE
            WHEN A.QHIP_RV = 0 THEN 0
            ELSE A.QHIP_RV +
                ((A.QHIP_RV * (1 + B.RunningFixed_RV)) - A.QHIP_RV) +
                CASE
                    WHEN A.QHIPCharged = 0 THEN 0
                    ELSE ((A.QHIP_RV * (1 + B.RunningCharged_RV)) - A.QHIP_RV)
                END
        END * B.Total) +
        (A.Fixed_RV * B.Total) +
        (A.Charged_RV * B.Total) +
        B.Total AS decimal(12, 2)) AS Total,
        CASE
            WHEN A.Fixed_RV = 0 THEN B.RunningFixed_RV
            ELSE A.Fixed_RV
        END AS RunningFixed_RV,
        CASE
            WHEN A.Charged_RV = 0 THEN B.RunningCharged_RV
            ELSE A.Charged_RV
        END AS RunningCharged_RV
    FROM #MonthlyChangesExp AS A
    INNER JOIN cte_B AS B
        ON A.StateKey = B.StateKey
        AND A.ProviderKey = B.ProviderKey
        AND A.ProductKey = B.ProductKey
        AND A.PlaceOfServiceKey = B.PlaceOfServiceKey
        AND A.CustomerSegmentKey = B.CustomerSegmentKey
        AND A.InsuredTypeKey = B.InsuredTypeKey
        AND A.HIX = B.HIX
        AND A.Position - 1 = B.Position
    WHERE A.Position BETWEEN 2 AND 12)

    INSERT INTO #BaseChange
        SELECT
            StateKey,
            ProviderKey,
            ProductKey,
            PlaceOfServiceKey,
            CustomerSegmentKey,
            InsuredTypeKey,
            HIX,
            CASE
                WHEN SUM(Total) = 0 THEN 0
                ELSE SUM(BaseAllowed) / SUM(Total)
            END AS AdjustmentFactor
        FROM cte_B
        GROUP BY Statekey,
                 ProviderKey,
                 ProductKey,
                 PlaceOfServiceKey,
                 CustomerSegmentKey,
                 InsuredTypeKey,
                 HIX
    /**************************************************************
    Update "MonthlyChangesExp" data using "BaseChange" data.
    Will update "AdjustedAllowed" column.
    **************************************************************/
    UPDATE #MonthlyChangesExp
    SET AdjustedAllowed = MCE.BaseAllowed * BC.AdjustmentFactor
    FROM #MonthlyChangesExp AS MCE
    INNER JOIN #BaseChange AS BC
        ON MCE.StateKey = BC.StateKey
        AND MCE.ProviderKey = BC.ProviderKey
        AND MCE.ProductKey = BC.ProductKey
        AND MCE.PlaceOfServiceKey = BC.PlaceOfServiceKey
        AND MCE.CustomerSegmentKey = BC.CustomerSegmentKey
        AND MCE.InsuredTypeKey = BC.InsuredTypeKey
        AND MCE.HIX = BC.Hix

    /*********************************************************************
    Creating "UnsignedTrends" data using MonthlyChangesExp data and 
    inserting that into another temp table: #UnsignedTrends.
    
    STEP-A: Calculating Trends for Positive Direction
    STEP-B: Calculating Trends for Negetive Direction
    STEP-C: Combibe both Trends data
    STEP-D: Insert that data into the temp table:#UnsigedTrends 
    *********************************************************************/
    CREATE TABLE #UnsigedTrends (
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
    /*********************************************
    [A]Calculating Trends: Positive Direction
    *********************************************/
    ;
    WITH cte_positive
    AS (SELECT
        Statekey,
        ProviderKey,
        ProductKey,
        PlaceOfServiceKey,
        CustomerSegmentKey,
        InsuredTypeKey,
        HIX,
        Position,
        DateDate,
        DateYear,
        DateMonth,
        [TimeStamp],
        QHIP_RV,
        Fixed_RV,
        Charged_RV,
        Closed,
        ChangePresent,
        BaseAllowed,
        AdjustedAllowed,
        CAST((CASE
            WHEN QHIP_RV = 0 THEN 0
            ELSE QHIP_RV +
                ((QHIP_RV * (1 + Fixed_RV)) - QHIP_RV) +
                CASE
                    WHEN QHIPCharged = 0 THEN 0
                    ELSE ((QHIP_RV * (1 + Charged_RV)) - QHIP_RV)
                END
        END) * AdjustedAllowed AS decimal(12, 2)) AS QHIP,
        CAST((Fixed_RV * AdjustedAllowed) AS decimal(12, 2)) AS Fixed,
        CAST((Charged_RV * AdjustedAllowed) AS decimal(12, 2)) AS Charged,
        CAST(((CASE
            WHEN QHIP_RV = 0 THEN 0
            ELSE QHIP_RV +
                ((QHIP_RV * (1 + Fixed_RV)) - QHIP_RV) +
                CASE
                    WHEN QHIPCharged = 0 THEN 0
                    ELSE ((QHIP_RV * (1 + Charged_RV)) - QHIP_RV)
                END
        END) * AdjustedAllowed) +
        (Fixed_RV * AdjustedAllowed) +
        (Charged_RV * AdjustedAllowed) +
        AdjustedAllowed AS decimal(12, 2)) AS Total,
        Fixed_RV AS RunningFixed_RV,
        Charged_RV AS RunningCharged_RV
    FROM #MonthlyChangesExp
    WHERE Position = 1

    UNION ALL

    SELECT
        A.Statekey,
        A.ProviderKey,
        A.ProductKey,
        A.PlaceOfServiceKey,
        A.CustomerSegmentKey,
        A.InsuredTypeKey,
        A.HIX,
        A.Position,
        A.DateDate,
        A.DateYear,
        A.DateMonth,
        A.[TimeStamp],
        A.QHIP_RV,
        A.Fixed_RV,
        A.Charged_RV,
        A.Closed,
        A.ChangePresent,
        A.BaseAllowed,
        A.AdjustedAllowed,
        CAST((CASE
            WHEN A.QHIP_RV = 0 THEN 0
            ELSE A.QHIP_RV +
                ((A.QHIP_RV * (1 + B.RunningFixed_RV)) - A.QHIP_RV) +
                CASE
                    WHEN A.QHIPCharged = 0 THEN 0
                    ELSE ((A.QHIP_RV * (1 + B.RunningCharged_RV)) - A.QHIP_RV)
                END
        END) * B.Total AS decimal(12, 2)) AS QHIP,
        CAST((A.Fixed_RV * B.Total) AS decimal(12, 2)) AS Fixed,
        CAST((A.Charged_RV * B.Total) AS decimal(12, 2)) AS Charged,
        CAST(((CASE
            WHEN A.QHIP_RV = 0 THEN 0
            ELSE A.QHIP_RV +
                ((A.QHIP_RV * (1 + B.RunningFixed_RV)) - A.QHIP_RV) +
                CASE
                    WHEN A.QHIPCharged = 0 THEN 0
                    ELSE ((A.QHIP_RV * (1 + B.RunningCharged_RV)) - A.QHIP_RV)
                END
        END) * B.Total) +
        (A.Fixed_RV * B.Total) +
        (A.Charged_RV * B.Total) +
        B.Total AS decimal(12, 2)) AS Total,
        CASE
            WHEN A.Fixed_RV = 0 THEN B.RunningFixed_RV
            ELSE A.Fixed_RV
        END AS RunningFixed_RV,
        CASE
            WHEN A.Charged_RV = 0 THEN B.RunningCharged_RV
            ELSE A.Charged_RV
        END AS RunningCharged_RV
    FROM #MonthlyChangesExp AS A
    INNER JOIN cte_positive AS B
        ON A.StateKey = B.StateKey
        AND A.ProviderKey = B.ProviderKey
        AND A.ProductKey = B.ProductKey
        AND A.PlaceOfServiceKey = B.PlaceOfServiceKey
        AND A.CustomerSegmentKey = B.CustomerSegmentKey
        AND A.InsuredTypeKey = B.InsuredTypeKey
        AND A.HIX = B.HIX
        AND A.Position > 1
        AND A.Position - 1 = B.Position)
    /*********************************************
    [B]Calculating Trends: Negetive Direction
    **********************************************/
    ,
    cte_negetive
    AS (SELECT
        Statekey,
        ProviderKey,
        ProductKey,
        PlaceOfServiceKey,
        CustomerSegmentKey,
        InsuredTypeKey,
        HIX,
        Position,
        DateDate,
        DateYear,
        DateMonth,
        [TimeStamp],
        QHIP_RV,
        Fixed_RV,
        Charged_RV,
        QHIPCharged,
        BaseAllowed,
        AdjustedAllowed,
        CAST(AdjustedAllowed - (AdjustedAllowed / (1 + (CASE
            WHEN QHIP_RV = 0 THEN 0
            ELSE QHIP_RV +
                ((QHIP_RV * (1 + Fixed_RV)) - QHIP_RV) +
                CASE
                    WHEN QHIPCharged = 0 THEN 0
                    ELSE ((QHIP_RV * (1 + Charged_RV)) - QHIP_RV)
                END
        END))) AS decimal(12, 2)) AS QHIP,
        CAST(AdjustedAllowed - (AdjustedAllowed / (1 + Fixed_RV)) AS decimal(12, 2)) AS Fixed,
        CAST(AdjustedAllowed - (AdjustedAllowed / (1 + Charged_RV)) AS decimal(12, 2)) AS Charged,
        CAST(AdjustedAllowed AS decimal(12, 2)) AS Total,
        Closed,
        ChangePresent
    FROM #MonthlyChangesExp
    WHERE Position = 0

    UNION ALL

    SELECT
        A.Statekey,
        A.ProviderKey,
        A.ProductKey,
        A.PlaceOfServiceKey,
        A.CustomerSegmentKey,
        A.InsuredTypeKey,
        A.HIX,
        A.Position,
        A.DateDate,
        A.DateYear,
        A.DateMonth,
        A.[TimeStamp],
        A.QHIP_RV,
        A.Fixed_RV,
        A.Charged_RV,
        A.QHIPCharged,
        A.BaseAllowed,
        A.AdjustedAllowed,
        CAST(B.Total - (B.Total / (1 + CASE
            WHEN A.QHIP_RV = 0 THEN 0
            ELSE A.QHIP_RV +
                ((A.QHIP_RV * (1 + A.Fixed_RV)) - A.QHIP_RV) +
                CASE
                    WHEN A.QHIPCharged = 0 THEN 0
                    ELSE ((A.QHIP_RV * (1 + A.Charged_RV)) - A.QHIP_RV)
                END
        END)) AS decimal(12, 2)) AS QHIP,
        CAST(B.Total - (B.Total / (1 + A.Fixed_RV)) AS decimal(12, 2)) AS Fixed,
        CAST(B.Total - (B.Total / (1 + A.Charged_RV)) AS decimal(12, 2)) AS Charged,
        CAST((B.Total / (1 + CASE
            WHEN B.QHIP_RV = 0 THEN 0
            ELSE B.QHIP_RV +
                ((B.QHIP_RV * (1 + B.Fixed_RV)) - B.QHIP_RV) +
                CASE
                    WHEN B.QHIPCharged = 0 THEN 0
                    ELSE ((B.QHIP_RV * (1 + B.Charged_RV)) - B.QHIP_RV)
                END
        END +
        B.Fixed_RV +
        B.Charged_RV)) AS decimal(12, 2)) AS Total,
        A.Closed,
        A.ChangePresent
    FROM #MonthlyChangesExp AS A
    INNER JOIN cte_negetive AS B
        ON A.StateKey = B.StateKey
        AND A.ProviderKey = B.ProviderKey
        AND A.ProductKey = B.ProductKey
        AND A.PlaceOfServiceKey = B.PlaceOfServiceKey
        AND A.CustomerSegmentKey = B.CustomerSegmentKey
        AND A.InsuredTypeKey = B.InsuredTypeKey
        AND A.HIX = B.HIX
        AND A.Position < 0
        AND A.Position + 1 = B.Position)

    /*****************************************************
    [C]Combining Positive & Negetive direction Trends
    *****************************************************/
    ,
    cte_positive_negetive
    AS (SELECT
        StateKey,
        ProviderKey,
        ProductKey,
        PlaceOfServiceKey,
        CustomerSegmentKey,
        InsuredTypeKey,
        HIX,
        DateYear AS [Year],
        DateMonth AS [Month],
        DateDate AS ChangeDate,
        [TimeStamp],
        BaseAllowed AS Base,
        Total AS Allowed,
        QHIP + Fixed + Charged AS Total,
        QHIP AS QHIPPortion,
        Fixed AS FixedPortion,
        Charged AS ChargedPortion,
        Closed,
        ChangePresent,
        Position
    FROM cte_positive
    UNION ALL
    SELECT
        StateKey,
        ProviderKey,
        ProductKey,
        PlaceOfServiceKey,
        CustomerSegmentKey,
        InsuredTypeKey,
        HIX,
        DateYear AS [Year],
        DateMonth AS [Month],
        DateDate AS ChangeDate,
        [TimeStamp],
        BaseAllowed AS Base,
        Total AS Allowed,
        QHIP + Fixed + Charged AS Total,
        QHIP AS QHIPPortion,
        Fixed AS FixedPortion,
        Charged AS ChargedPortion,
        Closed,
        ChangePresent,
        Position
    FROM cte_negetive)
    /*************************************************
    Inserting Positive & Negetive direction Trend
    data into the temp table: #UnsigedTrends
    **************************************************/
    INSERT INTO #UnsigedTrends
        SELECT
            *
        FROM cte_positive_negetive

    /************************************************
    UPDATING #UnsigedTrends
    [A] Reset The position to be positive
    [B] Updating the closed status
    ************************************************/
    --------[A]
    UPDATE #UnsigedTrends
    SET Position = Position + SB.PositionOffset
    FROM #UnsigedTrends AS UT
    INNER JOIN (SELECT
        *
    FROM dbo.Statebase(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS SB
        ON UT.StateKey = SB.StateKey

    --------[B]
    ;
    WITH cte_ut
    AS (SELECT
        StateKey,
        ProviderKey,
        ProductKey,
        PlaceOfServiceKey,
        CustomerSegmentKey,
        InsuredTypeKey,
        HIX,
        ChangeDate,
        Total,
        Closed AS OldClosed,
        1 AS NewClosed,
        [TimeStamp],
        Position
    FROM #UnsigedTrends
    WHERE Position = 1

    UNION ALL

    SELECT
        A.StateKey,
        A.ProviderKey,
        A.ProductKey,
        A.PlaceOfServiceKey,
        A.CustomerSegmentKey,
        A.InsuredTypeKey,
        A.HIX,
        A.ChangeDate,
        A.Total,
        A.Closed AS OldClosed,
        CASE
            WHEN A.ChangePresent = 1 THEN A.Closed
            ELSE B.NewClosed
        END AS NewClosed,
        CASE
            WHEN A.[TimeStamp] IS NULL THEN B.[TimeStamp]
            ELSE A.[TimeStamp]
        END AS [TimeStamp],
        A.Position
    FROM #UnsigedTrends AS A
    INNER JOIN cte_ut AS B
        ON A.StateKey = B.StateKey
        AND A.ProviderKey = B.ProviderKey
        AND A.ProductKey = B.ProductKey
        AND A.PlaceOfServiceKey = B.PlaceOfServiceKey
        AND A.CustomerSegmentKey = B.CustomerSegmentKey
        AND A.InsuredTypeKey = B.InsuredTypeKey
        AND A.HIX = B.HIX
        AND A.Position - 1 = B.Position)

    UPDATE #UnsigedTrends
    SET Closed = B.NewClosed,
        [TimeStamp] = B.[TimeStamp]
    FROM #UnsigedTrends AS Y
    INNER JOIN cte_ut AS B
        ON Y.StateKey = B.StateKey
        AND Y.ProviderKey = B.ProviderKey
        AND Y.ProductKey = B.ProductKey
        AND Y.PlaceOfServiceKey = B.PlaceOfServiceKey
        AND Y.CustomerSegmentKey = B.CustomerSegmentKey
        AND Y.InsuredTypeKey = B.InsuredTypeKey
        AND Y.HIX = B.HIX
        AND Y.ChangeDate = B.ChangeDate
    OPTION (MAXRECURSION 120)

    /********************************************************
    Putting the final data into a physical table 
    (having a random key [GUId] attached with it's name)
    ********************************************************/
    DECLARE @GUId uniqueidentifier = NEWID();
    DECLARE @strGUID nvarchar(250)
    DECLARE @VarOutputTable nvarchar(max)
    ---
    SET @strGUID = CONVERT(nvarchar(250), @GUid)
    SET @strGUID = REPLACE(@strGUID, '-', '')
    SET @VarOutputTable = N'BaseData_' + @strGUID
    SET @OutputTable_BD = @VarOutputTable
    --PRINT @OutputTable
    ---
    
	DECLARE @sql nvarchar(max)
    SET @sql = N'select * into ' + @VarOutputTable + N' from #UnsigedTrends'
    EXEC sp_executesql @sql
	

    /***************************************************
    FINAL STEP: Dropping Temp Tables & selecting 
    required data
    ***************************************************/
    /*SELECT
        *
    FROM #UnsigedTrends*/

    DROP TABLE #tempMonthlyChanges
    DROP TABLE #BaseChange
    DROP TABLE #MonthlyChangesExp
    DROP TABLE #UnsigedTrends
END
