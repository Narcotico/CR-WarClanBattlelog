while (0 -eq 0) {

    #Token Insert your token between " ""
    $Token = ""
    write-host "Starting"
    #Clan Tag Insert your clan tag between "" ex #abcde
    $clanTag = "2PRL2RV8"

    $clanPath = ".\battlelog\$clanTag.csv"

    $csv = import-csv -path $clanPath -Delimiter ";"

    #First Reset Needs to be set every monday
    $firstReset = Get-Date -Date "2020-12-14 10:00:00Z"

    #URI for Clan
    $uri = "https://api.clashroyale.com/v1/clans/%23$($ClanTag)"

    $clan = Invoke-RestMethod -Method GET -Uri $uri -Headers @{
        'authorization' = "Bearer $Token"
        'Content-Type'  = 'application/json'
    }

    function Get-LastWarEndTime {
        param ($clanTag) 

        $uri = "https://api.clashroyale.com/v1/clans/%23$($clanTag)/riverracelog"

        $riverracelog = Invoke-RestMethod -Method GET -Uri $uri -Headers @{
            'authorization' = "Bearer $Token"
            'Content-Type'  = 'application/json'
        }
        return $riverracelog.items[0].createdDate
    }

    $LastWarEndTimeRaw = Get-LastWarEndTime $clanTag
    $LastWarEndTimeProcess = $LastWarEndTimeRaw.Split(".")[0]
    $LastWarEndTime = [datetime]::parseexact($LastWarEndTimeProcess, 'yyyyMMddTHHmmss', $null)

    #URI for Clan
    $uri = "https://api.clashroyale.com/v1/clans/%23$($ClanTag)"

    $clan = Invoke-RestMethod -Method GET -Uri $uri -Headers @{
        'authorization' = "Bearer $Token"
        'Content-Type'  = 'application/json'
    }

    foreach ($member in $clan.memberList) {
        $memberTag = $member.tag -replace '[#]'
 
        $uriMember = "https://api.clashroyale.com/v1/players/%23$($memberTag)/battlelog"

        $battleLog = Invoke-RestMethod -Method GET -Uri $uriMember -Headers @{
            'authorization' = "Bearer $Token"
            'Content-Type'  = 'application/json'
        }

        foreach ($battle in $battleLog) { 

            if (($battle.type -eq "riverRaceDuel") -or ($battle.type -eq "riverRacePvP") -or ($battle.type -eq "riverRaceDuelColosseum") -and ($battle.team.clan.tag -eq "#2PRL2RV8")) {

                $BattleTimeRaw = $battle.battletime
                $BattleTimeRawProcess = $BattleTimeRaw.Split(".")[0]
                $BattleTime = [datetime]::parseexact($BattleTimeRawProcess, 'yyyyMMddTHHmmss', $null)

                if ($BattleTime -ge $LastWarEndTime) { 
                    if ($BattleTime -lt $firstReset) { $battleday = -1 }
                    else { 
                        $left = NEW-TIMESPAN –Start $firstReset –End $BattleTime
                        $battleday = $left.days
                    }

                    $Player = $battle | Select-Object -Property *
                    $hour = $player.battletime.substring(9) -replace ".{9}$"
                    $minute = $player.battletime.substring(11) -replace ".{7}$"
                    $second = $player.battletime.substring(13) -replace ".{5}$"
                    $teamcards = $player.team.cards | Measure-Object
                    $PlayerProperties = @{
                        type       = $Player.type
                        battledate = $BattleTime
                        battleday  = $battleday
                        battleTime = $Player.battleTime
                        gameMode   = $Player.gameMode.name
                        team       = $Player.team.name
                        opponent   = $Player.opponent.name
                        numBattles = ($teamcards.Count / 8 )
            
                    }
                    $obj = New-Object -TypeName PSObject -Property $PlayerProperties
                    if (-not ($csv | where { $_.battleTime -eq $player.battleTime })) { 
                        $obj = New-Object -TypeName PSObject -Property $PlayerProperties
                        write-host "New battle found: " $obj
                        $obj | export-csv -Path $clanPath -NoTypeInformation -Append -UseQuotes Never -Delimiter ";" -Encoding utf8
                    }

                }

            }
    
        }
    }

}
