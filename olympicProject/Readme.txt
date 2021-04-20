#####################################################
# Copright SIOS Technology Corp 2021 
BuildDate: 15Apr2021

Contents:
====================================================
New-SPSWResource.ps1

#####################################################

This script can be used for creating a working LifeKeeper cluster with an IP resource protected. There are certain prerequisite for running this script which are given below:
    - Two windows machines each with 2 or more nics.
    - LifeKeeper should be installed on both machines, along with requisite licences
    - Both machines are able to communicate with each other.
    - PowerShell is installed on both and a remote session(Enable-PSRemoting) is enabled on the systems.
    - If systems are in AWS Cloud then AWS CLI needs to be installed and pre-configured with AWS credentials.
    - Get the GUIDs for the machines as it’s required for setting up VIP resources. Follow the steps given below to get GUIDs on both machines: run getmac.exe
	
Administrator@AG-WIN-4 /cygdrive/c/LK/Bin$ getmac.exe

            Physical Address       Transport Name
            =============        ===============================================
            06-B1-A3-41-B3-83    \Device\Tcpip_{83DAA390-BF79-4A61-98D4-FA0C98A0BEA2}
            06-34-E1-4D-9B-7B   \Device\Tcpip_{85B529FE-B405-4995-9DB6-4527178DF4BF}
            06-81-1F-92-29-09     \Device\Tcpip_{B05DE617-1AB4-4882-B9F0-A36E0DA09995}


            Capture the Transport Name e.g. the highlighted part shown below:
                \Device\Tcpip_{BA8E70DC-BB4A-4A80-B3B6-1113C34D6CE2}
	
Execute the following script to setup comm paths, Virtual IP and AWS ECC resource - 

.\New-SPSWResource.ps1 
    -Nodes AG-WIN-4,AG-WIN-5 
    -AWSNode 1
    -CommPath1IPs '12.0.3.132','12.0.3.62' 
    -CommPath2IPs '12.0.3.240','12.0.3.72' 
    -VIP '10.1.0.200' 
    -VIPNetMask '255.255.255.0' 
    -LogFile 'C:\LK\Support\log.txt' 
    -DeviceGUIDs B05DE617-1AB4-4882-B9F0-A36E0DA09995,5C2DE1A1-1A7C-4987-83AB-19E164C8BC99 
