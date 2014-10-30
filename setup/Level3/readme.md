#Pre-Requisites

<ol>
    <li>Have an Azure Subscription https://portal.azure.com/ </li>
    <li>Install Azure Powershell http://azure.microsoft.com/en-us/documentation/articles/install-configure-powershell/ </li>
</ol>

***
#Getting Started
When using azure PowerShell the first thing you need to do is get your PowerShell environment ready to work with Azure.

To do this you will need to get your Azure Account and Subscription by running the following PS cmdlets:
**<blockquote>Add-AzureAccount</blockquote>**
Add-AzureAccount will prompt you to log-in to assure.

After Loging in, if you have more than one subscription you will need to use the Select Azure Subscription to specify what subscription to use.

You can query for your subscription with Get-AzureSubscription cmdlet
	**<blockquote>Get-AzureSubscription</blockquote>**

Select your subscription by using the Select-AzureSubscription cmdlet
	**<blockquote>Select-AzureSubscription</blockquote>**
***
#Environment Setup

Once you have logged-in and selected the subscription to use, you can now execute the setup script.

Run the **setup-level3.ps1** from your PowerShell cmdline.

The **templatelevel3.json** and **schemaphotogallery.sql** should be on the same directory.

To clean up all you need to do is delete the resourcegroup:

#Environment Cleanup


Most of the assets can be cleaned up usign the Remove-AzureResourceGroup cmdlet:
**<blockquote>Remove-AzureResourceGroup -Name _Resource Group Name_ -Force</blockquote>**

This will remove the Resource Group, Web Hosting Plans, Websites, SQL servers and SQL databases created by the automation.

Storage accounts are not yet supported in CSM so they will need to be cleaned up manually.
