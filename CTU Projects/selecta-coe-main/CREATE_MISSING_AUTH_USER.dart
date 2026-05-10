// Run this script to create missing Firebase Auth user for existing Firestore user
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createMissingAuthUser() async {
  // Initialize Firebase if not already initialized
  // await Firebase.initializeApp();
  
  final email = 'shawnnicks05@gmail.com';
  final password = 'password123'; // Use the original password
  
  try {
    print('Creating Firebase Auth user for existing Firestore user: $email');
    
    // Create the user in Firebase Auth
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    
    print('Firebase Auth user created successfully!');
    print('User ID: ${userCredential.user?.uid}');
    print('Email: ${userCredential.user?.email}');
    
    // Verify the user exists
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('User is now signed in: ${currentUser.email}');
    }
    
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      print('User already exists in Firebase Auth: $email');
    } else {
      print('Error creating Firebase Auth user: ${e.code} - ${e.message}');
    }
  } catch (e) {
    print('Unexpected error: $e');
  }
}

// To run this, you can:
// 1. Add it to your main.dart temporarily
// 2. Or create a separate Flutter script
// 3. Or manually create the user in Firebase Console
