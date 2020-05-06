# LabBuilder
These are two PowerShell scripts to run in sequence to speed up the deployment of Hyper-V and some VM shells on a blank machine. It was originally intended to be used to spin up the base of a nested virtualization hypervisor on Azure Labs, but can be repurposed for other needs to reduce time on keyboard.

1. Extract the two .ps1 files on your desktop.
2. Run virtual_environment_builder.ps1 to install Hyper-V and restart.
3. After reboot, run virtual_environment_builder2.ps1 to install virtual switches, adapters and VM shells (sorry, the auto-continue from the runonce registry key currently looks broken, and it's hardcoded for a specific user. Sorry.)
