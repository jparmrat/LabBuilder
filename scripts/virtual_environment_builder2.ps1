#Author: Josh Parmely
#First publish: 20200505
#Last edit date:20200505

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

#Set VMs to use NAT network
Connect-VMNetworkAdapter -vmname "DC 1" -switchname "InternalNAT"
Connect-VMNetworkAdapter -vmname "IPAM" -switchname "InternalNAT"
Connect-VMNetworkAdapter -vmname "DC 2" -switchname "InternalNAT"
Connect-VMNetworkAdapter -vmname "Client" -switchname "InternalNAT"

#Create firewall rule for ICMP on host machine
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow

#Install Chrome
$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)

#Post-script TO-DOs for the user, for those reading:
#Download eval copies of 2019 DC and Windows 10
#Add a SCSI DVD drive, mount the ISO, set the firmware to boot from optical
#Install OSes on their respective VMs
#Add ICMP rules on VMs
#Test for network connectivity
#Publish template
