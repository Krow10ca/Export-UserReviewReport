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

    References
    https://social.technet.microsoft.com/Forums/ie/en-US/34cfcfaf-7783-4e9a-b93f-e660a09ae093/count-and-ad-group-membership?forum=winserverpowershell

#>



[CmdletBinding()]

Param(
  [switch]$Param1 = $false,
  [string]$Param2 = "Text",
  [switch]$ManagerReport = $false
)

# Start of script

# Retrieve list of AD users with direct reports
$ManagementList = Get-ADUser -Filter { (directReports -like "*") -and (enabled -eq $true) } -Properties name,mail,directReports | Select-Object name,mail,directReports | Sort-Object name

# Set variables for manager processing status bar
$CurrentManager = 0
$ManagerCount = $ManagementList.Count
Write-Host $ManagerCount

ForEach ($Manager in $ManagementList)
{
    # Start/Update managers processed progress bar
    $CurrentManager++
    Write-Progress -Activity "ManagerProcessing" -Status "Processing" -PercentComplete (($CurrentManager / $ManagerCount) * 100) -Id 0
    
    $ManagerDirectReports = $Manager | Select-Object -ExpandProperty directReports
    
    # Set variables for direct reports processing status bar
    $CurrentDirectReport = 0
    $DirectReportCount = $ManagerDirectReports.Count
    
    #Write-Host $DirectReportCount
    
    ForEach ($DirectReport in $ManagerDirectReports)
    {
        $CurrentDirectReport++
        Write-Progress -Activity "DirectReportProcessing" -Status "Processing" -PercentComplete (($CurrentDirectReport / $DirectReportCount) * 100) -Id 1 -ParentId 0
        #Write-Host $DirectReport
        #Get-ADUser -Identity $DirectReport
    }

    Write-Progress -Activity "DirectReportProcessing" -Status "Complete" -Completed -Id 1

}

Write-Progress -Activity "ManagerProcessing" -Status "Complete" -Completed -Id 0