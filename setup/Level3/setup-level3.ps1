$start = get-date

if (!(Test-Path .\templatelevel3.json)) 
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
	$Random3 = [system.guid]::NewGuid().tostring().substring(0,5)

	#Resource Group Properties
	$RG_Name = "scaleDemo" + $Random3
	$RG_Location = "West Us"

	#Web Hosting Plan Location1
	$WHP1_Name = "WHP" + $Random1
	$WHP1_Location = "West Europe"

	#Web Hosting Plan Location2
	$WHP2_Name = "WHP" + $Random2
	$WHP2_Location = "North Europe"

	#Website Location 1
	$WS1_Name = "scaledemo-" +  $Random1
	$WS1_Hostname = $WS1_Name + ".azurewebsites.net"
	$Site1Settings = @{ "dbRead" = "read"; "dbWrite" = "write"; "SiteName" = $WS1_Name; "queueName"="scaledemo"; "blobContainer" = "scaledemo"; "WEBSITE_ARR_SESSION_AFFINITY_DISABLE" = "TRUE" }	
	
	#Website Location 2
	$WS2_Name = "scaledemo-" +  $Random2
	$WS2_Hostname = $WS2_Name + ".azurewebsites.net"
	$Site2Settings = @{ "dbRead" = "read"; "dbWrite" = "write"; "SiteName" = $WS2_Name; "queueName"="scaledemo"; "blobContainer" = "scaledemo"; "WEBSITE_ARR_SESSION_AFFINITY_DISABLE" = "TRUE" }

	#SQL Servers
	$SQL1_Server = "scaledemosql-" +  $Random1
	$SQL2_Server = "scaledemosql-" +  $Random2
	$SQL_Database = "scaleDB"
	$SQL_User = "scaleAdmin"
	$SQL_Password = "p@ssw0rd"

	#Storage Accounts
	$SA1_Name = "scaledemostorage" +  $Random1
	$SA2_Name = "scaledemostorage" +  $Random2

	#Connection Strings
	$primaryDB = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo
	$secondaryDB = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo
	$Site1Storage = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo
	$Site2Storage = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.ConnStringInfo

	#traffic manager properties
	$WATM_Domain = $RG_Name + ".trafficmanager.net"



	#Provition Resources From Template
	#This will create:
	#		1 Resource Group, 
	#		2 WHP in different regions
	#		2 Websites (one in each WHP) and deploy the Picture Gallery
	#		2 SQL Servers in matching regions with the WHPs

	Write-Host "Creating Resource Group, Web Hosting Plan, Sites and SQL Servers..." -ForegroundColor Green 
	try 
	{ 
		New-AzureResourceGroup -name $RG_Name -location $RG_Location -TemplateFile .\templatelevel3.json -whp1 $WHP1_Name -location1 $WHP1_Location -siteName1 $WS1_Name -whp2 $WHP2_Name -location2 $WHP2_Location -siteName2 $WS2_Name -serverName1 $SQL1_Server -serverName2 $SQL2_Server
		[System.Console]::Beep(400,1500)
	}
	catch 
	{
    	Write-Host $Error[0] -ForegroundColor Red 
    	exit 1 
	} 
	
	Switch-AzureMode -Name AzureServiceManagement
	CLS

	#Traffic Manager
	try 
	{
		$WATM_Profile = New-AzureTrafficManagerProfile -Name $RG_Name -DomainName $WATM_Domain -LoadBalancingMethod "Performance" -MonitorPort 80 -MonitorProtocol "Http" -MonitorRelativePath "/" -Ttl 120

		$WATM_Profile = Add-AzureTrafficManagerEndpoint -TrafficManagerProfile $WATM_Profile -DomainName $WS1_Hostname -Status Enabled -Type AzureWebsite
		$WATM_Profile = Add-AzureTrafficManagerEndpoint -TrafficManagerProfile $WATM_Profile -DomainName $WS2_Hostname -Status Enabled -Type AzureWebsite

        Set-AzureTrafficManagerProfile -TrafficManagerProfile $WATM_Profile
		Enable-AzureTrafficManagerProfile -Name $RG_Name
		
        Get-AzureTrafficManagerProfile -Name $RG_Name
		[System.Console]::Beep(400,1500)

	}
	catch 
	{
		Write-Host $Error[0] -ForegroundColor Red 
    	exit 1 
	}

	#SQL Continous Copy
	Write-Host "Setting Up SQL Continous Copy..." -ForegroundColor Green 
	try 
	{ 
		Start-AzureSqlDatabaseCopy -ServerName $SQL1_Server -DatabaseName "scaleDb" -PartnerServer $SQL2_Server –ContinuousCopy
		[System.Console]::Beep(400,1500)
	}
	catch 
	{
    	Write-Host $Error[0] -ForegroundColor Red 
    	exit 1 
	} 

	

	write-host "Setting Up Storage Accounts" -ForegroundColor Green 
	try 
	{ 
		New-AzureStorageAccount -Location $WHP1_Location -StorageAccountName $SA1_Name
		$SA1 = Get-AzureStorageAccount -StorageAccountName $SA1_Name
		$SA1_Key = Get-AzureStorageKey -StorageAccountName $SA1_Name
		$SA1_C = New-AzureStorageContext -StorageAccountKey $SA1_Key.Primary -StorageAccountName $SA1.StorageAccountName -Protocol Https
		New-AzureStorageContainer -Name scaledemo -Permission "Container" -Context $SA1_C

		New-AzureStorageAccount -Location $WHP2_Location -StorageAccountName $SA2_Name
		$SA2 = Get-AzureStorageAccount -StorageAccountName $SA2_Name
		$SA2_Key = Get-AzureStorageKey -StorageAccountName $SA2_Name
		$SA2_C = New-AzureStorageContext -StorageAccountKey $SA2_Key.Primary -StorageAccountName $SA2.StorageAccountName -Protocol Https
		New-AzureStorageContainer -Name scaledemo -Permission "Container" -Context $SA2_C
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
		Set-AzureWebsite $WS2_Name -AppSettings $Site2Settings

		write-host ((Get-AzureWebsite $WS1_Name).AppSettings | Format-List | Out-String)  -ForegroundColor Green 
		write-host ((Get-AzureWebsite $WS2_Name).AppSettings | Format-List | Out-String)  -ForegroundColor Green 
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
		$primaryDB.Name = "write"
		$primaryDB.ConnectionString = "Data Source=" + $SQL1_Server + ".database.windows.net; Initial Catalog=scaleDB; User ID=scaleAdmin; Password=p@ssw0rd"
		$primaryDB.Type = "SQLAzure"

		$secondaryDB.Name = "read"
		$secondaryDB.ConnectionString = "Data Source=" + $SQL1_Server + ".database.windows.net; Initial Catalog=scaleDB; User ID=scaleAdmin; Password=p@ssw0rd"
		$secondaryDB.Type = "SQLAzure"

		$Site1Storage.Name = $WS1_Name
		$Site1Storage.ConnectionString = "DefaultEndpointsProtocol=http;AccountName=" + $SA1_Name + ";AccountKey=" + $SA1_Key.Primary 
		$Site1Storage.Type = "Custom"

		$Site2Storage.Name = $WS2_Name
		$Site2Storage.ConnectionString = "DefaultEndpointsProtocol=http;AccountName=" + $SA2_Name + ";AccountKey=" + $SA2_Key.Primary 
		$Site2Storage.Type = "Custom"

		$ConnectionStringList1 = (Get-AzureWebsite $WS1_Name).ConnectionStrings
		$ConnectionStringList1.add($primaryDB)
		$ConnectionStringList1.add($secondaryDB)
		$ConnectionStringList1.add($Site1Storage)
		$ConnectionStringList1.add($Site2Storage)

		Write-Host ($ConnectionStringList1 | Format-List | Out-String)  -ForegroundColor Green 
		Set-AzureWebsite $WS1_Name -ConnectionStrings $ConnectionStringList1

		$primaryDB.Name = "write"
		$primaryDB.ConnectionString = "Data Source=" + $SQL1_Server + ".database.windows.net; Initial Catalog=scaleDB; User ID=scaleAdmin; Password=p@ssw0rd"
		$primaryDB.Type = "SQLAzure"

		$secondaryDB.Name = "read"
		$secondaryDB.ConnectionString = "Data Source=" + $SQL2_Server + ".database.windows.net; Initial Catalog=scaleDB; User ID=scaleAdmin; Password=p@ssw0rd"
		$secondaryDB.Type = "SQLAzure"

		$Site1Storage.Name = $WS1_Name
		$Site1Storage.ConnectionString = "DefaultEndpointsProtocol=http;AccountName=" + $SA1_Name + ";AccountKey=" + $SA1_Key.Primary 
		$Site1Storage.Type = "Custom"

		$Site2Storage.Name = $WS2_Name
		$Site2Storage.ConnectionString = "DefaultEndpointsProtocol=http;AccountName=" + $SA2_Name + ";AccountKey=" + $SA2_Key.Primary 
		$Site2Storage.Type = "Custom"

		$ConnectionStringList2 = (Get-AzureWebsite $WS2_Name).ConnectionStrings
		$ConnectionStringList2.add($primaryDB)
		$ConnectionStringList2.add($secondaryDB)
		$ConnectionStringList2.add($Site1Storage)
		$ConnectionStringList2.add($Site2Storage)

		Write-Host ($ConnectionStringList2 | Format-List | Out-String)  -ForegroundColor Green 
		Set-AzureWebsite $WS2_Name -ConnectionStrings $ConnectionStringList2
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