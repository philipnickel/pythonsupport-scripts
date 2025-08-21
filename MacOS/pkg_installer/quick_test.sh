#!/bin/bash
# Quick PKG validation test

PKG_PATH="/Users/philipnickel/Documents/GitHub/pythonsupport-scripts/MacOS/pkg_installer/builds/DtuPythonInstaller_1.0.59.pkg"

echo "DTU Python PKG Quick Validation"
echo "==============================="

# Test 1: File exists
if [ -f "$PKG_PATH" ]; then
    echo "✅ PKG file exists: $(basename "$PKG_PATH")"
    echo "   Size: $(ls -lh "$PKG_PATH" | awk '{print $5}')"
else
    echo "❌ PKG file not found"
    exit 1
fi

# Test 2: XAR format
if file "$PKG_PATH" | grep -q "xar archive"; then
    echo "✅ PKG has correct XAR format"
else
    echo "❌ PKG format incorrect"
    exit 1
fi

# Test 3: Contents
echo "📦 PKG Contents:"
xar -tf "$PKG_PATH" | head -10 | while read line; do
    echo "   $line"
done

# Test 4: Key files present
contents=$(xar -tf "$PKG_PATH")
checks=0
total=4

if echo "$contents" | grep -q "Distribution"; then
    echo "✅ Distribution file found"
    checks=$((checks + 1))
else
    echo "❌ Distribution file missing"
fi

if echo "$contents" | grep -q "\.pkg/"; then
    echo "✅ Package directory found" 
    checks=$((checks + 1))
else
    echo "❌ Package directory missing"
fi

if echo "$contents" | grep -q "Scripts"; then
    echo "✅ Scripts archive found"
    checks=$((checks + 1))
else
    echo "❌ Scripts archive missing"
fi

if echo "$contents" | grep -q "Payload"; then
    echo "✅ Payload archive found"
    checks=$((checks + 1))
else
    echo "❌ Payload archive missing"
fi

echo ""
echo "Results: $checks/$total checks passed"
if [ $checks -eq $total ]; then
    echo "🎉 PKG VALIDATION PASSED!"
    exit 0
else
    echo "⚠️  PKG validation found issues"
    exit 1
fi