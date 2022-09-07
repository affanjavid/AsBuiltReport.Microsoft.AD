function Get-AbrADInfrastructureService {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD Domain Controller Infrastructure Services information.
    .DESCRIPTION

    .NOTES
        Version:        0.7.7
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
            [string]
            $DC
    )

    begin {
        Write-PscriboMessage "Discovering Active Directory DC Infrastructure Services information of $DC."
    }

    process {
        Write-PscriboMessage "Discovering AD Domain Controller Infrastructure Services information for $DC."
        try {
            $DCPssSession = New-PSSession $DC -Credential $Credential -Authentication $Options.PSDefaultAuthentication
            $Available = Invoke-Command -Session $DCPssSession -ScriptBlock {Get-Service "W32Time" | Select-Object DisplayName, Name, Status}
            if ($Available) {
                Write-PscriboMessage "Discovered Active Directory DC Infrastructure Services information of $DC."
                Section -ExcludeFromTOC -Style NOTOCHeading6 $($DC.ToString().ToUpper().Split(".")[0]) {
                    $OutObj = @()
                    if ($DC) {
                        $Services = @('CertSvc','DHCPServer','DNS','DFS Replication','Intersite Messaging','Kerberos Key Distribution Center','NetLogon','Active Directory Domain Services','W32Time','ADWS','RPCSS','EVENTSYSTEM','DNSCACHE','SAMSS','WORKSTATION')
                        foreach ($Service in $Services) {
                            try {
                                $Status = Invoke-Command -Session $DCPssSession -ScriptBlock {Get-Service $using:Service -ErrorAction SilentlyContinue | Select-Object DisplayName, Name, Status}
                                if ($Status) {
                                    Write-PscriboMessage "Collecting Domain Controller '$($Status.DisplayName)' Services status on $DC."
                                    $inObj = [ordered] @{
                                        'Display Name' = $Status.DisplayName
                                        'Short Name' = $Status.Name
                                        'Status' = $Status.Status
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Domain Controller Infrastructure Services Item)"
                            }
                        }

                        if ($HealthCheck.DomainController.Services) {
                            $OutObj | Where-Object { $_.'Status' -notlike 'Running'} | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Infrastructure Services Status - $($DC.ToString().ToUpper().Split(".")[0])"
                            List = $false
                            ColumnWidths = 40, 40, 20
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Display Name' | Table @TableParams
                    }
                    Remove-PSSession -Session $DCPssSession
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Domain Controller Infrastructure Services Section)"
        }
    }

    end {}

}