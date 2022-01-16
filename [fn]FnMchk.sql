

/*select * from dbo.mchk ('3','42','2016-09-12',2015)*/

CREATE FUNCTION dbo.FnMchk (@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears AS int)
RETURNS @ReturnTbl TABLE (
    ChangeKey bigint,
    MaxChangeHistoryKey bigint
)
AS
BEGIN
    DECLARE @temp_mchk TABLE (
        Changekey bigint,
        MaxChangeHistoryKey bigint
    )

    INSERT INTO @temp_mchk
        SELECT
            CH.ChangeKey,
            MAX(CH.ChangeHistoryKey) AS MaxChangeHistoryKey
        FROM dbo.ChangeHistory AS CH
        INNER JOIN dbo.Changes AS C
            ON CH.ChangeKey = C.ChangeKey
        INNER JOIN
        --(select * from StateBase('3','49','2016-09-12',2015))sb /*test*/
        (SELECT
            *
        FROM StateBase(@Bkey, @StateKey, @AsOfdate, @BackYears)) sb
            ON C.StateKey = SB.StateKey
            AND CAST(CH.DateTimeChanged AS date) <= SB.SetDate
        GROUP BY CH.ChangeKey


    INSERT INTO @ReturnTbl
        SELECT
            ChangeKey,
            MaxChangeHistoryKey
        FROM @temp_mchk
    RETURN
END
