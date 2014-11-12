$start = get-date

if (!(Test-Path .\templatelevel2.json)) 
{
	write-host "templete not found"  -ForegroundColor Red
}
else 
{
	#Use ARM cmdlets
	Switch-AzureMode -Name AzureResourceManager
	CLS

	#Random
	#Used to randomize the names of the resources being created to avoid conflicts
	$Random1 = [system.guid]::NewGuid().tostring().substring(0,5)
	$Random2 = [system.guid]::NewGuid().tostring().substring(0,5)

	#Resource Group Properties
	$RG_Name = "scaleDemo" + $Random2
	$RG_Location = "West Us"

	#Web Hosting Plan Location1
	$WHP1_Name = "WHP" + $Random1
	$WHP1_Location = "West Europe"

	#Website Location 1
	$WS1_Name = "scaledemo-" +  $Random1
	$WS1_Hostname = $WS1_Name + ".azurewebsites.net"
	$Site1Settings = @{ "dbRead" = "read"; "dbWrite" = "write"; "SiteName" = $WS1_Name; "queueName"="scaledemo"; "blobContainer" = "scaledemo"; "WEBSITE_ARR_SESSION_AFFINITY_DISABLE" = "TRUE"}	
		
	#SQL Servers
	$SQL1_Server = "scaledemosql-" +  $Random1
	$SQL_Database = "scaleDB"
	$SQL_User = "scaleAdmin"
	$SQL_Password = "p@ssw0rd"

	#Storage Accounts
	$SA1_Name = "scaledemostorage" +  $Random1

	#Connection Strings
	$primaryDB = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo
    $secondaryDB = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo
	$Site1Storage = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo

	#Provition Resources From Template
	#This will create:
	#		1 Resource Group, 
	#		2 WHP in different regions
	#		2 Websites (one in each WHP) and deploy the Picture Gallery
	#		2 SQL Servers in matching regions with the WHPs

	Write-Host "Creating Resource Group, Web Hosting Plan, Site and SQL Server..." -ForegroundColor Green 
	try 
	{ 
		New-AzureResourceGroup -name $RG_Name -location $RG_Location -TemplateFile .\templatelevel2.json -whp $WHP1_Name -location1 $WHP1_Location -siteName $WS1_Name -serverName $SQL1_Server
		[System.Console]::Beep(400,1500)
	}
	catch 
	{
    	Write-Host $Error[0] -ForegroundColor Red 
    	exit 1 
	} 
	
	Switch-AzureMode -Name AzureServiceManagement
	CLS

	write-host "Setting Up Storage Accounts" -ForegroundColor Green 
	try 
	{ 
		New-AzureStorageAccount -Location $WHP1_Location -StorageAccountName $SA1_Name
		$SA1 = Get-AzureStorageAccount -StorageAccountName $SA1_Name
		$SA1_Key = Get-AzureStorageKey -StorageAccountName $SA1_Name
		$SA1_C = New-AzureStorageContext -StorageAccountKey $SA1_Key.Primary -StorageAccountName $SA1.StorageAccountName -Protocol Https
		New-AzureStorageContainer -Name scaledemo -Permission "Container" -Context $SA1_C
		[System.Console]::Beep(400,1500)
	}
	catch
	{
		Write-Host $Error[0] -ForegroundColor Red 
    	exit 1 
	}

	write-host "Setting Up AppSettings" -ForegroundColor Green 
	write-host "This Takes a little while, be patient :)" -ForegroundColor Green 
	try 
	{ 
		#AppSettings
		Set-AzureWebsite $WS1_Name -AppSettings $Site1Settings
		write-host ((Get-AzureWebsite $WS1_Name).AppSettings | Format-List | Out-String)  -ForegroundColor Green 
		[System.Console]::Beep(400,1500)
	}
	catch
	{
		Write-Host $Error[0] -ForegroundColor Red 
    	exit 1 
	}

	write-host "Setting Up Connection Strings" -ForegroundColor Green 
	write-host "This Takes a little while, be patient :)" -ForegroundColor Green 
	try 
	{ 
		$primaryDB.Name = "read"
		$primaryDB.ConnectionString = "Data Source=" + $SQL1_Server + ".database.windows.net; Initial Catalog=scaleDB; User ID=scaleAdmin; Password=p@ssw0rd"
		$primaryDB.Type = "SQLAzure"

        $secondaryDB.Name = "write"
		$secondaryDB.ConnectionString = "Data Source=" + $SQL1_Server + ".database.windows.net; Initial Catalog=scaleDB; User ID=scaleAdmin; Password=p@ssw0rd"
		$secondaryDB.Type = "SQLAzure"

		$Site1Storage.Name = $WS1_Name
		$Site1Storage.ConnectionString = "DefaultEndpointsProtocol=http;AccountName=" + $SA1_Name + ";AccountKey=" + $SA1_Key.Primary 
		$Site1Storage.Type = "Custom"

		$ConnectionStringList1 = (Get-AzureWebsite $WS1_Name).ConnectionStrings
		$ConnectionStringList1.add($primaryDB)
        $ConnectionStringList1.add($secondaryDB)
		$ConnectionStringList1.add($Site1Storage)

		Write-Host ($ConnectionStringList1 | Format-List | Out-String)  -ForegroundColor Green 
		Set-AzureWebsite $WS1_Name -ConnectionStrings $ConnectionStringList1

		[System.Console]::Beep(400,1500)
	}
	catch
	{
		Write-Host $Error[0] -ForegroundColor Red 
    	exit 1 
	}

	write-host "Populating SQL Schema" -ForegroundColor Green 
	#Connect to MS SQL Server 
	try 
	{ 
	    $SQLConnection = New-Object System.Data.SqlClient.SqlConnection 
	    $SQLConnection.ConnectionString = $primaryDB.ConnectionString
	    $SQLConnection.Open() 
	} 
	#Error of connection 
	catch 
	{ 
    	Write-Host $Error[0] -ForegroundColor Red 
    	exit 1 
	} 

	#Execute Script 
	$SQLCommandText = @(Get-Content -Path "./schemaphotogallery.sql") 
	foreach($SQLString in  $SQLCommandText) 
	{ 
	    if($SQLString -ne "go") 
	    { 
	        #Preparation of SQL packet 
	        $SQLPacket += $SQLString + "`n" 
	    } 
	    else 
	    { 
	        Write-Host "---------------------------------------------"  -ForegroundColor Green 
	        Write-Host "Executed SQL packet:"  -ForegroundColor Green 
	        Write-Host $SQLPacket  -ForegroundColor Green 
	        $IsSQLErr = $false 
	        #Execution of SQL packet 
	        try 
	        { 
	            $SQLCommand = New-Object System.Data.SqlClient.SqlCommand($SQLPacket, $SQLConnection) 
	            $SQLCommand.ExecuteScalar() 
	        } 
	        catch 
	        { 

	            $IsSQLErr = $true 
	            Write-Host $Error[0] -ForegroundColor Red 
	            $SQLPacket | Out-File -FilePath ($PWD.Path + "\SQLErrors.txt") -Append 
	            $Error[0] | Out-File -FilePath ($PWD.Path + "\SQLErrors.txt") -Append 
	            "----------" | Out-File -FilePath ($PWD.Path + "\SQLErrors.txt") -Append 
	        } 
	        if(-not $IsSQLErr) 
	        { 
	            Write-Host "Execution succesful"  -ForegroundColor Green 
	        } 
	        else 
	        { 
	            Write-Host "Execution failed"  -ForegroundColor Red 
	        } 
	        $SQLPacket = "" 
	    } 
	} 


	#Disconnection from MS SQL Server 
	$SQLConnection.Close() 
	Write-Host "-----------------------------------------"  -ForegroundColor Green 
	Write-Host $file "execution done"  -ForegroundColor Green 
	[System.Console]::Beep(400,1500)
	
	$end = get-date

	write-host "Start= " $start.Hour ":" $start.Minute ":" $start.Second
	write-host "End= " $end.Hour ":" $end.Minute ":" $end.Second
	pause
}