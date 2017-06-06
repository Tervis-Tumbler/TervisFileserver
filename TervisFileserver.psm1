$ExplorerFavoritesShortcutDefinition = [PSCustomObject][Ordered]@{
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
    [PSCustomObject][Ordered]@{
        Name = "Art"
        Target = "\\tervis.prv\departments\Art"
    },
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
    [PSCustomObject][Ordered]@{
        Name = "Admin"
        Target = "\\tervis.prv\departments\Admin"
    },
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
        [Parameter(Mandatory)]$Name
    )
        $ExplorerFavoritesShortcutDefinition | where Name -like $Name
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
        $ComputerList = Get-ADComputer -filter * -SearchBase $ComputerOrganizationalUnit
    }
    else{
        $ComputerList = $ComputerName
    }

    $ExplorerFavoritesDefinition = Get-ExplorerFavoritesShortcutDefinition -Name $Name
    

        $WindowsVersion = invoke-command -ComputerName $ComputerName -ScriptBlock {[Environment]::OSVersion.Version.Major}
        if ($WindowsVersion -lt 10){
            $UserProfiles = Get-UserProfilesOnComputer -Computer $ComputerName -Username $UserName
            foreach ($Profile in $UserProfiles){
                foreach ($Favorite in $ExplorerFavoritesDefinition){
                    if($WindowsVersion -lt 10){
                        $LinksFolderPath = "\\$ComputerName\c$\$($Profile.UserProfilePath)\Links"
                        Set-Shortcut -LinkPath "$LinksFolderPath\$Favorite.Name.lnk" -IconLocation "c:\windows\system32\SHELL32.dll,42" -TargetPath $_.Target
                    }
                }
            }
        }

        if ($WindowsVersion -ge 10){
            $RegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
            $ExplorerFavoritesDefinition | %{
                $PowershellScript += "(new-object -com shell.application).Namespace(`"$($_.Target)`").Self.InvokeVerb(`"pintohome`")`n"
        }
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($PowershellScript)
                if(-not (Test-Path c:\scripts)){New-Item -Path c:\ -Name Scripts -ItemType Directory}
                $PowershellScript | Out-File C:\Scripts\ExplorerFavorites.ps1
                New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name ExplorerFavorites -Value "Powershell -windowstyle hidden -File c:\Scripts\ExplorerFavorites.ps1" -PropertyType String -Force
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
        $Argument = '-Command Push-TervisExplorerFavoritesOrQuickAccess -ComputerName dmohlmaster-new -Name it -NoProfile'
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

    $ComputerNames = Get-ADComputer -Filter * -SearchBase $OrganizationalUnit |
    Select -ExpandProperty name

    $Responses = Start-ParallelWork -ScriptBlock {
        param($Parameter)
        [pscustomobject][ordered]@{
            ComputerName = $Parameter;
            Online = $(Test-Connection -ComputerName $Parameter -Count 1 -Quiet);        
        }
    } -Parameters $ComputerNames

    if ($Online) {
        $Responses | 
        where Online -EQ $true |
        Select -ExpandProperty ComputerName
    } else {
        $Responses |         
        Select -ExpandProperty ComputerName
    }
}

 