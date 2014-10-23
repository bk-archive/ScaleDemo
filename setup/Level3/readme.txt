Pre-Requisites

1) Have an Azure Subscription
2) Install Azure Powershell


Getting Started

When using azure powershell the first thing you need to do is get your powershell environment ready to work with Azure.

To do this you will need to get your Azure Account and Subscription by running the following PS cmdlets:

	Setup Azure
	Add-AzureAccount

If you have more than one subscription you will neeed to use the Select Azure Subscription to specify what subscription to use. 

You can query for your subscription with Get-AzureSubscription cmdlet
	Get-AzureSubscription

Select your subscription by using the Select-AzureSubscription cmdlet
	Select-AzureSubscription

Once this is done execute the setup.ps1 script to provition your subscription with the artifacts for the scale demo.

The scaledemotemplate.json should be on the same directory.

To clean up all you need to do is delete the resourcegroup:

#Cleanup
	Remove-AzureResourceGroup -Name $RG_Name -Force