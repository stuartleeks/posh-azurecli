# clean choco cache
dir $env:ProgramData\chocolatey\lib\posh-azurecli* | Remove-Item -Recurse -Force
# install choco package from local dir
choco install posh-azurecli -source "$pwd" -pre -force