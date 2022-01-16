USE [ITF_Obfuscated_Final]
GO
/****** Object:  StoredProcedure [dbo].[GetBCBSProjection]    Script Date: 11-09-2016 12:03:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
EXECUTE GetBCBSProjection
@OutputTable=BaseData_D8FDC660990945F89957FD8AC933160B
*/

ALTER PROCEDURE [dbo].[GetBCBSProjection]
(@OutputTable nvarchar(200))
AS
BEGIN
SET NOCOUNT OFF

DECLARE @VarOutputTable varchar(250)
SET @VarOutputTable = @OutputTable

DECLARE @sql nvarchar (max)              
SET @sql = ';WITH CTE_BCBS as
(SELECT S.StateName
      ,P.ZipCode
      ,POS.PlaceOfService
      ,[Year]
      ,SUM(Allowed)        AS Allowed
FROM ' + @VarOutputTable + ' AS X 
INNER JOIN dbo.vwCurrentProviders AS P
  ON X.ProviderKey = P.Providerkey
INNER JOIN dbo.PlaceOfServices AS POS
  ON X.PlaceOfServiceKey = POS.PlaceOfServiceKey
                      INNER JOIN dbo.States AS S
  ON X.StateKey = S.StateKey
Group BY S.StateName
        ,P.ZipCode
        ,POS.PlaceOfService
        ,[Year])
 
 SELECT A.StateName
      ,A.Zipcode
      ,A.PlaceOfService
      ,A.[Year]
      ,A.Allowed        AS CurrentAllowed
      ,B.Allowed        AS PreviousAllowed 
FROM CTE_BCBS AS A 
INNER JOIN CTE_BCBS AS B
  ON A.StateName      = B.StateName
  AND A.ZipCode        = B.ZipCode
  AND A.PlaceOfService = B.PlaceOfService
  AND A.[Year]         = B.[Year] - 1
  ORDER BY 1,2,3,4'
  

CREATE TABLE #temp
(
 StateName varchar(50)
,ZipCode char(5)
,PlaceOfService varchar(50)
,[Year] int
,CurrentAllowed decimal(15,5)
,PreviousAllowed decimal(15,5)
)  
INSERT INTO #Temp 
EXECUTE sp_executesql @sql

select * from #Temp
Drop Table #Temp

SET NOCOUNT ON
END  
  
