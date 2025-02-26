function Get-AbrADCATemplate {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD Certification Authority Templates information.
    .DESCRIPTION

    .NOTES
        Version:        0.8.1
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
        $CA
    )

    begin {
        Write-PScriboMessage "Collecting AD Certification Authority Templates information from $($CA.ComputerName)."
    }

    process {
        $Templates = Get-CATemplate -CertificationAuthority $CA | Select-Object -ExpandProperty Templates
        if ($Templates) {
            try {
                Section -Style Heading3 "Certificate Template Summary" {
                    Paragraph "The following section provides the certificate templates that are assigned to a specified Certification Authority (CA). CA server can issue certificates only based on assigned templates."
                    BlankLine
                    $OutObj = @()
                    foreach ($Template in $Templates) {
                        try {
                            $inObj = [ordered] @{
                                'Template Name' = $Template.DisplayName
                                'Schema Version' = $Template.SchemaVersion
                                'Supported CA' = $Template.SupportedCA
                                'Autoenrollment' = ConvertTo-TextYN $Template.AutoenrollmentAllowed
                            }
                            $OutObj += [pscustomobject]$inobj
                        } catch {
                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (CA Certificate Templates table)"
                        }
                    }

                    $TableParams = @{
                        Name = "Issued Certificate Template - $($CA.Name)"
                        List = $false
                        ColumnWidths = 40, 12, 30, 18
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Template Name' | Table @TableParams
                    if ($InfoLevel.CA -ge 3) {
                        try {
                            Section -Style Heading4 "Issued Certificate Template ACLs" {
                                Paragraph "The following section provides the certificate templates Access Control List that are assigned to a specified Certification Authority (CA)."
                                BlankLine
                                foreach ($Template in $Templates) {
                                    try {
                                        $Rights = Get-CertificateTemplateAcl -Template $Template | Select-Object -ExpandProperty Access
                                        if ($Rights) {
                                            Section -ExcludeFromTOC -Style NOTOCHeading5 "$($Template.DisplayName)" {
                                                $OutObj = @()
                                                foreach ($Right in $Rights) {
                                                    try {
                                                        $inObj = [ordered] @{
                                                            'Identity' = $Right.IdentityReference
                                                            'Access Control Type' = $Right.AccessControlType
                                                            'Rights' = $Right.Rights
                                                            'Inherited' = ConvertTo-TextYN $Right.IsInherited
                                                        }
                                                        $OutObj += [pscustomobject]$inobj
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (Certificate Templates ACL Item)"
                                                    }
                                                }
                                                $TableParams = @{
                                                    Name = "Certificate Template ACL - $($Template.DisplayName)"
                                                    List = $false
                                                    ColumnWidths = 40, 12, 30, 18
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Sort-Object -Property 'Identity' | Table @TableParams
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (Certificate Templates ACL Table)"
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (Issued Certificate Template ACLs Section)"
                        }
                    }
                    if ($InfoLevel.CA -ge 2) {
                        try {
                            $Templates = Get-CertificateTemplate
                            if ($Templates) {
                                Section -Style Heading4 "Certificate Template In Active Directory" {
                                    Paragraph "The following section provides registered certificate templates from Active Directory."
                                    BlankLine
                                    $OutObj = @()
                                    foreach ($Template in $Templates) {
                                        try {
                                            $inObj = [ordered] @{
                                                'Template Name' = $Template.DisplayName
                                                'Schema Version' = $Template.SchemaVersion
                                                'Supported CA' = $Template.SupportedCA
                                                'Autoenrollment' = ConvertTo-TextYN $Template.AutoenrollmentAllowed
                                            }
                                            $OutObj += [pscustomobject]$inobj
                                        } catch {
                                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (Certificate Template In Active Directory Item)"
                                        }
                                    }

                                    $TableParams = @{
                                        Name = "Certificate Template in AD - $($ForestInfo.toUpper())"
                                        List = $false
                                        ColumnWidths = 40, 12, 30, 18
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Sort-Object -Property 'Template Name' | Table @TableParams
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (Certificate Template In Active Directory Table)"
                        }
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning "$($_.Exception.Message) (CA Certificate Templates section)"
            }
        }
    }

    end {}

}