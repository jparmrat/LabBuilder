#Author: Josh Parmely
#First publish: 20200505
#Last edit date:20200505

#Install Hyper-V
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart

#Set second script to run on reboot (runonce regkey)
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name '!VMENV_Setup' -Value "powershell.exe -noexit -executionpolicy bypass -file 'C:\Users\students\Desktop\virtual_environment_builder2.ps1'"



