
/*
EXECUTE [dbo].[CreateTempPrecursor]
@BKey='3',
@StateKey='49',
@AsOfDate='2016-01-01',
@BackYears=1,
@ForwardYears=4,
@InputTable =BaseData_864D84BBBC8B44B5870614C485BE4CC8,
@OutputTable_P =output
*/
-----------------------------------------------


ALTER PROCEDURE [dbo].[CreateTempPrecursor](
@BKey varchar(12)
, @stateKey varchar(max)
, @AsOfDate date
, @BackYears int
, @ForwardYears int
, @InputTable nvarchar(200) 
, @OutputTable_P nvarchar(200) output
)

AS
BEGIN TRY

SET NOCOUNT ON	 

DECLARE @VarErrorMessage varchar(max)

DECLARE @VarInputTable varchar(250)
SET @VarInputTable = @InputTable

declare @VarIdentifier varchar(100)
set @VarIdentifier = substring(@VarInputTable, charindex('_',@VarInputTable)+1,len(@VarInputTable)-9);

declare @VarTempPrecursor varchar(100)
set @VarTempPrecursor = 'Precursor_' + @VarIdentifier

Set @OutputTable_P=@VarTempPrecursor



--if object_id('tempdb..#temp_Precursor') is NOT null drop TABLE #temp_Precursor;



--CREATE Index idx_Provider ON {FROM_TABLE} (ProviderKey)  
/*
SET @sql = 'CREATE Index idx_Provider ON ' + @VarOutputTable (ProviderKey) 
exec sp_executesql @sql 
*/

     
DECLARE @sql nvarchar (max)              
SET @sql = 'SELECT A_Current.StateKey
      ,A_Current.ProviderKey
      ,A_Current.ProductKey
      ,A_Current.PlaceOfServiceKey
      ,A_Current.CustomerSegmentKey
      ,A_Current.InsuredTypeKey
      ,A_Current.HIX
      ,A_Current.[Year]
      ,A_Current.[Month]
      ,cast(A_Current.[Year] AS varchar(4)) + 
       CASE WHEN A_Current.[Month] < 10 THEN ''-0'' ELSE ''-'' END +
       cast(A_Current.[Month] AS varchar(2)) AS YearMonth
      ,A_Current.QHIPPortion
      ,A_Current.FixedPortion
      ,A_Current.ChargedPortion
      ,A_Current.Total
      ,A_Current.Allowed
      ,A_Current.Base
      ,A_Current.Closed 
      ,B_Previous.Allowed           AS Prev_Allowed
      ,B_Previous.Total             AS Prev_Total
      ,B_Previous.QHIPPortion       AS Prev_QHIP
      ,B_Previous.FixedPortion      AS Prev_Fixed
      ,B_Previous.ChargedPortion    AS Prev_Charged
	  ,A_Current.Allowed-B_Previous.Allowed AS Difference
	  ,CASE WHEN B_Previous.Allowed=0 THEN NULL ELSE (A_Current.Allowed-B_Previous.Allowed)/B_Previous.Allowed END AS Percent_Difference
INTO ' + @VarTempPrecursor + '
FROM ' + @VarInputTable + ' AS A_Current INNER JOIN ' + @VarInputTable + ' AS B_Previous
  ON A_Current.StateKey            = B_Previous.StateKey          
 AND A_Current.ProviderKey         = B_Previous.ProviderKey
 AND A_Current.ProductKey          = B_Previous.ProductKey
 AND A_Current.PlaceOfServiceKey   = B_Previous.PlaceOfServiceKey
 AND A_Current.CustomerSegmentKey  = B_Previous.CustomerSegmentKey
 AND A_Current.InsuredTypeKey      = B_Previous.InsuredTypeKey
 AND A_Current.HIX                 = B_Previous.HIX
 AND A_Current.[Year]              = B_Previous.[Year] + 1
 AND A_Current.[Month]             = B_Previous.[Month]'
 
EXEC sp_executesql @sql 


/*********************
To show the result..
**********************/
/*
SET @sql = N'select * from ' + @VarTempPrecursor
EXEC sp_executesql @sql 
*/

SET NOCOUNT ON	 
END TRY	

BEGIN CATCH

IF @@ERROR <> 0 
    BEGIN
    -- Return 99 to the calling program to indicate failure.
	SET @VarErrorMessage  = 'An error on retreiving CreateTempPrecursor.'
	EXEC dbo.InsertErrorLog
	EXEC dbo.InsertMessageLog @VarErrorMessage
	RETURN 99;
    END

END CATCH

SET NOCOUNT OFF
GO

