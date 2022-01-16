
/*
execute GetExpectedIncreases 
@StateKeys= '49,42,30'
*/

ALTER PROCEDURE GetExpectedIncreases
(@StateKeys varchar(max))

AS 
BEGIN
SET NOCOUNT OFF

DECLARE @VarStateKeys varchar(max)
SET @VarStateKeys=@StateKeys

;WITH CTE_HospitalIncreases as
 (SELECT S.StateName
       ,p.MedicareId
       ,p.Providername
       ,p.[System]
       ,pgn.ProductGroupName
       ,posgn.PlaceOfServiceGroupName
       ,d.datedate AS IncreaseDate
       ,ch.QHIPValue
       ,ch.QHIPRatio
       ,ch.fixedvalue
       ,ch.FixedRatio
       ,ch.ChargedValue
       ,ch.ChargedRatio
       ,ROW_NUMBER() OVER 
	  (PARTITION BY c.ProviderKey, pgn.ProductGroupNameKey, posgn.PlaceOfServiceGroupName 
      ORDER BY c.ProviderKey, pgn.ProductGroupNameKey, posgn.PlaceOfServiceGroupName, d.datedate) AS Row_Counter 
 
 FROM dbo.[Changes] AS c 
 INNER JOIN dbo.ChangeHistory AS ch
 ON c.changekey = ch.changekey
 AND c.MaxChangeHistoryKey = ch.ChangeHistoryKey
 INNER JOIN dbo.States AS S
 ON C.StateKey = S.StateKey
 LEFT JOIN dbo.dates AS d
 ON ch.ChangeDateKey = d.DateKey
 LEFT JOIN dbo.ProductGroupNames AS pgn
 ON ch.ProductGroupNameKey = pgn.productgroupnamekey
 LEFT JOIN dbo.PlaceOfServiceGroupNames AS posgn
 ON ch.PlaceOfServiceGroupNameKey = posgn.placeofservicegroupnamekey
 INNER JOIN 
 (SELECT p.ProviderKey
 ,p.MedicareId
 ,p.ProviderName
 ,CASE WHEN s.SystemKey is null THEN ''
  ELSE s.SystemName END AS [System]
  FROM dbo.vwCurrentProviders AS p 
  LEFT JOIN dbo.Systems AS s
  ON p.systemkey = s.systemkey
  INNER JOIN	dbo.SplitVariable(@VarStateKeys,',') as sp 
  ON p.statekey = sp.Value OR @VarStateKeys IS NULL
  ---WHERE p.statekey IN ({STATEKEYS})
  AND p.Active = 1) AS p
  ON c.ProviderKey = p.ProviderKey
  INNER JOIN	dbo.SplitVariable(@VarStateKeys,',') as sp 
  ON c.statekey = sp.Value OR @VarStateKeys IS NULL
  ---WHERE c.Statekey IN ({STATEKEYS})
  AND ch.Deleted = 0
  AND ch.Closed = 0)
 ---------------------------Query
        SELECT StateName
       ,MedicareId
       ,ProviderName
       ,[System]
       ,ProductGroupName
       ,PlaceOfServiceGroupName
       ,isnull(D1,'') AS D1
       ,isnull(D2,'') AS D2
       ,isnull(D3,'') AS D3
       ,isnull(D4,'') AS D4
       ,isnull(V1,'') AS V1
       ,isnull(V2,'') AS V2
       ,isnull(V3,'') AS V3
       ,isnull(V4,'') AS V4
  FROM (SELECT StateName
             ,MedicareId
             ,ProviderName
             ,[System]
             ,ProductGroupName
             ,PlaceOfServiceGroupName
             ,Convert(varchar(10),max(CASE WHEN Row_counter = 1 THEN IncreaseDate ELSE null END),101) AS D1
             ,Convert(varchar(10),max(CASE WHEN Row_counter = 2 THEN IncreaseDate ELSE null END),101) AS D2
             ,Convert(varchar(10),max(CASE WHEN Row_counter = 3 THEN IncreaseDate ELSE null END),101) AS D3
             ,Convert(varchar(10),max(CASE WHEN Row_counter = 4 THEN IncreaseDate ELSE null END),101) AS D4
             ,Convert(varchar(7),convert(decimal(10,2),max(CASE WHEN Row_counter = 1 THEN FixedValue ELSE null END))) AS V1
             ,Convert(varchar(7),convert(decimal(10,2),max(CASE WHEN Row_counter = 2 THEN FixedValue ELSE null END))) AS V2
             ,Convert(varchar(7),convert(decimal(10,2),max(CASE WHEN Row_counter = 3 THEN FixedValue ELSE null END))) AS V3
             ,Convert(varchar(7),convert(decimal(10,2),max(CASE WHEN Row_counter = 4 THEN FixedValue ELSE null END))) AS V4
       FROM CTE_HospitalIncreases
       group BY StateName
               ,MedicareId
               ,ProviderName
               ,[System]
               ,ProductGroupName
               ,PlaceOfServiceGroupName) AS SQ
       ORDER BY 1,2,3,4,5,6
 
 SET NOCOUNT OFF
 END
