#
# This script is used to start scan on all Endpoints associated with a user
#
# The following steps are performed:
#
# 1. Determine input type (username, IP, hostname, or SAM Account Name)
# 2. Get Endpoint ID
# 3. Start Scan on Endpoint
#
#================================================#
# LogRhythm SmartResponse Plugin                 #
# Sophos Central Expansion Pack- SmartResponse   #
# Log Rhythm Community DosPuntoCero              #
# v2  --  May, 2021                              #
#================================================#

[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True)]
   [string]$ToBeScanned
)

# Trap for an exception during the script
Trap [Exception]
{
    if($PSItem.ToString() -eq "ExecutionFailure")
	{
		exit 1
	}
    else
	{
		Write-Error $("Trapped: $_")
		Write-Output "Aborting Operation."
		exit
	}
}

	#Function to Start Scan
function StartEndpointScan {

    Try {
		
        $JWT = GenerateToken

        $Header = @{"X-Tenant-ID" = "$TenantId"; "Authorization" = "Bearer $JWT"; "Accept" = "application/json"}
		
        $Machines = GetEndpointIds
		
        $Machines.Keys | %{
			$ScanEndpointUri = $BaseUrl + "/endpoint/v1/endpoints/" + $_ + "/scans"
        
			$Output = Invoke-RestMethod -Uri $ScanEndpointUri -Method Post -Body "{}" -Headers $Header -ContentType "application/json"

            If($Output.Status -eq "requested") {
			    Write-Output "Scan has been requested sucessfully for $($Machines.$_) at `'$($Output.requestedAt)`'"
			    Write-Output "Please check `'Sophos Central Dashbord`' for Endpoint status."
		    } Else {
			    Write-Output "Scan cannot be started for $($Machines.$_) `n Status: `'$($Output.status)`'"
			    Throw "ExecutionFailure"
		    }
		}

		
	} Catch {
		If($_.Exception.Message -eq "InvalidCredentials") {
			Write-Output "InValid Credentials."
			Throw "ExecutionFailure"
		} ElseIf($_.Exception.Message -eq "EndPointNotFound") {
			Write-Output "Endpoint for `"$ToBeScanned`" was not found."
			Throw "ExecutionFailure"
		} ElseIf($_.Exception.Message -match "The remote server returned an error: \(400\) Bad Request*") {
			Write-Output "Scan cannot be started for `"$ToBeScanned`"."
			Write-Error "Trapped: $_"
			Throw "ExecutionFailure"
		} ElseIf($_.Exception.Message -eq "ExecutionFailure") {
			Throw "ExecutionFailure"
		} Else {
			Write-Output "Unexpected Error/Response"
			Write-Error "Trapped: $_"
			Throw "ExecutionFailure"
		}
	}
}

# Dot Source GenerateToken.ps1 to get GenerateToken Function
. .\GenerateToken.ps1

# Dot Source FetchConfig.ps1 to get Configarion file parameters (Hash Table $ConfigItems will have all the parameters)
. .\FetchConfig.ps1

# Dot Source GetEndpointId.ps1 to get GetEndpointIds and DeterminReference functions
. .\GetEndpointId.ps1

$ClientID = $ConfigItems.ClientID
$ClientID = $ClientID.Trim()
$ClientPassword = $ConfigItems.ClientPassword
$ClientPassword = $ClientPassword.Trim()
$BaseUrl = $ConfigItems.BaseUrl
$BaseUrl = $BaseUrl.Trim()
$TenantID = $ConfigItems.TenantID
$TenantID = $TenantID.Trim()

# Call function
StartEndpointScan
