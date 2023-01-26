# Sophos-Central-Expansion-Pack

Description:
This was originally written to cover some use cases that I felt were missing from the LogRhythm supported Sophos Central SRP.

V2 Differences:
In v1 there were different scripts for each type of metadata that could be fed into the script (ip, hostname, username). Now it has all been combined into one script per action with the parameter being parsed by a separate getendpointid function that is dot sourced into all of the main scripts.
I also added a script to query the endpoint, a use case for this is in the event of an anonymous logon you could query the host or ip to find the associated user.

Current Issues:
If running this within LogRhythm, the queryEndpoint script will only output to the webconsole screen or alarm SRP output if you query only one field. Any amount more than 1 and you get an empty response. If you would like to see what I have tried it is all commented out within the script (except for changing the Invoke-RestMethod to (Invoke-WebRequest).content, that was attempted after the initial commit).

How to Use:
LogRhythm-
Download the lpi and import it like you normally would to the Client Console, just be aware that this is still a test version and there is the issue noted above.

Locally-
Clone the repo, or download the scripts to a folder and call the scripts from your local PowerShell instance, they work great.
	
Step 1-
Create the config file.
Run the configuration script. The required parameters are your ClientID and ClientPassword (also known as Client Secret).  https://developer.sophos.com/getting-started-tenant 

Step 2-
Started running the scripts. That's it.
*If running locally you can pass multiple values to the script in the instance that you need to scan or isolate a block of machines
@(‘host1’,’host2’,’ip1’,’ip2’)|%{.\IsolateEndpoint.ps1 –ToBeIsolated $_ -Comment “Iterate through an array of hosts”}
1..255 | %{)|%{.\IsolateEndpoint.ps1 –ToBeIsolated 10.1.1.$_ -Comment “Iterate through a VLAN (No idea on how long this would take)”}
gc hostsToIsolate.txt)|%{.\IsolateEndpoint.ps1 –ToBeIsolated $_ -Comment “Pull from an external file”}






Scripts (LogRhythm Action in Parenthesis):
Called by User-

Configuration.ps1 (Create Sophos Central Configuration file)-
Parameters:
ClientID - The Client ID for the API credentials that you configured within Sophos Central https://developer.sophos.com/getting-started-tenant 
ClientPassword - The Client Secret for the API credentials that you configured within Sophos Central https://developer.sophos.com/getting-started-tenant 

Action:
This script will test the provided API credentials against the Sophos Central whoami API to validate them as well as get the correct Tenant ID and Data Region. It will then take the provided ClientID and ClientSecret as well as the queried Tenant ID and Data Region, convert them to secure strings and put export them in a Clixml. *NOTE These exported values can only be accessed by the user who created the file*

EndpointScan.ps1 (Scan Endpoint)-
Parameters: 
ToBeScanned - Provided the IP, host name, user name, user email, user samaccountname, or host samaccountname upon which you would like to initiate a Sophos endpoint scan (IP and user could result in more than one machine, host could as well but really shouldn't).

IsolateEndpoint.ps1 (Isolate Endpoint)-
Parameters: 
ToBeIsolated - Provided the IP, host name, user name, user email, user samaccountname, or host samaccountname corresponding to the endpoint(s) you would like to isolate (IP and user could result in more than one machine, host could as well but really shouldn't).

QueryEndpoint.ps1 (Query Endpoint)-
Parameters: 
ToBeQueried - Provided the IP, host name, user name, user email, user samaccountname, or host samaccountname corresponding to the endpoint(s) you would like to query (IP and user could result in more than one machine, host could as well but really shouldn't).

InformationFields - Provide the fields that you would like from the endpoint API call (list below). If you would like more than one field delimit with commas (e.g. "associatedUser,host"), if you would like the whole reponse, leave this blank.
id
type
tenant
hostname
health
os
ipv4Addresses
macAddresses
group
associatedPerson
tamperProtectionEnabled
assignedProducts
lastSeenAt
lockdown
isolation

Dot Sourced by the other scripts-
Read the comments in the script, you shouldn't need to worry about these anyway.
