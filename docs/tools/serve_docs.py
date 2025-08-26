#!/usr/bin/env python3
"""
Documentation server for local testing and development.
Serves generated documentation with live reloading.
"""

import os
import sys
import threading
import time
from pathlib import Path
from http.server import HTTPServer, SimpleHTTPRequestHandler
import argparse
import markdown
import subprocess
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler


class MarkdownHandler(SimpleHTTPRequestHandler):
    """HTTP handler that converts markdown to HTML on the fly."""
    
    def __init__(self, *args, docs_dir='docs/generated', **kwargs):
        self.docs_dir = docs_dir
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle GET requests, converting markdown to HTML as needed."""
        path = self.path.strip('/')
        
        # Default to index.md
        if not path or path == '/':
            path = 'index.md'
            
        # Add .md extension if missing and not a file extension already
        if not '.' in os.path.basename(path):
            path += '.md'
            
        file_path = os.path.join(self.docs_dir, path)
        
        if os.path.exists(file_path) and file_path.endswith('.md'):
            self.serve_markdown(file_path)
        else:
            # Fall back to default behavior for other files
            super().do_GET()
    
    def serve_markdown(self, file_path):
        """Convert markdown file to HTML and serve it."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Convert markdown to HTML
            md = markdown.Markdown(extensions=['codehilite', 'toc', 'tables', 'fenced_code'])
            html_content = md.convert(content)
            
            # Wrap in basic HTML template
            html = f"""
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Python Support Scripts Documentation</title>
                <style>
                    body {{
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
                        line-height: 1.6;
                        color: #333;
                        max-width: 1200px;
                        margin: 0 auto;
                        padding: 20px;
                        background-color: #fff;
                    }}
                    h1, h2, h3, h4, h5, h6 {{
                        color: #2c3e50;
                        border-bottom: 1px solid #eaecef;
                        padding-bottom: 0.3em;
                    }}
                    code {{
                        background-color: #f8f8f8;
                        padding: 2px 4px;
                        border-radius: 3px;
                        font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, Courier, monospace;
                    }}
                    pre {{
                        background-color: #f8f8f8;
                        padding: 16px;
                        border-radius: 6px;
                        overflow-x: auto;
                    }}
                    pre code {{
                        background-color: transparent;
                        padding: 0;
                    }}
                    blockquote {{
                        border-left: 4px solid #dfe2e5;
                        padding: 0 16px;
                        color: #6a737d;
                    }}
                    table {{
                        border-collapse: collapse;
                        width: 100%;
                        margin: 16px 0;
                    }}
                    th, td {{
                        border: 1px solid #dfe2e5;
                        padding: 8px 12px;
                        text-align: left;
                    }}
                    th {{
                        background-color: #f8f9fa;
                        font-weight: 600;
                    }}
                    .nav {{
                        margin-bottom: 30px;
                        padding: 10px;
                        background-color: #f8f9fa;
                        border-radius: 6px;
                    }}
                    .nav a {{
                        margin-right: 15px;
                        text-decoration: none;
                        color: #0366d6;
                    }}
                    .nav a:hover {{
                        text-decoration: underline;
                    }}
                </style>
            </head>
            <body>
                <div class="nav">
                    <a href="/">🏠 Home</a>
                    <a href="/components">📚 Components</a>
                    <a href="#" onclick="location.reload()">🔄 Refresh</a>
                </div>
                {html_content}
            </body>
            </html>
            """
            
            # Send response
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            self.wfile.write(html.encode('utf-8'))
            
        except Exception as e:
            self.send_error(500, f"Error serving markdown: {str(e)}")


class DocRegenHandler(FileSystemEventHandler):
    """Handler for file system events to regenerate docs."""
    
    def __init__(self, extract_script, input_dir, output_dir):
        self.extract_script = extract_script
        self.input_dir = input_dir
        self.output_dir = output_dir
        self.last_regen = 0
        
    def on_modified(self, event):
        """Regenerate docs when shell scripts are modified."""
        if not event.is_directory and event.src_path.endswith('.sh'):
            # Throttle regeneration to avoid excessive rebuilds
            now = time.time()
            if now - self.last_regen > 2:  # Wait at least 2 seconds between regens
                print(f"📝 Detected change in {event.src_path}, regenerating docs...")
                self.regenerate_docs()
                self.last_regen = now
    
    def regenerate_docs(self):
        """Regenerate documentation."""
        try:
            result = subprocess.run([
                'python3', self.extract_script,
                '--input', self.input_dir,
                '--output', self.output_dir
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✅ Documentation regenerated successfully")
            else:
                print(f"❌ Documentation regeneration failed: {result.stderr}")
        except Exception as e:
            print(f"❌ Error regenerating docs: {e}")


def serve_docs(port=8000, docs_dir='docs/generated', watch=False):
    """Serve documentation on local HTTP server."""
    
    # Make sure docs directory exists
    os.makedirs(docs_dir, exist_ok=True)
    
    # Change to docs directory
    original_cwd = os.getcwd()
    os.chdir(docs_dir)
    
    try:
        # Create custom handler
        def handler(*args, **kwargs):
            return MarkdownHandler(*args, docs_dir='.', **kwargs)
        
        # Start server
        httpd = HTTPServer(('localhost', port), handler)
        
        # Setup file watching if requested
        observer = None
        if watch:
            print("👁️  Setting up file watching for auto-regeneration...")
            event_handler = DocRegenHandler(
                extract_script=os.path.join(original_cwd, 'tools/extract_docs.py'),
                input_dir=os.path.join(original_cwd, 'MacOS/Components'),
                output_dir=os.path.join(original_cwd, docs_dir)
            )
            observer = Observer()
            observer.schedule(event_handler, os.path.join(original_cwd, 'MacOS/Components'), recursive=True)
            observer.start()
        
        print(f"🚀 Documentation server started at http://localhost:{port}")
        print(f"📁 Serving from: {docs_dir}")
        if watch:
            print("👁️  Auto-regeneration enabled - edit shell scripts to see changes")
        print("Press Ctrl+C to stop...")
        
        httpd.serve_forever()
        
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Server error: {e}")
    finally:
        if observer:
            observer.stop()
            observer.join()
        os.chdir(original_cwd)


def main():
    parser = argparse.ArgumentParser(description='Serve documentation locally')
    parser.add_argument('--port', '-p', type=int, default=8000, help='Port to serve on')
    parser.add_argument('--docs-dir', '-d', default='docs/generated', help='Documentation directory')
    parser.add_argument('--watch', '-w', action='store_true', help='Watch for changes and auto-regenerate')
    parser.add_argument('--regenerate', '-r', action='store_true', help='Regenerate docs before serving')
    
    args = parser.parse_args()
    
    # Regenerate docs if requested
    if args.regenerate:
        print("📝 Regenerating documentation...")
        try:
            result = subprocess.run([
                'python3', 'tools/extract_docs.py',
                '--input', 'MacOS/Components',
                '--output', args.docs_dir,
                '--verbose'
            ], check=True)
            print("✅ Documentation regenerated")
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to regenerate docs: {e}")
            return 1
    
    # Serve docs
    serve_docs(port=args.port, docs_dir=args.docs_dir, watch=args.watch)
    return 0


if __name__ == '__main__':
    sys.exit(main())