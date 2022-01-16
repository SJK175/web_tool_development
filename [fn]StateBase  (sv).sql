

/*
select * from dbo.Statebase('3','49,30','2016-09-12',2015)
*/


ALTER FUNCTION dbo.StateBase (@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears AS int)

RETURNS @ReturnTbl TABLE (
    Statekey bigint,
    SetDate date,
    BaseYear int,
    StartYear int,
    PositionOffset int
)

AS
BEGIN

    DECLARE @temp_StateBase TABLE (
        Statekey bigint,
        SetDate date,
        BaseYear int,
        StartYear int,
        PositionOffset int
    )
    IF (SUBSTRING(@BKEY, 2, 9) = 'BUDGETKEY')
    BEGIN
        INSERT INTO @temp_StateBase
            SELECT
                S.StateKey,
                @AsOfDate AS SetDate,
                S.eHausBaseYear AS BaseYear,
                S.eHausStartYear AS StartYear,
                ((S.eHausBaseYear - S.eHausStartYear) + @BackYears) * 12 AS PositionOffset

            FROM dbo.States AS S
            INNER JOIN	dbo.SplitVariable(@stateKey,',') as c ON S.StateKey = c.Value OR @stateKey IS NULL
			WHERE S.eHausState = 1
            --AND CAST(S.StateKey AS varchar(max)) IN (@stateKey)
            ORDER BY 1
    END
    ELSE
    BEGIN

        INSERT INTO @temp_StateBase
            SELECT
                SBP.StateKey,
                SBP.SetDate,
                S.eHausBaseYear AS BaseYear,
                S.eHausStartYear AS StartYear,
                ((S.eHausBaseYear - S.eHausStartYear) + @BackYears) * 12 AS PositionOffset

            FROM dbo.BudgetPeriods AS BP
            INNER JOIN dbo.StateBudgetPeriods AS SBP
                ON BP.BudgetKey = SBP.BudgetPeriodKey
            INNER JOIN dbo.States AS S
                ON SBP.StateKey = S.StateKey
			INNER JOIN	dbo.SplitVariable(@stateKey,',') as c ON S.StateKey = c.Value OR @stateKey IS NULL
            WHERE CAST(BP.BudgetKey AS varchar(max)) = @BKEY
            --AND CAST(SBP.StateKey AS varchar(max)) IN (@stateKey)
    END

    INSERT INTO @ReturnTbl
        SELECT
            StateKey,
            Setdate,
            BaseYear,
            StartYear,
            PositionOffset
        FROM @temp_StateBase

    RETURN
END
