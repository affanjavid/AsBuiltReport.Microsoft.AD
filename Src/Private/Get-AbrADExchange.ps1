function Get-AbrADExchange {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD Exchange information
    .DESCRIPTION

    .NOTES
        Version:        0.8.2
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "Collecting AD Exchange information of $($ForestInfo.toUpper())."
    }

    process {
        $EXServers = try {Get-ADExchangeServer} catch {Out-Null}
        try {
            if ($EXServers ) {
                Section -Style Heading3 'Exchange Infrastructure' {
                    Paragraph "The following section provides a summary of the Exchange Infrastructure configured on Active Directory."
                    BlankLine
                    $EXInfo = @()
                    foreach ($EXServer in $EXServers) {
                        try {
                            $inObj = [ordered] @{
                                'Name' = $EXServer.Name
                                'Dns Name' = $EXServer.DnsHostName
                                'Server Roles' = $EXServer.ServerRoles -join ", "
                                'Version' = $EXServer.Version
                            }
                            $EXInfo += [pscustomobject]$inobj
                        } catch {
                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (Exchange Item)"
                        }
                    }

                    if ($InfoLevel.Forest -ge 2) {
                        foreach ($EXServer in $EXInfo) {
                            Section -Style NOTOCHeading4 -ExcludeFromTOC "$($EXServer.Name)" {
                                $TableParams = @{
                                    Name = "Exchange Infrastructure - $($EXServer.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $EXServer | Table @TableParams
                            }
                        }
                    } else {
                        $TableParams = @{
                            Name = "Exchange Infrastructure - $($ForestInfo.toUpper())"
                            List = $false
                            Columns = 'Name', 'DNS Name', 'Server Roles', 'Version'
                            ColumnWidths = 25, 25, 25, 25
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $EXInfo | Table @TableParams
                    }
                }
            } else {
                Write-PScriboMessage -IsWarning "No Exchange Infrastructure information found in $($ForestInfo.toUpper()), disabling the section."
            }
        } catch {
            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (Exchabge Table)"
        }
    }

    end {}

}