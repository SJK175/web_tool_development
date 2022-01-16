

/****** Object:  StoredProcedure [dbo].[GetTrendDataBykeyV2]    Script Date: 10-17-2016 09:50:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetTrendDataBykeyV2]
/********************************************
--Optional parameters--
********************************************/
-- @PlaceOfServiceKey varchar(max) =null 
@ServiceGroupNameKey varchar(max) = null
,@ProductGroupNameKey varchar(max) =null
,@SystemKey varchar(max) =null
,@ContractorKey varchar(max) =null
,@ProviderKey varchar(max) =null
,@Signed varchar(max) =null
,@Show varchar(max) =null
/*******************************************
--Mandatory parameters--
*******************************************/
,@StateKey varchar(50)
,@AsOfDate datetime      
,@StartDate datetime    
,@EndDate datetime
,@ProviderCategoryKey int
,@LineOfBisunessKey int
     

AS BEGIN TRY
SET NOCOUNT ON;
/*****************************************************************************
 --DECLARING VARIABLES--
*****************************************************************************/
DECLARE @VarErrorMessage varchar(max)

/*OPTIONAL:Handling 'no value' for input parameters*/

/*
DECLARE @VarPlaceOfService varchar(max);
IF LEN(@PlaceOfServiceKey) = 0 
SET @VarPlaceOfService = NULL;
ELSE SET @VarPlaceOfService = @PlaceOfServiceKey;
*/

DECLARE @VarServiceGroupNameKey varchar(max);
IF LEN(@ServiceGroupNameKey) = 0 
SET @VarServiceGroupNameKey = NULL;
ELSE SET @VarServiceGroupNameKey = @ServiceGroupNameKey;


DECLARE @VarProductGroupNameKey varchar(max);
IF LEN(@ProductGroupNameKey) = 0
SET @VarProductGroupNameKey = NULL;
ELSE SET @VarProductGroupNameKey=@ProductGroupNameKey;

DECLARE @VarSystemKey varchar(max);
IF LEN(@SystemKey) = 0
SET @VarSystemKey = NULL;
ELSE SET @VarSystemKey=@SystemKey;

DECLARE @VarContractorKey varchar(max);
IF LEN(@ContractorKey) = 0
SET @VarContractorKey = NULL;
ELSE SET @VarContractorKey=@ContractorKey;

DECLARE @VarProviderKey varchar(max);
IF LEN(@ProviderKey) = 0
SET @VarProviderKey = NULL;
ELSE SET @VarProviderKey=@ProviderKey;

DECLARE @VarSigned varchar(max);
IF LEN(@Signed) = 0
SET @VarSigned = NULL;
ELSE SET @VarSigned=@Signed;

DECLARE @VarShow varchar(max);
IF LEN(@Show) = 0
SET @VarShow = NULL;
ELSE SET @VarShow=@Show;

/********MANDATORY********/
DECLARE @VarState varchar(50);
SET @VarState=@StateKey;
DECLARE @VarAsOfDate datetime;
SET @VarAsOfDate=@AsOfDate;
DECLARE @VarStartDate datetime;   
SET @VarStartDate=@StartDate
DECLARE @VarEndDate datetime;
SET @VarEndDate=@EndDate;
DECLARE @VarProvidercategoryKey int
SET @VarProvidercategoryKey=@ProvidercategoryKey
DECLARE @VarLineOfBisunessKey int
SET @VarLineOfBisunessKey=@LineOfBisunessKey

/****************************
        --Query--
****************************/
SELECT 
 ch.changekey
--,concat(ph.ProviderName,'-',ph.ProviderKey) as Provider
,ph.ProviderName as Provider
,pgn.ProductGroupName as ProductGroup
,posgn.PlaceOfServiceGroupName
,vsge.ServiceGroupName
,posgn.PlaceOfServiceGroupName+'-'+vsge.ServiceGroupName CombinedServiceName
,dt.DateDate as ChangeDate
,ch.QHIPValue
,ch.QHIPRatio
,ch.FixedValue
,ch.FixedRatio
,ch.ChargedValue
,ch.ChargedRatio
,CASE WHEN ch.Closed=0 THEN 'No' ELSE 'Yes' END AS Signed
,CASE WHEN ch.Deleted=0 THEN 'No' ELSE 'Yes' END AS Deleted
/******************************************************************************
 following coulmns are not needed to show in trend grid.
 Thet are given just to populate data in filter.
******************************************************************************/
,syst.SystemName
,syst.SystemKey
,con.ContractorName
,con.ContractorKey
,ph.ProviderKey
,posgn.PlaceOfServiceGroupNameKey
,vsge.ServiceGroupNameKey
,cast(posgn.PlaceOfServiceGroupNameKey as varchar(20))+'|'+cast(vsge.ServiceGroupNameKey as varchar(20)) AS CombinedServiceNameKey
,pgn.ProductGroupNameKey
,provctg.ProviderCategoryKey
,provctg.ProviderCategoryName
,LOB.LineOfBusinessKey
,LOB.LineOfBusinessName

FROM dbo.changehistory as ch
Inner Join (select distinct ProviderKey, ProviderName from dbo.ProviderHistory) as ph
ON ch.ProviderKey =ph.ProviderKey
Inner Join dbo.Changes as cg
ON ch.ChangeKey=cg.ChangeKey 
AND ch.ChangeHistoryKey=cg.MaxChangeHistoryKey
Left Join dbo.LineOfBusiness as LOB
ON cg.LineOfBusinessKey=LOB.LineOfBusinessKey 
Left Join dbo.ProductGroupNames as pgn
ON ch.ProductGroupNameKey=pgn.ProductGroupNameKey
Left Join dbo.ProductGroups as pg
ON ch.ProductGroupNameKey = pg.ProductGroupNameKey
Left Join Products as p
ON pg.ProductKey = p.ProductKey
Left Join dbo.PlaceOfServiceGroupNames as posgn
ON ch.PlaceOfServiceGroupNameKey=posgn.PlaceOfServiceGroupNameKey
Left Join dbo.PlaceOfServiceGroups as posg
ON ch.PlaceOfServiceGroupNameKey=posg.PlaceOfServiceGroupNameKey
Left Join dbo.PlaceOfServices as pos
ON posg.PlaceOfServiceKey=pos.PlaceOfServiceKey
LEFT JOIN dbo.vwServiceGroupExpanded vsge
ON posg.PlaceOfServiceGroupNameKey = vsge.PlaceOfServiceGroupNameKey	
AND posg.PlaceOfServiceKey = vsge.PlaceOfServiceKey
Left Join dbo.ProviderHistory as phis
ON ch.ProviderKey =phis.ProviderKey
Left Join dbo.Systems as syst
ON phis.SystemKey=syst.SystemKey
Left Join (select FirstName+' '+Lastname as ContractorName,ContractorKey from Contractors) as con
ON phis.ContractorKey=con.ContractorKey
Left Join States as St
ON phis.PhysicalStateKey=St.StateKey
Left Join Dates as dt
ON ch.ChangeDateKey=dt.DateKey
Left Join Providers as prov
ON ch.ProviderKey=prov.ProviderKey
Left Join ProviderCategories as provctg
ON provctg.ProviderCategoryKey=prov.ProviderCategoryKey

/*************************************************************************************************************************************
 --Handling Multiple Parameter value for Optional Parameters--
*************************************************************************************************************************************/
INNER JOIN  dbo.SplitVariable(@VarServiceGroupNameKey, ',') as a ON vsge.ServiceGroupNameKey = a.Value OR @VarServiceGroupNameKey IS NULL	
INNER JOIN	dbo.SplitVariable(@VarProductgroupNameKey,',') as b ON pgn.ProductGroupNameKey = b.Value OR @ProductGroupNameKey IS NULL	
INNER JOIN	dbo.SplitVariable(@VarSystemKey,',') as c ON syst.SystemKey = c.Value OR @SystemKey IS NULL
INNER JOIN	dbo.SplitVariable(@VarContractorKey,',') as d ON con.ContractorKey = d.Value OR @ContractorKey IS NULL
INNER JOIN	dbo.SplitVariable(@VarProviderKey,',') as e ON ph.ProviderKey = e.Value OR @Providerkey IS NULL
INNER JOIN	dbo.SplitVariable(@VarSigned,',') as f ON ch.Closed = cast(f.Value as int) OR @VarSigned IS NULL
INNER JOIN	dbo.SplitVariable(@VarShow,',') as g ON ch.Deleted = cast(g.Value as int) OR @VarShow IS NULL

/*************************************************************************************************
 --Passing Mandatory Parameters--
*************************************************************************************************/
WHERE
prov.ProviderCategoryKey=@VarProvidercategoryKey
AND st.StateKey=@VarState
AND LOB.LineOfBusinessKey=@VarLineOfBisunessKey
--AND ch.Closed=@VarSigned
--AND ch.Deleted=@VarShow

/***************
 --DATES--
***************/ 
AND dt.DateDate <= cast(@VarAsOfDate as date)
AND cast(ch.DateTimeChanged as date)>=cast(@VarStartDate as date) 
AND cast(ch.DateTimeChanged as date)<=cast(@VarEndDate as date)

SET NOCOUNT OFF;
END TRY


BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving records for Trends..'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END

END CATCH



