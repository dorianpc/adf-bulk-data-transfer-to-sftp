# Azure Data Factory Pipeline - Multiple data files are created based on different configurations and sent to multiple SFTP destinations.

This is a simple prototype that can be improved further that uses configurations to run multiples data flows .

## Description
The ADF pipeline reads a table with configuration records and builds customized data files that are sent to multiple SFTP destinations.

Each configuration record stores information like the status, file format, delimeter, SFTP destination details, execution query, etc.

The SFTP login credentials are also stored in Azure Data Vault for extra security and just the secret name is exposed in the config record.

The pipeline also sends COT and TRG files if needed.

<p align="left">
  <img src="https://github.com/dorianpc/adf-data-to-multiple-sftps/assets/15469007/73d1903d-55a7-4c62-83e2-1be2923c9a1f" width="500">
  <img src="https://github.com/dorianpc/adf-data-to-multiple-sftps/assets/15469007/8d953bbe-a125-4e5e-a6ad-9ab3e485c98f" width="500">
</p>


## Deployment

```powershell
.\deployment\azure-deploy.ps1
```
The script deploys the following Azure resources.
1. Resource Group
2. 1 Storage Account & Container
3. 3 Storage Accounts configured for SFTP (to mimic external SFTP servers)
4. Azure Key Vault
5. Stores 3 SFTP Credentials in Azure Key Vault
6. SQL Server and Azure Database with AdventureWorksLT sample db
7. Execute SQL Scripts to create tables, config records, and stored procedures
8. Azure Data Factory

