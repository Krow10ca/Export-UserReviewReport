<#
.SYNOPSIS
	Script overview
.DESCRIPTION
	Larger description of script
.PARAMETER Param1
    Details of parameter 1
.PARAMETER Param2
    Details of parameter 2
.EXAMPLE
	.\Export-UserReviewReport.ps1
	Example of running the script
.EXAMPLE
	.\Export-UserReviewReport.ps1 -Param1 -Param2
	Example of running the script with parameters
.NOTES
	Additional notes regarding the script

	Script: Export-UserReviewReport.ps1
	Author: Mike Daniels
    Created:    Jan-05-2023
    Last Updated:   Jan-31-2023
    	
	Changelog
		0.1		Initial version of Export-UserReviewReport.ps1 script
        0.2     Added basic progress bars for manager and staff processing
        0.3     Added CSV output
        0.4     Add some script prerequisite checks, modify output to not automatically generate the IT report.
        0.5     Add some additional command line switches for future use, rename others for new flow.
        0.6     Add Manager report output, sort output reports by manager name then employee name. Update default output file to include a datestamp.

    References
    https://social.technet.microsoft.com/Forums/ie/en-US/34cfcfaf-7783-4e9a-b93f-e660a09ae093/count-and-ad-group-membership?forum=winserverpowershell

#>

[CmdletBinding()]

Param(
    [switch]$CSV = $false,
    [switch]$HTML = $false,
    [switch]$IncludeContacts = $false,
    [switch]$IncludeDisabledAccounts = $false,
    [switch]$ITReport = $false,
    [switch]$ManagerReport = $false,
    [string]$ReportFilename = (Get-Date).ToString('yyyy-MM-dd') + "_Export-UserReviewReport"
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
    Write-Host "`nError: No output format selected. Script must be run with at least one of -HTML or -CSV specified.`nUsage: .\Export-UserReviewReport.ps1 [-HTML] [-CSV] [-ManagerReport]`n" -ForegroundColor Red
    Break
}

If ($ITReport -eq $false -and $ManagerReport -eq $false)
{
    # Display usage and exit script
    Write-Host "`nError: No output reports selected. Script must be run with at least one of -ITReport or -ManagerReport specified.`nUsage: .\Export-UserReviewReport.ps1 [-HTML] [-CSV] [-ManagerReport]`n" -ForegroundColor Red
    Break
}

# Retrieve list of AD users with direct reports
If ($IncludeDisabledAccounts)
{
    $ManagementList = Get-ADUser -Filter { (directReports -like "*") } -Properties name,mail,directReports | Select-Object name,mail,directReports | Sort-Object name
}
Else
{
    $ManagementList = Get-ADUser -Filter { (directReports -like "*") -and (enabled -eq $true) } -Properties name,mail,directReports | Select-Object name,mail,directReports | Sort-Object name
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
        
        # Retrieve user data from Active Directory
        $DirectReportUserData = Get-ADUser -Identity $DirectReport -properties Name,Title,SamAccountName,EmailAddress,Enabled,AccountExpirationDate,LastLogonDate,PasswordExpired,PasswordLastSet,PasswordNeverExpires
        
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

        # Process direct reports with disabled accounts if IncludeDisabledAccounts switch is enabled
        If ($DirectReportUserData.Enable -eq $false -and $IncludeDisabledAccounts)
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

    # Update the direct report status bar to completed
    Write-Progress -Activity "Processing Management User's Direct Reports" -Status "Complete" -Completed -Id 1
}

# Update the manager status bar to completed
Write-Progress -Activity "Processing Management Users" -Status "Complete" -Completed -Id 0

# If CSV format is specified, generate CSV outputs
If ($CSV)
{
    # If ManagerReport is selected, output the IT formatted report   
    If ($ManagerReport)
    {
        $ManagerReportContent =  $ReportContent | Select-Object 'ManagerName','Name','Title','Email','AccountLastLogon' | Sort-Object ManagerName,Name
        $ManagerReportContent | Export-Csv -NoTypeInformation -Path $ReportFilename"_Manager_Format.csv"
    }

    # If ITReport is selected, output the IT formatted report
    If ($ITReport)
    {
        $ITReportContent = $ReportContent | Select-Object 'ManagerName','Name','Title','Email','AccountName','AccountEnabled','AccountExpiration','AccountLastLogon','AccountPasswordLastSet','AccountPasswordExpired','AccountPasswordNeverExpires' | Sort-Object ManagerName,Name
        $ITReportContent | Export-Csv -NoTypeInformation -Path $ReportFilename"_IT_Format.csv"
    }
}