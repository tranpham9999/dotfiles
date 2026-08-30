# =============================================================================
# Windows bootstrap: prepares WSL (recommended runtime for opencode on
# Windows), then runs the same install.sh used on macOS — inside WSL.
#
# Usage (PowerShell, from the cloned dotfiles folder on the Windows side):
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   .\install-windows.ps1 -RepoUrl https://github.com/<you>/dotfiles.git
# =============================================================================
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoUrl
)

$ErrorActionPreference = "Stop"

function Info($m)  { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)    { Write-Host "  [ok] $m" -ForegroundColor Green }
function Warn($m)  { Write-Host "  [!] $m"  -ForegroundColor Yellow }

# --- 1. WSL present? ---------------------------------------------------------
Info "checking WSL"
$wslOut = wsl --status 2>$null
if ($LASTEXITCODE -ne 0) {
    Warn "WSL not installed. Installing Ubuntu (needs admin, may require a reboot)..."
    wsl --install -d Ubuntu
    Write-Host ""
    Warn "If Windows asked you to reboot: REBOOT, then re-run this script."
    Warn "On first Ubuntu launch, create your Linux username/password, then re-run this script."
    exit 0
}
Ok "WSL available"

# --- 2. Ubuntu distro present? ------------------------------------------------
Info "checking Ubuntu distro"
$distros = (wsl --list --quiet) 2>$null
if (-not $distros -or ($distros -join "`n") -notmatch "Ubuntu") {
    Info "installing Ubuntu"
    wsl --install -d Ubuntu --no-launch
    Warn "Ubuntu installed. Launch 'Ubuntu' from the Start menu once to finish setup, then re-run this script."
    exit 0
}
Ok "Ubuntu available"

# --- 3. Clone + run installer INSIDE WSL --------------------------------------
Info "cloning dotfiles into WSL and running installer"
$inWsl = @"
set -e
if [ ! -d ~/dotfiles ]; then
  git clone '$RepoUrl' ~/dotfiles
else
  echo '  [ok] ~/dotfiles already cloned (git pull it to update)'
fi
cd ~/dotfiles
./install.sh
"@

wsl -e bash -c $inWsl
if ($LASTEXITCODE -ne 0) { throw "install.sh failed inside WSL — scroll up for the error." }

Write-Host ""
Ok "done. Open the Ubuntu terminal and run: opencode"
Warn "remember to edit ~/.config/opencode/.env inside WSL (secrets)."
