# *************************************************************************************************
# Name: API-M_Tester.ps1 Script
#
# Description: A PowerShell Script where you can input an API URL, file name and your API-M Subscription Key
#              and the script will call the API "fileupload" POST method & pass in your file
#
# Usage: 
# 
# API-M_Tester.ps1 <API URL> <subscription key> <path to file>
#
# <API URL> is the URL for the API we are calling
#
# <subscription key> is 32 characters long & can be copied from your profile in the API-M developer portal:
# https://s1uksapimmapspd.developer.azure-api.net/apis
#
# <path to file> is the file path to the CSV to upload
# If there are spaces in the file or folders YOU MUST add quotes around the <path to file>
# 
# e.g. c:\scripts\API-M_Tester.ps1 https://sb1pdpapim.moneyhelper.org.uk/mock/fileupload 123456789abcdefghijklmnopqrstuvw "c:\data\myOrg_Tasks_July_2023.csv"
#
# *************************************************************************************************

function show_usage {
    Write-Host "`nMaPS API execution script, for testing & learning purposes, this code is not supported."
    Write-Host "The script will upload a file to the MaPS file Upload API"
    Write-Host "`nUsage:"
    Write-Host "------"
    Write-Host "`nAPI-M_Tester.ps1 <API URL> <subscription key> <path to file>"
    Write-Host "`n<API URL> is the URL for the API we are calling"
    Write-Host "`n<subscription key> is 32 characters long & can be copied from your profile in the MaPS developer portal:"
    Write-Host "    https://s1uksapimmapspd.developer.azure-api.net/apis"
    Write-Host "`n<path to file> is the file path to the CSV to upload"
    Write-Host "If there are spaces in the file or folders YOU MUST add quotes around the <path to file>"
    Write-Host "`ne.g. c:\scripts\API-M_Tester.ps1 https://sb1pdpapim.moneyhelper.org.uk/mock/fileupload 123456789abcdefghijklmnopqrstuvw ""c:\data\myOrg_Tasks_July_2023.csv""`n"
    exit
}

# Check we have 3 arguments
$num_args=$args.Length
if ($num_args -ne 3){
    Write-Host
    Write-Host "ERROR - Not enough/too many arguments passed in - expecting 3 arguments but $num_args arguments passed in (check for spaces!!)" -ForegroundColor red
    show_usage
}

# Check URL
$url = $args[0]
if ($url.Length -lt 10){
    Write-Host
    Write-Host -ForegroundColor Red "API URL invalid, enter a valid URL"
    show_usage
}

# Check subscription key
$subscriptionKey=$args[1]
if ($subscriptionKey.Length -ne 32){
    Write-Host
    Write-Host -ForegroundColor Red "No 32 character subscription key entered."
    show_usage
}

# File to upload passed in from command line
$filePath=$args[2]
# check file exists
if (-not (Test-Path $filePath)) {
    Write-Host
    Write-Host -ForegroundColor Red "File Path $filePath not found, please check the file name & location & try again."
    show_usage
}

Write-Host "`nAttempting to upload $filePath`n"

# Set subscription key header
$headers = @{}
$headers.Add('Ocp-Apim-Subscription-Key',$subscriptionKey)

# Set up file in form data
$fileBytes = [System.IO.File]::ReadAllBytes($FilePath);
$fileEnc = [System.Text.Encoding]::GetEncoding('UTF-8').GetString($fileBytes);
$boundary = [System.Guid]::NewGuid().ToString(); 
$LF = "`r`n";
$fileName=Split-Path $filePath -Leaf

$bodyLines = ( 
    "--$boundary",
    "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
    "Content-Type: application/octet-stream$LF",
    $fileEnc,
    "--$boundary--$LF" 
) -join $LF

 try {
     Invoke-RestMethod -Method 'POST' -Uri $url -Headers $headers -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines
     Write-Host "File Upload Sucessful`n" -ForegroundColor Green
 } catch {
     # Dig into the exception to get the Response details.
     Write-Host "Error - file not accepted" -ForegroundColor red
     Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ -ForegroundColor red
     Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor red
     Write-Host "`nFull Error:`n"
     Throw $_
 }
