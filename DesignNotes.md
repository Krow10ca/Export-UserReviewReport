# RATIONALE
User management can be difficult. In larger organizations that do not have a well defined offboarding process, stale accounts can remain in the environment long after employees have left. This script is intended to be used on a regular basis to provide managers and supervisors within an organization a list of their employees for confirmation.

# INTENT
The intent of the script is to comb through Active Directory and return a list of supervisors/managers/other that have staff reporting to them.
This list will be used to generate a report of their reporting users, and the applicable stats for determining if the account is stale.

The generated report will be used to review each manager's user list to find users that are no longer with the company.
This script wouldn't be necessary with an onboarding/offboarding process that was timelier.

# DESIGN OPTIONS
Active Directory users have an attribute, directReports. This attribute is used to list the user accounts with the account listed in their manager field.
Setting the manager field on a user account is a manual process and is required for this script to function.

Add a section to check for PS module prerequisites.

Update script name to approved verb-noun structure ala get-verb
Get-UserReviewReport.ps1
Export-UserReviewReport.ps1

# FUTURE FUNCTIONALITY
-Email managers their reports directly for review.