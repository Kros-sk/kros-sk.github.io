param (
    [Parameter(Mandatory = $true)][String]$StorageAccountName,
    [Parameter(Mandatory = $true)][String]$ContainerName,
    [Parameter(Mandatory = $true)][String]$BlobName,
    [Parameter(Mandatory = $true)][String]$SourceFolder,
    [Parameter(Mandatory = $true)][String]$TempFolder
)

$ContainerName = $ContainerName.ToLower() -replace "[^a-z0-9-]", "-"
$BlobName = $BlobName.ToLower() -replace "[^a-z0-9-]", "-"

Write-Output "----------------------------------------------------------------------"
Write-Output "Input parameters:"
Write-Output "    `$StorageAccountName = $StorageAccountName"
Write-Output "    `$ContainerName = $ContainerName"
Write-Output "    `$BlobName = $BlobName"
Write-Output "    `$SourceFolder = $SourceFolder"
Write-Output "    `$TempFolder = $TempFolder"
Write-Output "The values of `$ContainerName and `$BlobName were sanitized. All characters except alphanumeric and hyphen were replaced with hyphen (-)."
Write-Output "----------------------------------------------------------------------"

$SourceFolder = Join-Path -Path $SourceFolder -ChildPath "*"
$TempZip = Join-Path -Path $TempFolder -ChildPath ([guid]::NewGuid().ToString() + ".zip")

$ContainerPublicAccess = "blob"
$ContentType = "application/zip"
$ContentDisposition = "attachment; filename=""$BlobName.zip"""

Write-Output "Checking if container exists."
$result = az storage container exists --account-name "$StorageAccountName" --name "$ContainerName" | ConvertFrom-Json
if (-not $result) {
    throw "Error while checking if container exists."
}

if (-not $result.exists) {
    Write-Output "Container does not exist, so it will be created."
    $result = az storage container create --name "$ContainerName" --account-name "$StorageAccountName" --public-access $ContainerPublicAccess
    if (-not $result) {
        throw "Error while creating container."
    }
    Write-Output "Container successfully created."
}

Write-Output "Creating archive for upload:"
Write-Output "    Source: $SourceFolder"
Write-Output "    Destination: $TempZip"
Compress-Archive -Path "$SourceFolder" -DestinationPath $TempZip -Force
if (-not (Test-Path -Path $TempZip -PathType leaf)) {
    throw "Error while creating archive."
}

Write-Output "Uploading archive to storage:"
Write-Output "    File: $TempZip"
Write-Output "    ContainerName: $ContainerName"
Write-Output "    BlobName: $BlobName"
$result = az storage blob upload --file "$TempZip" --container-name "$ContainerName" --name "$BlobName" --account-name "$StorageAccountName" --content-type "$ContentType" --content-disposition "$ContentDisposition" --no-progress
if (-not $result) {
    throw "Error while uploading file."
}

Remove-Item -Path "$TempZip" -Force

Write-Output "Data was successfully uploaded to storage."
Write-Output "Download link: https://$StorageAccountName.blob.core.windows.net/$ContainerName/$BlobName"
