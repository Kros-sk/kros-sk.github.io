Write-Output "Prune all images"
docker system prune --all --force

Write-Output "Shut down wsl"
wsl --shutdown
Stop-Process -Name "Docker desktop"

$userName = [System.Environment]::UserName
$path = "c:\Users\" + $userName + "\AppData\Local\Docker\wsl\data\ext4.vhdx"

Write-Output "Optimize vhdx file"
optimize-vhd -Path $path -Mode full

Write-Output "Starting docker ..."
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
