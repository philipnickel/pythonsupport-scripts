# Piwik Event Codes for macOS Installer

Simple event tracking for the DTU Python Support macOS installer.

## Event Code Table

| Event | Pass Code | Fail Code |
|-------|-----------|-----------|
| **Installation Started** | 1 | - |
| **Python Installation** | 10 | 11 |
| **First Year Setup** | 20 | 21 |
| **VS Code Installation** | 30 | 31 |
| **VS Code Extensions** | 40 | 41 |
| **Script Finished** | 99 | - |

## Usage Examples

**Successful installation:**
```bash
piwik_log 1   # Started
piwik_log 10  # Python success
piwik_log 20  # Packages success  
piwik_log 30  # VS Code success
piwik_log 40  # Extensions success
piwik_log 99  # Finished
```

**Failed installation:**
```bash
piwik_log 1   # Started
piwik_log 11  # Python failed
piwik_log 99  # Finished
```