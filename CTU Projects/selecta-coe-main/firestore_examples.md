# Firestore Examples - Correct Syntax

## Firestore vs MongoDB Syntax

### ❌ MongoDB Syntax (What you used):
```javascript
db.my_collection.aggregate([
  { "$match": { "property_01": "value" } },
  { "$sort": { "property_99": 1 } },
  { "$limit": 10 }
]);
```

### ✅ Firestore Syntax (What you need):

#### Simple Query:
```dart
// In Flutter/Dart
final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('property_01', isEqualTo: 'value')
    .orderBy('property_99')
    .limit(10)
    .get();
```

#### Complex Query (Firestore equivalent of aggregate):
```dart
final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('userType', isEqualTo: 'Student')
    .orderBy('createdAt', descending: true)
    .limit(10)
    .get();
```

## Your App's Collections

Your app expects these collections:
- `users` - User account data
- `skill_categories` - Skill categories
- `skills` - Individual skills
- `projects` - User projects
- `certifications` - User certifications
- `educational_attainments` - Education history
- `experiences` - Work experience
- `achievements` - User achievements

## Test Your Firestore Connection

Run this in your app to test:
```dart
try {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .limit(1)
      .get();
  print('Firestore working! Found ${snapshot.docs.length} users');
} catch (e) {
  print('Firestore error: $e');
}
```
