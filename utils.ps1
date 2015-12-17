
function FindInPath() # http://blogs.msdn.com/b/stuartleeks/archive/2015/07/02/finding-files-in-the-path-with-powershell.aspx
{
    param ( 
        [string] $filename 
    )
    
    $matches = $env:Path.Split(';') | ?{$_ -ne ''} | %{ join-path $_ $filename} | ?{ test-path $_ }
    
    if ($matches.Length -eq 0){ 
        $null
    } else { 
        $matches 
    }
}

function Coalesce($a, $b) { if ($a -ne $null) { $a } else { $b } }

function GetAzureCmdPath() {
    FindInPath "azure.cmd" | Select -First 1
}
function GetAzureLibPath(){
	$azureCmdPath = GetAzureCmdPath
    $azurecliLibPath = $azureCmdPath | Split-Path | Join-Path -ChildPath "node_modules\azure-cli\lib"
	if(-not (Test-Path $azurecliLibPath)) {
		$azurecliLibPath = $azureCmdPath | Split-Path | Join-Path -ChildPath "..\lib"
	}
    if(Test-Path $azurecliLibPath) {
        return $azurecliLibPath
    }
}
function Install-AzureCliCompletion(){
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
}

function Uninstall-AzureCliCompletion(){
    # remove profile entry
    $newprofile = Get-Content $PROFILE | ?{-not $_.Contains("posh-azurecli") }
    $newprofile | Set-Content $PROFILE
}

function Reset-AzureCliCompletion() {
    [Cmdletbinding()]
    param()

    DebugMessage -message "Reset AzureCliCompletion"
    
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
    
}

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

function DebugMessage($message){
    if($env:POSH_AZURECLI_DEBUG -eq 1){
        [System.Diagnostics.Debug]::WriteLine("PoshAzureCli:$message")
    }
}
