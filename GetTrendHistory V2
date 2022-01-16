

CREATE PROCEDURE [dbo].[GetTrendHistoryV2]
@ChangeKey bigint
AS
BEGIN TRY
---------------------------------------
DECLARE @VarErrorMessage varchar(max)
DECLARE @VarChangeKey bigint;
SET @VarChangeKey = @ChangeKey;
---------------------------------------
SELECT
ch.ChangeHistoryKey as HistoryKey
,dt.DateDate as ChangeDate
,pgn.ProductGroupName as Product
--,posgn.PlaceOfServiceGroupName as PlaceOfService
,posgn.PlaceOfServiceGroupName+'-'+vsge.ServiceGroupName as CombinedServiceName
,ch.QHIPValue
,ch.QHIPRatio
,ch.FixedValue
,ch.FixedRatio
,ch.ChargedValue
,ch.ChargedRatio
,ch.Closed
,ch.Deleted
,ect.ChangeTypeName as [Type]
,ch.DateTimeChanged as [DateTime]
--,u.FirstName+' '+u.LastName as [User]
,NULL as [user]
,ch.Notes
FROM dbo.ChangeHistory as ch
Left Join dbo.ProductGroupNames as pgn
ON ch.ProductGroupNameKey=pgn.ProductGroupNameKey
Left Join dbo.PlaceOfServiceGroupNames as posgn
ON ch.PlaceOfServiceGroupNameKey=posgn.PlaceOfServiceGroupNameKey
LEFT JOIN dbo.vwServiceGroupExpanded vsge
ON posgn.PlaceOfServiceGroupNameKey = vsge.PlaceOfServiceGroupNameKey
Left join eHaus_ChangeTypes as ect
ON ch.ChangeTypeKey=ect.ChangeTypekey
Left Join users as u
ON ch.UserKey=u.UserKey
Left Join Dates as dt
ON ch.ChangeDateKey=dt.DateKey
	
WHERE ch.ChangeKey = @VarChangeKey;
--END
END TRY

BEGIN CATCH
IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error occured on retreiving records for the given ChangeKey. @ChangeKey=' + @VarChangeKey	
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END

END CATCH
