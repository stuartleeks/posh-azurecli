# This PS script replicates the functionality in https://github.com/Azure/azure-xplat-cli/blob/90a20ee00e0741a5ec8cece69bf5e18bf1e0ecda/lib/autocomplete.js
# An alternative approach would be to look at ways to directly invoke the functionality and capture the output :-)
# This has a dependency on plugins json files (Use "azure --gen" to create)  
$installPath = Split-Path $MyInvocation.MyCommand.Path
. "$installPath\utils.ps1"

function AzureCliExpansion($line) {
	# TODO - error handling (e.g. azure.cmd not found, plugins.xxx.json not found)
	
	$azureCmdPath = GetAzureCmdPath
	$azurecliLibPath = GetAzureLibPath
	
	# Based on https://github.com/Azure/azure-xplat-cli/blob/90a20ee00e0741a5ec8cece69bf5e18bf1e0ecda/lib/util/utilsCore.js#L77
	$config = Get-Content "~/.azure/config.json" | ConvertFrom-Json
	$mode = $config.mode
	
	# Based on https://github.com/Azure/azure-xplat-cli/blob/90a20ee00e0741a5ec8cece69bf5e18bf1e0ecda/lib/autocomplete.js#L26
	$datafile = "$azurecliLibPath/plugins.$mode.json"
	$plugins = Get-Content $datafile | ConvertFrom-Json
	
	# Based on https://github.com/Azure/azure-xplat-cli/blob/90a20ee00e0741a5ec8cece69bf5e18bf1e0ecda/lib/autocomplete.js#L49
	$args = $line.Split(' ') | ?{ $_ -ne ''} | %{ $_.Trim() }
	
	# start from 1, so to discard "azure" word
	$currentCategory = $plugins;
	for ($index = 1; $index -lt $args.Length; $index++){
		$arg = $args[$index]
		$parentCategory = $currentCategory
		$currentCategory = $currentCategory.categories.psobject.Properties[$arg].Value
		if( $currentCategory -eq $null){
			break
		}
	}
	
	$tempCategory = Coalesce $currentCategory $parentCategory
	$allSubCategoriesAndCommands = @($tempCategory.categories.PSObject.Properties | select -ExpandProperty Name) `
						+ @($tempCategory.commands | select -ExpandProperty Name)
	
	$currentCommand = $tempCategory.commands | where Name -eq $arg | select -First 1
	
	
	# run out argument while have a valid category?
	if ($currentCategory -ne $null) {
		#return sub categories and command combind
		return $allSubCategoriesAndCommands
	}
	
	if ($currentCommand -ne $null) {
		$allCommandOptions = @($currentCommand.options | select -ExpandProperty long) `
								+ @($currentCommand.options | select -ExpandProperty short -ErrorAction SilentlyContinue) # silent continue to ignore options without short property
	}
	
	# we are at the last arg, try match both categories and commands
	if ($index -eq $args.Length -1) {
		if ($currentCommand -ne $null) {
			return $allCommandOptions
		} else {
			return $allSubCategoriesAndCommands | ?{ $_.StartsWith($arg) }
		}
	}
	
	# try to match a command's options
	$lastArg = $args[$args.Length - 1]
	if( ($currentCommand -ne $null) -and ($lastArg.StartsWith('-') ) ) {
		$option = $currentCommand.options | ?{ $_.fileRelatedOption -and ($_.short -eq $lastArg -or $_.long -eq $lastArg ) } | select -First 1
		
		if ($option -ne $null) {
			# return this.reply(fs.readdirSync(process.cwd()));
			# Default PS behaviour is to complete files :-)
		} else {
			return $allCommandOptions | ?{ $_.StartsWith($lastArg) }
		}
	}
}


# TODO - look at posh-git/posh-hg to link with powertab
if(-not (Test-Path Function:\AzureCliTabExpansionBackup)){

    if (Test-Path Function:\TabExpansion) {
        Rename-Item Function:\TabExpansion AzureCliTabExpansionBackup
    }

    function TabExpansion($line, $lastWord) {
       $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

       switch -Regex ($lastBlock) {
            "^azure (.*)" { AzureCliExpansion $lastBlock }

            # Fall back on existing tab expansion
            default { if (Test-Path Function:\AzureCliTabExpansionBackup) { AzureCliTabExpansionBackup $line $lastWord } }
       }
    }
}