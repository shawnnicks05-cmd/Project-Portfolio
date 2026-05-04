void main() {
  // 1. Basic Variables
  String name = "Gemini";
  int year = 2026;

  // 2. Lists (Dynamic Arrays)
  var languages = ['Java', 'C', 'Dart'];
  languages.add('Python');

  // 3. String Interpolation (much easier than Java's + or printf)
  print('Hello, $name! The year is $year.');
  print('You are learning these languages: ${languages.join(", ")}');

  // 4. Calling a function
  int result = calculateSum(10, 20);
  print('The sum is: $result');
}

// A simple arrow function for conciseness
int calculateSum(int a, int b) => a + b;
