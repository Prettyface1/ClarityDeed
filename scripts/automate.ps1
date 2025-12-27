param (
    [Parameter(Mandatory = $true)]
    [string]$BranchName,
    [Parameter(Mandatory = $true)]
    [string]$CommitMessage,
    [switch]$SkipSync,
    [string]$PRTitle = "",
    [string]$PRBody = ""
)

$BaseBranch = "main"
$ErrorActionPreference = "Stop"

try {
    if (-not $SkipSync) {
        Write-Host "Syncing with origin/$BaseBranch..." -ForegroundColor Cyan
        git checkout $BaseBranch -f
        git fetch origin $BaseBranch
        git reset --hard "origin/$BaseBranch"
    }

    if (git branch --list $BranchName) {
        Write-Host "Deleting existing local branch $BranchName..." -ForegroundColor Yellow
        git branch -D $BranchName
    }

    Write-Host "Creating branch $BranchName..." -ForegroundColor Green
    git checkout -b $BranchName

    Write-Host "Staging and committing..." -ForegroundColor Green
    git add -A
    git commit -m $CommitMessage

    Write-Host "Pushing to origin..." -ForegroundColor Green
    git push origin $BranchName --force

    if ($PRTitle -ne "") {
        Write-Host "Creating Pull Request..." -ForegroundColor Yellow
        $ExistingPRList = gh pr list --head $BranchName --base $BaseBranch --json number --jq ".[0].number"
        if ($ExistingPRList) {
            Write-Host "PR already exists." -ForegroundColor Yellow
        }
        else {
            gh pr create --title $PRTitle --body "$PRBody`n`n- $CommitMessage" --base $BaseBranch --head $BranchName
            Start-Sleep -Seconds 5
        }
        Write-Host "Merging PR..." -ForegroundColor Yellow
        gh pr merge --merge --admin --delete-branch
    }

    git checkout $BaseBranch -f
    git pull origin $BaseBranch
    Write-Host "SUCCESS: $BranchName processed." -ForegroundColor Cyan

}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
