# Microsoft Store packaging

The unsigned development MSIX can be built with:

```powershell
flutter build windows --release
dart run msix:create --build-windows false --sign-msix false --install-certificate false
```

Output: build/distribution/Frame-Octopus-0.2.0-Windows-x64-unsigned-dev.msix.

This package uses an explicit **development identity**, is not signed, and is not an install-ready release or a Store submission. No certificate is generated, installed or trusted by these commands. For running locally, use the complete Windows Release directory.

## Prepare the Store submission

1. Reserve the app in Partner Center. Copy the exact Package/Identity/Name, Package/Identity/Publisher and publisher display name from Product identity into pubspec.yaml. Set store to true. Do not substitute the development identity.
2. Build the Store MSIX with `dart run msix:create --store --sign-msix false --install-certificate false`. Microsoft signs accepted Store MSIX packages; a paid external signing certificate is not required for this path.
3. Run Windows App Certification Kit on the correctly identified package in a suitable test environment. WACK has not been claimed as passed by the development package.
4. Finalize native source/license redistribution materials. The current native license/source inventory is described in THIRD_PARTY_NOTICES.md. A package build alone is not proof of licensing completeness.
5. Publish docs/PRIVACY.md at a stable public URL, complete the Store listing/age-rating declarations and upload the package/screenshots for review. A listing draft is in STORE_LISTING.md.

Source: https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options
Identity checklist: https://learn.microsoft.com/en-us/windows/apps/publish/store-readiness-checklist

Keep all private signing certificates, passwords, local identity overrides and development test certificates outside Git. No signing material from other projects is used. Store account reservation, legal declarations, public release and certification remain external release steps.

The packaging helper `tool/package_windows.ps1` creates both artifacts and SHA256.json. It restores the installed runtime files after MSIX tooling cleanup, then creates the portable ZIP. Structural checks are recorded in ARTIFACT_AUDIT.json. They do not substitute for WACK or a clean-machine installed-package test.
