#!/bin/bash

_prefix="PYS:"

echo "$_prefix Testing PDF export functionality from Jupyter notebook..."

# Download the test notebook
TEST_NOTEBOOK="test_notebook.ipynb"
OUTPUT_PDF="test_output.pdf"

echo "$_prefix Downloading test notebook..."
if [ -n "$REMOTE_PS" ] && [ -n "$BRANCH_PS" ]; then
    notebook_url="https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS/Components/Latex/test_notebook.ipynb"
    echo "$_prefix Downloading from: $notebook_url"
    if ! curl -fsSL "$notebook_url" -o "$TEST_NOTEBOOK"; then
        echo "$_prefix Error: Failed to download test notebook from $notebook_url"
        exit 1
    fi
else
    notebook_url="https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Latex/test_notebook.ipynb"
    echo "$_prefix Downloading from: $notebook_url"
    if ! curl -fsSL "$notebook_url" -o "$TEST_NOTEBOOK"; then
        echo "$_prefix Error: Failed to download test notebook from $notebook_url"
        exit 1
    fi
fi

echo "$_prefix Test notebook downloaded successfully"

# Check if test notebook exists
if [ ! -f "$TEST_NOTEBOOK" ]; then
    echo "$_prefix Error: Test notebook not found at $TEST_NOTEBOOK"
    exit 1
fi

echo "$_prefix Found test notebook: $TEST_NOTEBOOK"

# Update PATH to include TeX binaries (both BasicTeX and MacTeX locations)
export PATH="/usr/local/texlive/2024/bin/universal-darwin:/usr/local/texlive/2023/bin/universal-darwin:/usr/local/texlive/2024basic/bin/universal-darwin:/usr/local/texlive/2023basic/bin/universal-darwin:$PATH"

# Setup conda environment if available
if command -v conda >/dev/null 2>&1; then
    echo "$_prefix Setting up conda environment..."
    eval "$(conda shell.bash hook)" 2>/dev/null || true
fi

# Check if required tools are available
echo "$_prefix Checking required tools..."

if ! command -v python3 >/dev/null 2>&1; then
    echo "$_prefix Error: python3 not found"
    exit 1
fi
echo "$_prefix ✓ python3 found: $(python3 --version)"

if ! command -v pandoc >/dev/null 2>&1; then
    echo "$_prefix Error: pandoc not found"
    exit 1
fi
echo "$_prefix ✓ pandoc found: $(pandoc --version | head -1)"

if ! command -v pdflatex >/dev/null 2>&1; then
    echo "$_prefix Error: pdflatex not found"
    exit 1
fi
echo "$_prefix ✓ pdflatex found: $(pdflatex --version | head -1)"

# Check if nbconvert is available
if ! python3 -c "import nbconvert" >/dev/null 2>&1; then
    echo "$_prefix Error: nbconvert not available"
    echo "$_prefix Attempting to install nbconvert..."
    python3 -m pip install nbconvert || {
        echo "$_prefix Error: Failed to install nbconvert"
        exit 1
    }
fi
echo "$_prefix ✓ nbconvert available"

# Also check for jupyter
if ! python3 -c "import jupyter" >/dev/null 2>&1; then
    echo "$_prefix Warning: jupyter not available, installing..."
    python3 -m pip install jupyter || {
        echo "$_prefix Warning: Failed to install jupyter (continuing anyway)"
    }
fi

# Attempt to convert notebook to PDF
echo "$_prefix Attempting to convert notebook to PDF..."
echo "$_prefix Running: jupyter nbconvert --to pdf \"$TEST_NOTEBOOK\" --output \"$OUTPUT_PDF\""

# Use jupyter nbconvert to export to PDF
if python3 -m jupyter nbconvert --to pdf "$TEST_NOTEBOOK" --output="test_output" 2>/dev/null; then
    echo "$_prefix ✓ PDF export successful!"
    
    # Check if PDF file was created and has reasonable size
    if [ -f "$OUTPUT_PDF" ]; then
        file_size=$(stat -f%z "$OUTPUT_PDF" 2>/dev/null || stat -c%s "$OUTPUT_PDF" 2>/dev/null)
        if [ "$file_size" -gt 1000 ]; then
            echo "$_prefix ✓ PDF file created successfully (size: $file_size bytes)"
            
            # Clean up test files
            rm -f "$OUTPUT_PDF" "$TEST_NOTEBOOK"
            echo "$_prefix ✓ Cleaned up test files"
            
            echo "$_prefix PDF export test completed successfully!"
            exit 0
        else
            echo "$_prefix Error: PDF file too small (size: $file_size bytes)"
            exit 1
        fi
    else
        echo "$_prefix Error: PDF file not found after conversion"
        exit 1
    fi
else
    echo "$_prefix Error: PDF export failed"
    echo "$_prefix This could indicate missing LaTeX packages or other issues"
    exit 1
fi