# Logo Setup Guide for sijil App

## Current Configuration ✅

Your app is already configured to use `assets/logo.png` for:
- ✅ App icon (iOS & Android)
- ✅ Splash screen logo
- ✅ Login page logo

## Steps to Add Your sijil Logo

### Step 1: Add Logo File
1. Place your sijil logo image in: `attendance_app/assets/logo.png`
2. Recommended specifications:
   - **Format**: PNG (with transparency if needed)
   - **Size**: 1024x1024 pixels (square)
   - **Background**: Transparent or white (as per your design)

### Step 2: Generate App Icons
After adding the logo file, run:

```bash
cd attendance_app
flutter pub get
flutter pub run flutter_launcher_icons
```

This will automatically generate all required icon sizes for:
- iOS (all required sizes)
- Android (all required sizes including adaptive icons)

### Step 3: Verify
- Check that `assets/logo.png` exists
- Run the app to see the logo on splash and login screens
- App icons will be updated automatically

## Current Logo Usage

### Splash Screen (`lib/presentation/views/auth/splash_page.dart`)
- Logo size: 120x120 pixels
- Centered on white background

### Login Page (`lib/presentation/views/auth/login_page.dart`)
- Logo size: 120x120 pixels
- Centered above login form

### App Icon Configuration (`pubspec.yaml`)
- Uses `assets/logo.png` for both iOS and Android
- Adaptive icon background: White (#FFFFFF)
- iOS: Alpha channel removed (App Store requirement)

## Notes

- The logo will automatically appear in splash and login screens once you add `assets/logo.png`
- App icons are generated from the same logo file
- Make sure the logo looks good on both light and dark backgrounds (if you plan to support dark mode)

