
/*
EXECUTE dbo.StProc_ChangesExpanded_With_Missing_Prov '3','30','2016-09-12',1
DROP PROCEDURE dbo.StProc_ChangesExpanded_With_Missing_Prov
---
select * from dbo.FnChangesExpanded_With_Missing_Prov ('3','30','2016-09-12',1)
DROP FUNCTION dbo.FnChangesExpanded_With_Missing_Prov
*/


CREATE FUNCTION dbo.FnChangesExpanded_With_Missing_Prov
 (@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears AS int)

     Returns @ReturnTbl table  
	    (StateKey bigint,
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
        Closed smallint)

AS
BEGIN

/*******************************************************************
Inserting FnMchk data into a table-variable for further use.
We created a table-variable instead of using the FnMchk directly
because we created index on the table-variable to make the process
faster.
*******************************************************************/
      DECLARE @mchk table 
	  (ChangeKey bigint,
      MaxChangeHistoryKey bigint
	  UNIQUE NONCLUSTERED (ChangeKey,MaxChangeHistoryKey) 
	  )
	  INSERT INTO @mchk
	  select * from dbo.FnMchk(@Bkey, @StateKey, @AsOfdate, @BackYears)

	
		
/*********************************************************
Grab and Expand the Change Record: Creating a table-var
that will hold all data
**********************************************************/
	    DECLARE @temp_ChangesExpanded TABLE  
		(StateKey bigint,
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
    INSERT INTO @temp_ChangesExpanded
    SELECT
            C.StateKey,
            CH.ProviderKey,
            CH.ChangeDateKey,
            CAST(CAST(D.DateYear * 10000 + D.DateMonth * 100 + 1 AS varchar(8)) AS date) AS ChangeDate,
            MAX(CH.DateTimeChanged) AS [TimeStamp],
            PGE.ProductKey,
            POSGE.PlaceOfServiceKey,
            SUM(CH.QHIPValue) AS QHIPValue,
            MAX(CH.QHIPRatio) AS QHIPRatio,
            SUM(CH.FixedValue) AS FixedValue,
            MAX(CH.FixedRatio) AS FixedRatio,
            SUM(CH.ChargedValue) AS ChargedValue,
            MAX(CH.ChargedRatio) AS ChargedRatio,
            MAX(CH.Closed) AS Closed
        FROM @mchk A
        INNER JOIN dbo.Changes AS C
            ON A.ChangeKey = C.ChangeKey
        INNER JOIN dbo.ChangeHistory AS CH
            ON A.ChangeKey = CH.ChangeKey
            AND A.MaxChangeHistoryKey = CH.ChangeHistoryKey
        INNER JOIN dbo.Dates AS D
            ON CH.ChangeDateKey = D.DateKey
        INNER JOIN dbo.vwProductGroupExpanded AS PGE
            ON CH.ProductGroupNameKey = PGE.ProductGroupNameKey
        INNER JOIN dbo.vwPlaceOfServiceGroupExpanded AS POSGE
            ON CH.PlaceOfServiceGroupNameKey = POSGE.PlaceOfServiceGroupNameKey
        WHERE CH.Deleted = 0
        AND (CH.QHIPValue * CH.QHIPRatio <> 0 OR
                   CH.FixedValue * CH.FixedRatio <> 0 OR
                   CH.ChargedValue * CH.ChargedRatio <> 0)
           
        GROUP BY C.StateKey,
                 CH.ProviderKey,
                 CH.ChangeDateKey,
                 CAST(CAST(D.DateYear * 10000 + D.DateMonth * 100 + 1 AS varchar(8)) AS date),
                 PGE.ProductKey,
                 POSGE.PlaceOfServiceKey

/****************************************************************
Adding Missing Providers' records with the already inserted
data into the temp table 
*****************************************************************/

;WITH cte_Everything
    AS (SELECT DISTINCT
        SB.StateKey,
        P.ProviderKey,
        Pr.ProductKey,
        POS.PlaceOfServiceKey,
        D.DateDate AS ChangeDate,
        D.DateKey AS ChangeDateKey
    FROM (SELECT
        *
    FROM dbo.StateBase(@Bkey, @StateKey, @AsOfdate, @BackYears)) AS SB
    INNER JOIN dbo.vwCurrentProviders AS P
        ON SB.StateKey = P.StateKey
        AND P.ShowInOutput = 1
        AND P.Active = 1
        AND P.ProviderCategoryKey = 1
    INNER JOIN dbo.Products AS Pr
        ON SB.StateKey = Pr.StateKey
    INNER JOIN dbo.PlaceOfServices AS POS
        ON 1 = 1
        AND POS.PlaceOfServiceKey <> 0
    INNER JOIN dbo.Dates AS D
        ON SB.StartYear = D.DateYear
        AND D.DateMonth = 1
        AND D.DateDay = 1)
		
	,cte_Set
    AS (SELECT DISTINCT
        Statekey,
        ProviderKey,
        ProductKey,
        PlaceOfServiceKey
    FROM @temp_ChangesExpanded) 

/*****************************************************************
 @temp_ChangesExpanded is already having data. We will just add
 few more rows for missing providers
*****************************************************************/
	INSERT INTO @temp_ChangesExpanded
	SELECT A.Statekey
       ,A.ProviderKey
       ,A.ChangeDateKey
       ,A.ChangeDate     
       ,'1900.01.01 00:00:01'AS [TimeStamp]          
       ,A.ProductKey
       ,A.PlaceOfServiceKey
       ,0 AS QHIPValue
       ,0 AS QHIPRatio
       ,0 AS FixedValue
       ,0 AS FixedRatio
       ,0 AS ChargedValue
       ,0 AS ChargedRatio
       ,0 AS Closed
  FROM cte_Everything AS A 
  LEFT OUTER JOIN cte_Set AS B
  ON A.StateKey= B.StateKey
  AND A.ProviderKey= B.ProviderKey
  AND A.ProductKey=B.ProductKey
  AND A.PlaceOfServiceKey=B.PlaceOfServiceKey
  WHERE B.StateKey is null	

 /***************************************************
 Displaying data of the temp table & then dropping
 the temp table
 ***************************************************/   
	
	INSERT INTO @ReturnTbl
	SELECT * FROM @temp_ChangesExpanded
	

RETURN
END
