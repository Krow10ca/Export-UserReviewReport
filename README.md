# Export-UserReviewReport.ps1
The Export-UserReviewReport.ps1 script is intended to be used on a periodic basis as part of an account review process to ensure only active users are enabled. The script pulls a list of users from Active Directory with direct reports. It then uses the retrieved information to pull additional information regarding each direct report user and generates an output report. The script includes options to include both enabled and disabled managers and direct reports. Report output formats are enabled with the use of switches.

# PREREQUISITES
PowerShell Active Directory Module
Organizational structure implemented in Active Directory using the Manged By attribute.

# OPTIONS
This script has several options that ban be set through command line execution.

-CSV
    Create reports in CSV format. May be used in conjunction with -HTML. At least one output format must be selected for the script to run.

-HTML
    Create reports in HTML. May be used in conjunction with -CSV. At least one output format must be selected for the script to run.

-IncludeDisabledManagers
    Include disabled accounts that have direct reports. Disabled accounts are excluded by default.

-IncludeDisabledDirectReports
    Include disable direct report accounts. Disabled accounts are excluded by default.

-OutputITReport
    The -OutputITReport switch enables output of an IT focussed report. The report contains information about each direct report including name, job title, and email address. It also includes information around the account including the logon name, status (enabled/disabled), expiration date, last logon date, password expiry date, password last set date, and the status of the password never expires flag.

-OutputManagerReport
    Enable output of the manager report. The report fields are limited to direct report name, job title, and email address.

-OutputReportFilename
    Override the default output filename for the selected reports. The filename specified here will be appended with _ITReport or _ManagerReport to indicate the report type. The default filename is 'YYYY-MM-DD_Export-UserReviewReport'.

# USAGE
.\Export-UserReviewReport.ps1 [-HTML] [-CSV] [-IncludeDisabledManagers] [-IncludeDisabledDirectReports] [-OutputITReport] [-OutputManagerReport] [-OutputReportFilename <filename>]

Usage example 1: Show the script usage.
	.\Export-UserReviewReport.ps1

Usage example 2: Generate IT format report in HTML format.
	.\Export-UserReviewReport.ps1 -HTML -OutputITReport
	
Usage example 3: Generate manager focused reports in CSV and HTML formats. Include disabled manager users.
    .\Export-UserReviewReport.ps1 -CSV -HTML -OutputManagerReport -IncludeDisabledManagers

# RESOLVED ISSUES
2023-01-31  Handling of contact type AD accounts which specify a manager are not currently handled gracefully. Enjoy that angry red PowerShell error.

# KNOWN ISSUES
None