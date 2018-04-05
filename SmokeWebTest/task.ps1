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
    [Parameter(Mandatory = $true)]
    [ValidateRange(1,50)]
    $retryAttemptCount
)

Write-Host "Begin Smoke Test ...";



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




<#
    PerformCallAndStatusCheck
        -- this does the work of making a call to the requested URL and 
            checking the return status againt the expected return
#>
function PerformCallAndStatusCheck
{
    [bool] $returnVal = $false;
    $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    $HTTP_Status_Timeout = 0
    $HTTP_Request = [System.Net.WebRequest]::Create($url)
    Write-Host "calling to check $url";
    try
    {
        $HTTP_Request.Timeout = $timeout * 1000
        $HTTP_Response = $HTTP_Request.GetResponse()
        $HTTP_Status = [int]$HTTP_Response.StatusCode
        $HTTP_Response.Close()
    }
    catch [System.Net.WebException]
    {
        $res = $_.Exception.Response
        $HTTP_Status = [int]$res.StatusCode
    }
    catch
    {
        throw "$_"
    }

    If ($HTTP_Status -eq $expectedReturnCode) {
        $returnVal = $true;

    }
    ElseIf ($HTTP_Status -eq $HTTP_Status_Timeout) {
        Write-Host "Request failed due to timeout after $timeout seconds."
    }
    Else {
        Write-Host "Web test failed, received HTTP $HTTP_Status but expected HTTP $expectedReturnCode."
    }

    return $returnVal;
}


<#
    Main
        -- This is the main logic control, currently handles the retry logic for 
            for the calls to check the website status
#>
function Main
{
    Write-Debug "Begin Main";
    [int] $count = 0;
    [bool] $success = $false;
    DO {
        if($count -gt 0)
        {
            Write-Host " Retrying ....  ";
            Start-Sleep -Seconds 1;
        }
        $success = PerformCallAndStatusCheck;
        
        $count += 1;

    } While ($count -le $retryAttemptCount -and -Not $success)

    if($success)
    {
        Write-Host "Smoke test was successful for $url";
    
    }
    Else{
        Write-Error "Failed to get an expected result ... "
        #throw "failed smoke test of $url";
        
    }
}


Main;