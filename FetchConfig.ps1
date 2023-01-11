# Requires -Version 3
#
# Common File called to fetch values from configuration file and Disable SSL Certificate and Enable Tls1.2
#
#
#==========================================#
# LogRhythm SmartResponse Plugin           #
# Common File - SmartResponse              #
# sakshi.rawal@logrhythm.com               #
# V1  --  Oct, 2020       				   #
#Modified by DosPuntoCero                  #
#==========================================#

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


#This Function Returns a hashtable containing all configuration file variables

function Get-ConfigFileData([string]$FilePath) {
	try{
		if (!(Test-Path -Path $FilePath)){
			Write-Error "Error: Config File Not Found. Please run 'Create Configuration File' action."
			throw "Configurion File Not Found"
		}
		else{
			$ConfigFileContent = Import-Clixml -Path $FilePath

	        #Convert PSObject into HashTable
            $ConfigContent = @{}
            $ConfigFileContent.psobject.properties | ForEach-Object { $ConfigContent[$_.Name] = $_.Value }

            #Create a hashtable for configuration file content
            $ConfigHash = @{}
            $ConfigContent.Keys | ForEach-Object {
                $key = $_
                $keyvalue = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ConfigContent.$key))
                $ConfigHash.Add($key, $keyvalue)
            }
            return $ConfigHash
        }
	}
	catch{
		$message = $_.Exception.message
		if($message -eq "Configuration File Not Found"){
			throw "ConfigurationFileNotFound"
		}
		else{
			Write-Error $message
			throw "ExecutionFailure"
		}
	}
}

Disable-SSLError

#GetContent in Hash Table

$ConfigurationFilePath = "C:\Program Files\LogRhythm\SmartResponse Plugins2\SophosExpansionConfigFileTest.xml"
Try {
    $ConfigItems = Get-ConfigFileData -FilePath $ConfigurationFilePath
} Catch {
    If ( $_.Exception.Message -eq "ConfigurationFileNotFound" ) {
        Write-Output "Config File Not Found. Please run 'Create Configuration File' action."
		throw "ExecutionFailure"
    } Else {
        Write-Output "User does not have access to Config File."
		throw "ExecutionFailure"
    }
}
