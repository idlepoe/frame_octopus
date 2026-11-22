# Microsoft Store package

Store product: https://apps.microsoft.com/detail/9NVSS25893SG
Partner Center identity: STORE_IDENTITY.json. First Store package version: 1.0.0.0 (current application functionality, Flutter version 1.0.0+3).

Build with `tool/package_store.ps1`. The Store MSIX is unsigned intentionally: Microsoft signs accepted packages. No certificate is generated, installed or trusted, and no private signing key is stored in Git.

Output: build/distribution/Frame-Octopus-1.0.0-Windows-x64-store.msix. Its SHA-256 and manifest/CRC audit are in STORE_SHA256.json and STORE_PACKAGE_AUDIT.json. The identity matches Partner Center and only Windows.Desktop x64 is enabled.

Privacy: https://gist.github.com/idlepoe/a9d2af09558b57ae532b9f41be53b3af
English, Korean and Japanese listing text: STORE_LISTINGS.json. Certification test steps and runFullTrust justification: CERTIFICATION_NOTES.txt. Refreshed current screenshots/video are in distribution-media/. Native copyright notices, source links, selected DLL configuration and replacement instructions are included under licenses/native-provenance in the package.

Partner Center package-upload validation passed. Local WACK execution was blocked by automatic approval review; it is not reported as passed. Package static checks and native application verification are separate from Microsoft certification.

The earlier 0.2.0 unsigned development artifacts remain local historical builds. The repository remains private; only the privacy policy was published separately.
