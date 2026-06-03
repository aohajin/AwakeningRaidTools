# Safe MCP Config Manager
# Usage: powershell -File manage-mcp.ps1 -Action <add|remove|list|backup|restore> [-Name <name>] [-Command <cmd>] [-Args <arg1,arg2,...>]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("add","remove","list","backup","restore")]
    [string]$Action,
    [string]$Name,
    [string]$Command,
    [string[]]$ArgsList
)

$ErrorActionPreference = "Stop"
$configPath = "$env:USERPROFILE\.reasonix\config.json"
$backupDir = "$env:USERPROFILE\.reasonix\mcp-backups"
$utf8 = [System.Text.UTF8Encoding]::new($false)

function Read-Config {
    if (-not (Test-Path $configPath)) { throw "Config not found: $configPath" }
    $raw = [System.IO.File]::ReadAllText($configPath, $utf8)
    return $raw | ConvertFrom-Json
}

function Write-Config($config) {
    # Backup first
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$backupDir\config-$ts.json"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    if (Test-Path $configPath) {
        Copy-Item $configPath $backupPath
        Write-Host "Backup: $backupPath"
    }
    # Write
    $json = ConvertTo-Json $config -Depth 10
    [System.IO.File]::WriteAllText($configPath, $json, $utf8)
    # Verify
    try {
        $verify = [System.IO.File]::ReadAllText($configPath, $utf8) | ConvertFrom-Json
        Write-Host "Config written and verified OK"
    } catch {
        # Rollback
        Copy-Item $backupPath $configPath -Force
        throw "Config write verification failed — rolled back to $backupPath"
    }
}

function Build-McpEntry($name, $command, $argsList) {
    if ($argsList -and $argsList.Count -gt 0) {
        $quotedArgs = $argsList | ForEach-Object {
            if ($_ -match '\s') { return "`"$_`"" } else { return $_ }
        }
        return "$name=$command " + ($quotedArgs -join " ")
    }
    return "$name=$command"
}

switch ($Action) {
    "list" {
        $cfg = Read-Config
        Write-Host "=== MCP Servers ==="
        for ($i = 0; $i -lt $cfg.mcp.Count; $i++) {
            Write-Host "[$i] $($cfg.mcp[$i])"
        }
        Write-Host "==================="
        if (Test-Path $backupDir) {
            Write-Host "Backups:"
            Get-ChildItem $backupDir | Sort-Object LastWriteTime -Descending | ForEach-Object { Write-Host "  $($_.Name)" }
        }
    }
    "backup" {
        $ts = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = "$backupDir\config-$ts.json"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Copy-Item $configPath $backupPath
        Write-Host "Backup saved: $backupPath"
    }
    "restore" {
        $backups = Get-ChildItem $backupDir -Filter "config-*.json" | Sort-Object LastWriteTime -Descending
        if (-not $backups) { Write-Host "No backups found"; return }
        $latest = $backups[0]
        Copy-Item $latest.FullName $configPath -Force
        Write-Host "Restored from: $($latest.Name)"
    }
    "add" {
        if (-not $Name -or -not $Command) { throw "add requires -Name and -Command" }
        $cfg = Read-Config
        # Check for duplicate
        if ($cfg.mcp | Where-Object { $_ -match "^$Name=" }) {
            throw "MCP server '$Name' already exists. Remove it first."
        }
        $entry = Build-McpEntry $Name $Command $ArgsList
        $cfg.mcp += $entry
        Write-Config $cfg
        Write-Host "Added: $entry"
    }
    "remove" {
        if (-not $Name) { throw "remove requires -Name" }
        $cfg = Read-Config
        $before = $cfg.mcp.Count
        $cfg.mcp = @($cfg.mcp | Where-Object { $_ -notmatch "^$Name=" })
        if ($cfg.mcp.Count -eq $before) {
            Write-Host "No entry found for '$Name'"
            return
        }
        Write-Config $cfg
        Write-Host "Removed: $Name"
    }
}
