# VS Code

The VS Code installer, settings, and extension scripts are environment-dependent
leaf operations. Use the full online installer or the command launcher's
`install-vscode` action, which runs all three operations in order.

For custom online integration tests, `PS_VSCODE_URL` may override the
architecture-appropriate stable installer selected by `Core/env.*`.

## Default settings

- Disable AI features
- Disable chat agent
- Set Python locator to JS
- Disable telemetry

Extensions are listed and documented in `config/extensions.txt`. Both online
and offline-core setups install those IDs through the VS Code Marketplace, so
the extension step requires internet access. A Marketplace failure is reported
as a warning by the aggregate installers and can be retried later.
