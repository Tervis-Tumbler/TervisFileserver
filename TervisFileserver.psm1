﻿#$ModulePath = (Get-Module -ListAvailable TervisFileserver).ModuleBase
#. $ModulePath\TervisFileserverDefinitions.ps1

$ModulePath = Split-Path -parent $MyInvocation.MyCommand.Path
. $ModulePath\TervisFileserverDefinitions.ps1

$ExplorerFavoritesShortcutDefinition = [PSCustomObject][Ordered]@{
        Name = "Applications"
        Target = "\\tervis.prv\Applications"
    },
    [PSCustomObject][Ordered]@{
        Name = "Departments"
        Target = "\\tervis.prv\departments"
    },
    [PSCustomObject][Ordered]@{
        Name = "Creative"
        Target = "\\tervis.prv\Creative"
    }

function Get-ExplorerFavoritesShortcutDefinition {
    param(
        $Name
    )
    if ($name){
        $ExplorerFavoritesShortcutDefinition | where Name -like $Name
    }
    else {$ExplorerFavoritesShortcutDefinition}
}

function Get-UserProfilesOnComputer {
    param(
        [Parameter(Mandatory)]$Computer,
        $Username = "*"

    )
    $AllProfilesonSystem = gwmi -ComputerName $Computer win32_userprofile | select localpath -ExpandProperty localpath
    $UserProfileExceptions = "localservice","systemprofile","defaultapppool","NetworkService",".NET v4.5 Classic",".NET v4.5"
    $AllUserProfilesWithoutExceptions = $AllProfilesonSystem |  Where {$UserProfileExceptions -notcontains (Split-Path -Leaf $_)}
    
    if ($Username){
        $UserProfiles = $AllUserProfilesWithoutExceptions | where {$_ -like "*$Username"}
    }
    Else{
        $UserProfiles = $AllUserProfilesWithoutExceptions
    }
    $AllUserProfiles = $UserProfiles | % {
        [PSCustomObject][Ordered]@{
            UserProfileName = $_ | select localpath -ExpandProperty localpath | Split-Path -Leaf
            UserProfilePath = $_ | select localpath -ExpandProperty localpath | Split-Path -NoQualifier
        }
    }
    $AllUserProfiles
}

function Push-TervisExplorerFavoritesOrQuickAccess {
    param(
        [Parameter(ParameterSetName="PushFavoritesbyOU",Mandatory)]
        $ComputerOrganizationalUnit,

        [Parameter(ParameterSetName="PushFavoritesbyComputer",Mandatory)]
        $ComputerName,

        [Parameter(ParameterSetName="PushFavoritesbyComputer")]
        $UserName = "*",

        [Parameter(ParameterSetName="PushFavoritesbyOU")]
        [Parameter(ParameterSetName="PushFavoritesbyComputer")]
        $Name = "*"
    )
    if ($ComputerOrganizationalUnit){
        $ComputerList = Get-ComputersWithinOU -OrganizationalUnit "OU=Departments,DC=tervis,DC=prv" -Online | where {$_.distinguishedname -NotLike "*Remote Store Computers*" -and $_.distinguishedname -NotLike "*Welder Stations*"} | select Name -ExpandProperty Name
#        $ComputerList = Get-ComputersWithinOU -OrganizationalUnit $ComputerOrganizationalUnit -Online | where {$_.distinguishedname -NotLike "*Remote Store Computers*" -and $_.distinguishedname -NotLike "*Welder Stations*"}
#        $ComputerList = Get-ADComputer -Filter 'name -eq "dmohlmaster2012"' -SearchBase "OU=Computers,OU=Information Technology,OU=Departments,DC=tervis,DC=prv" | select dnshostname -ExpandProperty dnshostname
    }
    else{
        $ComputerList = $ComputerName
    }

    $ExplorerFavoritesDefinition = Get-ExplorerFavoritesShortcutDefinition -Name $Name
    
    foreach ($ComputerName in $ComputerList){
        $PowershellScript = ""
        if ( -not ($WindowsVersion = invoke-command -ComputerName $ComputerName -ScriptBlock {[Environment]::OSVersion.Version.Major} -ErrorAction SilentlyContinue)){
 #           [pscustomobject][ordered]@{
 #               Name = $ComputerName
 #               Status = "Failed - Version $WindowsVersion"
 #           }
        Continue
        }

        if ($WindowsVersion -lt 10){
            $UserProfiles = Get-UserProfilesOnComputer -Computer $ComputerName -Username $UserName
            foreach ($Profile in $UserProfiles){
                $LinksFolderPath = "\\$ComputerName\c$\$($Profile.UserProfilePath)\Links"
                if(-not (Test-Path $LinksFolderPath -PathType Container)){
                    Continue
                }
                foreach ($Favorite in $ExplorerFavoritesDefinition){
                    if($WindowsVersion -lt 10){
                        if($Favorite.Delete -and (Test-Path -Path "$LinksFolderPath\$($Favorite.Name).lnk")){
                            Remove-Item -Path "$LinksFolderPath\$($Favorite.Name).lnk" -Force
                        }
                        Else{
                            Set-Shortcut -LinkPath "$LinksFolderPath\$($Favorite.Name).lnk" -IconLocation "c:\windows\system32\SHELL32.dll,42" -TargetPath $Favorite.Target
                        }
                    }
                }
            }
        }

        if ($WindowsVersion -ge 10){
            $ExplorerFavoritesDefinition | %{
                if($_.Delete -ne $True){
                    $PowershellScript += "(new-object -com shell.application).Namespace(`"$($_.Target)`").Self.InvokeVerb(`"pintohome`")`n"
                }
            }
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($PowershellScript)
                if(-not (Test-Path c:\scripts)){New-Item -Path c:\ -Name Scripts -ItemType Directory}
                $PowershellScript | Out-File C:\Scripts\ExplorerFavorites.ps1
                New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name ExplorerFavorites -Value "Powershell -windowstyle hidden -File c:\Scripts\ExplorerFavorites.ps1" -PropertyType String -Force
            } -ArgumentList $PowershellScript
        }
        
    }
}

function Install-ExplorerFavoritesScheduledTasks {
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$ComputerName
    )
    begin {
        $ScheduledTaskCredential = New-Object System.Management.Automation.PSCredential (Get-PasswordstatePassword -AsCredential -ID 259)
        $Execute = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
        $Argument = '-NoProfile -Command Push-TervisExplorerFavoritesOrQuickAccess -ComputerOrganizationalUnit "OU=Departments,DC=tervis,DC=prv" > c:\schedoutput\PushExplorerFavorites.log'
    }
    process {
        $CimSession = New-CimSession -ComputerName $ComputerName
        If (Get-ScheduledTask -TaskName PushExplorerFavorites -CimSession $CimSession -ErrorAction SilentlyContinue) {
            Uninstall-TervisScheduledTask -TaskName PushExplorerFavorites -ComputerName $ComputerName -Force
        }
        Install-TervisScheduledTask -Credential $ScheduledTaskCredential -TaskName PushExplorerFavorites -Execute $Execute -Argument $Argument -RepetitionIntervalName EverWorkdayDuringTheDayEvery15Minutes -ComputerName $ComputerName

#        If (-NOT (Get-ScheduledTask -TaskName PushExplorerFavorites -CimSession $CimSession -ErrorAction SilentlyContinue)) {
#            Install-TervisScheduledTask -Credential $ScheduledTaskCredential -TaskName PushExplorerFavorites -Execute $Execute -Argument $Argument -RepetitionIntervalName EverWorkdayDuringTheDayEvery15Minutes -ComputerName $ComputerName
#        }
    }
}

function Get-ComputersWithinOU{
    param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$OrganizationalUnit,
        [Switch]$Online
    )

    $Computers = Get-ADComputer -Filter * -SearchBase $OrganizationalUnit
    

    $Responses = Start-ParallelWork -ScriptBlock {
        param($Parameter)
        [pscustomobject][ordered]@{
            Name = $Parameter.Name;
            DistinguishedName = $Parameter.DistinguishedName
            Online = $(Test-Connection -ComputerName $Parameter.Name -Count 1 -Quiet);        
        }
    } -Parameters $Computers

    if ($Online) {
        $Responses | where Online -EQ $true
    } else {
        $Responses
    }
}

function Test-TervisExplorerFavoritesOrQuickAccess {
    param(
        [Parameter(ParameterSetName="TestFavoritesbyOU",Mandatory)]
        $ComputerOrganizationalUnit,

        [Parameter(ParameterSetName="TestFavoritesbyComputer",Mandatory)]
        $ComputerName,

        [Parameter(ParameterSetName="PushFavoritesbyOU")]
        [Parameter(ParameterSetName="PushFavoritesbyComputer")]
        $Name = "*"
    )
    $FavoritesStateWin7 = @()
    $FavoritesStateWin10 = @()
    if ($ComputerOrganizationalUnit){
        $ComputerList = Get-ComputersWithinOU -OrganizationalUnit $ComputerOrganizationalUnit -Online | select Name -ExpandProperty Name
    }
    else{
        $ComputerList = $ComputerName
    }

    $ExplorerFavoritesDefinition = Get-ExplorerFavoritesShortcutDefinition -Name $Name
    $PowershellScript = ""
    
    foreach ($ComputerName in $ComputerList){
        if (-not ($WindowsVersion = invoke-command -ComputerName $ComputerName -ScriptBlock {[Environment]::OSVersion.Version.Major} -ErrorAction SilentlyContinue)){
            Continue
        }
        if ($WindowsVersion -lt 10){
            $State = $true
            $UserProfiles = Get-UserProfilesOnComputer -Computer $ComputerName -Username $UserName
            $Profile = $UserProfiles | where {$ComputerName -match (($_.userprofilename -split "-")[0])}
                foreach ($Favorite in $ExplorerFavoritesDefinition){
                    if($WindowsVersion -lt 10){
                        $LinksFolderPath = "\\$ComputerName\c$\$($Profile.UserProfilePath)\Links"
                        if($Favorite.Delete){
                            $LinkExists = Test-Path -Path "$($LinksFolderPath)\$($Favorite.name).lnk"
                            if ($LinkExists -eq $true){
                                $State -eq $false
                                Break
                            }
                        }
                        Else{
                            $LinkExists = Test-Path -Path "$($LinksFolderPath)\$($Favorite.name).lnk"
                            if ($LinkExists -eq $false){
                                $State = $false
                                Break
                            }
                        }
                    }
                }
                if ($State -eq $false){
                    $FavoritesStateWin7 += [PSCustomObject][Ordered]@{
                        Computer = $ComputerName
                        WindowsVersion = $WindowsVersion
                        Profile = $Profile.UserProfileName
                        Compliant = $State
                    }
                }
        }

        if ($WindowsVersion -ge 10){
            $output = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Test-Path c:\scripts\ExplorerFavorites.ps1}
            if ($Output -eq $false){
                $State = $false
            }
            if ($State -eq $false){
                $FavoritesStateWin10 += [PSCustomObject][Ordered]@{
                    Computer = $ComputerName
                    WindowsVersion = $WindowsVersion
                    Profile = "-"
                    Compliant = $State
                }
            }
        }
    }
    $FavoritesStateWin7
    $FavoritesStateWin10
}

function Get-MappedDrives {
    param(
        [Parameter(Mandatory,ValueFromPipeline)] $ComputerName
    )
    Process{
        Start-ParallelWork -ScriptBlock {
            param($ComputerName)
            if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet){
                #Get remote explorer session to identify current user
                $explorer = Get-WmiObject -ComputerName $ComputerName -Class win32_process -ErrorAction SilentlyContinue | ?{$_.name -eq "explorer.exe"}
                
                #If a session was returned check HKEY_USERS for Network drives under their SID
                if($explorer){
                    $Hive = [long]$HIVE_HKU = 2147483651
                    $sid = ($explorer.GetOwnerSid()).sid
                    $owner  = $explorer.GetOwner()
                    $RegProv = get-WmiObject -List -Namespace "root\default" -ComputerName $ComputerName | Where-Object {$_.Name -eq "StdRegProv"}
                    $DriveList = $RegProv.EnumKey($Hive, "$($sid)\Network")
                    $DriveMappings = @()
        
                    #If the SID network has mapped drives iterate and report on said drives
                    if($DriveList.sNames.count -gt 0){
                        foreach($drive in $DriveList.sNames){
                            $DriveMappings += [PSCustomObject][Ordered]@{
                                DriveLetter = $($drive)
                                Target = $(($RegProv.GetStringValue($Hive, "$($sid)\Network\$($drive)", "RemotePath")).sValue)
                            }
                        }
                    }
                    else{$DriveMappings = "None"}
                }
                else{$DriveMappings = "WMI Error"}
            }
            else{$DriveMappings = "Cannot Connect"}
    
            [PSCustomObject][Ordered]@{
                ComputerName = $($ComputerName)
                User = "$($owner.Domain)\$($owner.user)"
                DriveMappings = $DriveMappings
            }
        } -Parameters $ComputerName
        
    }
}

function Invoke-PushTervisExplorerFavoritesOrQuickAccessToNewEndpoint {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]$ComputerName
    )
    if(-not (Test-Path "\\$ComputerName\c$\users\default\links" -PathType Container)){
        New-Item -Path "\\$ComputerName\c$\users\default" -Name "Links" -ItemType Directory
    }
    Set-Shortcut -LinkPath "\\$computername\c$\users\default\Links\Departments.lnk" -IconLocation "c:\windows\system32\SHELL32.dll,42" -TargetPath "\\tervis.prv\Departments"
    Set-Shortcut -LinkPath "\\$computername\c$\users\default\Links\Applications.lnk" -IconLocation "c:\windows\system32\SHELL32.dll,42" -TargetPath "\\tervis.prv\Applications"
    Set-Shortcut -LinkPath "\\$ComputerName\c$\users\default\Links\Creative.lnk" -IconLocation "c:\windows\system32\SHELL32.dll,42" -TargetPath "\\tervis.prv\Creative"

    $ExplorerQuickAccessScript = @"
if(-not (Test-Path "`$env:USERPROFILE\links" -PathType Container)){
    New-Item -Path "`$env:USERPROFILE" -Name "Links" -ItemType Directory
}
Copy-Item -Path "C:\users\Default\Links\*" -Destination "`$env:USERPROFILE\Links" -Force
(new-object -com shell.application).Namespace(`"\\tervis.prv\Creative`").Self.InvokeVerb(`"pintohome`")
(new-object -com shell.application).Namespace(`"\\tervis.prv\Applications`").Self.InvokeVerb(`"pintohome`")
(new-object -com shell.application).Namespace(`"\\tervis.prv\Departments`").Self.InvokeVerb(`"pintohome`")
"@
    $ScriptPathRoot = "c:\programdata"
    $ScriptFolderName = "Tervis"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        if(-not (Test-Path "$using:ScriptPathRoot\$using:ScriptFolderName" -PathType Container)){
            New-Item -Path $using:ScriptPathRoot -Name "Tervis" -ItemType Directory
        }
        $using:ExplorerQuickAccessScript | Out-File "$using:ScriptPathRoot\$using:ScriptFolderName\ExplorerQuickAccess.ps1" -Force
        & REG LOAD HKU\TEMP C:\Users\Default\NTUSER.DAT
        if (-not (Test-Path "Registry::HKEY_USERS\TEMP\Software\Microsoft\Windows\CurrentVersion\RunOnce")){
            New-Item -Path "Registry::HKEY_USERS\TEMP\Software\Microsoft\Windows\CurrentVersion" -Name "RunOnce"
        }
        New-ItemProperty -Path "Registry::HKEY_USERS\TEMP\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name ExplorerFavorites -Value "powershell.exe -noprofile -file $using:ScriptPathRoot\$using:ScriptFolderName\ExplorerQuickAccess.ps1" -PropertyType String -Force
        & reg unload HKU\TEMP
    }
}

Function Wait-Path {
    <#
    .SYNOPSIS
        Wait for a path to exist

    .DESCRIPTION
        Pulled from https://www.powershellgallery.com/packages/WFTools
        Wait for a path to exist

        Default behavior will throw an error if we time out waiting for the path
        Passthru behavior will return true or false
        Behaviors above apply to the set of paths; unless all paths test successfully, we error out or return false

    .PARAMETER Path
        Path(s) to test
    
        Note
            Each path is independently verified with Test-Path.
            This means you can pass in paths from other providers.

    .PARAMETER Timeout
        Time to wait before timing out, in seconds

    .PARAMETER Interval
        Time to wait between each test, in seconds

    .PARAMETER Passthru
        When specified, return true if we see all specified paths, otherwise return false

        Note:
            If this is specified and we time out, we return false.
            If this is not specified and we time out, we throw an error.

    .EXAMPLE
        Wait-Path \\Path\To\Share -Timeout 30

        # Wait for \\Path\To\Share to exist, test every 1 second (default), time out at 30 seconds.

    .EXAMPLE
        $TempFile = [System.IO.Path]::GetTempFileName()
    
        if ( Wait-Path -Path $TempFile -Interval .5 -passthru )
        {
            Set-Content -Path $TempFile -Value "Test!"
        }
        else
        {
            Throw "Could not find $TempFile"
        }

        # Create a temp file, wait until we can see that file, testing every .5 seconds, write data to it.

    .EXAMPLE
        Wait-Path C:\Test, HKLM:\System

        # Wait until C:\Test and HKLM:\System exist

    .FUNCTIONALITY
        PowerShell Language

    #>
    [cmdletbinding()]
    param (
        [string[]]$Path,
        [int]$Timeout = 5,
        [int]$Interval = 1,
        [switch]$Passthru
    )

    $StartDate = Get-Date
    $First = $True

    Do
    {
        #Only sleep if this isn't the first run
            if($First -eq $True)
            {
                $First = $False
            }
            else
            {
                Start-Sleep -Seconds $Interval
            }

        #Test paths and collect output
            [bool[]]$Tests = foreach($PathItem in $Path)
            {
                Try
                {
                    if(Test-Path $PathItem -ErrorAction stop)
                    {
                        Write-Verbose "'$PathItem' exists"
                        $True
                    }
                    else
                    {
                        Write-Verbose "Waiting for '$PathItem'"
                        $False
                    }
                }
                Catch
                {
                    Write-Error "Error testing path '$PathItem': $_"
                    $False
                }
            }

        # Identify whether we can see everything
            $Return = $Tests -notcontains $False -and $Tests -contains $True
        
        # Poor logic, but we break the Until here
            # Did we time out?
            # Error if we are not passing through
            if ( ((Get-Date) - $StartDate).TotalSeconds -gt $Timeout)
            {
                if( $Passthru )
                {
                    $False
                    break
                }
                else
                {
                    Throw "Timed out waiting for paths $($Path -join ", ")"
                }
            }
            elseif($Return)
            {
                if( $Passthru )
                {
                    $True
                }
                break
            }
    }
    Until( $False ) # We break out above

}

function Invoke-InfrastructurePathChecks{
        [CmdletBinding()]
    $FailedLinuxMounts = Test-LocalLinuxDirectoryHealthCheck
    $FailedNamespaces = Test-DFSNamespaceFolderHealth
    $FromAddress = "Mailerdaemon@tervis.com"
    $ToAddress = "SystemsTeam@tervis.com"
    $Subject = "***ACTION REQUIRED*** Mounpoint or Share Folder Failure"
    $Body = @"
<html><body>
<h2>The following Namespace folders or Linux Mountpoint checks failed</h2>
$(
    if($FailedLinuxMounts){
        $FailedLinuxMounts | ConvertTo-Html -As Table -Fragment
    }
    if($FailedNamespaces){
        $FailedNamespaces | ConvertTo-Html -As Table -Fragment
    }
)
</body></html>
"@
    if($FailedLinuxMounts -or $FailedNamespaces){
        Send-TervisMailMessage -From $FromAddress -To $ToAddress -Subject $Subject -Body $Body -BodyAsHTML
    }
}

function Test-DFSNamespaceFolderHealth {
    $DFSNRootFolders = Get-DfsnRoot -Domain tervis.prv
    $Timeout = 10
    foreach ($Folder in $DFSNRootFolders){
        $NamespaceShares = Get-DfsnFolder -Path "$($Folder.path)\*"
        foreach ($Share in $NamespaceShares.Path){
            if($Share -notlike "*\applications\MES\Helix\HotFolders*"){
                if((wait-path -Path $Share -Timeout $Timeout -Passthru) -eq $false){
                    [PSCustomObject]@{
                        Path = $Share
                        Status = "Timed Out"
                    }
                }
            }
        }
    }
}


function Test-LocalLinuxDirectoryHealthCheck {
    $LinuxServersToMonitor = `
"ebsdb-prd", `
"ebsapps-prd", `
"p-odbee02", `
"p-weblogic01", `
"p-weblogic02", `
"p-infadac"

    $PasswordstateCredential = New-Object System.Management.Automation.PSCredential (Get-PasswordstatePassword -AsCredential -ID 5574)
    ForEach($ComputerName in $LinuxServersToMonitor){
        if(-not (Get-SSHSession -ComputerName $ComputerName)){
            $SSHSession = New-SSHSession -ComputerName $ComputerName $PasswordstateCredential -AcceptKey
        }
        else{
            $SSHSession = Get-SSHSession -ComputerName $ComputerName
        }
        $RawFSTAB = (Invoke-SSHCommand -SSHSession $SSHSession -Command "sudo cat /etc/fstab").output -split "`r`n" | Where-Object {$_ -NotMatch "^#"}
        try{
            Invoke-SSHCommand -SSHSession (Get-SSHSession -ComputerName $($ComputerName)) -Command "df" -TimeOut 10 | Out-Null
        }
        catch{
            [PSCustomObject]@{
                Path = "df command execution"
                Computername = $ComputerName
                Status = "df execution timed out"
            }
        }
        foreach($Entry in $RawFSTAB){
            $Mountpoint = ($Entry -split "\s+")[1]
            $FilesystemType = ($Entry -split "\s+")[2]
            $WriteTestCommand = "sudo touch $($Mountpoint)/LocalFileSystemWriteTest"
            $DeleteTestCommand = "sudo rm -f $($Mountpoint)/LocalFileSystemWriteTest"
            if(((Invoke-SSHCommand -SSHSession (Get-SSHSession -ComputerName $($ComputerName)) -Command "mountpoint $($Mountpoint)").output) -ne "$($Mountpoint) is a mountpoint"){
                [PSCustomObject]@{
                    Path = $Mountpoint
                    Computername = $ComputerName
                    Status = "Not Mounted"
                }
                Continue
            }
            if($FilesystemType -eq "nfs"){
                try{
                    Invoke-SSHCommand -SSHSession (Get-SSHSession -ComputerName $($ComputerName)) -Command $WriteTestCommand -TimeOut 10 | Out-Null
                    Invoke-SSHCommand -SSHSession (Get-SSHSession -ComputerName $($ComputerName)) -Command $DeleteTestCommand -TimeOut 10 | Out-Null
                }
                catch{
                    [PSCustomObject]@{
                        Path = $Mountpoint
                        Computername = $ComputerName
                        Status = "Write Timed Out"
                    }
                }
            }
        }
    }
    Get-SSHSession | Remove-SSHSession | Out-Null
}

function Install-FileResourceMonitorPowershellApplication {
	param (
		$ComputerName
	)
    $ScheduledTaskCredential = New-Object System.Management.Automation.PSCredential (Get-PasswordstatePassword -AsCredential -ID 259)
    Install-PowerShellApplication -ComputerName $ComputerName `
        -EnvironmentName "Infrastructure" `
        -ModuleName "TervisFileServer" `
        -TervisModuleDependencies PasswordstatePowershell,TervisMicrosoft.PowerShell.Utility,TervisMailMessage `
        -PowerShellGalleryDependencies "Posh-SSH" `
        -ScheduledTasksCredential $ScheduledTaskCredential `
        -ScheduledTaskName "TervisFileShareMonitor" `
        -RepetitionIntervalName "EverWorkdayDuringTheDayEvery15Minutes" `
        -CommandString @"
Invoke-InfrastructurePathChecks
"@
}

function Get-TervisFileRetentionDefinition {
    param (
        [Parameter(Mandatory)]$ApplicationName
    )
    $FileRetentionDefinitions | where ApplicationName -eq $ApplicationName
}

function Invoke-DataRetentionPolicyEnforcement{
    [CmdletBinding(SupportsShouldProcess=$True)]
    param()

    Foreach($Location in $FileRetentionDefinitions){
#        $TimeSpan = New-TimeSpan -Days $Location.RetentionDays -Hours $Location.RetentionHours -Minutes $Location.RetentionMinutes -Seconds $Location.RetentionSeconds
        $OldestRetentionDate = (get-date) - $Location.RetentionTimeSpan

        Get-ChildItem -Path $Location.Path -File | where CreationTime -lt $OldestRetentionDate | Remove-Item -Force
    }
}

function Install-DataRetentionPolicyEnforcementPowershellApplication {
	param (
		$ComputerName
	)
    $ScheduledTaskCredential = New-Object System.Management.Automation.PSCredential (Get-PasswordstatePassword -AsCredential -ID 259)
    Install-PowerShellApplication -ComputerName $ComputerName `
        -EnvironmentName "Infrastructure" `
        -ModuleName "TervisFileServer" `
        -TervisModuleDependencies "TervisMicrosoft.PowerShell.Utility","TervisFileServer" `
        -ScheduledTasksCredential $ScheduledTaskCredential `
        -ScheduledTaskName "DataRetentionPolicyEnforcement" `
        -RepetitionIntervalName "EverWorkdayDuringTheDayEvery15Minutes" `
        -CommandString @"
Invoke-DataRetentionPolicyEnforcement
"@
}

function Invoke-ConfigureNewDFSReplicationGroup{
    param(
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$SourcePath,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$DestinationPath
    )
    process{
        $Domain = Get-ADDomain
        $DFSRoots = Get-DfsnRoot -Domain $Domain.DNSRoot | select path -ExpandProperty path
        $DestinationNamespace = $DFSRoots | where {$DestinationPath -like "$($_.path)*" }
        $DFSRGroupName = ($sourcepath.Split("\") | select -last 3) -join "_"
        $DFSRFolderName = ($sourcepath.Split("\") | select -last 1) -join "_"
        $DFSNamespaceFolders = (Get-DfsnFolder -Path "$DestinationNamespace\*").Path.Replace($Domain.NetBIOSName,$Domain.DNSRoot)
        $DFSReplicationGroups = Get-DfsReplicationGroup

        if($DFSReplicationGroups.GroupName -notcontains $DFSRGroupName){
            if($SourcePath -notlike "\\$($Domain.NetBIOSName)*"){
                $SourceComputerName = $SourcePath.Split("\")[2]
                $SourceShares = Get-WmiObject -Class Win32_Share -computer $SourceComputerName
                $SourceShare = $SourceShares | where {$SourcePath -match $_.name}
                $SourcePathSplit = $sourcepath.Split("\")
                $ShareSubPathPosition = $SourcePathSplit.IndexOf($SourceShare.Name)
                $SourceSubPath = $SourcePathSplit[($ShareSubPathPosition+1)..$SourcePathSplit.count] -join "\"
                $SourcePhysicalPath = "$($SourceShare.path)\$SourceSubPath"
            }
            else{
                $SourceDFSNAbsoluteSharePath = (((dfsutil diag viewdfspath $SourcePath) -split "[<>]") -match "[\\]")[-1]
                $SourceComputerName = $SourceDFSNAbsoluteSharePath.split("\")[2]
                $SourceDFSNamespaceFolderPath = $DFSNamespaceFolders | Where {$SourcePath -like "$_*"}
                $SourcePathSuffix = $SourcePath -iReplace [regex]::Escape($SourceDFSNamespaceFolderPath),""
                $SourceShares = Get-WmiObject -Class Win32_Share -computer $SourceComputerName
                $SourceShareDetail = $SourceShares | where {($SourcePath -Match ($_.name -replace ".$","")) -and ($_.Description -ne "Default share") -and ($($Sourcenamespace) -notlike "*$($_.Name)")  }
                $SourcePhysicalPath = "$($SourceShareDetail.Path)$SourcePathSuffix"
            }
            if($DestinationPath -notlike "\\$($Domain.NetBIOSName)*"){
                $SourceComputerName = $SourcePath.Split("\")[2]
                $DestinationShares = Get-WmiObject -Class Win32_Share -computer $DestinationComputerName
                $DestinationShare = $DestinationShares | where {$DestinationPath -match $_.name}
                $DestinationPathSplit = $Destinationpath.Split("\")
                $ShareSubPathPosition = $DestinationPathSplit.IndexOf($DestinationShare.Name)
                $DestinationSubPath = $DestinationPathSplit[($ShareSubPathPosition+1)..$DestinationPathSplit.count] -join "\"
                $DestinationPhysicalPath = "$($DestinationShare.path)\$DestinationSubPath"
            }
            else{
                $DestinationDFSNAbsoluteSharePath = (((dfsutil diag viewdfspath $destinationpath) -split "[<>]") -match "[\\]")[-1]
                $DestinationComputerName = $DestinationDFSNAbsoluteSharePath.split("\")[2]
                $DestinationDFSNamespaceFolderPath = $DFSNamespaceFolders | Where {$DestinationPath -like "$_*"}
                $DestinationPathSuffix = $DestinationPath -iReplace [regex]::Escape($DestinationDFSNamespaceFolderPath),""
                $DestinationShares = Get-WmiObject -Class Win32_Share -computer $DestinationComputerName
                $DestinationShareDetail = $DestinationShares | where {($DestinationPath -Match ($_.name -replace ".$","")) -and ($_.Description -ne "Default share") -and ($($Destinationnamespace) -notlike "*$($_.Name)")  }
                $DestinationPhysicalPath = "$($DestinationShareDetail.Path)$DestinationPathSuffix"
            }

            New-DfsReplicationGroup -GroupName $DFSRGroupName -DomainName $($Domain.DNSRoot)
            Add-DfsrMember -GroupName $DFSRGroupName -ComputerName $SourceComputerName -DomainName $($Domain.DNSRoot)
            Add-DfsrMember -GroupName $DFSRGroupName -ComputerName $DestinationComputerName -DomainName $($Domain.DNSRoot)
            New-DfsReplicatedFolder -GroupName $DFSRGroupName -DomainName $($Domain.DNSRoot) -FolderName $DFSRFolderName
            Add-DfsrConnection -GroupName $DFSRGroupName -SourceComputerName $SourceComputerName -DestinationComputerName $DestinationComputerName

            Set-DfsrMembership -GroupName $DFSRGroupName -FolderName $DFSRFolderName -ComputerName $SourceComputerName -ContentPath $SourcePhysicalPath -PrimaryMember $true -Force
            Set-DfsrMembership -GroupName $DFSRGroupName -FolderName $DFSRFolderName -ComputerName $DestinationComputerName -ContentPath $DestinationPhysicalPath -Force

            Update-DfsrConfigurationFromAD -ComputerName $SourceComputerName,$DestinationComputerName
        }
    }
}    

function Invoke-OracleDRServerProvision {
    $EnvironmentName = "Infrastructure"
    $ApplicationName = "OracleDR"
    $TervisApplicationDefinition = Get-TervisApplicationDefinition -Name $ApplicationName
    Invoke-ApplicationProvision -ApplicationName $ApplicationName -EnvironmentName $EnvironmentName
}

function Invoke-AcronisFileServerProvision {
    $EnvironmentName = "Infrastructure"
    $ApplicationName = "AcronisFileServer"
    $TervisApplicationDefinition = Get-TervisApplicationDefinition -Name $ApplicationName
    Invoke-ApplicationProvision -ApplicationName $ApplicationName -EnvironmentName $EnvironmentName
}

function Invoke-2019FileServerProvision {
    $EnvironmentName = "Infrastructure"
    $ApplicationName = "2019FileServer"
    $TervisApplicationDefinition = Get-TervisApplicationDefinition -Name $ApplicationName
    Invoke-ApplicationProvision -ApplicationName $ApplicationName -EnvironmentName $EnvironmentName
    
}
