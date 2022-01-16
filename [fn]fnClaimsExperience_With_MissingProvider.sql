
/*
SELECT * from [dbo].[fnClaimsExperience_With_MissingProvider] ('3','49','2016-01-01',1)
DROP FUNCTION fnClaimsExperience_With_MissingProvider 
*/

ALTER FUNCTION [dbo].[fnClaimsExperience_With_MissingProvider] (@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears AS int)

RETURNS @ReturnTbl TABLE (
    StateKey bigint,
    ProviderKey bigint,
    ProductKey bigint,
    PlaceOfServiceKey bigint,
    CustomerSegmentKey bigint,
    InsuredTypeKey bigint,
    HIX tinyint,
    BaseAllowed decimal(18, 2),
    AdjustedAllowed decimal(15, 4)
)
AS
BEGIN
    /**************************************************
    Declaring a Table variable which will store
    the final data (Claim Experience data for both)
    Missing & Non-Missing Providers
    **************************************************/
    DECLARE @ClaimsExperience_With_MissingProvider TABLE (
        Statekey bigint,
        ProviderKey bigint,
        ProductKey bigint,
        PlaceOfServiceKey bigint,
        CustomerSegmentKey bigint,
        InsuredTypeKey bigint,
        HIX int,
        BaseAllowed int,
        AdjustedAllowed int
    )

    /************************************************
    Creating two CTEs which we use to populate 
    missing providers' record
    ************************************************/
    ---[First CTE]

    ;
    WITH cte_SP
    AS (SELECT
        P.StateKey,
        P.ProviderKey
    FROM dbo.vwCurrentProviders AS P
    WHERE P.StateKey IN (SELECT DISTINCT
        StateKey
    FROM (SELECT
        *
    FROM dbo.Statebase(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS SB)
    AND P.Active = 1
    AND P.ShowInOutput = 1
    AND P.ProviderKey NOT IN (SELECT DISTINCT
        ProviderKey
    FROM (SELECT
        *
    FROM dbo.FnClaimsExperience(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS CE)),

    ---[second CTE]
    cte_SPPCI
    AS (SELECT DISTINCT
        Statekey,
        ProductKey,
        PlaceOfServiceKey,
        CustomerSegmentKey,
        InsuredTypeKey
    FROM (SELECT
        *
    FROM dbo.FnClaimsExperience(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS CE
    WHERE CustomerSegmentKey <> 0)

    /**************************************************************
    Inserting Missing Providers' Claim Experience Data into 
    the created table-variable (using both CTEs)
    **************************************************************/
    INSERT INTO @ClaimsExperience_With_MissingProvider
        SELECT
            SP.Statekey,
            SP.ProviderKey,
            SPPCI.ProductKey,
            SPPCI.PlaceOfServiceKey,
            SPPCI.CustomerSegmentKey,
            SPPCI.InsuredTypeKey,
            0 AS HIX,
            0 AS BaseAllowed,
            0 AS AdjustedAllowed
        FROM cte_SP AS SP
        INNER JOIN cte_SPPCI AS SPPCI
            ON SP.StateKey = SPPCI.StateKey
    --CREATE index idx_SPPP ON #ClaimsExperienceMissingProvider 
    --(StateKey, ProviderKey, ProductKey, PlaceOfServiceKey)

    /**************************************************************
    Inserting Non-Missing Providers' Claim Experience Data into 
    the created table-variable
    **************************************************************/
    INSERT INTO @ClaimsExperience_With_MissingProvider
        SELECT
            *
        FROM dbo.FnClaimsExperience(@Bkey, @StateKey, @AsOfdate, @BackYears)

    INSERT INTO @ReturnTbl
        SELECT
            *
        FROM @ClaimsExperience_With_MissingProvider

    RETURN
END
