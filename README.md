# Export-UserReviewReport.ps1
This PowerShell script pulls a list of users from Active Directory with direct reports. It then uses the information to pull additional information regarding the direct reports and generates a CSV output file.

# PREREQUISITES
PowerShell Active Directory Module
Organizational structure implemented in Active Directory using the Manged By attribute.

# OPTIONS
This script has several options that ban be set through command line execution. The defaults defined in the script are intended as a starting point.

-HTML
 Create reports in HTML. May be used in conjunction with -CSV. NOTE: This feature is not yet implemented.

-CSV
 Create reports in CSV format. May be used in conjunction with -HTML.

-ReportFilename
 Provide a filename for the report. The filename specified here will be appended with _ITReport or _ManagerReport to indicate the report type.

-IncludeContacts
 Override the default script function and include contacts when processing managers and direct reports.

-ITReport
 The -ITReport switch enables output of an IT focussed report. The report contains information about each direct report including name, job title, and email address. It also includes information around the account including the logon name, status (enabled/disabled), expiration date, last logon date, password expiry date, password last set date, and the status of the password never expires flag.

-ManagerReport
 The -ManagerReport switch enables output of a manager friendly version of the report which includes direct report name, job title, email address, and the last login time for the account.

# USAGE
.\Export-UserReviewReport.ps1 [-HTML] [-CSV] [-CSVFilename <filename>] [-ITReport] [-ManagerReport]

Usage example 1: Generate an IT report in CSV format using the default filename.
.\Export-UserReviewReport.ps1 -CSV -ITReport

Usage example 2: Generate IT and Manager reports in CSV format using a custom filename.
.\Export-UserReviewReport.ps1 -CSV -ITReport -ManagerReport -ReportFilename ExampleReport

# KNOWN ISSUES
2023-01-31  Handling of contact type AD accounts which specify a manager are not currently handled gracefully. Enjoy that angry red PowerShell error.