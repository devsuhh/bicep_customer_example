#This script deploys the bicep file and the parameter file with conditional checks to see if resources exist.


#----------------------------------------FILE SELECTION----------------------------------------#
#Originally, a GUI file selection was used, but it was removed due to the Powershell 7 and Powershell 5 compatibility issues.
#This file should work on PowerShell 5 and 7.

# Get the path of the script
#$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$scriptPath = $pwd

#The commands below list all JSON files in the script directory, allow the user to select the parameter file
$jsonFiles = Get-ChildItem -Path $scriptPath -Filter "*.json"
Write-Host "JSON Parameters files have been listed below with their corresponding index number:"
for ($i = 0; $i -lt $jsonFiles.Count; $i++) {
    Write-Host "[$i] $($jsonFiles[$i].Name)"
}
$selectedJsonIndex = Read-Host "Enter the index of the JSON file you want to select"
$templateParameterFilePath = $jsonFiles[$selectedJsonIndex].FullName

#The commands below list all BICEP files in the script directory, allow the user to select the bicep file
$bicepFiles = Get-ChildItem -Path $scriptPath -Filter "*.bicep"
Write-Host "BICEP files have been listed below with their corresponding index number:"
for ($i = 0; $i -lt $bicepFiles.Count; $i++) {
    Write-Host "[$i] $($bicepFiles[$i].Name)"
}
$selectedBicepIndex = Read-Host "Enter the index of the BICEP file you want to select"
$BicepFilePath = $bicepFiles[$selectedBicepIndex].FullName


#----------------------------------------RESOURCE SYNTHESIS----------------------------------------#
#Originally, the script ran to capture -Whatif from New-AZSubscriptionDeployment, but it was removed due to not being able to capture the output.
#The script also used capture -Whatif from az deployment sub create, but it was removed due to being unreliable.
#The script now references the JSON deployment file, extracts their values, and uses them to determine if resources exist.

$deployment_json = Get-Content $templateParameterFilePath -Raw | ConvertFrom-Json

$customer = $deployment_json.parameters.customerName.value
$subnetPrefix = $deployment_json.parameters.customerSubnetAddressPrefix.value
#$privateIPAddress = $deployment_json.parameters.privateIPAddress.value


$resourceGroup_computed_value = "rg-$customer"
$subnet_computed_value = "subnet-$customer"
$datafactory_computed_value = "adf-$customer"
$privateEndpointName_computed_value = "pe-$customer"
$privateEndpointInterfaceName_computed_value = "pi-$customer"
$sql_computed_value = "sql-$customer"

$resoureGroup_shared = 'rg-shared-prod'
$virtualNetwork_shared = 'vnet-shared-prod-eus2'

#Resources are put into an array of objects

$resourceArray = @(
    [PSCustomObject]@{
        Name = "Resource Group"
        Value = $resourceGroup_computed_value
        Status = "Not Yet Determined"
    },
    [PSCustomObject]@{
        Name = "Subnet"
        Value = $subnet_computed_value
        Status = "Not Yet Determined"
    },
    [PSCustomObject]@{
        Name = "Data Factory"
        Value = $datafactory_computed_value
        Status = "Not Yet Determined"
    },
    [PSCustomObject]@{
        Name = "SQL"
        Value = $sql_computed_value
        Status = "Not Yet Determined"
    },
    [PSCustomObject]@{
        Name = "Private Endpoint"
        Value = $privateEndpointName_computed_value
        Status = "Not Yet Determined"
    },
    [PSCustomObject]@{
        Name = "Subnet Prefix"
        Value = $subnetPrefix
        Status = "Not Yet Determined"
    }
)

#----------------------------------------RESOURCE CHECKING and LOGIN----------------------------------------#
#AZ CLI was originally used to login, but it was removed due to not being able to switch to the correct subscription.

#Import Modules
Import-Module Az.Accounts
Import-Module Az.Network

#Login Sessions (AZ CLI - NOT USED)
#az login --tenant "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" --output none
#az account set --subscription "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
#Write-Host "Succesfully Logged In!" -ForegroundColor Green
#Start-Sleep -Seconds 1.5

#Loign Sessions (Powershell Command)
Connect-AzAccount -Tenant "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" -Subscription "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Loop through each resource in the array and update its status based on whether it is available in Azure or not
Write-Host "Checking if resources are available in Azure..." -ForegroundColor Yellow
Start-Sleep -Seconds 1.5

foreach ($resource in $resourceArray) {
    $resourceAvailable = $false

    # Check if resource is available in Azure
    switch ($resource.Name) {
        "Resource Group" {
            $resourceAvailable = -not (Get-AzResourceGroup -Name $resource.Value -ErrorAction SilentlyContinue)
        }
        "Subnet Resource Group" {
            $resourceAvailable = -not (Get-AzResourceGroup -Name $resource.Value -ErrorAction SilentlyContinue)
        }
        "Subnet" {
            $vnet = $null
            $vnet = Get-AzVirtualNetwork -Name $virtualNetwork_shared 
            $resourceAvailable = -not ($vnet.Subnets.Name -contains $resource.Value)
        }
        "Data Factory" {
            $factories = $null
            $factories = Get-AzResource -ResourceType "Microsoft.DataFactory/factories"
            $resourceAvailable = -not ($factories.Name -contains $resource.Value )
        }
          
        "SQL" {
            $resourceAvailable = -not (Get-AzSqlServer -ServerName $resource.Value -ErrorAction SilentlyContinue) 
        }
        "Private Endpoint" {
            $resourceAvailable = -not (Get-AzPrivateEndpoint -Name $resource.Value -ErrorAction SilentlyContinue)
        }
        "Subnet Prefix" {
            $vnet = $null
            $vnet = Get-AzVirtualNetwork -Name $virtualNetwork_shared
            $resourceAvailable = -not ($vnet.Subnets.AddressPrefix -contains $resource.Value)
        }
        "Private Endpoint IP" {
            $ips = $null
            $ips = Get-AzNetworkInterface | Select-Object -ExpandProperty IpConfigurations 
            $ips.PrivateIPAddress
            $resourceAvailable = -not ($ips.PrivateIPAddress -contains $resource.Value)
        }
        default {
        }
    }

    # Update status based on whether resource is available or not
    if ($resourceAvailable) {
        $resource.Status = "Available for Use"
    }
    else {
        $resource.Status = "Currently in Use"
    }
}


# Output the updated array of objects
$resourceArray | Out-Host #Out-Host is used to display the array in the console immediately instead of waiting for the script to finish

Start-Sleep -Seconds 3
if ($resourceArray -match "Currently in Use") {
    Write-Host "The script has stopped because resource names (or values) are already in use!" -ForegroundColor Yellow
    Write-Host "Please change the names (or values) and run the script again." -ForegroundColor Red
    return  #Prevents array from being displayed again
}

# Prompt the user to continue
Write-Host "Values are available for use!" -ForegroundColor Green
Start-Sleep -Seconds 1.5
$continue = Read-Host "Would you like to continue with the deployment? (Y/N)" 

# Check if the user wants to continue
if ($continue -ne "Y" -and $continue -ne "y") {
    Write-Host "Script execution has been cancelled."
    return
}


#----------------------------------------RESOURCE DEPLOYMENT----------------------------------------#

#The command below deploys the resources to the subscription
Write-Host "Deploying resources to the subscription..." -ForegroundColor Yellow
az deployment sub create --template-file $BicepFilePath --parameters $templateParameterFilePath  --location eastus2

Write-Host "The resources have been deployed to the subscription" -ForegroundColor Green