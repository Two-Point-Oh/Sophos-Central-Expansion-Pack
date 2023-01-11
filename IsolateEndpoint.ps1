#
# This script is used to start scan on all Endpoints associated with a user
#
# The following steps are performed:
#
# 1. Determine input type (username, IP, hostname, or SAM Account Name)
# 2. Get Endpoint ID
# 3. Isolate Endpoint
#
#================================================#
# LogRhythm SmartResponse Plugin                 #
# Sophos Central Expansion Pack- SmartResponse   #
# Log Rhythm Community DosPuntoCero              #
# v2  --  Jan, 2023                              #
#================================================#

[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True)]
   [string]$ToBeIsolated
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

	#Function to Isolate Endpoint
function IsolateEndpoint {

	Try {
		
		$JWT = GenerateToken

        $Header = @{"X-Tenant-ID" = "$TenantId"; "Authorization" = "Bearer $JWT"; "Accept" = "application/json"; "Content-Type" = "application/json"}
		#The endpoint ids must be given as an array for the api call to work, otherwise you get a "bad request"
        $Machines = GetEndpointIds
		$EndpointId = @()
		$HostNames = @()
		$Machines.Keys | %{
			$EndpointId += $_
			$HostNames += $Machines.$_
		}
		$IsolateUri = $BaseUrl + "/endpoint/v1/endpoints/isolation"
		
		$Body = ConvertTo-Json (@{"enabled" = $true;"ids" = $EndpointId;"comment" = "Isolated by LogRhythm via API"}) 
		#As of May 2021 the comment does not show up in the audit logs, in fact there are no audit logs for api calls in Sophos Central, but I have been told that they are working on this.#>
        $Output = Invoke-RestMethod -Uri $IsolateUri -Headers $Header -Method Post -Body $Body -UseBasicParsing
		
		If($output.items.isolation.enabled) {
			Write-Output "Endpoint `'$HostNames`' is isolating.`nComment: $($output.items.isolation.comment)`n"
			Write-Output "Please check `'Sophos Central Dashbord`' for Endpoint status.'"
		} Else {
			Write-Output "There has been an error in the isolation request of Endpoint `"$HostNames`".`nThe endpoints current isolation status is`'$($output.items.isolation.enabled)`'"
			Throw "ExecutionFailure"
		}
	} Catch {
		If($_.Exception.Message -eq "InvalidCredentials") {
			Write-Output "InValid Credentials."
			Throw "ExecutionFailure"
		} ElseIf($_.Exception.Message -eq "EndPointNotFound") {
			Write-Output "Endpoint with Host Name `"$HostName`" was not found."
			Throw "ExecutionFailure"
		} ElseIf($_.Exception.Message -match "The remote server returned an error: \(400\) Bad Request*") {
			Write-Output "Isolation cannot be excuted on Endpoint `"$HostName`"."
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
IsolateEndpoint
