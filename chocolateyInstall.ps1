$packageName = 'posh-azurecli'
$sourcePath = Split-Path -Parent $MyInvocation.MyCommand.Definition

$targetPath = Join-Path ([System.Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Modules\posh-azurecli"

if(Test-Path $targetPath){
    Write-Host "Remove previous module folder"
    Remove-Item -Path $targetPath -Recurse -Force | out-null
}
New-Item -ItemType Directory -Path $targetPath | out-null

Copy-Item "$sourcePath\*" $targetPath | out-null

# Adapted from http://www.west-wind.com/Weblog/posts/197245.aspx and discovered via posh-git
function Get-FileEncoding($Path) {
    $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)

    if(!$bytes) { return 'utf8' }

    switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3]) {
        '^efbbbf'   { return 'utf8' }
        '^2b2f76'   { return 'utf7' }
        '^fffe'     { return 'unicode' }
        '^feff'     { return 'bigendianunicode' }
        '^0000feff' { return 'utf32' }
        default     { return 'ascii' }
    }
}

$installPath = Split-Path $MyInvocation.MyCommand.Path
. "$installPath\utils.ps1"


# Test Azure CLI installed
$cliPath = GetAzureCmdPath
if($cliPath -eq $null) {
    Write-Error "Could not find azure cli"
    return
}
Write-Host "Found Azure CLI in $cliPath"

$libPath = GetAzureLibPath
if ($libPath -eq $null){
    Write-Error "Could not find azure cli lib path"
    return
}

# Check CLI version
$output = azure
$output | %{ 
    if ($_ -match "Tool version (\d*)\.(\d*)\.(\d*)") {
        $version = $matches
    }
}
if ($version -eq $null) {
    Write-Error "Failed to determine CLI version"
    return
}
$major = [int] $version[1]
$minor = [int] $version[2]
$patch = [int] $version[3]
$supportedVersion = ( 
                        ($major -gt 0) `
                        -or ($major -eq 0 -and $minor -gt 9) `
                        -or ($major -eq 0 -and $minor -eq 9 -and $patch -ge 7) `
                    ) 
if (-not $supportedVersion) {
    Write-Error "You must have version 0.9.7 of Azure CLI or later"
    return
}



# generate plugins.xxx.json
# Initially made this conditional, but this approach at least ensure that the files are up-to-date on posh-azurecli installation!
# TODO look at adding detection when these are stale (when cli is updated) and triggering regeneration
Write-Host "Running 'azure --gen' to generate metadata files"
azure --gen

if(-not (Test-Path $PROFILE))
{
    Write-Host "Creating profile: $PROFILE"
    New-Item $PROFILE -Type File -ErrorAction Stop -Force | out-null
}
Write-Host "Add posh-azurecli to profile"
@"

# Load posh-azurecli example profile
Import-Module posh-azurecli

"@ | Out-File $PROFILE -Append -Encoding (Get-FileEncoding $PROFILE)