# Background Images Placeholder

This file serves as a placeholder for background images that would be used in the installer.

## Required Images:

- `background.png` - Light mode installer background (recommended: 620x418 pixels)
- `background-dark.png` - Dark mode installer background (recommended: 620x418 pixels)

## Design Guidelines:

### Colors:
- Primary: DTU Red (#DC2525 or similar)
- Secondary: DTU Blue (#2563eb) 
- Accent: Python Green (#30d158)
- Background: Light grey (#f8f9fa) for light mode, Dark grey (#1a1a1a) for dark mode

### Content:
- Subtle DTU branding
- Python/development theme elements
- Professional, clean design
- Compatible with macOS installer aesthetics

## Temporary Solution:
For development purposes, the installer will work without these images, using the default macOS installer appearance. The background references in Distribution.xml can be commented out if needed.

## Production:
For production use, create proper branded background images and replace this placeholder file.