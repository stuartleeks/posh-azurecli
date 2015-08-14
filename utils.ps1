
function FindInPath() # http://blogs.msdn.com/b/stuartleeks/archive/2015/07/02/finding-files-in-the-path-with-powershell.aspx
{
    param ( 
        [string] $filename 
    )
    
    $matches = $env:Path.Split(';') | %{ join-path $_ $filename} | ?{ test-path $_ }
    
    if ($matches.Length -eq 0){ 
        $null
    } else { 
        $matches 
    }
}

function Coalesce($a, $b) { if ($a -ne $null) { $a } else { $b } }

function GetAzureCmdPath() {
    FindInPath "azure.cmd"
}
function GetAzureLibPath(){
	$azureCmdPath = GetAzureCmdPath
    $azurecliLibPath = $azureCmdPath | Split-Path | Join-Path -ChildPath "node_modules\azure-cli\lib"
	if(-not (Test-Path $azurecliLibPath)) {
		$azurecliLibPath = $azureCmdPath | Split-Path | Join-Path -ChildPath "..\lib"
	}
    if(Test-Path $azurecliLibPath) {
        $azurecliLibPath
    }
}