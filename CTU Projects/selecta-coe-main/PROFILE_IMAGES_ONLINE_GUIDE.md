# Making Profile Images Viewable Online - Step-by-Step Guide

## Current Situation
- Profile images are stored as base64 data URIs in Firestore
- Images only work within the app, not accessible online
- Need to migrate to Firebase Cloud Storage for online visibility

## Step 1: Add Firebase Cloud Storage Dependency

### Update pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6  # Add this line
  image_picker: ^1.0.4
  provider: ^6.1.1
  shared_preferences: ^2.2.2
```

### Run flutter pub get
```bash
flutter pub get
```

## Step 2: Create Firebase Storage Service

### Create file: lib/data/firebase_storage_service.dart
```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload profile image and return public URL
  static Future<String> uploadProfileImage(
    String userId, 
    File imageFile
  ) async {
    try {
      // Create reference for user's profile image
      final ref = _storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child('avatar.jpg');
      
      // Upload file
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Profile image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image');
    }
  }
  
  // Delete old profile image
  static Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child('avatar.jpg');
      
      await ref.delete();
      print('Profile image deleted for user: $userId');
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }
  
  // Check if profile image exists
  static Future<bool> profileImageExists(String userId) async {
    try {
      final ref = _storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child('avatar.jpg');
      
      final metadata = await ref.getMetadata();
      return metadata != null;
    } catch (e) {
      return false;
    }
  }
}
```

## Step 3: Update Profile Screen Image Handling

### Modify _saveChanges() in profile_screen.dart
```dart
void _saveChanges() async {
  if (_displayUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Error: No user data available'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  setState(() => _loading = true); // Add loading state
  
  try {
    String newAvatarUrl = _displayUser!.avatarUrl;
    
    // Upload new image if selected
    if (_pickedImageFile != null) {
      // Delete old image if it's a Cloud Storage URL
      if (_displayUser!.avatarUrl.startsWith('https://')) {
        await FirebaseStorageService.deleteProfileImage(_displayUser!.id);
      }
      
      // Upload new image to Cloud Storage
      newAvatarUrl = await FirebaseStorageService.uploadProfileImage(
        _displayUser!.id,
        _pickedImageFile!,
      );
    }

    final existing = _displayUser!;
    final updatedUser = UserAccount(
      id: existing.id,
      name: _name?.text.trim() ?? '',
      email: _email?.text.trim() ?? '',
      phone: _phone?.text.trim() ?? '',
      password: existing.password,
      userType: existing.userType,
      course: _course?.text.trim() ?? '',
      yearLevel: _yearLevelController?.text.trim() ?? '1st Year',
      studentId: _studentId?.text.trim() ?? '',
      address: _location?.text.trim() ?? '',
      department: existing.department,
      avatarInitials: existing.avatarInitials,
      avatarUrl: newAvatarUrl, // Now a Cloud Storage URL
      bio: _bio?.text.trim() ?? '',
      instagramUrl: _instagramUrl?.text.trim() ?? '',
      facebookUrl: _facebookUrl?.text.trim() ?? '',
      // ... copy all other fields
    );

    await AppStore().updateCurrentUser(updatedUser);

    if (mounted) {
      setState(() {
        _displayUser = AppStore().currentUser!;
        _pickedImageFile = null;
        _editing = false;
        _loading = false;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
```

## Step 4: Update Image Display Logic

### Modify _buildAvatar() in profile_screen.dart
```dart
Widget _buildAvatar(UserAccount user) {
  Widget avatarChild;

  if (_pickedImageFile != null) {
    avatarChild = Image.file(
      _pickedImageFile!,
      fit: BoxFit.cover,
      width: 96,
      height: 96,
    );
  } else if (user.avatarUrl.isNotEmpty) {
    final isDataUri = user.avatarUrl.startsWith('data:image');
    final isLocalFile = user.avatarUrl.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:\\').hasMatch(user.avatarUrl);
    final isCloudUrl = user.avatarUrl.startsWith('https://');
    
    avatarChild = isDataUri
        ? Image.memory(
            base64Decode(user.avatarUrl.split(',').last),
            fit: BoxFit.cover,
            width: 96,
            height: 96,
            errorBuilder: (_, __, ___) =>
                _initialsWidget(user.avatarInitials),
          )
        : isLocalFile
            ? Image.file(
                File(user.avatarUrl),
                fit: BoxFit.cover,
                width: 96,
                height: 96,
                errorBuilder: (_, __, ___) =>
                    _initialsWidget(user.avatarInitials),
              )
            : isCloudUrl
                ? Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                    width: 96,
                    height: 96,
                    errorBuilder: (_, __, ___) =>
                        _initialsWidget(user.avatarInitials),
                  )
                : _initialsWidget(user.avatarInitials);
  } else {
    avatarChild = _initialsWidget(user.avatarInitials);
  }

  return GestureDetector(
    onTap: (_editing && _canEdit) ? _pickImage : null,
    child: Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(48),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: avatarChild,
          ),
        ),
        if (_editing && _canEdit)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Theme.of(context).colorScheme.surface, width: 2),
              ),
              child:
                  const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
      ],
    ),
  );
}
```

## Step 5: Update Navigation Drawer Avatar

### Modify _buildAvatarCircle() in Dashboard.dart
```dart
Widget _buildAvatarCircle({
  required BuildContext context,
  required double size,
  required String avatarUrl,
  required String initials,
}) {
  final double fontSize = size * 0.35;

  Widget child;
  if (avatarUrl.isNotEmpty) {
    final isDataUri = avatarUrl.startsWith('data:image');
    final isLocal = avatarUrl.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:\\').hasMatch(avatarUrl);
    final isCloudUrl = avatarUrl.startsWith('https://');
    
    child = isDataUri
        ? _buildDataUriImage(avatarUrl, size, fontSize, initials)
        : isLocal
            ? Image.file(
                File(avatarUrl),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _initialsText(initials, fontSize),
              )
            : isCloudUrl
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (_, __, ___) => _initialsText(initials, fontSize),
                  )
                : _initialsText(initials, fontSize);
  } else {
    child = _initialsText(initials, fontSize);
  }

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppTheme.getPrimary(context),
    ),
    child: ClipOval(child: child),
  );
}
```

## Step 6: Configure Firebase Security Rules

### Update storage.rules in Firebase Console
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{allPaths=**} {
      // Users can only access their own profile images
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 7: Update Firebase Console Settings

### Enable Public Access (Optional)
1. Go to Firebase Console → Storage
2. Click "Rules" tab
3. For public access, use:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{allPaths=**} {
      allow read: true;  // Public read access
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 8: Test the Implementation

### Testing Steps
1. Add a new profile image
2. Check Firebase Console → Storage to see uploaded file
3. Verify image displays in app
4. Test navigation drawer avatar
5. Try accessing the image URL directly in browser

### Expected Results
- Images stored in Firebase Cloud Storage
- Public URLs generated for each profile image
- Images viewable online via their URLs
- App performance improved (smaller database size)

## Migration Strategy

### For Existing Users
1. Add migration function to convert base64 to Cloud Storage
2. Run migration during app startup
3. Update user records with new URLs
4. Clean up old base64 data

### Benefits
✅ Images viewable online via public URLs  
✅ Better app performance (smaller database)  
✅ Scalable storage solution  
✅ Professional image hosting  
✅ Easy sharing capabilities  

## Troubleshooting

### Common Issues
- **Upload fails**: Check Firebase Storage rules and permissions
- **Images not showing**: Verify URL format and network connectivity
- **Performance issues**: Optimize image sizes before upload
- **Security concerns**: Implement proper access controls

### Debug Tips
- Use Firebase Console Storage tab to verify uploads
- Check network logs for upload errors
- Test with different image sizes
- Verify Firebase project configuration
