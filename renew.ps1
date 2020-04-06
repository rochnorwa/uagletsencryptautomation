<#
.DESCRIPTION
Script requests certificates from Letsencrypt with automatic DNS-01 challange and installs them on UAG and Connection Server
  
.NOTES
Author: Roch Norwa https://digitalworkspace.blog @rochnorwa https://linkedin.com/rochnorwa
  
#>
#go back to C:\ just in case the location i set to cert:
Set-Location C:
 
#information to be used in the cert request. use comma seperated domains for UCC/SAN certificate.
$domain = "*.domain.com","domain.com"
$uag_host = "uag.domain.com"
  
# information for letsncrypt POSH-ACME powershell script
$psMod = "Posh-ACME"
$dnsPlugin = "GoDaddy"
$pArgs = @{GDKey="9ZtodG7jWNC_84teqTR1231U3tpRV4PGKJ"; GDSecret="3TPk3B123rCyCAXhKEadQa"}
$email = "certadmin@domain.com"
  
# letsencrypt server address. Use LE_STAGE to test, if everything ok switch to LE_PROD.
Set-PAServer LE_STAGE
   
# Request the certificate
#New-PACertificate $domain -AcceptTOS -DnsPlugin $dnsPlugin -PluginArgs $pArgs -Contact $email -Verbose -Force
 
# Renew the certificate. Keep the above New-PACertificate hashed out!
# -AllOrders means all certificates requested by a specific account (email address). -Force will renew even if the certificate is not at the renewal period (30 days before expiration)
Submit-Renewal -AllOrders -Verbose -Force
  
# transform PEM key and certificate into single text lines
$PACert = Get-PACertificate
$key_multiline = [IO.File]::ReadAllText($PACert.KeyFile)
$key_oneline = $key_multiline.Replace("`n",'\n')
$cert_multiline = [IO.File]::ReadAllText($PACert.FullChainFile)
$cert_oneline = $cert_multiline.Replace("`n",'\n')
 
#replace cert on UAG with REST API call
#provide UAG credential and info for API access in the format username:password encoded with base64 https://www.base64encode.org/
 
$uagcred = "YWRWJDWDJDdsd13YXJlMSE=" 
$API_Settings = @{
    Headers     = @{ "Authorization" = "Basic $uagcred" }
    Method      = "PUT"
    Body        = $json_uag
    ContentType = "application/json"
}
#Create json string and make api call. Refer to https://docs.vmware.com/en/Unified-Access-Gateway/2.8/com.vmware.access-point-28-deploy-config/GUID-EDC244DD-07AB-4841-A893-84ADF8D59838.html
$json_uag = '{"privateKeyPem":"' + $key_oneline + '","certChainPem":"' + $cert_oneline + '"}'
$API_Endpoint = "https://" + $uag_host + ":9443/rest/v1/config/certs/ssl"
Invoke-RestMethod $API_Endpoint @API_Settings
 
#now lets replace the certificate on Connection Server. First we install the certificate in the local machine store
Install-PACertificate
 
#we will check if there are an existing certificates with a friendly name of "vdm"and rename it to "replaced" with the current date for the record
 
Set-Location cert:\LocalMachine\My
$old_certs = Get-Childitem |Where-Object {$_.FriendlyName -eq 'vdm'}
ForEach ($old_cert in $old_certs){
$old_cert.FriendlyName = "Replaced $(Get-Date -format 'u')"
write-host $old_cert.Thumbprint 
}
 
#now we will set the friendly name of this certificate to "vdm"
 
$cert_thumbprint_dirty = Get-PACertificate |fl Thumbprint
$cert_thumbprint = Out-String -InputObject $cert_thumbprint_dirty -Width 100
$cert = gci $cert_thumbprint.Substring(17)
$cert.FriendlyName = “vdm”
 
#and the last thing is to restart Hotizon Connection Server service to pickup the new certificate
 
Restart-Service -Name wsbroker
Set-Location C:
