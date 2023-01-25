The intent of the script is to comb through Active Directory and return a list of supervisors/managers/other that have staff reporting to them.
This list will be used to generate a report of their reporting users, and the applicable stats for determining if the account is stale.

The generated report will be used to review each manager's user list to find users that are no longer with the company.
This script wouldn't be necessary with an onboarding/offboarding process that was timelier.


Inputs



Outputs
IT report with details around last login time, password last changed, password expired, etc.
Manager report with details around user only.