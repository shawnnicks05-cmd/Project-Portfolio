# Firebase Password Reset Email Troubleshooting Guide

## Common Issues and Solutions

### 1. Check Firebase Console Email Configuration

**Go to Firebase Console:**
1. Visit https://console.firebase.google.com/
2. Select your project: `selecta-coe-main`
3. Go to **Authentication** → **Settings** → **Templates**

**Verify Email Template:**
- Ensure the "Password reset" template is enabled
- Check that the email template has valid content
- Verify the action URL is properly configured

### 2. Check Email Provider Settings

**In Firebase Console → Authentication → Settings:**
1. **Email/Password** should be enabled
2. **Email templates** should be configured
3. **Authorized domains** should include your app's domain

### 3. Test with Real User Account

**Important:** Firebase only sends password reset emails for existing users. Make sure:
- The email you're testing exists in Firebase Auth
- The user was created with email/password authentication (not social login)

### 4. Check Spam Folder

Emails often end up in spam. Check:
- Gmail's Spam folder
- Promotions tab in Gmail
- All Mail folder

### 5. Verify Firebase Project Configuration

**Check your google-services.json:**
- Project ID: `selecta-coe-main`
- Ensure the configuration matches your Firebase console

### 6. Network and Debugging

**Debug logs are now enabled. Run the app and check:**
- Console output for "Sending password reset email to: [email]"
- Any error messages from Firebase

**Common error codes:**
- `user-not-found`: Email doesn't exist in Firebase Auth
- `invalid-email`: Email format is invalid
- `too-many-requests`: Rate limit exceeded
- `network-request-failed`: Network connectivity issues

### 7. Email Delivery Issues

If emails aren't being delivered:

1. **Check Firebase email quotas:**
   - Go to Firebase Console → Usage and billing
   - Check Authentication service usage

2. **Verify domain reputation:**
   - If using custom domains, ensure they have good sending reputation

3. **Test with different email providers:**
   - Try Gmail, Outlook, Yahoo to see if it's provider-specific

### 8. Development vs Production

**Development environment:**
- Use emulator for testing: `firebase emulators:start`
- Check if you're accidentally hitting emulator instead of production

**Production environment:**
- Ensure you're not using test mode configurations

## Quick Test Steps

1. **Create a test user** in your app with email/password
2. **Try password reset** with that exact email
3. **Check console logs** for debug messages
4. **Check email inbox** (including spam folder)
5. **Wait up to 5 minutes** for email delivery

## If Still Not Working

1. **Check Firebase Console logs** for any authentication errors
2. **Verify internet connectivity** on the device
3. **Try a different email address** to rule out email-specific issues
4. **Contact Firebase support** if the issue persists

## Debug Output

The app now logs detailed information:
- Email being sent to
- Success/failure messages
- Firebase error codes and messages

Check your Flutter console/debug output for these messages when testing.
