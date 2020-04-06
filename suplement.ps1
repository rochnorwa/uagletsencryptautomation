# updated part of code from Darrell Dividen

#replace cert on UAG with REST API call
#provide UAG credential and info for API access in the format username:password encoded with base64 https://www.base64encode.org/

$uagcred = “yourBASE64ENCODEDusername:password”

$headers = New-Object “System.Collections.Generic.Dictionary[[String],[String]]”
$headers.Add(“Content-Type”, “application/json”)
$headers.Add(“Authorization”, “Basic $uagcred”)

#Create json string and make api call. Refer to https://docs.vmware.com/en/Unified-Access-Gateway/2.8/com.vmware.access-point-28-deploy-config/GUID-EDC244DD-07AB-4841-A893-84ADF8D59838.html
$json_uag = ‘{“privateKeyPem”:”‘ + $key_oneline + ‘”,”certChainPem”:”‘ + $cert_oneline + ‘”}’
$API_Endpoint = “https://” + $uag_host + “:9443/rest/v1/config/certs/ssl”
Invoke-RestMethod $API_Endpoint -Method ‘PUT’ -Headers $headers -Body $json_uag -Verbose
