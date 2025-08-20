#!/usr/bin/env python3
"""
Documentation testing script using requests and basic HTML parsing.
Works with existing Python environment without additional dependencies.
"""

import os
import sys
import subprocess
import time
import threading
from urllib.request import urlopen
from urllib.error import URLError
import socket
from contextlib import contextmanager


class DocTester:
    """Test documentation generation and serving."""
    
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        self.server_process = None
        
    def start_server(self, port=8000, docs_dir='docs/generated', timeout=10):
        """Start the documentation server."""
        print(f"🚀 Starting documentation server on port {port}...")
        
        # Start server in background
        # Use conda python if available, otherwise use current executable
        python_executable = '/opt/homebrew/Caskroom/miniconda/base/envs/pythonsupport/bin/python'
        if not os.path.exists(python_executable):
            python_executable = sys.executable
            
        cmd = [
            python_executable, 'docs/tools/serve_docs.py',
            '--port', str(port),
            '--docs-dir', docs_dir,
            '--regenerate'
        ]
        
        self.server_process = subprocess.Popen(
            cmd, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Wait for server to start
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                with urlopen(f"http://localhost:{port}") as response:
                    if response.getcode() == 200:
                        print("✅ Server started successfully!")
                        return True
            except (URLError, ConnectionError):
                time.sleep(0.5)
        
        print("❌ Server failed to start within timeout")
        return False
    
    def stop_server(self):
        """Stop the documentation server."""
        if self.server_process:
            print("🛑 Stopping server...")
            self.server_process.terminate()
            try:
                self.server_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.server_process.kill()
            self.server_process = None
    
    def test_page(self, path="", expected_content=None):
        """Test a documentation page."""
        url = f"{self.base_url}/{path}".rstrip('/')
        print(f"🔍 Testing: {url}")
        
        try:
            with urlopen(url) as response:
                if response.getcode() != 200:
                    print(f"❌ HTTP {response.getcode()}: {url}")
                    return False
                
                content = response.read().decode('utf-8')
                
                # Check if it's HTML
                if not content.strip().startswith('<!DOCTYPE html>'):
                    print(f"❌ Not HTML: {url}")
                    return False
                
                # Check for expected content
                if expected_content:
                    for expected in expected_content:
                        if expected not in content:
                            print(f"❌ Missing content '{expected}': {url}")
                            return False
                
                print(f"✅ OK: {url} ({len(content)} bytes)")
                return True
                
        except Exception as e:
            print(f"❌ Error loading {url}: {e}")
            return False
    
    def run_tests(self):
        """Run all documentation tests."""
        print("📚 Starting documentation tests...")
        
        tests = [
            # Test main pages
            {
                'path': '',
                'name': 'Index page',
                'expected': ['Python Support Scripts Documentation', 'Total Scripts']
            },
            {
                'path': 'components',
                'name': 'Components page', 
                'expected': ['Component Documentation', 'Python', 'LaTeX', 'VSCode']
            },
            {
                'path': 'index',
                'name': 'Index page (explicit)',
                'expected': ['Documentation Pages', 'Categories']
            }
        ]
        
        passed = 0
        failed = 0
        
        for test in tests:
            print(f"\n🧪 Testing {test['name']}...")
            if self.test_page(test['path'], test.get('expected')):
                passed += 1
            else:
                failed += 1
        
        print(f"\n📊 Test Results:")
        print(f"  ✅ Passed: {passed}")
        print(f"  ❌ Failed: {failed}")
        print(f"  📈 Success Rate: {passed/(passed+failed)*100:.1f}%")
        
        return failed == 0
    
    def test_docstring_extraction(self):
        """Test that docstrings are properly extracted."""
        print("\n🔧 Testing docstring extraction...")
        
        # Run extraction
        # Use conda python if available, otherwise use current executable
        python_executable = '/opt/homebrew/Caskroom/miniconda/base/envs/pythonsupport/bin/python'
        if not os.path.exists(python_executable):
            python_executable = sys.executable
            
        result = subprocess.run([
            python_executable, 'docs/tools/extract_docs.py',
            '--input', 'MacOS/Components',
            '--output', 'docs/generated',
            '--verbose'
        ], capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"❌ Extraction failed: {result.stderr}")
            return False
        
        print("✅ Extraction successful")
        
        # Check that files were created
        required_files = ['docs/generated/index.md', 'docs/generated/components.md']
        for file_path in required_files:
            if not os.path.exists(file_path):
                print(f"❌ Missing file: {file_path}")
                return False
            
            # Check file has content
            with open(file_path, 'r') as f:
                content = f.read().strip()
                if not content:
                    print(f"❌ Empty file: {file_path}")
                    return False
        
        print("✅ Generated files exist and have content")
        return True


@contextmanager 
def doc_server(port=8000):
    """Context manager for documentation server."""
    tester = DocTester()
    try:
        if tester.start_server(port=port):
            yield tester
        else:
            print("❌ Failed to start server")
            yield None
    finally:
        tester.stop_server()


def main():
    """Main test function."""
    print("🧪 Python Support Scripts Documentation Test Suite")
    print("=" * 60)
    
    # Test 1: Docstring extraction
    tester = DocTester()
    if not tester.test_docstring_extraction():
        print("❌ Docstring extraction tests failed")
        return 1
    
    # Test 2: Server and page loading
    with doc_server() as server:
        if server is None:
            print("❌ Could not start documentation server")
            return 1
        
        if not server.run_tests():
            print("❌ Documentation serving tests failed")
            return 1
    
    print("\n🎉 All tests passed!")
    print("\n📋 To manually test the documentation:")
    print("  1. conda activate pythonsupport")
    print("  2. python3 docs/tools/serve_docs.py --regenerate --watch")
    print("  3. Open http://localhost:8000 in your browser")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())