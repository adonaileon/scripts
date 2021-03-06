     
<#
 Name: RemoteDesktop
 Date Created: 28 JUN 2018
 Last Modified: 03 FEB 2019
 Version 1.1

 www.github.com/carybdea
#>

function Get-RDPstatus {
    <#
        .SYNOPSIS
            Show Remote Desktop access status.

        .DESCRIPTION
            Enable registry key to allow remote access..
            (HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server)
        
        .EXAMPLE
            Get-RDPStatus -ComputerName HOSTNAME
            -----------
            Remote Desktop is disabled on HOSTNAME     
    #>
    
    Param( 
        [Parameter()][string]$ComputerName = $env:COMPUTERNAME
    )

    $Hive = [Microsoft.Win32.RegistryHive]::LocalMachine
    $KeyPath = 'SYSTEM\CurrentControlSet\Control\Terminal Server'
    if (!(Test-Connection $ComputerName)){ Write-Warning "$ComputerName is unreachable." }
    else{
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $ComputerName)
        if ($reg.OpenSubKey($KeyPath)){
            $key = $reg.OpenSubKey($KeyPath,$true)
            if($key.GetValue("fDenyTSConnections") -eq "0"){
                Write-Host Remote Desktop is enabled on $ComputerName
            }else{
                Write-Host Remote Desktop is disabled on $ComputerName
            }
            
         
        }
    }
}

function Enable-RDP {
    <#
        .SYNOPSIS
            Enable remote access.

        .DESCRIPTION
            Set registry key to 0 to allow remote access.
            (HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server)
      
        .EXAMPLE
            Enable-RDP -ComputerName HOSTNAME
            -----------
            Remote Desktop is now enabled on HOSTNAME 
    #>
    
    Param( 
        [Parameter()][string]$ComputerName = $env:COMPUTERNAME
    )
    
    $Hive = [Microsoft.Win32.RegistryHive]::LocalMachine
    $KeyPath = 'SYSTEM\CurrentControlSet\Control\Terminal Server'
    if (!(Test-Connection $ComputerName)){ Write-Warning "$ComputerName is unreachable." }
    else{
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $ComputerName)
        if ($reg.OpenSubKey($KeyPath)){
            $key = $reg.OpenSubKey($KeyPath,$true)
            $key.SetValue("fDenyTSConnections",0,[Microsoft.Win32.RegistryValueKind]::DWord)
            if($key.GetValue("fDenyTSConnections") -eq "0"){
                Write-Host Remote Desktop is now enabled on $ComputerName
            }
        }
    }
}

function Disable-RDP {
    <#
        .SYNOPSIS
            Disable remote access.

        .DESCRIPTION
            Set registry key to 1 to block remote access.
            (HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server)
      
        .EXAMPLE
            Disable-RDP -ComputerName HOSTNAME
            -----------
            Remote Desktop is now disabled on HOSTNAME      
    #>
    
    Param( 
        [Parameter()][string]$ComputerName = $env:COMPUTERNAME
    )

    $Hive = [Microsoft.Win32.RegistryHive]::LocalMachine
    $KeyPath = 'SYSTEM\CurrentControlSet\Control\Terminal Server'
    if (!(Test-Connection $ComputerName)){ Write-Warning "$ComputerName is unreachable." }
    else{
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $ComputerName)
        if ($reg.OpenSubKey($KeyPath)){
            $key = $reg.OpenSubKey($KeyPath,$true)
            $key.SetValue("fDenyTSConnections",1,[Microsoft.Win32.RegistryValueKind]::DWord) 
            if($key.GetValue("fDenyTSConnections") -eq "1"){
                Write-Host Remote Desktop is now disabled on $ComputerName
            }
        }
    }
}

function Get-RDPGroup {
    <#
        .DESCRIPTION
            Get the name of the local group "Remote Desktop Users.            
    #>
    
    Param( 
        [Parameter()][string]$ComputerName
    )        
        
    if((Get-Culture).name -like "fr*"){
        $RDPGroup = [ADSI]"WinNT://$ComputerName/Utilisateurs du Bureau à distance,group"
    }elseif ((Get-Culture).name -eq "de*"){
        $RDPGroup = [ADSI]"WinNT://$ComputerName/Remotedesktopbenutzer,group"
    }else{
        $RDPGroup = [ADSI]"WinNT://$ComputerName/Remote Desktop Users,group"
    }
    
    return $RDPGroup
}

function Get-RDPUsers {
    <#
        .SYNOPSIS
            Get the members of "Remote Desktop Users" local group.

        .DESCRIPTION
            Get the members of "Remote Desktop Users" local group.
      
        .EXAMPLE
            Get-RDPUsers -ComputerName HOSTNAME
    #>
    
    Param( 
        [Parameter()][string]$ComputerName = $env:COMPUTERNAME
    )
    
    $RDPGroup = Get-RDPGroup -ComputerName $ComputerName    
    $list = ($RDPGroup).Members() | foreach {$_.GetType().InvokeMember("ADSpath", 'GetProperty', $null, $_, $null) } 
    if ($list){
        Write-Host $list
    }else{
        Write-Host '"Remote Desktop Users" local group on' $ComputerName 'is empty.' 
    }
}

function Add-RDPUser {
    <#
        .SYNOPSIS
            Add a a member to "Remote Desktop Users" local group.

        .DESCRIPTION
            Add a a member to "Remote Desktop Users" local group.
      
        .EXAMPLE
            add-RDPUser -Computername HOSTNAME -UserName USER -DomainName DOMAIN
            -----------
            Adding  USER  to "Remote Desktop Users" group...       
    #>
    
    Param( 
        [Parameter()][string]$ComputerName = $env:COMPUTERNAME,
        [Parameter(mandatory=$true)][string]$UserName,
        [Parameter(mandatory=$true)][string]$DomainName
    )
    
    
    $User = [ADSI]"WinNT://$DomainName/$UserName,user"
    $RDPGroup = Get-RDPGroup -ComputerName $ComputerName
    Write-Host 'Adding '$username ' to "Remote Desktop Users" group...'
    ($RDPGroup).Add($User.Path)
    Write-Host ' '         
}


function Remove-RDPUser {
    <#
        .SYNOPSIS
            Remove a member from "Remote Desktop Users" local group.

        .DESCRIPTION
            Remove a member from "Remote Desktop Users" local group.
      
        .EXAMPLE
            Remove-RDPUser -Computername HOSTNAME -UserName USER -DomainName DOMAIN
            -----------
            Removing USER from "Remote Desktop Users" group...       
    #>
    
    Param( 
        [Parameter()][string]$ComputerName = $env:COMPUTERNAME,
        [Parameter(mandatory=$true)][string]$UserName,
        [Parameter(mandatory=$true)][string]$DomainName
    )
    
    $User = [ADSI]"WinNT://$DomainName/$UserName,user"
    $RDPGroup = Get-RDPGroup -ComputerName $ComputerName
    Write-Host 'Removing ' $username ' from "Remote Desktop Users" group...'
    ($RDPGroup).Remove($User.Path)
    Write-Host ' '
}

Export-ModuleMember -Function Get-RDPstatus,Enable-RDP, Disable-RDP, Get-RDPUsers, Add-RDPUser, Remove-RDPUser
