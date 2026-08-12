# Active-Directory-Group-Members-Export

A PowerShell script for exporting members of selected Active Directory security groups into organised text files.

The script searches Active Directory for security groups matching specified criteria, determines which department each group belongs to using configurable mappings, retrieves the group's members, and exports the results into department-specific folders.

Requirements
Windows PowerShell
Active Directory PowerShell module
Access to the target Active Directory environment
Permission to read the relevant AD groups and users
Write access to the output location

The Active Directory module can typically be installed as part of the Remote Server Administration Tools (RSAT) for Active Directory.

Usage

Run the script with the required base output path:

.\ad-group-members-export.ps1 -BasePath "\\server\share\AD-Exports"
Parameters
Parameter	Required	Description
BasePath	Yes	UNC path or local path where the export will be created
SearchBase	No	Optional Active Directory search base
Department Mappings

The script uses a mapping table to determine which department a group belongs to.

For example:

$DepartmentMappings = @{
    "IT" = @("IT", "Technology", "Helpdesk")
    "Finance" = @("Finance", "Accounts")
    "HR" = @("HR", "Human Resources")
}

When processing a group, the script checks its name against the configured keywords.

If a group does not match any configured department, it is placed in:

Other
Customising the Mappings

The $DepartmentMappings section should be updated to match the naming conventions used by your Active Directory environment.

For example:

"Engineering" = @("Engineering", "ENG", "Development")

This would classify groups containing any of those keywords as Engineering.

Group Selection

The script searches for Active Directory groups where:

GroupCategory is Security
The group name matches the configured target criteria
Or the group description matches the configured target criteria

The target criteria can be adjusted in the $TargetGroups filtering section.

Output Structure

The script creates a directory for each department and places the exported group information inside it.

For example:

AD-Exports/
├── IT/
│   └── IT-Groups.txt
├── Finance/
│   └── Finance-Groups.txt
├── HR/
│   └── HR-Groups.txt
└── Other/
    └── Other-Groups.txt

Each department file contains the groups assigned to that department and the users belonging to each group.

Example:

Example Group
=============

John Smith
Jane Smith
Alex Johnson

--------------------------------------------------

If a group has no users, the export records:

(No members found)
What the Script Does

The script:

Imports the Active Directory PowerShell module.
Validates the output directory.
Searches Active Directory for security groups matching the configured criteria.
Determines the department for each group.
Creates the required department directories.
Retrieves the members of each group.
Retrieves user display names from Active Directory.
Sorts the members alphabetically.
Groups the results by department.
Creates a text file for each department.
Displays a summary of the export.
Error Handling

The script includes error handling for operations such as:

Importing the Active Directory module
Creating directories
Searching Active Directory
Retrieving group members
Retrieving user information
Creating output files

If a particular user cannot be retrieved, the script attempts to use the member's existing name instead.

Notes

The department mappings and group filtering criteria are intended to be customised for each Active Directory environment.

The script does not modify Active Directory objects. It performs read operations and writes the resulting information to the configured output location.
