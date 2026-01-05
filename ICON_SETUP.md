# App Icon & Splash Screen Setup Guide

## Step 1: Place Your Image File

1. **Save your FH Technology logo image** as `app_icon.jpg`
2. **Recommended size**: 1024x1024 pixels (square, PNG format)
3. **Place it here**: `assets/images/app_icon.jpg`

   The image should be:
   - Square (equal width and height)
   - High resolution (at least 1024x1024px)
   - PNG format with transparent background (if needed)
   - Or with blue background matching your logo

## Step 2: Install Dependencies

Run this command in your terminal:
```bash
flutter pub get
```

## Step 3: Generate Splash Screen & App Icons

After placing your image, run:
```bash
dart run flutter_native_splash:create
```

This will:
- ✅ Generate splash screen for Android and iOS
- ✅ Create app icons in all required sizes
- ✅ Configure everything automatically

## Step 4: Verify

1. Check that `assets/images/app_icon.png` exists
2. Run `flutter pub get`
3. Run `dart run flutter_native_splash:create`
4. Build and test on your device

## Manual App Icon Setup (Alternative)

If you prefer to set icons manually, you'll need to:

### Android:
- Replace icons in: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Sizes needed: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi

### iOS:
- Replace icons in: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Multiple sizes from 20x20 to 1024x1024

But using `flutter_native_splash` is much easier! 🎉

## Current Configuration

- **Splash Background Color**: Blue (#2196F3) - matches your logo
- **Splash Image**: Your app icon (centered)
- **Platforms**: Android & iOS enabled

## Troubleshooting

If you get errors:
1. Make sure the image file exists at `assets/images/app_icon.png`
2. Make sure the image is square (width = height)
3. Try a smaller image size if the tool has issues
4. Check that `flutter_native_splash` is installed: `flutter pub get`

