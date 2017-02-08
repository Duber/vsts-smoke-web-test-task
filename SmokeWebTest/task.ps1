[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String] [Parameter(Mandatory = $true)]
    $url,

    [String] [Parameter(Mandatory = $true)]
    $expectedReturnCode
)

Write-Host "Executing web test for $url"

$HTTP_Request = [System.Net.WebRequest]::Create($url)

try
{
    $HTTP_Response = $HTTP_Request.GetResponse()
    $HTTP_Status = [int]$HTTP_Response.StatusCode
    $HTTP_Response.Close()

    Write-Host "Web test success" -foregroundcolor green
}
catch [System.Net.WebException]
{
    Write-Host "$_" -foregroundcolor red
    exit 1
}
