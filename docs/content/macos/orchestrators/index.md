# Orchestrators Overview

Orchestrators combine multiple components to create complete installation workflows for specific use cases.

## Design 

Orchestrators:
1. **Combine Components**: Use existing components 
2. **Handle Dependencies**: Ensure components are installed in correct order
3. **Provide Context**: Tailor installation for specific user groups

## Usage 

There are two options: 

**GUI**: Download the GUI and follow the instructions

**CLI one liners**: Using 'one liners' in terminal by running one of the following commands:

## Available Orchestrators

| Orchestrator | Target Audience | What gets installed | Command |
|-------------|-----------------|---------------------|---------|
| [First Year Students](#first-year-students) | New DTU students | Python, VSCode, First Year Setup | <button onclick="navigator.clipboard.writeText('/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/orchestrators/first_year_students.sh)\"')">Copy one liner</button> |
| [Basic Python and VSCode](#basic-python-and-vscode) | General users | Python, VSCode | <button onclick="navigator.clipboard.writeText('/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/orchestrators/basic_python_vscode.sh)\"')">Copy one liner</button> |

---

## Orchestrator Details

---

### First Year Students

**Complete setup for new DTU students taking first-year Python courses**

#### What This Installs

This orchestrator provides a complete Python development environment setup:

- **Python Installation**: Installs Miniconda
- **VSCode Setup**: Installs Visual Studio Code with Python extensions
- **First Year Environment**: Sets up Python environment (in base environment) with course-specific packages

#### Components Used

- **Homebrew**: Installs Homebrew
- **Python Component**: Installs and configures Miniconda (via Homebrew)
- **VSCode Component**: Installs editor and extensions (via Homebrew)
- **Python First Year Setup**: Creates course-specific Python environment (in base environment)

#### Prerequisites

- Administrator privileges (for installation)
- No existing conda/miniconda installations

---

### Basic Python and VSCode

**Simple miniconda installation with VSCode and extensions**

#### What This Installs

- **Homebrew**: Installs Homebrew
- **Python**: Installs Miniconda (via Homebrew)
- **Visual Studio Code**: Installs VSCode (via Homebrew) and extensions

#### Prerequisites

- Administrator privileges (for installation)
- No existing conda/miniconda installations

---
