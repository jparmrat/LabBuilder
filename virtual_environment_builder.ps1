#Author: Josh Parmely
#First publish: 20200505
#Last edit date:20200505

#Install Hyper-V
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools

#Set second script to run on reboot (runonce regkey)
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name 'VMENV_Setup' -Value "C:\windows\System32\WindowsPowershell\v1.0\powershell.exe -noexit -executionpolicy bypass -file 'C:\Users\students\Desktop\virtual_environment_builder2.ps1'"

Restart-Computer

