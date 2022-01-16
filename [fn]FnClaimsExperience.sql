

/*select * from dbo.FnClaimsExperience('3','49','2016-01-01',1)*/


ALTER FUNCTION dbo.FnClaimsExperience 
(@BKey varchar(12)
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

    DECLARE @Temp_ClaimsExperience TABLE (
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

    INSERT INTO @Temp_ClaimsExperience
        SELECT
            CE.StateKey,
            CE.ProviderKey,
            CE.ProductKey,
            CE.PlaceOfServiceKey,
            CE.CustomerSegmentKey,
            CE.InsuredTypeKey,
            CE.HIX,
            SUM(CE.ValueAmount01) / 12.0000 AS BaseAllowed,
            CAST(0 AS decimal(15, 4)) AS AdjustedAllowed
        FROM dbo.Run AS R
        INNER JOIN dbo.ClaimsExperience AS CE
            ON R.RunKey = ce.RunKey
            AND R.Active = 1
        INNER JOIN dbo.Dates AS D
            ON ce.IncurredDateKey = d.datekey
        INNER JOIN (SELECT
            *
        FROM dbo.Statebase(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS SB
            ON ce.StateKey = SB.StateKey
        INNER JOIN dbo.ExperienceBaseYear AS EBY
            ON R.ExperienceBaseYearId = EBY.ExperienceBaseYearId
            AND EBY.ExperienceBaseYear = SB.BaseYear
        GROUP BY CE.StateKey,
                 CE.ProviderKey,
                 CE.ProductKey,
                 CE.PlaceOfServiceKey,
                 CE.CustomerSegmentKey,
                 CE.InsuredTypeKey,
                 CE.HIX

 INSERT INTO @ReturnTbl 
 SELECT * FROM @Temp_ClaimsExperience

RETURN
END
