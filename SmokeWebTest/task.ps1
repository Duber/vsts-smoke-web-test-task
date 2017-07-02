[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String] [Parameter(Mandatory = $true)]
    $url,

    [String] [Parameter(Mandatory = $true)]
    $expectedReturnCode,

    [int] [Parameter(Mandatory = $true)]
    $timeout 
)

Write-Host "Executing web test for $url"

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
Else {
    throw "Web test failed, received HTTP $HTTP_Status but expected HTTP $expectedReturnCode."
}
