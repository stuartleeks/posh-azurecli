
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

function DebugMessage($message){
    if($env:POSH_AZURECLI_DEBUG -eq 1){
        [System.Diagnostics.Debug]::WriteLine("PoshAzureCli:$message")
    }
}
