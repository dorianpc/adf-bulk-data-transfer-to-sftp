



------------------------------------------------------
--create 3 stage tables and model after source
------------------------------------------------------
DROP TABLE IF EXISTS SalesLT.Customer_Stage; 
DROP TABLE IF EXISTS SalesLT.SalesOrder_Stage; 
DROP TABLE IF EXISTS SalesLT.ProductModel_Stage; 

SELECT * INTO SalesLT.Customer_Stage FROM SalesLT.Customer WHERE 1 = 2;
SELECT * INTO SalesLT.ProductModel_Stage FROM SalesLT.ProductModel WHERE 1 = 2;

SELECT
soh.*
,sod.SalesOrderDetailID
,sod.OrderQty
,sod.ProductID
,sod.UnitPrice
,sod.UnitPriceDiscount
,sod.LineTotal
INTO SalesLT.SalesOrder_Stage
from [SalesLT].[SalesOrderHeader] soh 
	join [SalesLT].[SalesOrderDetail] sod 
	on soh.SalesOrderID = sod.SalesOrderID
WHERE 1=2;
GO



------------------------------------------------------
--create 3 stored procedures
------------------------------------------------------
CREATE OR ALTER PROCEDURE SalesLT.uspLoadCustomers_Stage
AS   
    SET NOCOUNT ON;  
    TRUNCATE TABLE SalesLT.Customer_Stage;
    INSERT INTO SalesLT.Customer_Stage
    (  [NameStyle]
      ,[Title]
      ,[FirstName]
      ,[MiddleName]
      ,[LastName]
      ,[Suffix]
      ,[CompanyName]
      ,[SalesPerson]
      ,[EmailAddress]
      ,[Phone]
      ,[PasswordHash]
      ,[PasswordSalt]
      ,[rowguid]
      ,[ModifiedDate]
      )
    SELECT
       [NameStyle]
      ,[Title]
      ,[FirstName]
      ,[MiddleName]
      ,[LastName]
      ,[Suffix]
      ,[CompanyName]
      ,[SalesPerson]
      ,[EmailAddress]
      ,[Phone]
      ,[PasswordHash]
      ,[PasswordSalt]
      ,[rowguid]
      ,[ModifiedDate]
    FROM SalesLT.Customer; 
GO

CREATE OR ALTER PROCEDURE SalesLT.uspLoadSalesOrders_Stage
AS   
    SET NOCOUNT ON;  
    TRUNCATE TABLE SalesLT.SalesOrder_Stage;
		INSERT INTO SalesLT.SalesOrder_Stage
    SELECT
		soh.*
		,sod.SalesOrderDetailID
		,sod.OrderQty
		,sod.ProductID
		,sod.UnitPrice
		,sod.UnitPriceDiscount
		,sod.LineTotal
		from [SalesLT].[SalesOrderHeader] soh 
			join [SalesLT].[SalesOrderDetail] sod 
			on soh.SalesOrderID = sod.SalesOrderID; 
		GO

CREATE OR ALTER PROCEDURE SalesLT.uspLoadProductModels_Stage
AS   
    SET NOCOUNT ON;  
    TRUNCATE TABLE SalesLT.ProductModel_Stage;
    INSERT INTO SalesLT.ProductModel_Stage
    (
       [Name]
      ,[CatalogDescription]
      ,[rowguid]
      ,[ModifiedDate]
    )
    SELECT
       [Name]
      ,[CatalogDescription]
      ,[rowguid]
      ,[ModifiedDate]
    FROM SalesLT.ProductModel; 
GO


------------------------------------------------------
--create configuration table
------------------------------------------------------
DROP TABLE IF EXISTS SalesLT.OutboundFilesConfig; 
CREATE TABLE SalesLT.OutboundFilesConfig 
(
    ConfigID int IDENTITY,
    LoadStatus varchar(100) not null,
    RecordUpdateDate datetime not null,
    [FileName] varchar(500) not null,
    FileNamePostFixFormat varchar(50) not null,
    FileExtension varchar(50) not null,
    FileDelimeter varchar(10) not null,
    TextQualifier varchar(5)  null,
    [FTPPath] varchar(500) not null,
    FTPHost varchar(500) not null,
    FTPPort varchar(10) not null,
    FTPUser varchar(100) not null,
    FTPAzureVaultSecretName varchar(500),
    AuditQuery varchar(8000) not null,
    ExecutionQuery varchar(8000) not null,
		StageTableSchema varchar(100) not null,
    StageTableName varchar(200) not null,
    IncludeTriggerFile bit,
    IncludeCOTFile bit
);
GO

------------------------------------------------------
--create configuration view to pull pending records
------------------------------------------------------
CREATE OR ALTER VIEW [SalesLT].[vw_OutboundFilesConfig] AS  
SELECT * FROM [SalesLT].[OutboundFilesConfig]
WHERE CAST(RecordUpdateDate AS DATE) < CAST(getdate() AS DATE);
GO

------------------------------------------------------
--insert configuration records
------------------------------------------------------
INSERT INTO [SalesLT].[OutboundFilesConfig]
(LoadStatus
,RecordUpdateDate
,[FileName]
,FileNamePostFixFormat
,FileExtension
,FileDelimeter
,TextQualifier
,FTPPath
,FTPHost
,FTPPort
,FTPUser
,FTPAzureVaultSecretName
,AuditQuery
,ExecutionQuery
,StageTableSchema
,StageTableName
,IncludeTriggerFile
,IncludeCOTFile
)
SELECT 
'Complete'
,getdate() - 1
,'CUSTOMERS'
,'yyyyMMddHHmmss'
,'.csv'
,'|'
,'"'
,'/uploads'
,'sftpserverdemo1.blob.core.windows.net'
,'22'
,'sftpserverdemo1.azureuser'
,'sftpserverdemosecret1'
,'Select 1'
,'exec SalesLT.uspLoadCustomers_Stage'
,'SalesLT'
,'Customer_Stage'
,1
,1;


INSERT INTO [SalesLT].[OutboundFilesConfig]
(LoadStatus
,RecordUpdateDate
,[FileName]
,FileNamePostFixFormat
,FileExtension
,FileDelimeter
,TextQualifier
,FTPPath
,FTPHost
,FTPPort
,FTPUser
,FTPAzureVaultSecretName
,AuditQuery
,ExecutionQuery
,StageTableSchema
,StageTableName
,IncludeTriggerFile
,IncludeCOTFile
)
SELECT 
'Complete'
,getdate() - 1
,'PRODUCT_MODELS'
,'yyyyMMddHHmmss'
,'.txt'
,'|'
,null
,'/uploads'
,'sftpserverdemo2.blob.core.windows.net'
,'22'
,'sftpserverdemo2.azureuser'
,'sftpserverdemosecret2'
,'Select 1'
,'exec SalesLT.uspLoadProductModels_Stage'
,'SalesLT'
,'ProductModel_Stage'
,1
,1;


INSERT INTO [SalesLT].[OutboundFilesConfig]
(LoadStatus
,RecordUpdateDate
,[FileName]
,FileNamePostFixFormat
,FileExtension
,FileDelimeter
,TextQualifier
,FTPPath
,FTPHost
,FTPPort
,FTPUser
,FTPAzureVaultSecretName
,AuditQuery
,ExecutionQuery
,StageTableSchema
,StageTableName
,IncludeTriggerFile
,IncludeCOTFile
)
SELECT 
'Complete'
,getdate() - 1
,'SALES_ORDER'
,'MMddyyyy'
,'.dat'
,','
,'"'
,'/uploads'
,'sftpserverdemo3.blob.core.windows.net'
,'22'
,'sftpserverdemo3.azureuser'
,'sftpserverdemosecret3'
,'Select 1'
,'exec SalesLT.uspLoadSalesOrders_Stage'
,'SalesLT'
,'SalesOrder_Stage'
,0
,0;
GO