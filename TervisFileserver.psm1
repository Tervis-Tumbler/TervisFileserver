﻿$ExplorerFavoritesShortcutDefinition = [PSCustomObject][Ordered]@{
        Name = "IT"
        Target = "\\tervis.prv\departments\IT"
    },
    [PSCustomObject][Ordered]@{
        Name = "Graphics"
        Target = "\\tervis.prv\creative\graphics drive"
    },
    [PSCustomObject][Ordered]@{
        Name = "Departments - I - Drive"
        Target = "\\tervis.prv\departments\Departments - I Drive"
    },
    [PSCustomObject][Ordered]@{
        Name = "Compliance"
        Target = "\\tervis.prv\departments\Compliance"
    },
#    [PSCustomObject][Ordered]@{
#        Name = "Art"
#        Target = "\\tervis.prv\departments\Art"
#        Delete = $true
#    },
    [PSCustomObject][Ordered]@{
        Name = "Web"
        Target = "\\tervis.prv\departments\Web"
    },
    [PSCustomObject][Ordered]@{
        Name = "Marketing"
        Target = "\\tervis.prv\departments\Marketing"
    },
    [PSCustomObject][Ordered]@{
        Name = "Engineering"
        Target = "\\tervis.prv\departments\Engineering"
    },
    [PSCustomObject][Ordered]@{
        Name = "Operations"
        Target = "\\tervis.prv\departments\Operations"
    },
    [PSCustomObject][Ordered]@{
        Name = "QA"
        Target = "\\tervis.prv\departments\QA"
    },
    [PSCustomObject][Ordered]@{
        Name = "HR"
        Target = "\\tervis.prv\departments\HR"
    },
    [PSCustomObject][Ordered]@{
        Name = "Sales"
        Target = "\\tervis.prv\departments\Sales"
    },
    [PSCustomObject][Ordered]@{
        Name = "Stores"
        Target = "\\tervis.prv\departments\Stores"
    },
    [PSCustomObject][Ordered]@{
        Name = "Supply Chain"
        Target = "\\tervis.prv\departments\Supply Chain"
    },
#    [PSCustomObject][Ordered]@{
#        Name = "Admin"
#        Target = "\\tervis.prv\departments\Admin"
#        Delete = $true
#    },
    [PSCustomObject][Ordered]@{
        Name = "New Product Development"
        Target = "\\tervis.prv\departments\New Product Development"
    },
    [PSCustomObject][Ordered]@{
        Name = "Applications"
        Target = "\\tervis.prv\Applications"
    },
    [PSCustomObject][Ordered]@{
        Name = "Finance"
        Target = "\\tervis.prv\departments\Finance"
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
        $WindowsVersion = invoke-command -ComputerName $ComputerName -ScriptBlock {[Environment]::OSVersion.Version.Major}
        if ($WindowsVersion -lt 10){
            $UserProfiles = Get-UserProfilesOnComputer -Computer $ComputerName -Username $UserName
            foreach ($Profile in $UserProfiles){
                foreach ($Favorite in $ExplorerFavoritesDefinition){
                    if($WindowsVersion -lt 10){
                        $LinksFolderPath = "\\$ComputerName\c$\$($Profile.UserProfilePath)\Links"
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
        $Argument = -NoProfile -Command 'Push-TervisExplorerFavoritesOrQuickAccess -ComputerOrganizationalUnit "OU=Computers,OU=Information Technology,OU=Departments,DC=tervis,DC=prv"'
    }
    process {
        $CimSession = New-CimSession -ComputerName $ComputerName
        If (-NOT (Get-ScheduledTask -TaskName PushExplorerFavorites -CimSession $CimSession -ErrorAction SilentlyContinue)) {
            Install-TervisScheduledTask -Credential $ScheduledTaskCredential -TaskName PushExplorerFavorites -Execute $Execute -Argument $Argument -RepetitionIntervalName EverWorkdayDuringTheDayEvery15Minutes -ComputerName $ComputerName
        }
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
        $Responses 
        where Online -EQ $true
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
        $ComputerList = Get-ComputersWithinOU -OrganizationalUnit $ComputerOrganizationalUnit -Online
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
