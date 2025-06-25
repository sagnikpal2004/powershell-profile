Set-Alias python3 python
Set-Alias pip3 pip
Set-Alias make mingw32-make

$Env:VIRTUAL_ENV_DISABLE_PROMPT = $true
$ENV:COMPUTERNAME = "Sagnik-EliteBook"


function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    Write-Host

    if (Test-Administrator) {
        Write-Host "root" -NoNewline -ForegroundColor DarkYellow
    } else {
        Write-Host "$ENV:USERNAME" -NoNewline -ForegroundColor DarkYellow
    }
    Write-Host "@" -NoNewline -ForegroundColor DarkMagenta
    Write-Host "$ENV:COMPUTERNAME" -NoNewline -ForegroundColor Magenta

    if ($null -ne $s) {
        Write-Host " (`$s: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($s.Name)" -NoNewline -ForegroundColor Yellow
        Write-Host ") " -NoNewline -ForegroundColor DarkGray
    }

    Write-Host " : " -NoNewline -ForegroundColor DarkGray
    Write-Host $($(Get-Location) -replace ($env:USERPROFILE).Replace('\','\\'), "~") -NoNewline -ForegroundColor Blue
    Write-Host " : " -NoNewline -ForegroundColor DarkGray
    Write-Host (Get-Date -Format G) -NoNewline -ForegroundColor DarkCyan
    Write-Host " : " -NoNewline -ForegroundColor DarkGray

    Write-Host

    Write-VEnvStatus

    $vcsStatus = Write-VcsStatus | Out-String
    $vcsStatus = $vcsStatus.Trim()
    if ($vcsStatus) {
        Write-Host "$vcsStatus " -NoNewline
    }

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
}


# function pip {
#     param (
#         [Parameter(
#             Position = 0
#         )][string]$Command,

#         [Parameter(
#             Position = 1, 
#             ValueFromRemainingArguments = $true
#         )][string[]]$Arguments,

#         [Parameter(
#         )][string]$VenvPath = ".venv",
#         [Parameter(
#         )][string]$RequirementsPath = "requirements.txt",
#         [Parameter(
#         )][switch]$Global = $false
#     )
#     $VenvPath = Resolve-FullPath $VenvPath
#     $RequirementsPath = Resolve-FullPath $RequirementsPath

#     if (-not $Global) {
#         Enable-VirtualEnvironment $VenvPath
#     }

#     pip.exe $Command $Arguments
# }

function Enable-VEnv {
    param(
        [string]$PythonVersion = $null,
        [string]$VenvPath = ".venv",
        [string]$RequirementsPath = "requirements.txt"
    )
    $VenvPath = Resolve-FullPath $VenvPath

    if ($PythonVersion) {
        $v = $PythonVersion -replace '\.', ''
        $pythonCommand = "C:\Program Files\Python$v\python.exe"

        if (-not (Test-Path $pythonCommand)) {
            Write-Host "Python version $PythonVersion not found" -ForegroundColor Red
            return
        }
    } else {
        $pythonCommand = "python"
    }

    if ($env:VIRTUAL_ENV -ne $VenvPath) {
        if (-not (Test-Path $VenvPath)) {
            & $pythonCommand -m venv $VenvPath
        }
        & $VenvPath\Scripts\Activate.ps1
        # if (Test-Path $RequirementsPath) {
        #     pip install -r requirements.txt
        # }
    }
}

function Disable-VEnv {
    if (-not $env:VIRTUAL_ENV) { return }
    deactivate
}

function Write-VEnvStatus {
    function Find-VEnvDir {
        param([string]$curDir)
        if ($curDir -eq "") { return $null }
        if (Test-Path "$curDir\.venv") { return "$curDir\.venv" }
        return Find-VEnvDir (Split-Path $curDir)
    }

    $venvDir = Find-VEnvDir (Get-Location)
    if (-not $venvDir) {
        Disable-VEnv
        return
    }

    Enable-VEnv -VenvPath $venvDir
    Write-Host "($(Split-Path -Leaf $venvDir)) " -NoNewline -ForegroundColor Green
}

function Resolve-FullPath {
    param (
        [string]$Path
    )

    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path -Path (Get-Location) -ChildPath $Path
    }
    return $Path
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
