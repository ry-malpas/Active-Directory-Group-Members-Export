param(
    [Parameter(Mandatory=$true)]
    [string]$BasePath = "UNC Path",
    
    [Parameter(Mandatory=$false)]
    [string]$SearchBase = $null
)

# Import Active Directory module
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Host "Active Directory module imported successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to import Active Directory module."
    exit 1
}

# Define department mappings
$DepartmentMappings = @{
    "Test" = @("placeholder1")
    "Test" = @("placeholder2")
    "Test" = @("placeholder3")
    "Test" = @("placeholder4")
    "Test" = @("placeholder5")
    "Test" = @("placeholder6")
    "Test" = @("placeholder7")
    "Test" = @("placeholder8")
    "Test" = @("placeholder9")
    "Test" = @("placeholder10")
    "Test" = @("placeholder11")
    "Test" = @("placeholder12")
    "Test" = @("placeholder13")
    "Test" = @("placeholder14")
}

# Function to determine department based on group name
function Get-Department {
    param([string]$GroupName)
    
    foreach ($dept in $DepartmentMappings.Keys) {
        foreach ($keyword in $DepartmentMappings[$dept]) {
            if ($GroupName -match [regex]::Escape($keyword)) {
                return $dept
            }
        }
    }
    return "Other"
}

# Function to create directory if it doesn't exist
function Ensure-Directory {
    param([string]$Path)
    
    if (!(Test-Path -Path $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-Host "Created directory: $Path" -ForegroundColor Yellow
        } catch {
            Write-Error "Failed to create directory: $Path. Error: $_"
            return $false
        }
    }
    return $true
}

# Function to get group members
function Get-GroupMembers {
    param([string]$GroupName)
    
    try {
        $group = Get-ADGroup -Identity $GroupName -ErrorAction Stop
        $members = Get-ADGroupMember -Identity $GroupName -ErrorAction Stop | 
                   Where-Object { $_.objectClass -eq "user" } |
                   ForEach-Object { 
                       try {
                           $user = Get-ADUser -Identity $_.SamAccountName -Properties DisplayName -ErrorAction Stop
                           return $user.DisplayName
                       } catch {
                           Write-Warning "Could not retrieve display name for user: $($_.SamAccountName)"
                           return $_.Name
                       }
                   } |
                   Sort-Object
        
        return $members
    } catch {
        Write-Warning "Could not retrieve members for group: $GroupName. Error: $_"
        return @()
    }
}

# Main script execution
Write-Host "Starting AD Security Group Members Export..." -ForegroundColor Cyan
Write-Host "Base Path: $BasePath" -ForegroundColor Cyan

# Create base directory if it doesn't exist
if (!(Ensure-Directory -Path $BasePath)) {
    Write-Error "Cannot proceed without base directory."
    exit 1
}

# Get all security groups that match the criteria (Instarmac Groups, Shared Drive Groups)
try {
    Write-Host "Searching for security groups..." -ForegroundColor Yellow
    $AllGroups = Get-ADGroup -Filter {GroupCategory -eq "Security"} -Properties Name, Description
    
    # Filter for Test Groups and Shared Drive Groups
    $TargetGroups = $AllGroups | Where-Object { 
        $_.Name -match "Test" -or 
        $_.Name -match "Shared Drive" -or
        $_.Description -match "Test" -or
        $_.Description -match "Shared Drive"
    }
    
    Write-Host "Found $($TargetGroups.Count) matching security groups" -ForegroundColor Green
} catch {
    Write-Error "Failed to retrieve AD groups: $_"
    exit 1
}

# Create department folders and process groups
$ProcessedGroups = @{}
$DepartmentCounts = @{}

foreach ($group in $TargetGroups) {
    $department = Get-Department -GroupName $group.Name
    $departmentPath = Join-Path -Path $BasePath -ChildPath $department
    
    # Ensure department directory exists
    if (!(Ensure-Directory -Path $departmentPath)) {
        continue
    }
    
    # Initialize department tracking
    if (!$ProcessedGroups.ContainsKey($department)) {
        $ProcessedGroups[$department] = @()
        $DepartmentCounts[$department] = 0
    }
    
    Write-Host "Processing group: $($group.Name) -> $department" -ForegroundColor White
    
    # Get group members
    $members = Get-GroupMembers -GroupName $group.Name
    
    # Create content for the file
    $content = @()
    $content += $group.Name
    $content += "=" * $group.Name.Length
    
    if ($members.Count -gt 0) {
        $content += ""
        $content += $members
    } else {
        $content += ""
        $content += "(No members found)"
    }
    
    $content += ""
    $content += "-" * 50
    $content += ""
    
    # Add to department collection
    $ProcessedGroups[$department] += $content
    $DepartmentCounts[$department]++
}

# Write files for each department
foreach ($dept in $ProcessedGroups.Keys) {
    $fileName = "$dept-Groups.txt"
    $filePath = Join-Path -Path $BasePath -ChildPath $dept | Join-Path -ChildPath $fileName
    
    try {
        $ProcessedGroups[$dept] | Out-File -FilePath $filePath -Encoding UTF8
        Write-Host "Created file: $filePath ($($DepartmentCounts[$dept]) groups)" -ForegroundColor Green
    } catch {
        Write-Error "Failed to create file: $filePath. Error: $_"
    }
}

# Summary
Write-Host "`nExport Summary:" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
$totalGroups = ($DepartmentCounts.Values | Measure-Object -Sum).Sum
Write-Host "Total groups processed: $totalGroups" -ForegroundColor White

foreach ($dept in $DepartmentCounts.Keys | Sort-Object) {
    Write-Host "$dept : $($DepartmentCounts[$dept]) groups" -ForegroundColor White
}

Write-Host "`nFiles created in: $BasePath" -ForegroundColor Green
Write-Host "Export completed successfully!" -ForegroundColor Green