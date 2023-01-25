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
	
	Changelog
		0.1		Initial version of UserReviewReport.ps1
#>

[CmdletBinding()]

Param(
  [switch]$Param1 = $false,
  [string]$Param2 = "Text"
)

# Start of script
