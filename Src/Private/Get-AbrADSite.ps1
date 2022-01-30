function Get-AbrADSite {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD Domain Sites information.
    .DESCRIPTION

    .NOTES
        Version:        0.6.3
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
        Write-PscriboMessage "Discovering Active Directory Sites information of forest $ForestInfo"
    }

    process {
        try {
            $Site =  Invoke-Command -Session $TempPssSession {Get-ADReplicationSite -Filter * -Properties *}
            if ($Site) {
                Section -Style Heading3 'Domain Sites' {
                    $OutObj = @()
                    Write-PscriboMessage "Discovered Active Directory Sites information of forest $ForestInfo"
                    foreach ($Item in $Site) {
                        try {
                            Write-PscriboMessage "Collecting '$($Item.Name)' Site"
                            $SubnetArray = @()
                            $Subnets = $Item.Subnets
                            foreach ($Object in $Subnets) {
                                $SubnetName =  Invoke-Command -Session $TempPssSession {Get-ADReplicationSubnet $using:Object}
                                $SubnetArray += $SubnetName.Name
                            }
                            $inObj = [ordered] @{
                                'Site Name' = $Item.Name
                                'Description' = ConvertTo-EmptyToFiller $Item.Description
                                'Subnets' = Switch (($SubnetArray).count) {
                                    0 {"-"}
                                    default {$SubnetArray}
                                }
                                'Creation Date' = $Item.createTimeStamp.ToShortDateString()
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Domain Site)"
                        }
                    }

                    $TableParams = @{
                        Name = "Sites - $($ForestInfo)"
                        List = $false
                        ColumnWidths = 25, 30, 25, 20
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Site Name' | Table @TableParams
                    try {
                        $Subnet = Invoke-Command -Session $TempPssSession {Get-ADReplicationSubnet -Filter * -Properties *}
                        if ($Subnet) {
                            Section -Style Heading4 'Site Subnets' {
                                $OutObj = @()
                                Write-PscriboMessage "Discovered Active Directory Sites Subnets information of forest $ForestInfo"
                                foreach ($Item in $Subnet) {
                                    try {
                                        Write-PscriboMessage "Collecting $($Item.Name) Site Subnet."
                                        $inObj = [ordered] @{
                                            'Subnet' = $Item.Name
                                            'Description' = ConvertTo-EmptyToFiller $Item.Description
                                            'Sites' = Get-ADObject $Item.Site | Select-Object -ExpandProperty Name
                                            'Creation Date' = $Item.Created.ToShortDateString()
                                        }
                                        $OutObj += [pscustomobject]$inObj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Site Subnets)"
                                    }
                                }

                                $TableParams = @{
                                    Name = "Site Subnets - $($ForestInfo)"
                                    List = $false
                                    ColumnWidths = 20, 30, 35, 15
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Subnet' | Table @TableParams
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Site Subnets)"
                    }
                    try {
                        $Link = Invoke-Command -Session $TempPssSession {Get-ADReplicationSiteLink -Filter * -Properties *}
                        if ($Link) {
                            Section -Style Heading4 'Site Links' {
                                $OutObj = @()
                                Write-PscriboMessage "Discovered Active Directory Sites Link information of forest $ForestInfo"
                                foreach ($Item in $Link) {
                                    try {
                                        Write-PscriboMessage "Collecting '$($Item.Name)' Site Link"
                                        $SiteArray = @()
                                        $Sites = $Item.siteList
                                        foreach ($Object in $Sites) {
                                            $SiteName =  Invoke-Command -Session $TempPssSession {Get-ADReplicationSite -Identity $using:Object}
                                            $SiteArray += $SiteName.Name
                                        }
                                        $inObj = [ordered] @{
                                            'Site Link Name' = $Item.Name
                                            'Cost' = $Item.Cost
                                            'Replication Frequency' = "$($Item.ReplicationFrequencyInMinutes) min"
                                            'Transport Protocol' = $Item.InterSiteTransportProtocol
                                            'Sites' = $SiteArray
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Site Links)"
                                    }
                                }

                                $TableParams = @{
                                    Name = "Site Links - $($ForestInfo)"
                                    List = $false
                                    ColumnWidths = 30, 15, 15, 15, 25
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Site Link Name' | Table @TableParams
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Site Subnets)"
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Domain Site Global)"
        }
    }

    end {}

}