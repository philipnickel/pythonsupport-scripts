#!/usr/bin/env python3
"""
Documentation extraction tool for shell scripts.
Parses docstrings from shell scripts and generates markdown documentation.
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional
import argparse


class DocstringExtractor:
    """Extracts and processes docstrings from shell scripts."""
    
    def __init__(self):
        self.docstring_pattern = re.compile(
            r'# @doc\s*\n(.*?)\n# @/doc',
            re.DOTALL | re.MULTILINE
        )
        self.field_pattern = re.compile(r'# @(\w+):\s*(.*?)(?=\n# @|\n# @/doc|\Z)', re.DOTALL)
    
    def extract_docstring(self, file_path: str) -> Optional[Dict[str, str]]:
        """Extract docstring from a shell script file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return None
        
        # Find the docstring block
        match = self.docstring_pattern.search(content)
        if not match:
            return None
        
        docstring_content = match.group(1)
        
        # Extract fields from the docstring
        fields = {}
        for field_match in self.field_pattern.finditer(docstring_content):
            field_name = field_match.group(1)
            field_value = field_match.group(2).strip()
            # Clean up the field value (remove leading # and spaces from multiline content)
            field_value = re.sub(r'\n#\s*', ' ', field_value)
            fields[field_name] = field_value.strip()
        
        # Add file path for reference
        fields['file_path'] = file_path
        
        return fields
    
    def find_shell_scripts(self, directory: str) -> List[str]:
        """Find all shell scripts in the given directory."""
        shell_scripts = []
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith('.sh'):
                    shell_scripts.append(os.path.join(root, file))
        return shell_scripts
    
    def extract_all_docs(self, directory: str) -> Dict[str, Dict[str, str]]:
        """Extract documentation from all shell scripts in directory."""
        scripts = self.find_shell_scripts(directory)
        docs = {}
        
        for script in scripts:
            doc = self.extract_docstring(script)
            if doc:
                # Use relative path as key
                rel_path = os.path.relpath(script, directory)
                docs[rel_path] = doc
        
        return docs


class MarkdownGenerator:
    """Generates markdown documentation from extracted docstrings."""
    
    def __init__(self):
        pass
    
    def generate_component_docs(self, docs: Dict[str, Dict[str, str]]) -> str:
        """Generate comprehensive component documentation."""
        # Group by category
        categories = {}
        for script_path, doc in docs.items():
            category = doc.get('category', 'Miscellaneous')
            if category not in categories:
                categories[category] = []
            categories[category].append((script_path, doc))
        
        markdown = "# Component Documentation\n\n"
        markdown += "Auto-generated documentation from script docstrings.\n\n"
        
        # Table of contents
        markdown += "## Table of Contents\n\n"
        for category in sorted(categories.keys()):
            markdown += f"- [{category}](#{category.lower().replace(' ', '-')})\n"
        markdown += "\n"
        
        # Generate sections for each category
        for category in sorted(categories.keys()):
            markdown += f"## {category}\n\n"
            scripts = categories[category]
            
            for script_path, doc in sorted(scripts):
                markdown += self.generate_script_section(script_path, doc)
                markdown += "\n---\n\n"
        
        return markdown
    
    def generate_script_section(self, script_path: str, doc: Dict[str, str]) -> str:
        """Generate markdown section for a single script."""
        name = doc.get('name', os.path.basename(script_path))
        markdown = f"### {name}\n\n"
        
        # Description
        if 'description' in doc:
            markdown += f"{doc['description']}\n\n"
        
        # File path
        markdown += f"**File:** `{script_path}`\n\n"
        
        # Requirements
        if 'requires' in doc:
            markdown += f"**Requirements:** {doc['requires']}\n\n"
        
        # Usage
        if 'usage' in doc:
            markdown += f"**Usage:**\n```bash\n{doc['usage']}\n```\n\n"
        
        # Example
        if 'example' in doc:
            markdown += f"**Example:**\n```bash\n{doc['example']}\n```\n\n"
        
        # Notes
        if 'notes' in doc:
            markdown += f"**Notes:** {doc['notes']}\n\n"
        
        # Version and author
        version_info = []
        if 'version' in doc:
            version_info.append(f"Version: {doc['version']}")
        if 'author' in doc:
            version_info.append(f"Author: {doc['author']}")
        
        if version_info:
            markdown += f"*{' | '.join(version_info)}*\n\n"
        
        return markdown
    
    def generate_index(self, docs: Dict[str, Dict[str, str]]) -> str:
        """Generate an index/overview page."""
        markdown = "# Python Support Scripts Documentation\n\n"
        markdown += "This documentation is automatically generated from docstrings in the shell scripts.\n\n"
        
        # Summary stats
        categories = {}
        for doc in docs.values():
            category = doc.get('category', 'Miscellaneous')
            categories[category] = categories.get(category, 0) + 1
        
        markdown += f"**Total Scripts:** {len(docs)}\n\n"
        markdown += "**Categories:**\n"
        for category, count in sorted(categories.items()):
            markdown += f"- {category}: {count} script{'s' if count > 1 else ''}\n"
        markdown += "\n"
        
        # Quick links
        markdown += "## Documentation Pages\n\n"
        markdown += "- [Components Documentation](components.md) - Detailed documentation for all components\n\n"
        
        return markdown
    
    def generate_structured_docs(self, docs: Dict[str, Dict[str, str]], output_dir: str, verbose: bool = False):
        """Generate documentation files organized by directory structure."""
        # Group docs by directory structure
        structure = {}
        
        for script_path, doc in docs.items():
            # Parse directory path (e.g., "Python/install.sh" -> ["Python"])
            path_parts = script_path.split('/')
            dir_name = path_parts[0] if len(path_parts) > 1 else 'Root'
            
            # Rename "Shared" to "Utilities" for better documentation organization
            if dir_name == 'Shared':
                dir_name = 'Utilities'
            
            if dir_name not in structure:
                structure[dir_name] = []
            structure[dir_name].append((script_path, doc))
        
        # Generate directory-specific files
        for dir_name, dir_docs in structure.items():
            dir_markdown = f"# {dir_name} Components\n\n"
            dir_markdown += f"Documentation for {dir_name} installation scripts.\n\n"
            
            for script_path, doc in sorted(dir_docs):
                script_name = os.path.basename(script_path).replace('.sh', '')
                dir_markdown += f"## {doc.get('name', script_name)}\n\n"
                
                if doc.get('description'):
                    dir_markdown += f"**Description:** {doc['description']}\n\n"
                
                if doc.get('usage'):
                    dir_markdown += f"**Usage:**\n```bash\n{doc['usage']}\n```\n\n"
                
                if doc.get('requirements'):
                    dir_markdown += f"**Requirements:** {doc['requirements']}\n\n"
                
                if doc.get('notes'):
                    dir_markdown += f"**Notes:** {doc['notes']}\n\n"
                
                # Add installation command
                github_url = f"https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/{script_path}"
                dir_markdown += f"**Installation:**\n```bash\n/bin/bash -c \"$(curl -fsSL {github_url})\"\n```\n\n"
                dir_markdown += "---\n\n"
            
            # Write directory-specific file
            filename = f"{dir_name.lower()}.md"
            with open(os.path.join(output_dir, filename), 'w') as f:
                f.write(dir_markdown)
            
            if verbose:
                print(f"  - {filename} ({len(dir_docs)} scripts)")
        
        # Generate navigation structure for MkDocs
        nav_items = []
        for dir_name in sorted(structure.keys()):
            filename = f"{dir_name.lower()}.md"
            nav_items.append(f"    - {dir_name}: generated/{filename}")
        
        nav_structure = "  - MacOS:\n" + "\n".join(nav_items)
        
        # Write navigation suggestion to a file
        with open(os.path.join(output_dir, 'mkdocs_nav.yml'), 'w') as f:
            f.write("# Suggested MkDocs navigation structure:\n")
            f.write("nav:\n")
            f.write("  - Home: index.md\n")
            f.write(nav_structure + "\n")
            f.write("  - Windows:\n")
            f.write("    - Components: windows/components/index.md\n")
        
        if verbose:
            print(f"  - mkdocs_nav.yml (navigation structure)")


def main():
    parser = argparse.ArgumentParser(description='Extract documentation from shell scripts')
    parser.add_argument('--input', '-i', default='MacOS/Components', help='Input directory to scan')
    parser.add_argument('--output', '-o', default='docs/generated', help='Output directory for documentation')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Create output directory
    os.makedirs(args.output, exist_ok=True)
    
    # Extract documentation
    extractor = DocstringExtractor()
    docs = extractor.extract_all_docs(args.input)
    
    if args.verbose:
        print(f"Found {len(docs)} documented scripts:")
        for script in docs.keys():
            print(f"  - {script}")
    
    if not docs:
        print("No documented scripts found!")
        return 1
    
    # Generate markdown
    generator = MarkdownGenerator()
    
    # Generate structured documentation
    generator.generate_structured_docs(docs, args.output, args.verbose)
    
    # Also generate the combined components.md for backward compatibility
    component_docs = generator.generate_component_docs(docs)
    with open(os.path.join(args.output, 'components.md'), 'w') as f:
        f.write(component_docs)
    
    # Generate index
    index_docs = generator.generate_index(docs)
    with open(os.path.join(args.output, 'index.md'), 'w') as f:
        f.write(index_docs)
    
    if not args.verbose:
        print(f"Documentation generated in {args.output}/")
        print(f"  - index.md ({len(docs)} scripts)")
        print(f"  - components.md (combined documentation)")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())