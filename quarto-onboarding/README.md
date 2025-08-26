# Python Installation Support - Onboarding Guide

🌐 **Live Site:** https://philipnickel.github.io/PIS_onboarding/

## About

This repository contains the onboarding guide for Python Installation Support team members. The guide is built using [Quarto](https://quarto.org/) and organized into three main sections:

- **Your Role in the Team** - Mission, responsibilities, workflow, and team values
- **Introduction Process** - Getting started, meetings, training, and success milestones  
- **Tools & Practicals** - Essential tools, time registration, daily operations, and support

## Features

- **Top Navigation** - Clean pinned navbar for easy section navigation
- **Table of Contents** - Right sidebar TOC for within-page navigation
- **PDF Downloads** - Individual section PDFs and complete guide available
- **External Links** - All external links open in new tabs
- **Step-by-step Images** - Visual guides for complex procedures (FUSION registration)
- **Responsive Design** - Works on desktop and mobile devices
- **Search** - Built-in search functionality

## File Structure

```
quarto-onboarding/
├── _quarto.yml                   # Quarto configuration
├── index.qmd                     # Welcome page and navigation guide
├── complete-guide.qmd            # Combined PDF version of all content
├── contents/                     # Individual content files
│   ├── your-role.qmd                 # Team responsibilities and workflow
│   ├── introduction-process.qmd      # Getting started and training
│   ├── tools-practicals.qmd         # Daily tools and procedures
│   └── fusion_steps/                 # Step-by-step screenshots for FUSION
├── fusion_steps/                 # Original screenshots (also in contents/)
├── docs/                         # Generated site (published to GitHub Pages)
└── styles.css                   # Custom styling
```

## Development Commands

### Render All Documents (HTML + Individual PDFs + Complete Guide PDF)
```bash
quarto render
```

### Render Individual Sections
```bash
quarto render contents/index.qmd
quarto render contents/your-role.qmd
quarto render contents/introduction-process.qmd
quarto render contents/tools-practicals.qmd
```

### Render Complete Guide PDF Only
```bash
quarto render complete-guide.qmd --to pdf
```

### Render HTML Only (faster for development)
```bash
quarto render --to html
```

### Preview Site Locally
```bash
quarto preview
```

### Clean Generated Files
```bash
quarto clean
```

## Content Management

### Complete Guide PDF
The complete guide PDF is automatically generated from individual content files using Quarto's `{{< include >}}` mechanism:
- Contains all sections with proper page breaks
- Includes step-by-step images with correct paths
- Maintains consistent formatting and table of contents
- Available for download from the home page

### Making Changes
1. Edit the individual content files in `contents/`
2. Run `quarto render` to update all HTML and PDF outputs
3. The complete guide PDF automatically reflects changes without manual updates

### Adding Images
- Place images in `contents/fusion_steps/` for proper path resolution
- Images work correctly in both individual pages and the complete guide
- Use relative paths like `fusion_steps/image.png` from content files

## Site Structure

The site uses:
- **Top navigation** (pinned, doesn't collapse on scroll)
- **Three main sections** with dedicated pages that don't auto-scroll between sections
- **Right sidebar** for "On this page" table of contents
- **External links** that open in new tabs using `{target="_blank"}` syntax
- **Bootstrap styling** with custom CSS for enhanced appearance

## Deployment

The site automatically deploys to GitHub Pages via GitHub Actions when changes are pushed to the main branch. The workflow:
1. Installs Quarto and TinyTeX (for PDF generation)
2. Renders all content (HTML and PDFs)
3. Deploys the `docs/` folder to GitHub Pages

