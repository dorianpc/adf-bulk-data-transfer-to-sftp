

param (
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential,
    [Parameter(Mandatory = $true)]
    [string]$MyIPAddress  
)


#------------------------------------------------------  
# set variables
#------------------------------------------------------  
$randomId = (Get-Random -Maximum 1000)
$rg = "rg-demo-" + $randomId
$location = "eastus"
$storageName = "sftpserverdemo"
$sftpUsername = $Credential.UserName

$sqlServerName = "azuresql-server-" + $randomId
$databaseName = "azuresqldb" + $randomId
$myIP = $MyIPAddress
$sqlUsername = $Credential.UserName
$sqlSecurePassword = $Credential.Password

$storageccountName = "azurestoragestage" + $randomId
$containerName1 = "stage"
$containerName2 = "logs"
$dataFactoryName = "azuredatafactory-" + $randomId

$keyVaultName = "azurevault" + $randomId
$secretName1 = "sftpserverdemosecret1"
$secretName2 = "sftpserverdemosecret2"
$secretName3 = "sftpserverdemosecret3"
$secretName4 = "azurestoragestage" + $randomId + "secret"


#------------------------------------------------------  
# create resource group
#------------------------------------------------------  
New-AzResourceGroup -Name $rg -Location $location -Force


#-------------------------------------------------------------------
# create basic blob storage account and container for stage and logs
#-------------------------------------------------------------------
New-AzStorageAccount `
    -ResourceGroupName $rg `
    -Name $storageccountName `
    -Location $location `
    -SkuName "Standard_LRS" `
    -Kind "StorageV2"

$ctx = New-AzStorageContext -StorageAccountName $storageccountName -UseConnectedAccount 
New-AzStorageContainer -Name $containerName1 -Context $ctx
New-AzStorageContainer -Name $containerName2 -Context $ctx


#------------------------------------------------------  
# deploy 3 sftp storage accounts
#------------------------------------------------------  
New-AzResourceGroupDeployment `
    -Name "sftp-deployment" `
    -ResourceGroupName $rg `
    -TemplateFile ".\deploy-sftp-storage.json" `
    -storageAccountName $storageName `
    -sftpUser $sftpUsername


#------------------------------------------------------  
# store credentials for the ftp servers
#------------------------------------------------------
$ftpservers = @()

for ($i = 1; $i -le $(Get-AzStorageAccount -ResourceGroupName $rg | Where-Object { $_.StorageAccountName -match 'sftpserverdemo' }).Count; $i++) {
    $ftpserver = @{
        "host"     = $(Get-AzStorageAccount -ResourceGroupName $rg -Name $storageName$i).PrimaryEndpoints.Blob.Substring(8).Replace('/', '')
        "user"     = $(Get-AzStorageLocalUser -ResourceGroupName $rg -StorageAccountName $storageName$i).Name  
        "password" = $(New-AzStorageLocalUserSshPassword -ResourceGroupName $rg -StorageAccountName $storageName$i -UserName $sftpUsername).SshPassword 
    }

    $ftpservers += $ftpserver
}


#-------------------------------------------------------------------------------
# create key vault and store 3 sftp server passwords and 1 storage account secret 
#-------------------------------------------------------------------------------
New-AzKeyVault -Name $keyVaultName -ResourceGroupName $rg -Location $location

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName1 -SecretValue $(ConvertTo-SecureString -String $ftpservers[0].password -AsPlainText -Force)
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName2 -SecretValue $(ConvertTo-SecureString -String $ftpservers[1].password -AsPlainText -Force)
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName3 -SecretValue $(ConvertTo-SecureString -String $ftpservers[2].password -AsPlainText -Force)

$storageAccountSecret = $(Get-AzStorageAccountKey -ResourceGroupName $rg -Name $storageccountName)[0].Value
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName4 -SecretValue $(ConvertTo-SecureString -String $storageAccountSecret -AsPlainText -Force)


#---------------------------------------------------------------
# deploy sql server and database with AdventureWorksLT sample db
#---------------------------------------------------------------
New-AzResourceGroupDeployment `
    -Name "sql-deployment" `
    -ResourceGroupName $rg `
    -TemplateFile ".\deploy-sqldb.json" `
    -serverName $sqlServerName `
    -sqlDBName $databaseName `
    -administratorLogin $sqlUsername `
    -administratorLoginPassword $sqlSecurePassword `
    -allowedIP $myIP


#------------------------------------------------------------
# install SQl Server module if needed and execute sql scripts
#------------------------------------------------------------
if (-not (Get-Module -Name SqlServer -ListAvailable)) {
    Install-Module -Name SqlServer -Force
}

# Read the content of the SQL script
$sqlScript = Get-Content -Path ".\sql\setup_script.sql" -Raw

# wait a little bit in case sql server is in the process of deployment
Start-Sleep -Seconds 30

# execute the SQL script
Invoke-Sqlcmd `
    -ServerInstance $("$sqlServerName.database.windows.net") `
    -Database $databaseName `
    -Username $sqlUsername `
    -Password $(ConvertFrom-SecureString -SecureString $sqlSecurePassword -AsPlainText) `
    -Query $sqlScript


#------------------------------------------------------  
# create data factory
#------------------------------------------------------ 
Set-AzDataFactoryV2 `
    -ResourceGroupName $rg `
    -Location $location `
    -Name $dataFactoryName

