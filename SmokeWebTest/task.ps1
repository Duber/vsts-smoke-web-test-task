[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String]
    [Parameter(Mandatory = $true)]
    $url,

    [int]
    [Parameter(Mandatory = $true)]
    [ValidateRange(100,600)]
    $expectedReturnCode,

    [int]
    [Parameter(Mandatory = $true)]
    [ValidateRange(1,600)] 
    $timeout,
	
	[int]
    [ValidateRange(0,10)] 
	$retries = 0,
	
	[int]
    [ValidateRange(1,30)] 
	$seconds = 5
)

$retryCount = 1
$stopLoop = $false

Write-Host "Executing web test for $url"

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
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$HTTP_Status_Timeout = 0
$HTTP_Request = [System.Net.WebRequest]::Create($url)

do 
{
	try
	{
		$HTTP_Request.Timeout = $timeout * 1000
		$HTTP_Response = $HTTP_Request.GetResponse()
		$HTTP_Status = [int]$HTTP_Response.StatusCode
		$HTTP_Response.Close()
		$Stoploop = $true
	}
	catch [System.Net.WebException]
	{	
		$res = $_.Exception.Response
		$HTTP_Status = [int]$res.StatusCode
		
		if ($retryCount -gt $retries) {
			$Stoploop = $true
		}
		else {
			Write-Host "Try $retryCount - StatusCode: $HTTP_Status - Retrying in $seconds seconds..." -foregroundcolor red
			Start-Sleep -Seconds $seconds
			$retryCount = $retryCount + 1
		}
	}
	catch
	{
		throw "$_"
	}
}
while ($stoploop -eq $false)


If ($HTTP_Status -eq $expectedReturnCode) {
    Write-Host "Web test success" -foregroundcolor green
}
ElseIf ($HTTP_Status -eq $HTTP_Status_Timeout) {
    throw "Request failed due to timeout after $timeout seconds."
}
Else {
    throw "Web test failed, received HTTP $HTTP_Status but expected HTTP $expectedReturnCode."
}