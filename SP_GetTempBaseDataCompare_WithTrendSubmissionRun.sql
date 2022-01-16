/* TrendComparisonData */


/* if object_id('tempdb..{INTO_TABLE}') is NOT null drop TABLE {INTO_TABLE} */
/*drop table TempBaseDataCompareTableA9F5E6D3DFCF4321B87AD56A2DD3A68C*/


/*
EXECUTE [dbo].[GetTempBaseDataCompare]
@TableC = BaseData_A9F5E6D3DFCF4321B87AD56A2DD3A68C
, @TableP = BaseData_592B9BC435764E4B920D0484DE3EE10C
, @TSID = 1

*/

USE [ITF_Obfuscated_Final]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
ALTER PROCEDURE [dbo].[GetTempBaseDataCompare](
@TableC varchar(250)
,@TableP varchar(250)
,@TSID BigInt
)

AS
BEGIN

--if object_id('tempdb..TempBaseDataCompareTable') is NOT null drop TABLE TempBaseDataCompareTable
DECLARE @VarTableC varchar(250)
SET @VarTableC = @TableC

DECLARE @VarTableP varchar(250)
SET @VarTableP = @TableP

DECLARE @VarTSID Bigint
SET @VarTSID = @TSID

DECLARE @VarOutputTable varchar(250)
DECLARE @tempBaseDataCompareTable varchar(250)
DECLARE @Varidentifier varchar(200)

DECLARE @sql nvarchar(max)
SET @sql = 'DROP TABLE ' + @TempBaseDataCompareTable

SET @VarOutputTable = 'BaseData_A9F5E6D3DFCF4321B87AD56A2DD3A68C'
SET @Varidentifier = substring(@VarOutputTable, charindex('_',@VarOutputTable)+1,len(@VarOutputTable)-9);
SET @tempBaseDataCompareTable = N'TempBaseDataCompareTable' + @Varidentifier

/*---------------- ORIGINAL QUERY (Table TrendSubmissionRun does not exist in the database) -----------
DECLARE @sql nvarchar(max)
SET @sql = 'SELECT S.StateName
      ,P.ProviderName
      ,P.ProviderId
      ,SQ.[Year]  
      ,SQ.C_Y2 - SQ.P_Y2 AS D_1
      ,SQ.C_Y3 - SQ.P_Y3 AS D_2
      ,SQ.C_Y4 - SQ.P_Y4 AS D_3
      ,CASE WHEN SQ.C_Y1 = 0 THEN 0 WHEN SQ.P_Y1 = 0 THEN 0 ELSE (SQ.C_Y2 / SQ.C_Y1) - (SQ.P_Y2 / SQ.P_Y1) END AS P_1
      ,CASE WHEN SQ.C_Y2 = 0 THEN 0 WHEN SQ.P_Y2 = 0 THEN 0 ELSE (SQ.C_Y3 / SQ.C_Y2) - (SQ.P_Y3 / SQ.P_Y2) END AS P_2
      ,CASE WHEN SQ.C_Y3 = 0 THEN 0 WHEN SQ.P_Y3 = 0 THEN 0 ELSE (SQ.C_Y4 / SQ.C_Y3) - (SQ.P_Y4 / SQ.P_Y4) END AS P_3
INTO ' + @tempBaseDataCompare +
' FROM (SELECT A.StateKey
            ,A.ProviderKey
            ,SEBY.[Year]
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 0 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y1
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 1 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y2
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 2 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y3
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 3 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y4
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 0 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y1
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 1 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y2
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 2 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y3
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 3 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y4
      FROM ' + @TableC + ' AS A full OUTER JOIN ' + @TableP + ' AS B
        ON A.StateKey = B.StateKey
       AND A.ProviderKey = B.ProviderKey
       AND A.ProductKey = B.ProductKey
       AND A.PlaceOfServiceKey = B.PlaceOfServiceKey
       AND A.CustomerSegmentKey = B.CustomerSegmentKey
       AND A.InsuredTypeKey = B.InsuredTypeKey
       AND A.[Month] = B.[Month]
       AND A.[Year] = B.[Year]
                                  INNER JOIN (SELECT TSR.StateKey 
                                                    ,EBY.ExperienceBaseYear AS [Year]
                                              FROM dbo.TrendSubmissions AS TS INNER JOIN dbo.TrendSubmissionRun AS TSR
                                                ON TS.TrendSubmissionId = TSR.TrendSubmissionId
                                                                              INNER JOIN dbo.ExperienceBaseYear AS EBY
                                                ON TSR.ExperienceBaseYearId = EBY.ExperienceBaseYearId
                                              WHERE TS.TrendSubmissionId = @TSID) AS SEBY
        ON A.StateKey = SEBY.StateKey
      group BY A.stateKey
              ,A.ProviderKey
              ,SEBY.[Year]) AS SQ INNER JOIN dbo.States AS S 
  ON SQ.StateKey = S.StateKey
                                    INNER JOIN dbo.vwCurrentProviders AS P
  ON SQ.ProviderKey = P.ProviderKey
ORDER BY S.StateName
        ,P.ProviderName
        ,P.ProviderId'
*/------------------------------------- END ORIGINAL QUERY --------------------------------------------

---------------------------------------- STAND By QUERY -----------------------------------------------
/*
--DECLARE @sql nvarchar(max)
--SET @sql = 'DROP TABLE ' + @tempBaseDataCompareTable
SET @sql = 'SELECT S.StateName
      ,P.ProviderName
      ,P.ProviderId
      ,SQ.[Year]  
      --,SQ.C_Y2 - SQ.P_Y2 AS D_1
	    ,2012 AS D_1
      --,SQ.C_Y3 - SQ.P_Y3 AS D_2
	    ,2012 AS D_2
      --,SQ.C_Y4 - SQ.P_Y4 AS D_3
	    ,2012 AS D_3
      --,CASE WHEN SQ.C_Y1 = 0 THEN 0 WHEN SQ.P_Y1 = 0 THEN 0 ELSE (SQ.C_Y2 / SQ.C_Y1) - (SQ.P_Y2 / SQ.P_Y1) END AS P_1
	    ,2012 AS P_1
      --,CASE WHEN SQ.C_Y2 = 0 THEN 0 WHEN SQ.P_Y2 = 0 THEN 0 ELSE (SQ.C_Y3 / SQ.C_Y2) - (SQ.P_Y3 / SQ.P_Y2) END AS P_2
	    ,2012 AS P_2
      --,CASE WHEN SQ.C_Y3 = 0 THEN 0 WHEN SQ.P_Y3 = 0 THEN 0 ELSE (SQ.C_Y4 / SQ.C_Y3) - (SQ.P_Y4 / SQ.P_Y4) END AS P_3
	    ,2012 AS P_3
INTO ' + @tempBaseDataCompareTable +
 ' FROM (SELECT A.StateKey
            ,A.ProviderKey			
           --,SEBY.[Year]
		   ,2012 as Year
            --,sum(CASE WHEN A.[Year] = SEBY.[Year] + 0 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y1
			,2012 AS C_Y1
            --,sum(CASE WHEN A.[Year] = SEBY.[Year] + 1 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y2
			,2012 AS C_Y2
            --,sum(CASE WHEN A.[Year] = SEBY.[Year] + 2 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y3
			,2012 AS C_Y3
            --,sum(CASE WHEN A.[Year] = SEBY.[Year] + 3 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y4
			,2012 AS C_Y4
            --,sum(CASE WHEN A.[Year] = SEBY.[Year] + 0 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y1
			,2012 AS P_Y1
            --,sum(CASE WHEN A.[Year] = SEBY.[Year] + 1 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y2
			,2012 AS P_Y2
            --,sum(CASE WHEN A.[Year] = SEBY.[Year] + 2 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y3
			,2012 AS P_Y3
            --,sum(CASE WHEN A.[Year] = SEBY.[Year] + 3 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y4
			,2012 AS P_Y4
      FROM ' + @TableC + ' AS A 
	  full OUTER JOIN ' + @TableP + ' AS B
        ON A.StateKey = B.StateKey
       AND A.ProviderKey = B.ProviderKey
       AND A.ProductKey = B.ProductKey
       AND A.PlaceOfServiceKey = B.PlaceOfServiceKey
       AND A.CustomerSegmentKey = B.CustomerSegmentKey
       AND A.InsuredTypeKey = B.InsuredTypeKey
       AND A.[Month] = B.[Month]
       AND A.[Year] = B.[Year]
                                /*  INNER JOIN (SELECT TSR.StateKey 
                                                    ,EBY.ExperienceBaseYear AS [Year]
                                              FROM dbo.TrendSubmissions AS TS INNER JOIN dbo.TrendSubmissionRun AS TSR
                                                ON TS.TrendSubmissionId = TSR.TrendSubmissionId
                                                                              INNER JOIN dbo.ExperienceBaseYear AS EBY
                                                ON TSR.ExperienceBaseYearId = EBY.ExperienceBaseYearId
                                              WHERE TS.TrendSubmissionId = @TSID) AS SEBY
        ON A.StateKey = SEBY.StateKey
*/      
	  group BY A.stateKey
              ,A.ProviderKey
              ,A.Year) AS SQ INNER JOIN dbo.States AS S 
  ON SQ.StateKey = S.StateKey
                                    INNER JOIN dbo.vwCurrentProviders AS P
  ON SQ.ProviderKey = P.ProviderKey
ORDER BY S.StateName
        ,P.ProviderName
        ,P.ProviderId'

/*drop table tempBaseDataCompareTable*/

/*select * from tempBaseDataCompare*/

*/
---------------------------------- QUERY with Table TrendSubmissionRun 07Nov2016 ------------------------------


--DECLARE @sql nvarchar(max)
--SET @sql = 'DROP TABLE ' + @tempBaseDataCompareTable
SET @sql = 'SELECT S.StateName
      ,P.ProviderName
      ,P.ProviderId
      ,SQ.[Year]  
      ,SQ.C_Y2 - SQ.P_Y2 AS D_1
	   
      ,SQ.C_Y3 - SQ.P_Y3 AS D_2
	    
      ,SQ.C_Y4 - SQ.P_Y4 AS D_3
	   
      ,CASE WHEN SQ.C_Y1 = 0 THEN 0 WHEN SQ.P_Y1 = 0 THEN 0 ELSE (SQ.C_Y2 / SQ.C_Y1) - (SQ.P_Y2 / SQ.P_Y1) END AS P_1
	   
      ,CASE WHEN SQ.C_Y2 = 0 THEN 0 WHEN SQ.P_Y2 = 0 THEN 0 ELSE (SQ.C_Y3 / SQ.C_Y2) - (SQ.P_Y3 / SQ.P_Y2) END AS P_2
	    
      ,CASE WHEN SQ.C_Y3 = 0 THEN 0 WHEN SQ.P_Y3 = 0 THEN 0 ELSE (SQ.C_Y4 / SQ.C_Y3) - (SQ.P_Y4 / SQ.P_Y4) END AS P_3
	    
INTO ' + @tempBaseDataCompareTable +
 ' FROM (SELECT A.StateKey
            ,A.ProviderKey			
           ,SEBY.[Year]
		   --,2012 as Year
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 0 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y1
			--,2012 AS C_Y1
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 1 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y2
			--,2012 AS C_Y2
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 2 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y3
			--,2012 AS C_Y3
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 3 THEN (A.Total + A.Allowed) ELSE 0 END) AS C_Y4
			--,2012 AS C_Y4
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 0 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y1
			--,2012 AS P_Y1
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 1 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y2
			--,2012 AS P_Y2
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 2 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y3
			--,2012 AS P_Y3
            ,sum(CASE WHEN A.[Year] = SEBY.[Year] + 3 THEN (B.Total + B.Allowed) ELSE 0 END) AS P_Y4
			--,2012 AS P_Y4
      FROM ' + @TableC + ' AS A 
	  full OUTER JOIN ' + @TableP + ' AS B
        ON A.StateKey = B.StateKey
       AND A.ProviderKey = B.ProviderKey
       AND A.ProductKey = B.ProductKey
       AND A.PlaceOfServiceKey = B.PlaceOfServiceKey
       AND A.CustomerSegmentKey = B.CustomerSegmentKey
       AND A.InsuredTypeKey = B.InsuredTypeKey
       AND A.[Month] = B.[Month]
       AND A.[Year] = B.[Year]
                                 INNER JOIN (SELECT TSR.StateKey 
                                                    ,EBY.ExperienceBaseYear AS [Year]
                                              FROM dbo.TrendSubmissions AS TS INNER JOIN dbo.TrendSubmissionRun AS TSR
                                                ON TS.TrendSubmissionId = TSR.TrendSubmissionId
                                                                              INNER JOIN dbo.ExperienceBaseYear AS EBY
                                                ON TSR.ExperienceBaseYearId = EBY.ExperienceBaseYearId
                                              WHERE TS.TrendSubmissionId = ' + cast(@TSID as varchar) + ' ) AS SEBY
        ON A.StateKey = SEBY.StateKey 
     
	  group BY A.stateKey
              ,A.ProviderKey
              ,SEBY.Year) AS SQ INNER JOIN dbo.States AS S 
  ON SQ.StateKey = S.StateKey
                                    INNER JOIN dbo.vwCurrentProviders AS P
  ON SQ.ProviderKey = P.ProviderKey
ORDER BY S.StateName
        ,P.ProviderName
        ,P.ProviderId'

/*drop table tempBaseDataCompareTable*/

/*select * from tempBaseDataCompare*/

--------------------------------------------------------------------------------------------------------
EXECUTE sp_executesql @sql

--SET @sql = 'select * from ' + @tempBaseDataCompareTable

SET @sql = 'select * from ' + @tempBaseDataCompareTable
EXECUTE sp_executesql @sql
SELECT @sql



END
 
 
 
