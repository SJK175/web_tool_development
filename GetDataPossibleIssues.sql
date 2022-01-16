
/*
EXECUTE [dbo].[GetDataPossibleIssues]
@BKey='1',
@StateKey='49',
@AsOfDate='2015-12-31',
@BackYears=1
*/

CREATE PROCEDURE [dbo].[GetDataPossibleIssues]
(
  @BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears int
)
AS
BEGIN

SELECT S.StateName
       ,P.ProviderName + '-' + P.ProviderId AS ProviderName
       ,Pr.ProductName
       ,POS.PlaceOfService
       ,BD.DateYear
       ,CASE
          WHEN (isnull(CS.QHIP,0) + isnull(CS.Fixed,0) + isnull(CS.Charged,0) = 0) THEN 'No Records'
          WHEN CS.QHIP > 1                                                         THEN 'Multiple QHIP'
          WHEN CS.Fixed > 1                                                        THEN 'Multiple Fixed'
          WHEN CS.Charged > 1                                                      THEN 'Multiple Charged'
          ELSE ''
        END              AS Reason
       ,1                AS Freq
 FROM (SELECT S.StateKey
             ,P.ProviderKey
             ,Pr.ProductKey
             ,POS.PlaceOfServiceKey
             ,DD.DateYear
       FROM dbo.States AS S INNER JOIN dbo.vwCurrentProviders AS P
         ON S.StateKey = P.StateKey
        AND P.Active = 1
        AND P.ProviderCategoryKey = 1
                           INNER JOIN dbo.Products AS Pr 
         ON S.StateKey = Pr.StateKey
                           INNER JOIN dbo.PlaceOfServices AS POS
         ON POS.PlaceOfServiceKey <> 0
                           INNER JOIN (SELECT Distinct D.DateYear
                                       FROM dbo.Dates AS D) AS DD
         ON DD.DateYear between S.eHausBaseYear AND S.eHausBaseYear + 4
		 INNER JOIN	dbo.SplitVariable(@stateKey,',') as e ON S.StateKey = e.Value OR @stateKey IS NULL
       -- WHERE S.StateKey IN ({STATEKEYS})
         AND Pr.Active = 1
         AND P.Active = 1
         AND P.ShowInOutput = 1) AS BD LEFT OUTER JOIN (SELECT Statekey
                                                              ,ProviderKey
                                                              ,ProductKey
                                                              ,PlaceOfServiceKey
                                                              ,D.DateYear
                                                              ,sum(CASE WHEN QHIPValue * QHIPRatio = 0 THEN 0 ELSE 1 END)    AS QHIP
                                                              ,sum(CASE WHEN FixedValue * FixedRatio = 0 THEN 0 ELSE 1 END)   AS Fixed
                                                              ,sum(CASE WHEN ChargedValue * ChargedRatio = 0 THEN 0 ELSE 1 END) AS Charged
                                                        FROM dbo.ChangesExpanded (@BKey,@stateKey,@AsOfDate,@BackYears) AS CE INNER JOIN dbo.Dates AS D
                                                          ON CE.ChangeDateKey = D.DateKey
														  INNER JOIN dbo.SplitVariable(@stateKey,',') as e ON CE.StateKey = e.Value OR @stateKey IS NULL
                                                        -- WHERE statekey IN ({STATEKEYS})
                                                        Group BY Statekey
                                                                ,ProviderKey
                                                                ,ProductKey
                                                                ,PlaceOfServiceKey
                                                                ,D.DateYear) AS CS
   ON BD.StateKey          = CS.StateKey
  AND BD.ProviderKey       = CS.ProviderKey
  AND BD.ProductKey        = CS.ProductKey
  AND BD.PlaceOfServiceKey = CS.PlaceOfServiceKey
  AND BD.DateYear          = CS.DateYear
                            INNER JOIN dbo.States AS S
   ON BD.StateKey = S.StateKey
                            INNER JOIN dbo.vwCurrentProviders AS P
   ON BD.ProviderKey = P.ProviderKey
                            INNER JOIN dbo.Products AS Pr
   ON BD.ProductKey = Pr.ProductKey
                            INNER JOIN dbo.PlaceOfServices AS POS
   ON BD.PlaceOfServiceKey = POS.PlaceOfServiceKey
 WHERE (isnull(CS.QHIP,0) + isnull(CS.Fixed,0) + isnull(CS.Charged,0) = 0)
   or CS.QHIP > 1
   or CS.Fixed > 1
   or CS.Charged > 1

   END
