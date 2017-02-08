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

    If ($HTTP_Status -eq $expectedReturnCode) {
        Write-Host "Web test success" -foregroundcolor green
    }
    Else {
        throw "Web test failed, received HTTP $HTTP_Status but expected HTTP $expectedReturnCode."
    }
}
catch [System.Net.WebException]
{
    throw "$_"
}
