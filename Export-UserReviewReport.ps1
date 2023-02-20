<#
.SYNOPSIS
	This script gathers users with direct reports from Active Directory and generates a report in HTML or CSV format as output.
.DESCRIPTION
	The Export-UserReviewReport.ps1 script is intended to be used on a periodic basis as part of an account review process to ensure only active users are enabled. The script includes options to include both enabled
    and disabled managers and direct reports. Report output formats are enabled with the use of switches. 
.PARAMETER CSV
    The CSV parameter enables the output of the report in CSV format. At least one report output format must be included for the script to run.
.PARAMETER HTML
    The HTML parameter enables the output of the report in HTML format. At least one report output format must be included for the script to run.
.PARAMETER IncludeDisabledManagers
    Enabling IncludeDisabledManagers will include disabled accounts with direct reports in the report. By default, these users are excluded.
.PARAMETER IncludeDisabledDirectReports
    Enabling IncludeDisableDirectReports will include disabled accounts that are listed as direct reports of users. By default, these users are excluded.
.PARAMETER OutputITReport
    This parameter will enable output of the IT formatted report which includes additional fields useful only to IT staff. At least one report output is required for the script to run.
.PARAMETER OutputManagerReport
    This parameter will enable output of the manager formatted report which includes bare minimum information of direct reports. At least one report output is required for the script to run.
.PARAMETER OutputReportFilename
    This parameter overrides the default output filename of 'YYYY-MM-DD_Export-UserReviewReport'.
.EXAMPLE
	.\Export-UserReviewReport.ps1
	Example of running the script; this will show the usage required for the script to run.
.EXAMPLE
	.\Export-UserReviewReport.ps1 -HTML -OutputITReport
	Example of running the script with IT report in HTML format as output.
.EXAMPLE
    .\Export-UserReviewReport.ps1 -CSV -HTML -OutputManagerReport -IncludeDisabledManagers
    Example of running the script for all managers, enabled or disabled, and outputting the manager report in CSV and HTML formats.
.NOTES
	Additional notes regarding the script

	Script: Export-UserReviewReport.ps1
	Author: Mike Daniels
    Created:    2023-01-05
    Last Updated:   2023-02-20
    	
	Changelog
		0.1		Initial version of Export-UserReviewReport.ps1 script
        0.2     Added basic progress bars for manager and staff processing
        0.3     Added CSV output
        0.4     Add some script prerequisite checks, modify output to not automatically generate the IT report.
        0.5     Add some additional command line switches for future use, rename others for new flow.
        0.6     Add Manager report output, sort output reports by manager name then employee name. Update default output file to include a datestamp.
        0.7     Added HTML output using Convert-HTML, streamlined output, added line to clear variables at the end of the script execution.
        0.8     Added error handling for non-user type accounts when handling direct reports. An example could be a contact set with a manager. Changed handling of disabled accounts by splitting
                manager and users to different switches to allow refined output.

    References
    https://social.technet.microsoft.com/Forums/ie/en-US/34cfcfaf-7783-4e9a-b93f-e660a09ae093/count-and-ad-group-membership?forum=winserverpowershell

#>

[CmdletBinding()]

Param(
    [switch]$CSV = $false,
    [switch]$HTML = $false,
    [switch]$IncludeDisabledManagers = $false,
    [switch]$IncludeDisabledDirectReports = $false,
    [switch]$OutputITReport = $false,
    [switch]$OutputManagerReport = $false,
    [string]$OutputReportFilename = (Get-Date).ToString('yyyy-MM-dd') + "_Export-UserReviewReport"
)

# Start of script

# Check for script prerequisite PowerShell modules and load if available
Try {
    # Load the ActiveDirectory PowerShell module
    Import-Module ActiveDirectory
}
Catch {
    # Required PowerShell module ActiveDirectory is not installed, show error message and resolution details
    Write-Host "`nError: Prerequisite PowerShell module ActiveDirectory is not installed. Please install the module in an elevated PowerShell console using:`nInstall-Module -Name ActiveDirectory`n" -ForegroundColor Red
    Break
}

# Check for output format selections
If ($CSV -eq $false -and $HTML -eq $false)
{
    # Display usage and exit script
    Write-Host "`nError: No output format selected. Script must be run with at least one of -HTML or -CSV specified.`nUsage: .\Export-UserReviewReport.ps1 [-HTML] [-CSV] [-OutputManagerReport] [-OutputITReport]`n" -ForegroundColor Red
    Break
}

If ($OutputITReport -eq $false -and $OutputManagerReport -eq $false)
{
    # Display usage and exit script
    Write-Host "`nError: No output reports selected. Script must be run with at least one of -OutputITReport or -OutputManagerReport specified.`nUsage: .\Export-UserReviewReport.ps1 [-HTML] [-CSV] [-OutputManagerReport] [-OutputITReport]`n" -ForegroundColor Red
    Break
}

# Retrieve list of AD users with direct reports
If ($IncludeDisabledManagers)
{
    Try {
        # Clear errors
        $error.Clear()

        # Pull users with direct reports from Active Directory, include disable users
        $ManagementList = Get-ADUser -Filter { (directReports -like "*") } -Properties name,mail,directReports | Select-Object name,mail,directReports | Sort-Object name    
    }
    Catch {
        # Unable to pull management users from AD, show error message
        Write-Host "`nError: Unable to get users with direct reports from Active Directory.`n" -ForegroundColor Red
        Break
    }
}
Else
{
    Try {
        # Clear errors
        $error.Clear()

        # Pull users with direct reports from Active Directory, exclude disable users
        $ManagementList = Get-ADUser -Filter { (directReports -like "*") -and (enabled -eq $true) } -Properties name,mail,directReports | Select-Object name,mail,directReports | Sort-Object name    
    }
    Catch {
        # Unable to pull management users from AD, show error message
        Write-Host "`nError: Unable to get users with direct reports from Active Directory.`n" -ForegroundColor Red
        Break
    }
    
}

# Set variables for manager processing status bar
$CurrentManager = 0
$ManagerCount = $ManagementList.Count

# Start ReportContent array
$ReportContent = @()

ForEach ($Manager in $ManagementList)
{
    # Start/Update managers processed progress bar
    $CurrentManager++
    Write-Progress -Activity "Processing Management Users" -Status "Processing Manager ($CurrentManager/$ManagerCount)" -PercentComplete (($CurrentManager / $ManagerCount) * 100) -Id 0
    
    $ManagerDirectReports = $Manager | Select-Object -ExpandProperty directReports
    
    # Set variables for direct reports processing status bar
    $CurrentDirectReport = 0
    $DirectReportCount = $ManagerDirectReports.Count
    
    ForEach ($DirectReport in $ManagerDirectReports)
    {
        # Increment progress bar counter and update displayed status
        $CurrentDirectReport++
        Write-Progress -Activity "Processing Management User's Direct Reports" -Status "Processing Employee ($CurrentDirectReport/$DirectReportCount)" -PercentComplete (($CurrentDirectReport / $DirectReportCount) * 100) -Id 1 -ParentId 0
        
        Try {
            # Clear errors
            $error.Clear()

            # Retrieve user data for direct report from Active Directory
            $DirectReportUserData = Get-ADUser -Identity $DirectReport -properties Name,Title,SamAccountName,EmailAddress,Enabled,AccountExpirationDate,LastLogonDate,PasswordExpired,PasswordLastSet,PasswordNeverExpires
        }
        Catch {
            Write-Verbose "Error occurred during collection of direct report information from Active Directory."
        }
        
        If ($error.Count -eq 0)
        {
            # Process direct reports with enabled accounts
            If ($DirectReportUserData.Enabled -eq $true)
            {
                # Add an entry for the user to the ReportContent array
                $ReportContent += New-Object PSObject -Property @{
                    'ManagerName' = $Manager.name
                    'Name' = $DirectReportUserData.Name
                    'Title' = $DirectReportUserData.Title
                    'Email' = $DirectReportUserData.EmailAddress
                    'AccountName' = $DirectReportUserData.SamAccountName
                    'AccountEnabled' = $DirectReportUserData.Enabled
                    'AccountExpiration' = $DirectReportUserData.AccountExpirationDate
                    'AccountLastLogon' = $DirectReportUserData.LastLogonDate
                    'AccountPasswordLastSet' = $DirectReportUserData.PasswordLastSet
                    'AccountPasswordExpired' = $DirectReportUserData.PasswordExpired
                    'AccountPasswordNeverExpires' = $DirectReportUserData.PasswordNeverExpires
                }
            }

            # Process direct reports with disabled accounts if IncludeDisabledDirectReports switch is enabled
            If ($DirectReportUserData.Enable -eq $false -and $IncludeDisabledDirectReports)
            {
                # Add an entry for the user to the ReportContent array
                $ReportContent += New-Object PSObject -Property @{
                    'ManagerName' = $Manager.name
                    'Name' = $DirectReportUserData.Name
                    'Title' = $DirectReportUserData.Title
                    'Email' = $DirectReportUserData.EmailAddress
                    'AccountName' = $DirectReportUserData.SamAccountName
                    'AccountEnabled' = $DirectReportUserData.Enabled
                    'AccountExpiration' = $DirectReportUserData.AccountExpirationDate
                    'AccountLastLogon' = $DirectReportUserData.LastLogonDate
                    'AccountPasswordLastSet' = $DirectReportUserData.PasswordLastSet
                    'AccountPasswordExpired' = $DirectReportUserData.PasswordExpired
                    'AccountPasswordNeverExpires' = $DirectReportUserData.PasswordNeverExpires
                }
            }
        }
        Else {
            # Add an entry for the user to the ReportContent array including error detail; reuse 'Title' field so it is included in accounts.
            $ReportContent += New-Object PSObject -Property @{
                'ManagerName' = $Manager.name
                'Name' = $DirectReport
                'Title' = "Error: User lookup from AD failed. This could be a contact class account."
            }
        }
    }
    # Update the direct report status bar to completed
    Write-Progress -Activity "Processing Management User's Direct Reports" -Status "Complete" -Completed -Id 1
}

# Update the manager status bar to completed
Write-Progress -Activity "Processing Management Users" -Status "Complete" -Completed -Id 0

# Sort report content by manager name and direct report name
$ReportContent = $ReportContent | Sort-Object ManagerName,Name

# If ManagerReport is selected, output reports
If ($OutputManagerReport)
{
    # If CSV format is specified, generate CSV output
    If ($CSV)
    {
        $ReportContent | Select-Object 'ManagerName','Name','Title','Email' | Export-Csv -NoTypeInformation -Path $OutputReportFilename"_Manager_Format.csv"
    }
    
    # If HTML format is specified, generate HTML output
    If ($HTML)
    {
        $HTMLparameters = @{
            Title = "Direct Report Users Report - Manager Version - " + (Get-Date).ToString('yyyy-MM-dd')
            PreContent = "<P>Please review the following table and notify IT of any incorrect entries.</P>"
            PostContent = "<P>Output generated on " + (Get-Date).ToString('yyyy-MM-dd') + "</P>"
        }
        
        $ReportContent | Select-Object 'ManagerName','Name','Title','Email' | ConvertTo-Html @HTMLparameters | Out-File -filePath $OutputReportFilename"_Manager_Format.html"
    }
}

If ($OutputITReport)
{
    # If CSV format is specified, generate CSV output
    If ($CSV)
    {
        $ReportContent | Select-Object 'ManagerName','Name','Title','Email','AccountName','AccountEnabled','AccountExpiration','AccountLastLogon','AccountPasswordLastSet','AccountPasswordExpired','AccountPasswordNeverExpires' | Export-Csv -NoTypeInformation -Path $OutputReportFilename"_IT_Format.csv"
    }

    # If HTML format is specified, generate HTML output
    If ($HTML)
    {
        $HTMLparameters = @{
            Title = "Direct Report Users Report - Manager Version - " + (Get-Date).ToString('yyyy-MM-dd')
            PreContent = "<P>Please review the following table and notify IT of any incorrect entries.</P>"
            PostContent = "<P>Output generated on " + (Get-Date).ToString('yyyy-MM-dd') + "</P>"
        }

        $ReportContent | Select-Object 'ManagerName','Name','Title','Email','AccountName','AccountEnabled','AccountExpiration','AccountLastLogon','AccountPasswordLastSet','AccountPasswordExpired','AccountPasswordNeverExpires' | ConvertTo-Html @HTMLparameters | Out-File -filePath $OutputReportFilename"_IT_Format.html"
    }
}

# Cleanup Script Variables, will generate errors so send standard output to $null
Remove-Variable -Scope Script -Name * -ErrorAction Continue 2>$null