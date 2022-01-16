/*
EXECUTE GetComparisonReport_1 
@BKey='3'
,@stateKey='42'
,@AsOfDateCurrent='2015-09-12'
,@AsOfDateOther='2016-09-12'
,@BackYears=2015
DROP PROCEDURE GetComparisonReport_1
*/


CREATE PROCEDURE GetComparisonReport_1 (@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDateCurrent date
, @AsOfDateOther date
, @BackYears AS int)

AS
BEGIN
    SET NOCOUNT OFF

    /*******************************
    --Current Data--
    *******************************/
    SELECT
        C.ChangeKey,
        S.StateName,
        P.ProviderName,
        P.ProviderId,
        PE.ProductName,
        PoSE.PlaceOfService,
        D.DateDate,
        CH.QHIPValue,
        CH.QHIPRatio,
        CH.FixedValue,
        CH.FixedRatio,
        CH.ChargedValue,
        CH.ChargedRatio,
        CH.Closed INTO #CurrentTrendInput
    FROM (SELECT
        ChangeKey,
        MaxChangeHistoryKey
    FROM dbo.mchk(@BKey, @StateKey, @AsOfDateCurrent, @BackYears)) AS MCHK
    INNER JOIN dbo.Changes AS C
        ON MCHK.ChangeKey = C.ChangeKey
    INNER JOIN dbo.ChangeHistory AS CH
        ON MCHK.MaxChangeHistoryKey = CH.ChangeHistoryKey
    INNER JOIN dbo.States AS S
        ON C.Statekey = S.StateKey
    INNER JOIN dbo.vwCurrentProviders AS P
        ON C.ProviderKey = P.ProviderKey
    INNER JOIN dbo.Dates AS D
        ON CH.ChangeDateKey = D.DateKey
    INNER JOIN dbo.vwProductGroupExpanded AS PE
        ON CH.ProductGroupNameKey = PE.ProductGroupNameKey
    INNER JOIN dbo.vwPlaceOfServiceGroupExpanded AS PoSE
        ON CH.PlaceOfServiceGroupNameKey = PoSE.PlaceOfServiceGroupNameKey
    --ORDER BY 1,2,3,4,5,6

    /**********************************
    --Other Data--
    **********************************/
    SELECT
        C.ChangeKey,
        S.StateName,
        P.ProviderName,
        P.ProviderId,
        PE.ProductName,
        PoSE.PlaceOfService,
        D.DateDate,
        CH.QHIPValue,
        CH.QHIPRatio,
        CH.FixedValue,
        CH.FixedRatio,
        CH.ChargedValue,
        CH.ChargedRatio,
        CH.Closed INTO #OtherTrendInput
    FROM (SELECT
        ChangeKey,
        MaxChangeHistoryKey
    FROM dbo.mchk(@BKey, @StateKey, @AsOfDateOther, @BackYears)) AS MCHK
    INNER JOIN dbo.Changes AS C
        ON MCHK.ChangeKey = C.ChangeKey
    INNER JOIN dbo.ChangeHistory AS CH
        ON MCHK.MaxChangeHistoryKey = CH.ChangeHistoryKey
    INNER JOIN dbo.States AS S
        ON C.Statekey = S.StateKey
    INNER JOIN dbo.vwCurrentProviders AS P
        ON C.ProviderKey = P.ProviderKey
    INNER JOIN dbo.Dates AS D
        ON CH.ChangeDateKey = D.DateKey
    INNER JOIN dbo.vwProductGroupExpanded AS PE
        ON CH.ProductGroupNameKey = PE.ProductGroupNameKey
    INNER JOIN dbo.vwPlaceOfServiceGroupExpanded AS PoSE
        ON CH.PlaceOfServiceGroupNameKey = PoSE.PlaceOfServiceGroupNameKey
    --order by 1,2,3,4,5,6

    /*******************************
    --Comparison Report--
    *******************************/
    SELECT
        ISNULL(A.StateName, B.StateName) AS StateName,
        ISNULL(A.ProviderName, B.ProviderName) AS ProviderName,
        ISNULL(A.ProviderId, B.ProviderId) AS ProviderId,
        ISNULL(A.ProductName, B.ProductName) AS ProductName,
        ISNULL(A.PlaceOfService, B.PlaceOfService) AS PlaceOfService,
        ISNULL(A.DateDate, B.DateDate) AS DateDate,
        A.QHIPRatio * A.QHIPValue AS QHIP_A,
        A.FixedRatio * A.FixedValue AS Fixed_A,
        A.chargedRatio * A.ChargedValue AS Charged_A,
        B.QHIPRatio * B.QHIPValue AS QHIP_B,
        B.FixedRatio * B.FixedValue AS Fixed_B,
        B.chargedRatio * B.ChargedValue AS Charged_B,
        CASE
            WHEN A.ChangeKey IS NULL THEN 'Missing'
            WHEN B.ChangeKey IS NULL THEN 'New'
            WHEN ((A.QHIPRatio * A.QHIPValue) <> (B.QHIPRatio * B.QHIPValue)) THEN 'QHIP'
            WHEN ((A.FixedRatio * A.FixedValue) <> (B.FixedRatio * B.FixedValue)) THEN 'Fixed'
            WHEN ((A.chargedRatio * A.ChargedValue) <> (B.chargedRatio * B.ChargedValue)) THEN 'Charged'
            ELSE ''
        END AS [What Changed]
    FROM #CurrentTrendInput AS A
    FULL OUTER JOIN #OtherTrendInput AS B
        ON A.StateName = B.StateName
        AND A.ProviderId = B.ProviderId
        AND A.ProductName = B.ProductName
        AND A.PlaceOfService = B.PlaceOfService
        AND A.DateDate = B.DateDate
    WHERE CASE
        WHEN A.ChangeKey IS NULL THEN 1
        WHEN B.ChangeKey IS NULL THEN 1
        WHEN ((A.QHIPRatio * A.QHIPValue) <> (B.QHIPRatio * B.QHIPValue)) THEN 1
        WHEN ((A.FixedRatio * A.FixedValue) <> (B.FixedRatio * B.FixedValue)) THEN 1
        WHEN ((A.chargedRatio * A.ChargedValue) <> (B.chargedRatio * B.ChargedValue)) THEN 1
        ELSE 0
    END = 1
    ORDER BY 1, 2, 3, 4, 5, 6

    SET NOCOUNT ON
END
