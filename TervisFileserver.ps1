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

function Add-TervisExplorerFavorites {
    param(
        [Parameter(Mandatory)]$Computer,
        $Name = "*",
        $UserName = "*"
    )
    $WindowsVersion = invoke-command -ComputerName $Computer -ScriptBlock {[Environment]::OSVersion.Version.Major}
    $ExplorerFavoritesDefinition = Get-ExplorerFavoritesShortcutDefinition -Name $Name

    if ($WindowsVersion -lt 10){
        $UserProfiles = Get-UserProfilesOnComputer -Computer $Computer -Username $UserName
        foreach ($Profile in $UserProfiles){
            foreach ($Favorite in $ExplorerFavoritesDefinition){
                if($WindowsVersion -lt 10){
                    $LinksFolderPath = "\\$Computer\c$\$($Profile.UserProfilePath)\Links"
                    Set-Shortcut -LinkPath "$LinksFolderPath\$Favorite.Name.lnk" -IconLocation "c:\windows\system32\SHELL32.dll,42" -TargetPath $_.Target
                }
            }
        }
    }
    
    if ($WindowsVersion -ge 10){
        invoke-command -ComputerName $Computer -ScriptBlock {
            param($Favorite)
            #Set-Location Registry::\HKEY_USERS
            $Users = Get-item * | select name -ExpandProperty name
        }

        $RegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
        $command = ""

        $ExplorerFavoritesDefinition | %{
            $PowershellScript += "(new-object -com shell.application).Namespace(`"$($_.Target)`").Self.InvokeVerb(`"pintohome`")`n"
        }
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            param($command,$PowershellScript)
            if(-not (Test-Path c:\scripts)){New-Item -Path c:\ -Name Scripts -ItemType Directory}
            $PowershellScript | Out-File C:\Scripts\ExplorerFavorites.ps1
            New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name ExplorerFavorites -Value "Powershell -windowstyle hidden -File c:\Scripts\ExplorerFavorites.ps1" -PropertyType String -Force
        }-ArgumentList $command,$PowershellScript
    }
}



 