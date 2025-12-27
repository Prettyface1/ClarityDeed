param (
    [Parameter(Mandatory = $true)]
    [string]$BranchName,
    [Parameter(Mandatory = $true)]
    [string]$CommitMessage,
    [string]$PRTitle = "",
    [string]$PRBody = ""
)

# Ensure we are on a clean state
$currentBranch = git branch --show-current
Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan

# Check if branch exists locally, if so delete it to start fresh
if (git branch --list $BranchName) {
    Write-Host "Branch $BranchName exists locally. Deleting..." -ForegroundColor Yellow
    git checkout main
    git branch -D $BranchName
}

# Create new branch from main
Write-Host "Creating branch $BranchName..." -ForegroundColor Green
git checkout main
git pull origin main
git checkout -b $BranchName

# Add changes
Write-Host "Staging changes..." -ForegroundColor Green
git add -A

# Commit
Write-Host "Committing: $CommitMessage" -ForegroundColor Green
git commit -m $CommitMessage

# Push
Write-Host "Pushing to origin..." -ForegroundColor Green
git push origin $BranchName --force

# PR Creation
if ($PRTitle -ne "") {
    Write-Host "Creating Pull Request..." -ForegroundColor Yellow
    if ($PRBody -eq "") {
        $PRBody = "#### Analysis`nAutomated PR for feature: $PRTitle`n`n#### Implementation Details`n- " + $CommitMessage + "`n`n#### Testing Strategy`n- Manual verification of changes in the codebase."
    }
    
    # Check if PR already exists
    $existingPR = gh pr list --head $BranchName --json number --jq '.[0].number'
    if ($existingPR) {
        Write-Host "PR already exists: $existingPR" -ForegroundColor Yellow
    }
    else {
        gh pr create --title $PRTitle --body $PRBody --base main --head $BranchName
    }
    
    # Auto Merge
    Write-Host "Merging PR..." -ForegroundColor Yellow
    # Using --merge --delete-branch
    gh pr merge --merge --delete-branch --admin
}

# Go back to main
git checkout main
git pull origin main

Write-Host "Task completed for $BranchName" -ForegroundColor Cyan
