# Mac Setup Guide: Fixing the Xcode Project

## 📋 Overview
This guide will help you recreate the Xcode project on a Mac. The source code is complete and ready - we just need a valid Xcode project file.

**Estimated time: 15-30 minutes**

---

## Step 1: Clone the Repository

Open Terminal on the Mac and run:

```bash
cd ~/Desktop
git clone https://github.com/prateek54353/bitchord-ios.git
cd bitchord-ios
```

---

## Step 2: Open Xcode and Create New Project

1. Open Xcode from Applications
2. Choose "Create a new Xcode project"
3. Select **iOS** → **App**
4. Fill in the options:
   - **Product Name**: `BitChord`
   - **Team**: Your development team (or leave blank for unsigned builds)
   - **Organization Identifier**: `com.music`
   - **Bundle Identifier**: `com.music.bitchord`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None
   - **Include Tests**: ✅ (check this)
5. Click "Next"
6. Save it on Desktop, but **don't** save it in the `bitchord-ios` folder yet - save it as `BitChordTemp`

---

## Step 3: Delete Auto-Generated Files

In the new `BitChordTemp` project, delete these files (Right-click → Delete → Move to Trash):

From `BitChordTemp/BitChord/`:
- `ContentView.swift`
- `Assets.xcassets`
- `Preview Assets.xcassets`

From `BitChordTemp/BitChordTests/`:
- `BitChordTests.swift`

Keep:
- `BitChordApp.swift` (we'll replace it)
- `Info.plist` if it exists

---

## Step 4: Copy the Real Source Files

In Terminal:

```bash
# Copy the main app files
cp -r BitChord/BitChord/* BitChordTemp/BitChord/

# Copy the test files
cp -r BitChord/BitChordTests/* BitChordTemp/BitChordTests/
```

---

## Step 5: Add Files to Xcode Project

In Xcode:

1. In the Project Navigator (left sidebar), you'll see the `BitChord` folder
2. Right-click on the `BitChord` folder → "Add Files to BitChord..."
3. Navigate to `BitChordTemp/BitChord/`
4. Select all the folders:
   - `Core/`
   - `DesignSystem/`
   - `Features/`
   - `BitChordApp.swift`
5. Make sure these are checked:
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Create folder references
6. Click "Add"

7. Do the same for test files:
   - Right-click on `BitChordTests` folder
   - "Add Files to BitChord..."
   - Navigate to `BitChordTemp/BitChordTests/`
   - Select all test files
   - Add them

---

## Step 6: Create Asset Catalogs

1. In Xcode, right-click on the `BitChord` folder
2. "New File" → "Asset Catalog"
3. Name it `Assets.xcassets`
4. Click "Create"

5. In the Asset Catalog, you may need to add:
   - AppIcon (optional for now)
   - AccentColor (optional for now)

6. Right-click on `BitChord` folder
7. "New File" → "Asset Catalog"
8. Name it `Preview Assets.xcassets`
9. Click "Create"

---

## Step 7: Configure Build Settings

1. Click on the **BitChord** project (top of Project Navigator)
2. Select the **BitChord** target
3. Go to the **Build Settings** tab
4. Filter and set these values:

**Deployment**:
- iOS Deployment Target: `17.0`

**Packaging**:
- Product Bundle Identifier: `com.music.bitchord`

**Swift Compiler - Language**:
- Swift Version: `5.0`

**Signing & Capabilities**:
- Code Signing Style: `Automatic` (or `Manual` for unsigned)
- Development Team: Your team (or leave blank for unsigned)

**Search - User Header Framework Paths**:
- Leave empty

---

## Step 8: Configure Info.plist

1. Select the **BitChord** target
2. Go to the **Info** tab
3. Add these keys if missing:

**Required keys**:
- `UIApplicationSceneManifest` → Generation: `YES`
- `UIApplicationSupportsIndirectInputEvents`: `YES`
- `UILaunchScreen` → Generation: `YES`

**Supported Orientations**:
- `UISupportedInterfaceOrientations`: `UIInterfaceOrientationPortrait,UIInterfaceOrientationLandscapeLeft,UIInterfaceOrientationLandscapeRight`
- `UISupportedInterfaceOrientations~ipad`: `UIInterfaceOrientationPortrait,UIInterfaceOrientationPortraitUpsideDown,UIInterfaceOrientationLandscapeLeft,UIInterfaceOrientationLandscapeRight`

---

## Step 9: Replace the Corrupted Project

In Terminal:

```bash
# Backup the old project
mv BitChord/BitChord.xcodeproj BitChord/BitChord.xcodeproj.backup

# Copy the new project
cp -r BitChordTemp/BitChord.xcodeproj BitChord/

# Clean up temp
rm -rf BitChordTemp
```

---

## Step 10: Test the Build

In Xcode:

1. Open the project: `File` → `Open` → Select `BitChord/BitChord.xcodeproj`
2. Select a simulator (e.g., iPhone 15)
3. Press `⌘B` to build
4. Check for any errors

If it builds successfully, great! If not, check the errors below.

---

## Step 11: Commit and Push

In Terminal:

```bash
cd BitChord
git add BitChord.xcodeproj
git commit -m "Fix Xcode project file - recreated on Mac"
git push origin main
```

---

## 🔧 Troubleshooting

### Error: "File not found"
- Make sure all files were copied correctly
- Check that folder paths match
- Use "Add Files to Project" for missing files

### Error: "Missing asset catalog"
- Create Assets.xcassets and Preview Assets.xcassets as in Step 6
- Make sure they're added to the project

### Error: "Signing issues"
- For unsigned builds: Set Code Signing Style to `Manual` and leave Development Team blank
- For signed builds: Add your Apple ID in Xcode preferences

### Error: "iOS Deployment Target"
- Make sure it's set to 17.0 or higher
- Check both Project and Target settings

### Error: "Test target not found"
- Make sure BitChordTests target exists
- Check test files are added to the test target
- Verify Test Host is set correctly

---

## ✅ Verification Checklist

After completing the steps, verify:

- [ ] Project opens in Xcode without errors
- [ ] All 36 main Swift files are in the project
- [ ] All 3 test files are in the project
- [ ] Asset catalogs exist (Assets.xcassets, Preview Assets.xcassets)
- [ ] Build settings are correct (iOS 17.0, Swift 5.0)
- [ ] Project builds successfully (⌘B)
- [ ] No missing file errors
- [ ] No signing errors (or signed correctly)

---

## 📝 What to Report Back

If you encounter issues, report:
1. The exact error message
2. Which step you were on
3. A screenshot if possible
4. The Xcode version (from Xcode → About Xcode)

---

## 🎯 Success Indicators

You'll know it worked when:
- Xcode opens the project without errors
- All files show in the Project Navigator
- Build succeeds (or has only minor warnings)
- GitHub Actions workflow can now build the project

---

## 💡 Tips

- Take your time - rushing leads to mistakes
- Use Xcode's auto-fix suggestions when available
- If something looks wrong, delete and redo that step
- Don't modify the Swift files - only the project structure
- Keep the corrupted project as backup until the new one works

---

## 🆘 Need Help?

If you get stuck:
1. Check the troubleshooting section above
2. Look up the error message on Stack Overflow
3. Ask in r/iOSProgramming or r/swift
4. Post the exact error and which step you're on

---

**Good luck! Once this is done, the GitHub Actions workflow will work and you'll be able to build unsigned IPAs.**
