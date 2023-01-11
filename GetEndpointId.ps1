#================================================#
# LogRhythm SmartResponse Plugin                 #
# Sophos Central Expansion Pack- SmartResponse   #
# LogRhythm Community DosPuntoCero               #
# v2  --  Feb, 2022                              #
#================================================#

function DetermineReference <#This is to set the API URL based on the search criteria #>{
	if ($ToBeQueried){$ToBe = $ToBeQueried}
	if ($ToBeIsolated){$ToBe = $ToBeIsolated}
	if ($ToBeScanned){$ToBe = $ToBeScanned}
	
	try {
		$ToBe = $ToBe.Trim()
		if($ToBe.EndsWith("*")){
			$ToBe = $ToBe.TrimEnd("*")
			$ToBe = $ToBe.Trim()
		}
		
		if ($ToBe -match '@'){									#Convert From Email Address
			$ToBe = $ToBe -replace '@.*',''
		}
		
		$EndpointsUri = $BaseUrl + "/endpoint/v1/endpoints?"
		
		$SamByName = ([ADSISearcher]"name=$ToBe").FindAll().Properties.samaccountname
		$NameBySam = ([ADSISearcher]"samaccountname=$ToBe").FindAll().Properties.name
		$DnsHostName = ([ADSISearcher]"dnshostname=$ToBe").FindAll().Properties.cn
		
		if ($ToBe -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'){ 		#IP Address
			$EndpointsUri += "ipAddresses=$ToBe"
		} elseif ($SamByName){
			if ($SamByName -match '\$$'){									#Computer Account (HostName Provided)
				$EndpointsUri += "hostnameContains=$ToBe"
			} else {														#User Account (UserName Provided)
				$EndpointsUri += "associatedPersonContains=$ToBe"
			}
		} elseif ($NameBySam){
			if ($ToBe -match '\$$'){									#Computer Account (SamAccountName Provided)
				$EndpointsUri += "hostnameContains=$NameBySam"
			} else {														#User Account (SamAccountName Provided)
				$EndpointsUri += "associatedPersonContains=$NameBySam"
			}
		} elseif ($DnsHostName){
			$EndpointsUri += "hostnameContains=$DnsHostName"
		} else {
			Throw "I have no idea what information you fed me.`n`nI need an IPv4, a SAM Account Name, a User name, a DNS Host Name or a Host Name (with or without the trailing `$`n`nInput:`t$ToBe"
			Exit 1
			return 0
		}
		
		return $EndpointsUri
	} catch {
		$_
	}
}
	
function GetEndpointIds <#There could be more than one endpoint associated with the user so we will find all of them#> {

	Try{
		
		$machines = @{}
		
		$EndpointsUri = DetermineReference
		
		$response = Invoke-RestMethod -Uri $EndpointsUri -Method Get -Headers $Header -ContentType "application/json"
write-output "3"
        $response.items | %{
            $machines.Add($_.id, $_.hostname)
        }

		if ($machines.count -gt 0){
			return $machines
		} else {
			Throw "EndPointNotFound"
            # Just to avoid unexpected error
            return 0
        }
	} Catch {
		Throw "$_"
	}
}
