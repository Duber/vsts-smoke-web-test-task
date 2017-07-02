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
    $timeout 
)

Write-Host "Executing web test for $url"

$HTTP_Status_Timeout = 0
$HTTP_Request = [System.Net.WebRequest]::Create($url)

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
    Write-Host "Web test success" -foregroundcolor green
}
ElseIf ($HTTP_Status -eq $HTTP_Status_Timeout) {
    throw "Request failed due to timeout after $timeout seconds."
}
Else {
    throw "Web test failed, received HTTP $HTTP_Status but expected HTTP $expectedReturnCode."
}
