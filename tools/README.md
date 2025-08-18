# Documentation Tools

This directory contains tools for generating, serving, and testing the project documentation.

## Setup

First, set up the required dependencies in your pythonsupport conda environment:

```bash
# Setup dependencies
./tools/setup_docs_env.sh

# Or manually:
conda activate pythonsupport
pip install markdown watchdog
```

## Tools

### `extract_docs.py`
Extracts docstrings from shell scripts and generates markdown documentation.

```bash
# Generate documentation
python3 tools/extract_docs.py --input MacOS/Components --output docs/generated --verbose

# Help
python3 tools/extract_docs.py --help
```

### `serve_docs.py` 
Local development server for documentation with live reloading.

```bash
# Serve docs with auto-regeneration
conda activate pythonsupport
python3 tools/serve_docs.py --regenerate --watch

# Serve on different port
python3 tools/serve_docs.py --port 8080

# Help
python3 tools/serve_docs.py --help
```

**Features:**
- Converts markdown to HTML on-the-fly
- Auto-regenerates docs when shell scripts change
- Clean, responsive styling
- Navigation between pages

### `test_docs.py`
Automated testing for documentation generation and serving.

```bash
# Run all tests
conda activate pythonsupport
python3 tools/test_docs.py
```

**Tests:**
- Docstring extraction functionality
- Documentation server startup
- Page loading and content validation
- HTML structure verification

## Usage

### Development Workflow

1. **Add docstrings to shell scripts**:
   ```bash
   #!/bin/bash
   # @doc
   # @name: Script Name
   # @description: What it does
   # @category: Component
   # @usage: How to use it
   # @/doc
   ```

2. **Start development server**:
   ```bash
   conda activate pythonsupport
   python3 tools/serve_docs.py --regenerate --watch
   ```

3. **Open browser**: http://localhost:8000

4. **Edit scripts**: Documentation updates automatically!

### Testing

```bash
# Run comprehensive tests
conda activate pythonsupport
python3 tools/test_docs.py

# Manual verification
python3 tools/serve_docs.py --regenerate
# Open http://localhost:8000
```

## Files

- `extract_docs.py` - Documentation extraction engine
- `serve_docs.py` - Development server with live reload  
- `test_docs.py` - Automated testing suite
- `setup_docs_env.sh` - Environment setup script
- `requirements-docs.txt` - Python dependencies
- `package.json` - Node.js dependencies (if needed)

## Integration

The documentation system integrates with:
- **GitHub Actions**: Auto-generates docs on push
- **Shell Scripts**: Embedded docstring format
- **CI/CD**: Automated testing and validation
- **Local Development**: Live preview and testing

## Benefits

- ✅ **Always Up-to-Date**: Docs live with code
- ✅ **Easy Testing**: Local server + automated tests  
- ✅ **Developer Friendly**: Live reload during development
- ✅ **CI Integration**: Automated validation and deployment
- ✅ **No External Dependencies**: Uses your existing conda environment