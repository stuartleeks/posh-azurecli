
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

function DebugMessage($message){
    if($env:POSH_AZURECLI_DEBUG -eq 1){
        [System.Diagnostics.Debug]::WriteLine("PoshAzureCli:$message")
    }
}
