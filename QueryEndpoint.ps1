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
   [Parameter(Mandatory=$False)]
   [string]$ToBeQueried,
   [Parameter(Mandatory=$False)]
   [string[]]$InformationFields
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

	#Function to Query the Endpoint
function QueryEndpoint {

    Try {
		
        $JWT = GenerateToken

        $Header = @{"X-Tenant-ID" = "$TenantId"; "Authorization" = "Bearer $JWT"; "Accept" = "application/json"}
		
        $Machines = GetEndpointIds
		
		$FullInfo = @()
        $Machines.Keys | %{
			$QueryEndpointUri = $BaseUrl + "/endpoint/v1/endpoints/" + $_
        
			$FullInfo += Invoke-RestMethod -Uri $QueryEndpointUri -Method Get -Headers $Header -ContentType "application/json"
		}
		
		$OutputTempFileName = get-date -UFormat %m%d%y%H%M%S%s
		$OutputTempFile = "C:\Program Files\LogRhythm\SmartResponse Plugins\$OutputTempFileName"
		
		if ($InformationFields.count -gt 1){
			$FullInfo | %{
				
				#-----------------------------------------Write the API call directly by key-----------------------------------------
				$curr = $_
				$curr.hostname
				$InformationFields | %{
					if (!($_ -match 'hostname')){
						Write-Host $_
						Write-Host $curr.$_
					}
				}
				
				
				#-----------------------------------------Write to an output file (1 more line below)-----------------------------------------
				<#$currHost = $_
				$InformationFields | %{
					$currHost.$_ | ConvertTo-Json >> $OutputTempFile
				}#>
			
				
				#-----------------------------------------Write to a hash table-----------------------------------------
				<#$currHost = $_
				$Out = @{}
				$InformationFields | %{
					$Out.Add($_,($currHost.$_))
				}#>
				
										#***********************************************output as PS table**************************************
				<#$ModifiedHash = $Out | FT -HideTableHeaders
				Write-Output $ModifiedHash#>
				
										#***********************************************output as JSON********************************************
				#$Out | ConvertTo-Json
				
										#***********************************************convert JSON to string************************************
				<#$Json = $Out | ConvertTo-Json
				$String = ""
				($Json).split("`n") | %{$String+="$_`n"}
				Write-Output $String#>
							
				
			}
			#Get-Content $OutputTempFile     				#Write to an output file-----------------------------------------
		}elseif ($InformationFields.count -eq 1){
			Write-Output $FullInfo.$InformationFields
		}else{
			Write-Output $FullInfo
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

Function PrintHelp {
	Write-Output "If querying more than one field use commas (hostname,type,health)`n`nAvailable Fields:`nid`ntype`ntenant`nhostname`nhealth`nos`nipv4Addresses`nmacAddresses`ngroup`ntamperProtectionEnabled`nassignedProducts`nlastSeenAt`nlockdown (SERVERS ONLY)"
}

# Call function
if (($InformationFields -match 'help') -or ($ToBeQueried.length -lt 1)){
	PrintHelp
}else{
	
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

	QueryEndpoint
}