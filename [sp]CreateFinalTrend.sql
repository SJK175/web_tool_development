
/*
EXECUTE [dbo].[CreateFinalTrend]
@BKey='3',
@StateKey='49',
@AsOfDate='2016-01-01',
@BackYears=1,
@ForwardYears=4,
@OutputTable =Precursor_24CD95A1A7AC4B68AAB1DD7BC01CEC99
*/

ALTER PROCEDURE [dbo].[CreateFinalTrend](
@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears int
, @ForwardYears int
, @OutputTable nvarchar(200) 
)

AS
BEGIN

------
DECLARE @VarOutputTable varchar(250)
SET @VarOutputTable = @OutputTable

declare @VarIdentifier varchar(100)
set @VarIdentifier = substring(@VarOutputTable, charindex('_',@VarOutputTable)+1,len(@VarOutputTable)-10);

declare @VarTempPrecursor varchar(100)
set @VarTempPrecursor = 'FinalTrend_' + @VarIdentifier
-------
DECLARE @sql nvarchar (max)
SET @SQL=


'Select CustomerSegmentName as [Customer Segment]
,PlaceOfService as [Place Of Service]
,ProductName as [Product Name]
,MedicareId as [Medicare Id]
,ProviderName as [Provider Name]
,ProviderId as [Provider Id]
,StateName as [State]
,SystemName as [System]
,ProviderType as [Provider Type]
,[Year]
,[Month]
,[YearMonth]
,SUM(QHIPPortion) as QHIPPortion
,SUM(FixedPortion)    as FixedPortion
,SUM(ChargedPortion)  as ChargedPortion
,SUM(Total)            as Total
,SUM(Allowed)          as Allowed
,SUM(Base)             as Base
,SUM(Prev_Allowed) as Prev_Allowed
, SUM(Prev_Total)    as Prev_total
, SUM(Prev_QHIP)        as Prev_QHIP
, SUM(Prev_Fixed)           as Prev_Fixed
, sum(Prev_Charged) as Prev_Charged
 INTO ' + @VarTempPrecursor + 
 ' FROM ' + @VarOutputTable + ' as CE 
 left Join CustomerSegments as CS on CE.CustomerSegmentKey = CS.CustomerSegmentKey
 left Join PlaceOfServices as POS on CE.PlaceOfServiceKey = POS.PlaceOfServiceKey
 left Join Products as Pr on CE.ProductKey = Pr.ProductKey
 left Join vwCurrentProviders as P on CE.ProviderKey = P.ProviderKey
 left Join States as St on CE.StateKey = St.StateKey
 left Join Systems as S on P.SystemKey = S.SystemKey
 left Join ProviderTypes as PT on P.ProviderTypeKey = PT.ProviderTypeKey

Where P.ShowInOutput = 1
 and P.Active = 1
Group By CustomerSegmentName
,PlaceOfService
,ProductName
,MedicareId
,ProviderName
,ProviderId
,StateName
,SystemName
,ProviderType
,[Year]
,[Month]
,[YearMonth]'

select @sql
END
