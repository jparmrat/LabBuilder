#Author: Josh Parmely
#First publish: 20200505
#Last edit date:20200505

workflow Resume_Workflow
{
#Install Hyper-V
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart -Wait


#Create external switch
$adapter = Get-CimInstance -class win32_networkadapter -property netconnectionid |where-object {$_.NetconnectionID -match "ethernet" } | select-object -property NetconnectionId -ExpandProperty NetConnectionID
New-VMSwitch -name ExternalSwitch  -NetAdapterName $adapter -AllowManagementOS $true

#Create new VMs
New-VM -Name "DC 1" -MemoryStartupBytes 3GB -BootDevice VHD -NewVHDPath .\VMs\DC1.vhdx -NewVHDSizeBytes 64GB -Path .\VMData -Generation 2 -Switch ExternalSwitch
New-VM -Name "DC 2" -MemoryStartupBytes 3GB -BootDevice VHD -NewVHDPath .\VMs\DC2.vhdx -NewVHDSizeBytes 64GB -Path .\VMData -Generation 2 -Switch ExternalSwitch
New-VM -Name "IPAM" -MemoryStartupBytes 3GB -BootDevice VHD -NewVHDPath .\VMs\IPAM.vhdx -NewVHDSizeBytes 64GB -Path .\VMData -Generation 2 -Switch ExternalSwitch
New-VM -Name "Client" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath .\VMs\Client.vhdx -NewVHDSizeBytes 64GB -Path .\VMData -Generation 2 -Switch ExternalSwitch

#Set dynamic memory
Set-VM -Name "DC 1" -DynamicMemory -MemoryMaximumBytes 3GB
Set-VM -Name "DC 2" -DynamicMemory -MemoryMaximumBytes 3GB
Set-VM -Name "IPAM" -DynamicMemory -MemoryMaximumBytes 3GB
Set-VM -Name "Client" -DynamicMemory -MemoryMaximumBytes 2GB

#Build internal switch and NAT
New-VMSwitch -Name "InternalNAT" -SwitchType Internal
$ifindex = get-netadapter |where-object {$_.name -eq "Internal"} | select-object -property ifIndex -expandproperty ifIndex
New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $ifindex
New-NetNat -Name "InternalNat" -InternalIPInterfaceAddressPrefix 192.168.0.0/24
Get-VM -All | Set-VMNetworkAdapter InternalNat

#Set VMs to use NAT network
Set-VMNetworkAdapter -vmname "DC 1" -name "InternalNat"
Set-VMNetworkAdapter -vmname "IPAM" -name "InternalNat"
Set-VMNetworkAdapter -vmname "DC 2" -name "InternalNat"
Set-VMNetworkAdapter -vmname "Client" -name "InternalNat"

#Create firewall rule for ICMP on host machine
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow


}
# Create the scheduled job properties. Syntax repurposed from https://stackoverflow.com/questions/15166839/powershell-reboot-and-continue-script
$options = New-ScheduledJobOption -RunElevated -ContinueIfGoingOnBattery -StartIfOnBattery
$secpasswd = ConvertTo-SecureString "Password1!" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential (".\Administrator", $secpasswd)
$AtStartup = New-JobTrigger -AtStartup

# Register the scheduled job
Register-ScheduledJob -Name Resume_Workflow_Job -Trigger $AtStartup -ScriptBlock ({[System.Management.Automation.Remoting.PSSessionConfigurationData]::IsServerManager = $true; Import-Module PSWorkflow; Resume-Job -Name new_resume_workflow_job -Wait}) -ScheduledJobOption $options
# Execute the workflow as a new job
Resume_Workflow -AsJob -JobName new_resume_workflow_job

#Install Chrome
$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)

#Post-script TO-DOs for the user, for those reading:
#Download eval copies of 2019 DC and Windows 10
#Add a SCSI DVD drive, mount the ISO, set the firmware to boot from optical
#Install OSes on their respective VMs
#Add ICMP rules on VMs
#Test for network connectivity
#Publish template
