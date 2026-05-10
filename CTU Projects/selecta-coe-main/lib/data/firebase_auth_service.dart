// lib/data/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('Sending password reset email to: $email');

      // Directly send password reset email
      // Firebase will handle user existence checking for security
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent successfully');
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Check if user exists in Firebase Auth
  // Note: fetchSignInMethodsForEmail is deprecated due to email enumeration protection
  // We'll handle user existence checks through the password reset flow instead
  static Future<bool> userExists(String email) async {
    // For now, we'll assume user might exist and let the password reset handle validation
    return true;
  }

  // Get current Firebase user
  static User? get currentUser => _auth.currentUser;

  // Sign out current user
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create user in Firebase Auth
  static Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      print('Creating Firebase Auth user: $email');
      final stopwatch = Stopwatch()..start();
      
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      stopwatch.stop();
      print('Firebase Auth user created successfully: $email in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('Error creating Firebase Auth user: $e');
      rethrow;
    }
  }

  // Create Firebase Auth user for existing Firestore user
  static Future<bool> createAuthUserForExistingUser(String email, String password) async {
    try {
      print('Creating Firebase Auth user for existing Firestore user: $email');
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      print('Firebase Auth user created successfully for existing user: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error for existing user: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        print('User already exists in Firebase Auth: $email');
        return true; // User already exists, which is good
      }
      return false;
    } catch (e) {
      print('Unexpected error creating Firebase Auth user: $e');
      return false;
    }
  }

  // Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }
}

extension on FirebaseAuth {}
