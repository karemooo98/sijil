# Google Play Store Submission Guide for سجّل | Sijil

This guide will walk you through the complete process of uploading your Flutter app to the Google Play Store.

## Prerequisites

- Google Play Developer Account ($25 one-time fee)
- Completed app development and testing
- App icon and screenshots ready
- Privacy policy URL (if your app collects user data)

---

## Step 1: Create a Release Keystore

Your app must be signed with a release keystore before uploading to Play Store.

### Generate the Keystore

Run this command in your terminal (from the project root):

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important details to provide:**

- **Keystore password**: Choose a strong password (save it securely!)
- **Key password**: Can be same as keystore password or different
- **Name**: Your name or organization name
- **Organizational Unit**: Department (optional)
- **Organization**: Your company name
- **City**: Your city
- **State**: Your state/province
- **Country code**: Two-letter code (e.g., US, SA, AE)

### Configure Signing

1. Copy the template file:

   ```bash
   cp android/key.properties.template android/key.properties
   ```

2. Edit `android/key.properties` and fill in your actual values:

   ```properties
   storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
   keyPassword=YOUR_ACTUAL_KEY_PASSWORD
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

3. **IMPORTANT**: Add `key.properties` and `upload-keystore.jks` to `.gitignore` to keep them secure:

   ```
   android/key.properties
   android/upload-keystore.jks
   ```

4. **Backup your keystore**: Store `upload-keystore.jks` and passwords in a secure location. If you lose this file, you cannot update your app on Play Store!

---

## Step 2: Build the Release App Bundle (AAB)

Google Play requires Android App Bundle (AAB) format, not APK.

### Build the AAB

From the project root, run:

```bash
flutter build appbundle --release
```

The AAB file will be generated at:

```
build/app/outputs/bundle/release/app-release.aab
```

### Verify the Build

- Check the file size (should be reasonable for your app)
- Test the build locally if possible using:
  ```bash
  flutter build apk --release
  ```
  Then install on a device to verify everything works.

---

## Step 3: Create Google Play Developer Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your Google account
3. Pay the $25 one-time registration fee
4. Complete your developer profile

---

## Step 4: Create Your App in Play Console

1. In Play Console, click **"Create app"**
2. Fill in the details:
   - **App name**: سجّل | Sijil (or "Sijil" if Arabic causes issues)
   - **Default language**: Select your primary language
   - **App or game**: Select "App"
   - **Free or paid**: Select "Free" or "Paid"
   - **Declarations**: Accept terms and complete declarations

---

## Step 5: Set Up App Content

### 5.1 Store Listing

Fill in all required fields:

- **App name**: سجّل | Sijil
- **Short description**: (80 characters max)
  - Example: "Employee attendance tracking and management system"
- **Full description**: (4000 characters max)
  - Describe features, benefits, and usage
  - Include keywords for search optimization
- **App icon**: 512x512 PNG (no transparency)
- **Feature graphic**: 1024x500 PNG
- **Screenshots**:
  - Phone: At least 2, up to 8 (16:9 or 9:16 ratio)
  - Tablet (7-inch): Optional but recommended
  - Tablet (10-inch): Optional but recommended
- **Category**: Productivity / Business
- **Contact details**: Email and website
- **Privacy policy**: URL (required if app collects data)

### 5.2 Content Rating

Complete the content rating questionnaire. For an attendance app, it should be rated "Everyone" or "Teen".

### 5.3 Target Audience

- Select appropriate age groups
- Indicate if content is designed for children

---

## Step 6: Upload Your App Bundle

1. Go to **"Production"** (or **"Internal testing"** for initial testing)
2. Click **"Create new release"**
3. Upload your `app-release.aab` file
4. Fill in **Release name**: e.g., "1.0.0 (1)"
5. Add **Release notes**: Describe what's new in this version
6. Click **"Save"**

---

## Step 7: Complete App Information

### 7.1 App Access

- If your app requires login, provide test credentials for Google reviewers
- Add instructions if needed

### 7.2 Ads

- Declare if your app shows ads
- If yes, complete ad content rating

### 7.3 Content Rating

- Complete the IARC questionnaire
- This generates a rating certificate

### 7.4 Target Audience and Content

- Select appropriate categories
- Declare sensitive permissions usage

### 7.5 Data Safety

**Required section** - Declare:

- What data you collect (if any)
- How data is used
- Whether data is shared
- Security practices

For an attendance app, you might collect:

- Employee information
- Location data (if using GPS)
- Photos (if using image picker)

---

## Step 8: Pricing and Distribution

1. **Pricing**: Set as Free or Paid
2. **Countries**: Select where to distribute
3. **Device categories**: Phone, Tablet, etc.
4. **User programs**: Opt into programs if desired

---

## Step 9: Review and Submit

1. Review all sections - ensure nothing is missing (red/yellow indicators)
2. Click **"Start rollout to Production"** (or your chosen track)
3. Your app will be submitted for review
4. Review typically takes 1-7 days

---

## Step 10: After Submission

### Monitor Status

- Check Play Console regularly for review status
- Respond to any reviewer feedback promptly

### Common Issues

- **Rejected for policy violation**: Review Google Play policies
- **Request for more information**: Provide clarifications
- **Request for demo account**: Provide test credentials

### Once Approved

- Your app will be live on Play Store
- Users can download and install
- Monitor reviews and ratings
- Respond to user feedback

---

## Updating Your App

For future updates:

1. Increment version in `pubspec.yaml`:

   ```yaml
   version: 1.0.1+2 # versionName+versionCode
   ```

2. Build new AAB:

   ```bash
   flutter build appbundle --release
   ```

3. Upload to Play Console in the same release track

4. Submit for review

---

## Important Notes

### Version Code

- Must increase with each release
- Current: `1` (from `1.0.0+1`)
- Next release: `2` (e.g., `1.0.1+2`)

### Keystore Security

- **NEVER** commit `key.properties` or `upload-keystore.jks` to version control
- Store backups securely
- If lost, you cannot update your app (must create new app listing)

### Testing

Consider using these tracks before production:

1. **Internal testing**: For your team
2. **Closed testing**: For beta testers
3. **Open testing**: For public beta
4. **Production**: Public release

### Permissions

Your app uses these permissions:

- `CAMERA`: For taking photos
- `READ_MEDIA_IMAGES`: For selecting images (Android 13+)
- `READ_EXTERNAL_STORAGE`: For older Android versions
- `WRITE_EXTERNAL_STORAGE`: For older Android versions

Make sure to justify these in the Data Safety section.

---

## Checklist Before Submission

- [ ] Keystore created and configured
- [ ] App bundle (AAB) built successfully
- [ ] App tested on real devices
- [ ] App icon (512x512) ready
- [ ] Screenshots prepared (at least 2)
- [ ] Feature graphic (1024x500) ready
- [ ] Store listing description written
- [ ] Privacy policy URL ready (if needed)
- [ ] Content rating completed
- [ ] Data Safety section completed
- [ ] Test credentials provided (if app requires login)
- [ ] All app information sections completed
- [ ] App bundle uploaded
- [ ] Ready to submit for review

---

## Resources

- [Google Play Console](https://play.google.com/console)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/android)
- [Google Play Policies](https://play.google.com/about/developer-content-policy/)

---

## Support

If you encounter issues:

1. Check Play Console for specific error messages
2. Review Google Play policies
3. Check Flutter documentation
4. Review app logs for crashes

Good luck with your submission! 🚀
