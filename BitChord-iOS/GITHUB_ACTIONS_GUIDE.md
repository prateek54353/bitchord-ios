# GitHub Actions Unsigned Device IPA Build Guide

This repository includes a GitHub Actions workflow to build unsigned IPA files for iOS devices.

## Available Workflow

### Build Device IPA (Unsigned)
**File**: `.github/workflows/build-device-ipa.yml`

Builds an unsigned IPA for actual iOS devices. This is a real device build that can be:
- Installed on physical iOS devices (requires sideloading)
- Used for device testing
- Shared with testers

**Features**:
- Universal binary (arm64 + x86_64) for all device types
- Unsigned (no Apple Developer account required)
- Optimized release configuration
- Stripped Swift symbols for smaller file size

**Triggers**:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual trigger (workflow_dispatch)

## How to Trigger a Build

### Option 1: Push to Branch
Simply push to `main` or `develop`:
```bash
git push origin main
```

### Option 2: Manual Trigger
1. Go to the Actions tab in your GitHub repository
2. Select "Build Device IPA (Unsigned)"
3. Click "Run workflow"
4. Select the branch
5. Click "Run workflow" again

## Downloading the IPA

### After Build Completes

1. Go to the Actions tab in your GitHub repository
2. Click on the completed workflow run
3. Scroll down to the "Artifacts" section
4. Download the artifact: `BitChord-device-unsigned-ipa`

### Artifact Retention
- IPAs are retained for 30 days
- Build logs are retained for 7 days
- Archives are retained for 7 days

## Installing the IPA

Since this is an unsigned device IPA, you'll need to sideload it:

#### Option 1: AltStore (Recommended)
1. Install AltStore on your iOS device
2. Download the IPA
3. Open the IPA with AltStore
4. AltStore will sign it with your personal certificate
5. Install on your device

#### Option 2: Sideloadly
1. Download Sideloadly (macOS or Windows)
2. Connect your iOS device
3. Load the IPA
4. Sideloadly will sign and install it

#### Option 3: Xcode
1. Open the IPA in Xcode
2. Add your Apple ID as a team
3. Build and run on your device

## Important Notes

### Unsigned Builds
- These builds are NOT signed with a developer certificate
- They cannot be distributed via TestFlight or App Store
- They can only be installed via sideloading
- They will expire after 7 days (personal certificate) or need re-signing

### Code Signing
The workflows explicitly disable code signing:
```
CODE_SIGN_IDENTITY=""
CODE_SIGNING_REQUIRED=NO
CODE_SIGNING_ALLOWED=NO
```

This allows the build to complete without a paid Apple Developer account.

### For Production Builds
To create a production-ready IPA:
1. Add your Apple Developer account credentials to GitHub Secrets
2. Update the workflow to use proper code signing
3. Use `method: app-store` or `method: ad-hoc` in ExportOptions.plist
4. Configure provisioning profiles

## Workflow Details

### Build Steps
1. Checkout repository
2. Set up Xcode (latest stable)
3. Resolve Swift Package Manager dependencies
4. Clean build folder
5. Build for iOS Device (Universal binary: arm64 + x86_64)
6. Create archive
7. Export IPA (unsigned)
8. Upload artifacts

### Build Configuration
- **Configuration**: Release
- **Scheme**: BitChord
- **Destination**: Generic iOS platform
- **Architecture**: Universal (arm64 + x86_64)
- **Swift Package Manager**: Enabled
- **Code Signing**: Disabled (unsigned)
- **Swift Symbols**: Stripped (smaller file size)

## Troubleshooting

### Build Fails
- Check the build logs in the artifacts
- Ensure Xcode project is properly configured
- Verify all dependencies are resolvable

### IPA Not Found
- Check the "Artifacts" section in the workflow run
- Look at the build logs for errors
- The workflow outputs IPA location information

### Installation Fails
- Ensure you're using a compatible method (AltStore, Sideloadly, Xcode)
- Verify your device is supported
- Check that the IPA is not corrupted

## Customization

### Change iOS Version
Edit the workflow to specify a different iOS version:
```yaml
-destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### Change Build Configuration
Edit the workflow to use Debug instead of Release:
```yaml
-configuration Debug
```

### Add Custom Build Steps
Add additional steps in the workflow YAML as needed.

## Security

### GitHub Secrets
The current workflows don't require any secrets since they build unsigned apps.

For signed builds, you would need:
- `APPLE_CERTIFICATE`: Base64-encoded certificate
- `APPLE_CERTIFICATE_PASSWORD`: Certificate password
- `PROVISIONING_PROFILE`: Base64-encoded provisioning profile
- `KEYCHAIN_PASSWORD`: Keychain password

These should be added to GitHub repository secrets.

## Support

For issues with the workflows:
1. Check the workflow logs
2. Review Xcode build settings
3. Verify the project structure
4. Open an issue in the repository

## Related Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Xcode Build Settings Reference](https://developer.apple.com/library/archive/documentation/DeveloperTools/Reference/XcodeBuildSettingsRef/)
- [iOS App Signing Guide](https://developer.apple.com/support/app-signing/)
