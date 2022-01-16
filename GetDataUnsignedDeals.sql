
/*
EXECUTE GetDataUnsignedDeals 
 @Startdate='2015-01-01'
,@Enddate='2016-12-31'
,@StateKey=49
*/

CREATE PROCEDURE GetDataUnsignedDeals 
 (@Startdate date
, @Enddate date
, @StateKey bigint)
AS
BEGIN

    /*******************************************************
    Creating Local variables & inserting parameter values
    within Local variables
    ********************************************************/
    DECLARE @Var_Startdate date
    SET @var_Startdate = @Startdate
    DECLARE @Var_Enddate date
    SET @Var_Enddate = @Enddate
    DECLARE @var_StateKey bigint
    SET @var_StateKey = @StateKey

    /***************
       Query
    ***************/
    SELECT
        S.StateName,
        ISNULL(PT.ProviderType, '') AS ProviderType,
        CAST(D.DateYear AS varchar(4)) + CASE
            WHEN D.DateMonth < 10 THEN '-0'
            ELSE '-'
        END + CAST(D.DateMonth AS varchar(2)) AS YearMonth,
        P.ProviderName + ' (' + P.ProviderId + ')' AS Provider,
        CASE
            WHEN CH.Closed = 1 THEN 'Yes'
            ELSE 'No'
        END AS Signed,
        COUNT(1) AS Frequency
    --INTO {OUTPUTTABLE} 
    FROM dbo.Changes AS C
    INNER JOIN dbo.ChangeHistory AS CH
        ON C.ChangeKey = CH.ChangeKey
        AND C.MaxChangeHistoryKey = CH.ChangeHistoryKey
    INNER JOIN dbo.States AS S
        ON C.StateKey = S.StateKey
    INNER JOIN dbo.vwCurrentProviders AS P
        ON C.ProviderKey = P.ProviderKey
    LEFT OUTER JOIN dbo.ProviderTypes AS PT
        ON P.ProviderTypeKey = PT.ProviderTypeKey
    INNER JOIN dbo.Dates AS D
        ON Ch.ChangeDateKey = D.DateKey
    INNER JOIN dbo.SplitVariable(@Var_StateKey, ',') AS sv
        ON S.Statekey = sv.Value
        OR @Var_StateKey IS NULL
    /*Made the above inner join to allow multiple statekeys in parameter*/

    WHERE D.DateDate BETWEEN @Var_StartDate AND @Var_Enddate
    GROUP BY S.StateName,
             ISNULL(PT.ProviderType, ''),
             CAST(D.DateYear AS varchar(4)) + CASE
                 WHEN D.DateMonth < 10 THEN '-0'
                 ELSE '-'
             END + CAST(D.DateMonth AS varchar(2)),
             P.ProviderName + ' (' + P.ProviderId + ')',
             CASE
                 WHEN CH.Closed = 1 THEN 'Yes'
                 ELSE 'No'
             END
    ORDER BY S.StateName, YearMonth, Provider, Signed
END
