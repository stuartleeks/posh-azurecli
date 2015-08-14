# posh-azurecli
Provides tab completion for [azure cli](https://azure.microsoft.com/en-us/documentation/articles/xplat-cli/) commands in PowerShell

Inspired by [posh-git](https://github.com/dahlbyk/posh-git)


## Installation etc
Ensure that you have [chocolatey](https://chocolatey.org/) installed.


To install milestone drops:
N.B - waiting on chocolatey moderation (2015-08-14)
```
    choco install posh-azurecli
```

There is also a [non-milestone feed](https://www.myget.org/F/posh-azurecli/api/v2) now up on MyGet. 
To install these interim drops use:

```
    choco install posh-azurecli -source 'https://www.myget.org/F/posh-azurecli/api/v2'
```

## Release Notes

### 0.1.2 
Released to non-milestone feed: 14th August 2015
* Provide command completion for initial command
* Sort command completion results
* Add caching of parsed command metadata
 
### 0.1.1
Released to non-milestone feed: 14th August 2015
* Basic functionality
