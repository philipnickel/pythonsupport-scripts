#!/bin/bash

_prefix="PYS:"

echo "$_prefix Testing PDF export functionality from Jupyter notebook..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_NOTEBOOK="$SCRIPT_DIR/test_notebook.ipynb"
OUTPUT_PDF="$SCRIPT_DIR/test_output.pdf"

# Check if test notebook exists
if [ ! -f "$TEST_NOTEBOOK" ]; then
    echo "$_prefix Error: Test notebook not found at $TEST_NOTEBOOK"
    exit 1
fi

echo "$_prefix Found test notebook: $TEST_NOTEBOOK"

# Update PATH to include TeX binaries
export PATH="/usr/local/texlive/2024basic/bin/universal-darwin:/usr/local/texlive/2023basic/bin/universal-darwin:$PATH"

# Check if required tools are available
echo "$_prefix Checking required tools..."

if ! command -v python3 >/dev/null 2>&1; then
    echo "$_prefix Error: python3 not found"
    exit 1
fi
echo "$_prefix ✓ python3 found"

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
    exit 1
fi
echo "$_prefix ✓ nbconvert available"

# Attempt to convert notebook to PDF
echo "$_prefix Attempting to convert notebook to PDF..."
echo "$_prefix Running: jupyter nbconvert --to pdf \"$TEST_NOTEBOOK\" --output \"$OUTPUT_PDF\""

# Use jupyter nbconvert to export to PDF
if python3 -m jupyter nbconvert --to pdf "$TEST_NOTEBOOK" --output-dir="$SCRIPT_DIR" --output="test_output" 2>/dev/null; then
    echo "$_prefix ✓ PDF export successful!"
    
    # Check if PDF file was created and has reasonable size
    if [ -f "$OUTPUT_PDF" ]; then
        file_size=$(stat -f%z "$OUTPUT_PDF" 2>/dev/null || stat -c%s "$OUTPUT_PDF" 2>/dev/null)
        if [ "$file_size" -gt 1000 ]; then
            echo "$_prefix ✓ PDF file created successfully (size: $file_size bytes)"
            
            # Clean up test file
            rm -f "$OUTPUT_PDF"
            echo "$_prefix ✓ Cleaned up test PDF file"
            
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