# ──────────────────────────────────────────────────────────────────────────────
# File: scripts/init-repo.ps1
# Purpose: Initialize the Project Phoenix Git repository with proper branching.
# Run: Right-click → "Run with PowerShell" OR: .\scripts\init-repo.ps1
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "=== Project Phoenix — Git Repository Setup ===" -ForegroundColor Cyan

# ── Step 1: Initialize repo ────────────────────────────────────────────────
git init
Write-Host "[1/7] Git repository initialized." -ForegroundColor Green

# ── Step 2: Create .gitignore ──────────────────────────────────────────────
@"
# Dependencies
node_modules/
.npm

# Build artifacts
dist/
build/
coverage/
*.log

# Environment
.env
.env.*
!.env.example

# Terraform
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
!terraform.tfvars.example

# OS
.DS_Store
Thumbs.db
desktop.ini

# IDE
.vscode/
.idea/
*.swp

# Docker
*.tar
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8

Write-Host "[2/7] .gitignore created." -ForegroundColor Green

# ── Step 3: Initial commit on main ────────────────────────────────────────
git add .
git commit -m "chore: initial commit — Project Phoenix scaffold"
Write-Host "[3/7] Initial commit on main branch." -ForegroundColor Green

# ── Step 4: Rename default branch to 'main' (if needed) ───────────────────
$currentBranch = git branch --show-current
if ($currentBranch -ne "main") {
    git branch -M main
    Write-Host "[4/7] Renamed branch to 'main'." -ForegroundColor Green
} else {
    Write-Host "[4/7] Already on 'main' branch." -ForegroundColor Green
}

# ── Step 5: Create 'develop' branch ───────────────────────────────────────
git checkout -b develop
git push origin develop 2>$null
Write-Host "[5/7] 'develop' branch created." -ForegroundColor Green

# ── Step 6: Create 'feature/setup-pipeline' branch ────────────────────────
git checkout -b feature/setup-pipeline
Write-Host "[6/7] 'feature/setup-pipeline' branch created." -ForegroundColor Green

# ── Step 7: Switch back to main ───────────────────────────────────────────
git checkout main
Write-Host "[7/7] Switched back to 'main'." -ForegroundColor Green

# ── Summary ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Branch Structure ===" -ForegroundColor Cyan
git branch -a
Write-Host ""
Write-Host "=== Git Log ===" -ForegroundColor Cyan
git log --oneline --graph --all
Write-Host ""
Write-Host "✅ Repo setup complete! Branching strategy:" -ForegroundColor Green
Write-Host "   main              → Production-ready code (protected)"
Write-Host "   develop           → Integration branch (merge features here)"
Write-Host "   feature/*         → Individual feature branches"
Write-Host ""
Write-Host "Workflow: feature/* → develop → main (via PR)" -ForegroundColor Yellow
