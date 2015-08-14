$packageName = 'posh-azurecli'
$sourcePath = Split-Path -Parent $MyInvocation.MyCommand.Definition

$targetPath = Join-Path ([System.Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Modules\posh-azurecli"

if(Test-Path $targetPath){
    Remove-Item -Path $targetPath -Recurse -Force
}

# remove profile entry
$newprofile = Get-Content $PROFILE | ?{-not $_.Contains("posh-azurecli") }
$newprofile | Set-Content $PROFILE