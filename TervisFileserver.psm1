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
        $ScheduledTaskCredential = New-Object System.Management.Automation.PSCredential (Get-PasswordstateCredential -PasswordID 259)
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
        New-ItemProperty -Path "Registry::HKEY_USERS\TEMP\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name ExplorerFavorites -Value "powershell.exe -noprofile -file $using:ScriptPathRoot\$using:ScriptFolderName\ExplorerQuickAccess.ps1" -PropertyType String -Force
        & reg unload HKU\TEMP
    }
}

function Get-FileServerAnalysis {
$Files = gci "\\tervis.prv\departments\Departments - I Drive" -Recurse


}

