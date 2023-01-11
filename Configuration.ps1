# Requires -Version 3.0
# 
# This Script is used to configure fixed parameters for a plugin so as they need not to be provided everytime while executing an action.
#
# Use Case -> 
# Configure Fixed parameters in a one time script run. For Ex API Key, Username, Password
# Store parameter values in encrypted form.
# 
# The following steps are performed:
#
# 1. Input Validations.
# 2. Creating a file to store parameter values.
# 3. Encrypting the parameter values.
# 4. Storing the parameter values in the file.
#
### ===============================================================================================#
### Change the Value of ConfigurationFilePath for each Plugin                              #########          
### Change the dictionary Key Values for use in the individual Plugin.                     #########
###                                                                                        #########
###                                                                                        #########
###================================================================================================#
# 
#==========================================#
# LogRhythm SmartResponse Plugin           #
# SmartResponse Configure File             #
# Sakshi.Rawal@logrhythm.com               #
# V1.0  --  October, 2020                  #
#Modified by DosPuntoCero                  #
#==========================================#



[CmdletBinding()] 
Param( 
[Parameter(Mandatory=$True)]
[ValidateNotNullOrEmpty()]
[string]$ClientID, 
[Parameter(Mandatory=$True)]
[ValidateNotNullOrEmpty()]
[string]$ClientPassword
)


$ErrorActionPreference = "Stop"
# Trap for an exception during the script
Trap [Exception]
{
    if($PSItem.ToString() -eq "ExecutionFailure")
	{
		exit 1
	}
	elseif($PSItem.ToString() -eq "ExecutionSuccess")
	{
		exit
	}
	else
	{
		write-error $("Trapped: $_")
		Write-Output "Aborting Operation."
		exit
	}
}


# Function to Check and Create SmartResponse Directory
function CreateSRPDirectory
{
	if (!(Test-Path -Path $ConfigurationDirectoryPath))
	{
		New-Item -ItemType "directory" -Path $ConfigurationDirectoryPath -Force | Out-null
	}
}


# Function to Check and Create SmartResponse Config File

function CheckConfigFile
{
	if (!(Test-Path -Path $ConfigurationFilePath))
	{
		New-Item -ItemType "file" -Path $ConfigurationFilePath -Force | Out-null
	}
}


# Function to Disable SSL Certificate Error and Enable Tls12

function Disable-SSLError
{
	# Disabling SSL certificate error
    add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


    # Forcing to use TLS1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}


#Function to validate Cisco Secure X Parameters
function ValidateInputs{
    $Url = "https://id.sophos.com/api/v2/oauth2/token"
    $Header = @{
            "Content-Type"= "application/x-www-form-urlencoded"
            "Accept"= "application/json"
    }

    $Body = @{
        "client_id"= $ClientID;
        "client_secret"= $ClientPassword;
        "grant_type"= "client_credentials";
        "scope"="token"
    }
    
    try
	{
		$Output = Invoke-RestMethod -Uri $Url -Method Post -Headers $Header -Body $Body -ContentType "application/x-www-form-urlencoded"
        $Token = $Output.access_token   
    }
	catch
	{
        $ExceptionMessage = $_.Exception.Message      
		if ($ExceptionMessage -eq "The remote server returned an error: (401) Unauthorized."){
			Write-Output "Invalid Sophos Central ClientId/ Client Password"
			Exit 
		}
        else{
            Write-Output $ExceptionMessage
            Exit
        }
	}   

    $RegionUrl = "https://api.central.sophos.com/whoami/v1"
    $RegionHeader = @{
            "authorization"= "Bearer $Token"
            "Accept"= "application/json"
    }

    try
	{
		$Details = Invoke-RestMethod -Uri $RegionUrl -Method Get -Headers $RegionHeader	
        $TentantID = $Details.id
        $BaseURL = $Details.apiHosts.dataRegion          
    }
	catch
	{
        $ExceptionMessage = $_.Exception.Message      
        Write-Output $ExceptionMessage
        Exit 
	}  
    
    return $TentantID, $BaseURL
}


# Function to encrypt the values
function CreateHashtable
{
	$HashTable = [PSCustomObject]@{ 
								"ClientID" = $SecureClientID
								"ClientPassword" = $SecureClientPassword
                                "TenantID" = $SecureTenantID
                                "BaseURL" = $SecureBaseURL
						}
	return $HashTable					
}

# Function to Create Hashtable for the parameters
function CreateConfigFile
{
	CreateHashtable | Export-Clixml -Path $ConfigurationFilePath
	Write-Output "Validations Passed."
	Write-Output "Configuration Parameters saved for Sophos Central."
}


$ConfigurationDirectoryPath = "C:\Program Files\LogRhythm\SmartResponse Plugins2"
$ConfigurationFilePath = "C:\Program Files\LogRhythm\SmartResponse Plugins2\SophosExpansionConfigFileTest.xml"

$ClientID = $ClientID.trim()
$ClientPassword = $ClientPassword.trim()


CreateSRPDirectory
CheckConfigFile
Disable-SSLError

$ReturnArray = ValidateInputs
$TenantID = $ReturnArray[0]
$BaseURL = $ReturnArray[1]

$SecureClientID = $ClientID | ConvertTo-SecureString -AsPlainText -Force
$SecureClientPassword = $ClientPassword | ConvertTo-SecureString -AsPlainText -Force
$SecureTenantID = $TenantID | ConvertTo-SecureString -AsPlainText -Force
$SecureBaseURL = $BaseURL | ConvertTo-SecureString -AsPlainText -Force

CreateConfigFile
