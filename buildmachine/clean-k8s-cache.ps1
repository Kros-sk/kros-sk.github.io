#Requires -RunAsAdministrator

$users = Get-ChildItem -Path c:\users
$users | ForEach-Object {
    $user = $_
    $userHome = [IO.Path]::Join("C:\Users", $user.Name)
    $userKubeFolder = [IO.Path]::Join($userHome, ".kube")
    if (Test-Path -Path $userKubeFolder) {
        write-host "Deleting $userKubeFolder"
        Remove-Item -Path $userKubeFolder -Recurse -Force -ErrorAction Stop
    }
}
