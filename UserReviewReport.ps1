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
	.\UserReviewReport.ps1
	Example of running the script
.EXAMPLE
	.\UserReviewReport.ps1 -Param1 -Param2
	Example of running the script with parameters
.NOTES
	Additional notes regarding the script

	Script:		UserReviewReport.ps1
	Author:		Mike Daniels
    Created:		Jan-05-2023
    Last Updated:	Jan-05-2023
    	
	Changelog
		0.1		Initial version of UserReviewReport.ps1 script
        0.2     Added basic progress bars for manager and staff processing
        0.3     Added CSV output

    References
    https://social.technet.microsoft.com/Forums/ie/en-US/34cfcfaf-7783-4e9a-b93f-e660a09ae093/count-and-ad-group-membership?forum=winserverpowershell

#>



[CmdletBinding()]

Param(
    [switch]$HTML = $false,
    [switch]$CSV = $false,
    [switch]$ManagerReport = $false,
    [string]$CSVFilename = "csvoutput.csv"
)

# Start of script

# Check for output format selections
If ($CSV -eq $false -and $HTML -eq $false)
{
    # Display usage and exit script
    Write-Host "`nError: No output format selected. Script must be run with at least one of -HTML or -CSV specified.`nUsage: .\UserReviewReport.ps1 [-HTML] [-CSV] [-ManagerReport]`n" -ForegroundColor Red
    Break
}


# Retrieve list of AD users with direct reports
$ManagementList = Get-ADUser -Filter { (directReports -like "*") -and (enabled -eq $true) } -Properties name,mail,directReports | Select-Object name,mail,directReports | Sort-Object name

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
        Write-Progress -Activity "Processing Manager's Direct Reports" -Status "Processing Employee ($CurrentDirectReport/$DirectReportCount)" -PercentComplete (($CurrentDirectReport / $DirectReportCount) * 100) -Id 1 -ParentId 0
        
        # Retrieve user data from Active Directory
        $DirectReportUserData = Get-ADUser -Identity $DirectReport -properties Name,Title,SamAccountName,EmailAddress,Enabled,AccountExpirationDate,LastLogonDate,PasswordExpired,PasswordLastSet,PasswordNeverExpires
        
        # Add an entry for the user to the report content
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

    # Update the direct report status bar to completed
    Write-Progress -Activity "Processing Manager's Direct Reports" -Status "Complete" -Completed -Id 1

}

# Update the manager status bar to completed
Write-Progress -Activity "Processing Management Users" -Status "Complete" -Completed -Id 0

If ($CSV)
{
    # Create CSV output file
    $CSVOutputContent = $ReportContent | Select-Object 'ManagerName','Name','Title','Email','AccountName','AccountEnabled','AccountExpiration','AccountLastLogon','AccountPasswordLastSet','AccountPasswordExpired','AccountPasswordNeverExpires'
    $CSVOutputContent | Export-Csv -NoTypeInformation -Path $CSVFilename
}