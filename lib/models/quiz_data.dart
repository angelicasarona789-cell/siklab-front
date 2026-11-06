import 'package:flutter/material.dart';

enum QuizCategory { beginner, intermediate, upperIntermediate }

extension QuizCategoryX on QuizCategory {
  String get label {
    switch (this) {
      case QuizCategory.beginner:
        return 'Beginner';
      case QuizCategory.intermediate:
        return 'Intermediate';
      case QuizCategory.upperIntermediate:
        return 'Advanced';
    }
  }

  String get tag {
    switch (this) {
      case QuizCategory.beginner:
        return 'LVL 01';
      case QuizCategory.intermediate:
        return 'LVL 02';
      case QuizCategory.upperIntermediate:
        return 'LVL 03';
    }
  }

  Color get color {
    switch (this) {
      case QuizCategory.beginner:
        return const Color(0xFF00D68F);
      case QuizCategory.intermediate:
        return const Color(0xFF00CFFF);
      case QuizCategory.upperIntermediate:
        return const Color(0xFFB57BFF);
    }
  }

  IconData get icon {
    switch (this) {
      case QuizCategory.beginner:
        return Icons.star_border_rounded;
      case QuizCategory.intermediate:
        return Icons.star_half_rounded;
      case QuizCategory.upperIntermediate:
        return Icons.star_rounded;
    }
  }

  String get description {
    switch (this) {
      case QuizCategory.beginner:
        return 'Basic syntax, variables, data types & operators.';
      case QuizCategory.intermediate:
        return 'Conditionals, loops, and functions/methods.';
      case QuizCategory.upperIntermediate:
        return 'Arrays, strings, file handling & problem solving.';
    }
  }
}

class LanguageQuiz {
  final String name;
  final String tag;
  final Color color;
  final IconData icon;
  final Map<QuizCategory, List<QuizQuestion>> categories;
  const LanguageQuiz({
    required this.name,
    required this.tag,
    required this.color,
    required this.icon,
    required this.categories,
  });
}

class QuizQuestion {
  final String module;
  final String title;
  final String description;
  final String filename;
  final String starterCode;
  final String correctAnswer;
  final String explanation;
  final String hint;
  final List<int> highlightLines;
  final String sampleData;
  final String expectedOutput;
  const QuizQuestion({
    required this.module,
    required this.title,
    required this.description,
    required this.filename,
    required this.starterCode,
    required this.correctAnswer,
    required this.explanation,
    required this.hint,
    this.highlightLines = const [],
    this.sampleData = '',
    this.expectedOutput = '',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MODULE CASE PRACTICE
// Every module topic (and every DEBUG title) maps to ONE case whose scenario,
// sample data, expected output and answer all teach that same topic.
// ─────────────────────────────────────────────────────────────────────────────

class _ModuleCase {
  final String prompt;
  final String sample;
  final String output;
  final String java;
  final String csharp;
  final String javascript;
  final String python;
  final String sql;
  final Map<String, String> tips;

  const _ModuleCase(
    this.prompt,
    this.sample,
    this.output, {
    this.java = '',
    this.csharp = '',
    this.javascript = '',
    this.python = '',
    this.sql = '',
    this.tips = const {},
  });

  String answerFor(String language) => switch (language.toUpperCase()) {
        'JAVA' => java,
        'C#' => csharp,
        'JAVASCRIPT' => javascript,
        'PYTHON' => python,
        'SQL' => sql,
        _ => '',
      };
}

/// Turns @camelCase placeholders in a prompt into the naming style of the
/// language (snake_case for Python, PascalCase for C#, camelCase otherwise).
String _applyCaseNames(String text, String language) {
  return text.replaceAllMapped(RegExp(r'@(\w+)'), (match) {
    final name = match[1]!;
    switch (language.toUpperCase()) {
      case 'PYTHON':
        return name.replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => '_${m[0]!.toLowerCase()}',
        );
      case 'C#':
        return name[0].toUpperCase() + name.substring(1);
      default:
        return name;
    }
  });
}

// ── Case table ───────────────────────────────────────────────────────────────
const Map<String, _ModuleCase> _moduleCases = {
  // ───────── BEGINNER ─────────
  'output': _ModuleCase(
    'Visitors at the kiosk should see the message "Welcome!". Display exactly that message.',
    'Message: Welcome!',
    'Welcome!',
    java: r'''System.out.println("Welcome!");''',
    csharp: r'''Console.WriteLine("Welcome!");''',
    javascript: r'''console.log("Welcome!");''',
    python: r'''print("Welcome!")''',
  ),
  'variables': _ModuleCase(
    'The kiosk has 5 seats available. Store 5 in a variable named seats, then display seats.',
    'Available seats: 5',
    '5',
    java: r'''int seats = 5;
System.out.println(seats);''',
    csharp: r'''int seats = 5;
Console.WriteLine(seats);''',
    javascript: r'''const seats = 5;
console.log(seats);''',
    python: r'''seats = 5
print(seats)''',
  ),
  'datatypes': _ModuleCase(
    'The ticket price is 25. Store it in a constant named price, then display its type with typeof.',
    'Ticket price: 25',
    'number',
    javascript: r'''const price = 25;
console.log(typeof price);''',
  ),
  'strings_basic': _ModuleCase(
    'The check-in screen greets a guest called Mia. Store "Mia" in a variable named name, then display name.',
    'Guest name: Mia',
    'Mia',
    java: r'''String name = "Mia";
System.out.println(name);''',
    csharp: r'''string name = "Mia";
Console.WriteLine(name);''',
    javascript: r'''const name = "Mia";
console.log(name);''',
    python: r'''name = "Mia"
print(name)''',
  ),
  'template': _ModuleCase(
    'The check-in screen should display "Guest: Mia". Store "Mia" in name, then build the message with a template literal.',
    'Guest name: Mia',
    'Guest: Mia',
    javascript: r'''const name = "Mia";
console.log(`Guest: ${name}`);''',
  ),
  'arithmetic': _ModuleCase(
    'The kiosk sold 2 tickets in the morning and 3 in the afternoon. Store them in morning and afternoon, then display their total.',
    'Morning tickets: 2\nAfternoon tickets: 3',
    '5',
    java: r'''int morning = 2;
int afternoon = 3;
System.out.println(morning + afternoon);''',
    csharp: r'''int morning = 2;
int afternoon = 3;
Console.WriteLine(morning + afternoon);''',
    javascript: r'''const morning = 2;
const afternoon = 3;
console.log(morning + afternoon);''',
    python: r'''morning = 2
afternoon = 3
print(morning + afternoon)''',
  ),
  'comparison': _ModuleCase(
    'The door code entered is 7 and the required code is 7. Store them in entered and required, then display whether they are strictly equal (===).',
    'Entered code: 7\nRequired code: 7',
    'true',
    javascript: r'''const entered = 7;
const required = 7;
console.log(entered === required);''',
  ),
  'coercion': _ModuleCase(
    'A form returns the ticket count as the text "42". Convert it to a number with Number(), add 8, and display the result.',
    'Text value: "42"\nExtra tickets: 8',
    '50',
    javascript: r'''const text = "42";
console.log(Number(text) + 8);''',
  ),
  'if': _ModuleCase(
    'A guest is 20 years old. Store 20 in age, then display "Allowed" only if age is at least 18.',
    'Guest age: 20\nMinimum entry age: 18',
    'Allowed',
    java: r'''int age = 20;
if (age >= 18) {
  System.out.println("Allowed");
}''',
    csharp: r'''int age = 20;
if (age >= 18) Console.WriteLine("Allowed");''',
    javascript: r'''const age = 20;
if (age >= 18) console.log("Allowed");''',
    python: r'''age = 20
if age >= 18:
    print("Allowed")''',
  ),
  'for_print': _ModuleCase(
    'The kiosk must display ticket numbers 1 to 3, one per line. Use a for loop with ticket as the loop variable.',
    'Ticket numbers to display: 1, 2, 3',
    '1\n2\n3',
    java: r'''for (int ticket = 1; ticket <= 3; ticket++) {
  System.out.println(ticket);
}''',
    csharp: r'''for (int ticket = 1; ticket <= 3; ticket++) {
  Console.WriteLine(ticket);
}''',
    javascript: r'''for (let ticket = 1; ticket <= 3; ticket++) {
  console.log(ticket);
}''',
    python: r'''for ticket in range(1, 4):
    print(ticket)''',
  ),
  'array_first': _ModuleCase(
    'The kiosk holds ticket numbers 4, 7 and 9 in a collection named tickets. Display the first ticket number.',
    'Ticket numbers: [4, 7, 9]\nPosition to display: first',
    '4',
    java: r'''int[] tickets = {4, 7, 9};
System.out.println(tickets[0]);''',
    csharp: r'''int[] tickets = {4, 7, 9};
Console.WriteLine(tickets[0]);''',
    javascript: r'''const tickets = [4, 7, 9];
console.log(tickets[0]);''',
    python: r'''tickets = [4, 7, 9]
print(tickets[0])''',
  ),

  // ───────── INTERMEDIATE ─────────
  'ifelse': _ModuleCase(
    'A student scored 60. Store 60 in score, then display "Pass" if score is at least 75, otherwise display "Retry".',
    'Score: 60\nPassing score: 75',
    'Retry',
    java: r'''int score = 60;
if (score >= 75) {
  System.out.println("Pass");
} else {
  System.out.println("Retry");
}''',
    csharp: r'''int score = 60;
if (score >= 75) {
  Console.WriteLine("Pass");
} else {
  Console.WriteLine("Retry");
}''',
    javascript: r'''const score = 60;
if (score >= 75) {
  console.log("Pass");
} else {
  console.log("Retry");
}''',
    python: r'''score = 60
if score >= 75:
    print("Pass")
else:
    print("Retry")''',
  ),
  'ifelif': _ModuleCase(
    'A student scored 60. Store 60 in score, then display "Pass" if score is at least 75, "Almost" if it is at least 50, otherwise "Retry".',
    'Score: 60\nPass: 75 or more\nAlmost: 50 to 74',
    'Almost',
    java: r'''int score = 60;
if (score >= 75) {
  System.out.println("Pass");
} else if (score >= 50) {
  System.out.println("Almost");
} else {
  System.out.println("Retry");
}''',
    csharp: r'''int score = 60;
if (score >= 75) {
  Console.WriteLine("Pass");
} else if (score >= 50) {
  Console.WriteLine("Almost");
} else {
  Console.WriteLine("Retry");
}''',
    javascript: r'''const score = 60;
if (score >= 75) {
  console.log("Pass");
} else if (score >= 50) {
  console.log("Almost");
} else {
  console.log("Retry");
}''',
    python: r'''score = 60
if score >= 75:
    print("Pass")
elif score >= 50:
    print("Almost")
else:
    print("Retry")''',
  ),
  'switch': _ModuleCase(
    'Show the weekday name for day number 2 using a switch on day (1 = Monday, 2 = Tuesday, 3 = Wednesday).',
    'Day number: 2\n1 = Monday, 2 = Tuesday, 3 = Wednesday',
    'Tuesday',
    java: r'''int day = 2;
switch (day) {
  case 1:
    System.out.println("Monday");
    break;
  case 2:
    System.out.println("Tuesday");
    break;
  case 3:
    System.out.println("Wednesday");
    break;
}''',
    csharp: r'''int day = 2;
switch (day) {
  case 1:
    Console.WriteLine("Monday");
    break;
  case 2:
    Console.WriteLine("Tuesday");
    break;
  case 3:
    Console.WriteLine("Wednesday");
    break;
}''',
    javascript: r'''const day = 2;
switch (day) {
  case 1:
    console.log("Monday");
    break;
  case 2:
    console.log("Tuesday");
    break;
  case 3:
    console.log("Wednesday");
    break;
}''',
    python: r'''day = 2
match day:
    case 1:
        print("Monday")
    case 2:
        print("Tuesday")
    case 3:
        print("Wednesday")''',
  ),
  'for_sum': _ModuleCase(
    'Add the ticket numbers 1 to 4 with a for loop. Keep the running sum in total and display total after the loop.',
    'Ticket numbers: 1, 2, 3, 4',
    '10',
    java: r'''int total = 0;
for (int ticket = 1; ticket <= 4; ticket++) {
  total += ticket;
}
System.out.println(total);''',
    csharp: r'''int total = 0;
for (int ticket = 1; ticket <= 4; ticket++) {
  total += ticket;
}
Console.WriteLine(total);''',
    javascript: r'''let total = 0;
for (let ticket = 1; ticket <= 4; ticket++) {
  total += ticket;
}
console.log(total);''',
    python: r'''total = 0
for ticket in range(1, 5):
    total += ticket
print(total)''',
  ),
  'for_countdown': _ModuleCase(
    'The kiosk starts a countdown from 3 down to 1. Use a for loop with ticket as the loop variable and display each number.',
    'Countdown start: 3\nCountdown end: 1',
    '3\n2\n1',
    java: r'''for (int ticket = 3; ticket >= 1; ticket--) {
  System.out.println(ticket);
}''',
    csharp: r'''for (int ticket = 3; ticket >= 1; ticket--) {
  Console.WriteLine(ticket);
}''',
    javascript: r'''for (let ticket = 3; ticket >= 1; ticket--) {
  console.log(ticket);
}''',
    python: r'''for ticket in range(3, 0, -1):
    print(ticket)''',
  ),
  'for_list': _ModuleCase(
    'The kiosk holds ticket numbers 4, 7 and 9 in tickets. Loop over the collection and display each ticket on its own line.',
    'Ticket numbers: [4, 7, 9]',
    '4\n7\n9',
    java: r'''int[] tickets = {4, 7, 9};
for (int ticket : tickets) {
  System.out.println(ticket);
}''',
    csharp: r'''int[] tickets = {4, 7, 9};
foreach (int ticket in tickets) {
  Console.WriteLine(ticket);
}''',
    javascript: r'''const tickets = [4, 7, 9];
for (const ticket of tickets) {
  console.log(ticket);
}''',
    python: r'''tickets = [4, 7, 9]
for ticket in tickets:
    print(ticket)''',
  ),
  'for_sum_array': _ModuleCase(
    'The kiosk holds ticket numbers 4, 7 and 9 in tickets. Loop over them, add each one to total, and display total.',
    'Ticket numbers: [4, 7, 9]',
    '20',
    java: r'''int[] tickets = {4, 7, 9};
int total = 0;
for (int ticket : tickets) {
  total += ticket;
}
System.out.println(total);''',
    csharp: r'''int[] tickets = {4, 7, 9};
int total = 0;
foreach (int ticket in tickets) {
  total += ticket;
}
Console.WriteLine(total);''',
    javascript: r'''const tickets = [4, 7, 9];
let total = 0;
for (const ticket of tickets) {
  total += ticket;
}
console.log(total);''',
    python: r'''tickets = [4, 7, 9]
total = 0
for ticket in tickets:
    total += ticket
print(total)''',
  ),
  'while': _ModuleCase(
    'Start count at 3. While count is greater than 0, display count and then reduce it by 1.',
    'Starting count: 3',
    '3\n2\n1',
    java: r'''int count = 3;
while (count > 0) {
  System.out.println(count);
  count--;
}''',
    csharp: r'''int count = 3;
while (count > 0) {
  Console.WriteLine(count);
  count--;
}''',
    javascript: r'''let count = 3;
while (count > 0) {
  console.log(count);
  count--;
}''',
    python: r'''count = 3
while count > 0:
    print(count)
    count -= 1''',
  ),
  'while_power': _ModuleCase(
    'Start power at 1. While power is less than 20, double it (multiply by 2). Display power after the loop.',
    'Starting power: 1\nLimit: 20',
    '32',
    java: r'''int power = 1;
while (power < 20) {
  power *= 2;
}
System.out.println(power);''',
    csharp: r'''int power = 1;
while (power < 20) {
  power *= 2;
}
Console.WriteLine(power);''',
    javascript: r'''let power = 1;
while (power < 20) {
  power *= 2;
}
console.log(power);''',
    python: r'''power = 1
while power < 20:
    power *= 2
print(power)''',
  ),
  'while_up': _ModuleCase(
    'Display ticket numbers 1 to 5 with a while loop. Start count at 1 and make sure the loop increases count so it ends.',
    'Ticket numbers: 1, 2, 3, 4, 5',
    '1\n2\n3\n4\n5',
    java: r'''int count = 1;
while (count <= 5) {
  System.out.println(count);
  count++;
}''',
    csharp: r'''int count = 1;
while (count <= 5) {
  Console.WriteLine(count);
  count++;
}''',
    javascript: r'''let count = 1;
while (count <= 5) {
  console.log(count);
  count++;
}''',
    python: r'''count = 1
while count <= 5:
    print(count)
    count += 1''',
  ),
  'range': _ModuleCase(
    'Display the even ticket numbers 2, 4 and 6 using range() with a step. Use ticket as the loop variable.',
    'Even ticket numbers: 2, 4, 6',
    '2\n4\n6',
    python: r'''for ticket in range(2, 7, 2):
    print(ticket)''',
  ),
  'function': _ModuleCase(
    'The kiosk adds morning and afternoon ticket counts. Create @add that takes two numbers and returns their sum, then display @add(2, 3).',
    'Morning tickets: 2\nAfternoon tickets: 3',
    '5',
    java: r'''static int add(int a, int b) {
  return a + b;
}
System.out.println(add(2, 3));''',
    csharp: r'''static int Add(int a, int b) {
  return a + b;
}
Console.WriteLine(Add(2, 3));''',
    javascript: r'''function add(a, b) {
  return a + b;
}
console.log(add(2, 3));''',
    python: r'''def add(a, b):
    return a + b

print(add(2, 3))''',
  ),
  'function_arrow': _ModuleCase(
    'The kiosk adds morning and afternoon ticket counts. Create an arrow function stored in add that returns the sum of its two parameters, then display add(2, 3).',
    'Morning tickets: 2\nAfternoon tickets: 3',
    '5',
    javascript: r'''const add = (a, b) => a + b;
console.log(add(2, 3));''',
  ),
  'function_greet': _ModuleCase(
    'The kiosk greets guests by name. Create @greet that takes name and returns "Hello, " followed by the name and "!", then display @greet("Mia").',
    'Guest name: Mia',
    'Hello, Mia!',
    java: r'''static String greet(String name) {
  return "Hello, " + name + "!";
}
System.out.println(greet("Mia"));''',
    csharp: r'''static string Greet(string name) {
  return "Hello, " + name + "!";
}
Console.WriteLine(Greet("Mia"));''',
    javascript: r'''function greet(name) {
  return "Hello, " + name + "!";
}
console.log(greet("Mia"));''',
    python: r'''def greet(name):
    return "Hello, " + name + "!"

print(greet("Mia"))''',
  ),
  'default_args': _ModuleCase(
    'Create @greet with one parameter name that defaults to "Guest". Calling @greet() with no argument should display "Hello, Guest".',
    'Default name: Guest',
    'Hello, Guest',
    csharp: r'''static void Greet(string name = "Guest") {
  Console.WriteLine("Hello, " + name);
}
Greet();''',
    javascript: r'''function greet(name = "Guest") {
  console.log("Hello, " + name);
}
greet();''',
    python: r'''def greet(name="Guest"):
    print("Hello, " + name)

greet()''',
  ),
  'fizzbuzz': _ModuleCase(
    'For numbers 1 to 15, display "Fizz" for multiples of 3, "Buzz" for multiples of 5, "FizzBuzz" for multiples of both, otherwise the number itself.',
    'Numbers: 1 to 15',
    '1\n2\nFizz\n4\nBuzz\nFizz\n7\n8\nFizz\nBuzz\n11\nFizz\n13\n14\nFizzBuzz',
    java: r'''for (int number = 1; number <= 15; number++) {
  if (number % 15 == 0) {
    System.out.println("FizzBuzz");
  } else if (number % 3 == 0) {
    System.out.println("Fizz");
  } else if (number % 5 == 0) {
    System.out.println("Buzz");
  } else {
    System.out.println(number);
  }
}''',
    csharp: r'''for (int number = 1; number <= 15; number++) {
  if (number % 15 == 0) {
    Console.WriteLine("FizzBuzz");
  } else if (number % 3 == 0) {
    Console.WriteLine("Fizz");
  } else if (number % 5 == 0) {
    Console.WriteLine("Buzz");
  } else {
    Console.WriteLine(number);
  }
}''',
    javascript: r'''for (let number = 1; number <= 15; number++) {
  if (number % 15 === 0) {
    console.log("FizzBuzz");
  } else if (number % 3 === 0) {
    console.log("Fizz");
  } else if (number % 5 === 0) {
    console.log("Buzz");
  } else {
    console.log(number);
  }
}''',
    python: r'''for number in range(1, 16):
    if number % 15 == 0:
        print("FizzBuzz")
    elif number % 3 == 0:
        print("Fizz")
    elif number % 5 == 0:
        print("Buzz")
    else:
        print(number)''',
  ),
  'recursion_factorial': _ModuleCase(
    'Create a recursive @factorial(n) that returns 1 when n is 1 or less, otherwise n times @factorial(n - 1). Display @factorial(4).',
    'Input: 4\n4 x 3 x 2 x 1',
    '24',
    java: r'''static int factorial(int n) {
  if (n <= 1) return 1;
  return n * factorial(n - 1);
}
System.out.println(factorial(4));''',
    csharp: r'''static int Factorial(int n) {
  if (n <= 1) return 1;
  return n * Factorial(n - 1);
}
Console.WriteLine(Factorial(4));''',
    javascript: r'''function factorial(n) {
  if (n <= 1) return 1;
  return n * factorial(n - 1);
}
console.log(factorial(4));''',
    python: r'''def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

print(factorial(4))''',
  ),
  'recursion_fib': _ModuleCase(
    'Create a recursive @fib(n) that returns n when n is 0 or 1, otherwise @fib(n - 1) + @fib(n - 2). Display @fib(6).',
    'Sequence: 0, 1, 1, 2, 3, 5, 8\nInput: 6',
    '8',
    java: r'''static int fib(int n) {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2);
}
System.out.println(fib(6));''',
    csharp: r'''static int Fib(int n) {
  if (n <= 1) return n;
  return Fib(n - 1) + Fib(n - 2);
}
Console.WriteLine(Fib(6));''',
    javascript: r'''function fib(n) {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2);
}
console.log(fib(6));''',
    python: r'''def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

print(fib(6))''',
  ),
  'foreach_average': _ModuleCase(
    'The kiosk holds the numbers 2, 4 and 6 in numbers. Use a foreach-style loop to add them into total, then display the average (total divided by the number of items).',
    'Numbers: [2, 4, 6]',
    '4',
    java: r'''int[] numbers = {2, 4, 6};
int total = 0;
for (int number : numbers) {
  total += number;
}
System.out.println(total / numbers.length);''',
    csharp: r'''int[] numbers = {2, 4, 6};
int total = 0;
foreach (int number in numbers) {
  total += number;
}
Console.WriteLine(total / numbers.Length);''',
    javascript: r'''const numbers = [2, 4, 6];
let total = 0;
for (const number of numbers) {
  total += number;
}
console.log(total / numbers.length);''',
    python: r'''numbers = [2, 4, 6]
total = 0
for number in numbers:
    total += number
print(total // len(numbers))''',
  ),
  'trycatch': _ModuleCase(
    'The kiosk tries to read the entry "abc" as a number. Wrap the risky call in try/catch and display "Invalid entry" when it fails.',
    'Entry: abc',
    'Invalid entry',
    java: r'''try {
  int value = Integer.parseInt("abc");
  System.out.println(value);
} catch (NumberFormatException e) {
  System.out.println("Invalid entry");
}''',
    csharp: r'''try {
  int value = int.Parse("abc");
  Console.WriteLine(value);
} catch (FormatException) {
  Console.WriteLine("Invalid entry");
}''',
    javascript: r'''try {
  JSON.parse("abc");
} catch (error) {
  console.log("Invalid entry");
}''',
    python: r'''try:
    value = int("abc")
    print(value)
except ValueError:
    print("Invalid entry")''',
    tips: {
      'JAVA': 'Use Integer.parseInt and catch NumberFormatException e.',
      'C#': 'Use int.Parse and catch FormatException.',
      'JAVASCRIPT': 'Use JSON.parse("abc") inside try and catch (error).',
      'PYTHON': 'Use int("abc") inside try and catch ValueError.',
    },
  ),
  'callbacks': _ModuleCase(
    'Create @runTask(callback) that simply calls the callback. Pass it a callback that displays "Done".',
    'Callback message: Done',
    'Done',
    java: r'''static void runTask(Runnable callback) {
  callback.run();
}
runTask(() -> System.out.println("Done"));''',
    csharp: r'''static void RunTask(Action callback) {
  callback();
}
RunTask(() => Console.WriteLine("Done"));''',
    javascript: r'''function runTask(callback) {
  callback();
}
runTask(() => console.log("Done"));''',
    python: r'''def run_task(callback):
    callback()

run_task(lambda: print("Done"))''',
  ),
  'scope': _ModuleCase(
    'Create @makeCounter that keeps count (starting at 0) in a closure and returns a function which adds 1 and returns count. Call the returned function twice and display the second result.',
    'Calls: 2',
    '2',
    javascript: r'''function makeCounter() {
  let count = 0;
  return () => {
    count += 1;
    return count;
  };
}
const counter = makeCounter();
counter();
console.log(counter());''',
    python: r'''def make_counter():
    count = 0
    def increment():
        nonlocal count
        count += 1
        return count
    return increment

counter = make_counter()
counter()
print(counter())''',
  ),
  'array_max': _ModuleCase(
    'The kiosk holds ticket numbers 4, 7 and 9 in tickets. Find the largest ticket number and display it.',
    'Ticket numbers: [4, 7, 9]',
    '9',
    java: r'''int[] tickets = {4, 7, 9};
int largest = tickets[0];
for (int ticket : tickets) {
  if (ticket > largest) largest = ticket;
}
System.out.println(largest);''',
    csharp: r'''int[] tickets = {4, 7, 9};
int largest = tickets[0];
foreach (int ticket in tickets) {
  if (ticket > largest) largest = ticket;
}
Console.WriteLine(largest);''',
    javascript: r'''const tickets = [4, 7, 9];
console.log(Math.max(...tickets));''',
    python: r'''tickets = [4, 7, 9]
print(max(tickets))''',
    tips: {
      'JAVA': 'Loop through tickets and keep the biggest value in largest.',
      'C#': 'Loop through tickets and keep the biggest value in largest.',
      'JAVASCRIPT': 'Use Math.max with the spread operator.',
      'PYTHON': 'Use the built-in max().',
    },
  ),

  // ───────── UPPER INTERMEDIATE ─────────
  'array_length': _ModuleCase(
    'The kiosk holds ticket numbers 4, 7 and 9 in tickets. Display how many tickets there are.',
    'Ticket numbers: [4, 7, 9]',
    '3',
    java: r'''int[] tickets = {4, 7, 9};
System.out.println(tickets.length);''',
    csharp: r'''int[] tickets = {4, 7, 9};
Console.WriteLine(tickets.Length);''',
    javascript: r'''const tickets = [4, 7, 9];
console.log(tickets.length);''',
    python: r'''tickets = [4, 7, 9]
print(len(tickets))''',
  ),
  'list_add': _ModuleCase(
    'Create an empty list named tickets, add 4, 7 and then 9 to it, and display how many tickets the list holds.',
    'Tickets to add: 4, 7, 9',
    '3',
    java: r'''ArrayList<Integer> tickets = new ArrayList<>();
tickets.add(4);
tickets.add(7);
tickets.add(9);
System.out.println(tickets.size());''',
    csharp: r'''List<int> tickets = new List<int>();
tickets.Add(4);
tickets.Add(7);
tickets.Add(9);
Console.WriteLine(tickets.Count);''',
    javascript: r'''const tickets = [];
tickets.push(4);
tickets.push(7);
tickets.push(9);
console.log(tickets.length);''',
    python: r'''tickets = []
tickets.append(4)
tickets.append(7)
tickets.append(9)
print(len(tickets))''',
  ),
  'map_filter': _ModuleCase(
    'From numbers [1, 2, 3, 4], keep only the even numbers and double them with filter and map. Store the result in result and display it joined with ", ".',
    'Numbers: [1, 2, 3, 4]',
    '4, 8',
    javascript: r'''const numbers = [1, 2, 3, 4];
const result = numbers.filter(n => n % 2 === 0).map(n => n * 2);
console.log(result.join(", "));''',
  ),
  'reduce': _ModuleCase(
    'Add up the ticket numbers in tickets with reduce, starting from 0. Store the result in total and display it.',
    'Ticket numbers: [4, 7, 9]',
    '20',
    javascript: r'''const tickets = [4, 7, 9];
const total = tickets.reduce((sum, ticket) => sum + ticket, 0);
console.log(total);''',
  ),
  'list_comprehension': _ModuleCase(
    'Use a list comprehension to build squares containing the squares of 1 to 5, then display squares.',
    'Numbers: 1 to 5',
    '[1, 4, 9, 16, 25]',
    python: r'''squares = [number ** 2 for number in range(1, 6)]
print(squares)''',
  ),
  'string_builder': _ModuleCase(
    'Build the greeting "Hi Mia" piece by piece with a StringBuilder named builder (append "Hi " then "Mia"), then display it.',
    'Pieces: "Hi ", "Mia"',
    'Hi Mia',
    java: r'''StringBuilder builder = new StringBuilder();
builder.append("Hi ");
builder.append("Mia");
System.out.println(builder.toString());''',
    csharp: r'''StringBuilder builder = new StringBuilder();
builder.Append("Hi ");
builder.Append("Mia");
Console.WriteLine(builder.ToString());''',
  ),
  'string_reverse': _ModuleCase(
    'Store "abc" in text, reverse it, and display the reversed text.',
    'Text: abc',
    'cba',
    java: r'''String text = "abc";
System.out.println(new StringBuilder(text).reverse().toString());''',
    csharp: r'''string text = "abc";
char[] letters = text.ToCharArray();
Array.Reverse(letters);
Console.WriteLine(new string(letters));''',
    javascript: r'''const text = "abc";
console.log(text.split("").reverse().join(""));''',
    python: r'''text = "abc"
print(text[::-1])''',
  ),
  'string_manipulation': _ModuleCase(
    'Store "kiosk" in text. Display text in uppercase, then display its length.',
    'Text: kiosk',
    'KIOSK\n5',
    java: r'''String text = "kiosk";
System.out.println(text.toUpperCase());
System.out.println(text.length());''',
    csharp: r'''string text = "kiosk";
Console.WriteLine(text.ToUpper());
Console.WriteLine(text.Length);''',
    javascript: r'''const text = "kiosk";
console.log(text.toUpperCase());
console.log(text.length);''',
    python: r'''text = "kiosk"
print(text.upper())
print(len(text))''',
  ),
  'string_parse': _ModuleCase(
    'Store "4,7,9" in line. Split it at the commas into parts and display the second part.',
    'Line: 4,7,9',
    '7',
    java: r'''String line = "4,7,9";
String[] parts = line.split(",");
System.out.println(parts[1]);''',
    csharp: r'''string line = "4,7,9";
string[] parts = line.Split(',');
Console.WriteLine(parts[1]);''',
    javascript: r'''const line = "4,7,9";
const parts = line.split(",");
console.log(parts[1]);''',
    python: r'''line = "4,7,9"
parts = line.split(",")
print(parts[1])''',
  ),
  'dict': _ModuleCase(
    'Create a dictionary named ticket with "name" set to "Mia" and "seat" set to 12. Display the value stored under "name".',
    'Ticket: name = Mia, seat = 12',
    'Mia',
    python: r'''ticket = {"name": "Mia", "seat": 12}
print(ticket["name"])''',
  ),
  'objects': _ModuleCase(
    'Create an object named ticket with name "Mia" and seat 12. Use destructuring to pull out name and seat, then display both.',
    'Ticket: name = Mia, seat = 12',
    'Mia 12',
    javascript: r'''const ticket = { name: "Mia", seat: 12 };
const { name, seat } = ticket;
console.log(name, seat);''',
  ),
  'spread': _ModuleCase(
    'Combine first = [1, 2] and second = [3] into all using the spread operator, then display all joined with ", ".',
    'first: [1, 2]\nsecond: [3]',
    '1, 2, 3',
    javascript: r'''const first = [1, 2];
const second = [3];
const all = [...first, ...second];
console.log(all.join(", "));''',
  ),
  'oop_class': _ModuleCase(
    'Create a Dog class that stores a name and has a speak method that displays the name followed by " barks". Create Dog "Rex" and call speak.',
    'Dog name: Rex',
    'Rex barks',
    java: r'''class Dog {
  String name;
  Dog(String name) {
    this.name = name;
  }
  void speak() {
    System.out.println(name + " barks");
  }
}
new Dog("Rex").speak();''',
    csharp: r'''class Dog {
  string name;
  public Dog(string name) {
    this.name = name;
  }
  public void Speak() {
    Console.WriteLine(name + " barks");
  }
}
new Dog("Rex").Speak();''',
    javascript: r'''class Dog {
  constructor(name) {
    this.name = name;
  }
  speak() {
    console.log(this.name + " barks");
  }
}
new Dog("Rex").speak();''',
    python: r'''class Dog:
    def __init__(self, name):
        self.name = name

    def speak(self):
        print(self.name + " barks")

Dog("Rex").speak()''',
  ),
  'promises': _ModuleCase(
    'Create a promise named ready that resolves with "Ready", then use .then to display the resolved value.',
    'Resolved value: Ready',
    'Ready',
    javascript: r'''const ready = Promise.resolve("Ready");
ready.then(value => console.log(value));''',
  ),
  'file_read': _ModuleCase(
    'Read the saved kiosk message from message.txt into message and display it.',
    'File: message.txt\nContents: Welcome!',
    'Welcome!',
    java: r'''String message = Files.readString(Path.of("message.txt"));
System.out.println(message);''',
    csharp: r'''string message = File.ReadAllText("message.txt");
Console.WriteLine(message);''',
    javascript:
        r'''const message = require("fs").readFileSync("message.txt", "utf8");
console.log(message);''',
    python: r'''with open("message.txt", "r") as file:
    message = file.read()
print(message)''',
  ),
  'file_write': _ModuleCase(
    'Save the message "Welcome!" into a file named message.txt.',
    'File name: message.txt\nText to save: Welcome!',
    'message.txt now contains: Welcome!',
    java: r'''Files.writeString(Path.of("message.txt"), "Welcome!");''',
    csharp: r'''File.WriteAllText("message.txt", "Welcome!");''',
    javascript: r'''require("fs").writeFileSync("message.txt", "Welcome!");''',
    python: r'''with open("message.txt", "w") as file:
    file.write("Welcome!")''',
  ),
  'file_lines': _ModuleCase(
    'The file names.txt lists one guest per line (Mia, then Leo). Read the file line by line and display each name.',
    'File: names.txt\nLine 1: Mia\nLine 2: Leo',
    'Mia\nLeo',
    java: r'''for (String line : Files.readAllLines(Path.of("names.txt"))) {
  System.out.println(line);
}''',
    csharp: r'''foreach (string line in File.ReadAllLines("names.txt")) {
  Console.WriteLine(line);
}''',
    javascript:
        r'''for (const line of require("fs").readFileSync("names.txt", "utf8").split("\n")) {
  console.log(line);
}''',
    python: r'''with open("names.txt", "r") as file:
    for line in file:
        print(line.strip())''',
  ),
  'reverse_array': _ModuleCase(
    'The kiosk holds numbers [1, 2, 3] in numbers. Display them in reverse order, one per line (3, 2, 1).',
    'Numbers: [1, 2, 3]',
    '3\n2\n1',
    java: r'''int[] numbers = {1, 2, 3};
for (int i = numbers.length - 1; i >= 0; i--) {
  System.out.println(numbers[i]);
}''',
    csharp: r'''int[] numbers = {1, 2, 3};
for (int i = numbers.Length - 1; i >= 0; i--) {
  Console.WriteLine(numbers[i]);
}''',
    javascript: r'''const numbers = [1, 2, 3];
for (let i = numbers.length - 1; i >= 0; i--) {
  console.log(numbers[i]);
}''',
    python: r'''numbers = [1, 2, 3]
for number in reversed(numbers):
    print(number)''',
  ),
  'count_duplicates': _ModuleCase(
    'The kiosk logged tickets [4, 7, 4, 9, 4]. Count how many times ticket 4 appears and display the count.',
    'Tickets: [4, 7, 4, 9, 4]\nTicket to count: 4',
    '3',
    java: r'''int[] tickets = {4, 7, 4, 9, 4};
int count = 0;
for (int ticket : tickets) {
  if (ticket == 4) count++;
}
System.out.println(count);''',
    csharp: r'''int[] tickets = {4, 7, 4, 9, 4};
int count = 0;
foreach (int ticket in tickets) {
  if (ticket == 4) count++;
}
Console.WriteLine(count);''',
    javascript: r'''const tickets = [4, 7, 4, 9, 4];
let count = 0;
for (const ticket of tickets) {
  if (ticket === 4) count++;
}
console.log(count);''',
    python: r'''tickets = [4, 7, 4, 9, 4]
print(tickets.count(4))''',
  ),
  'palindrome': _ModuleCase(
    'Store "level" in word. Display "Palindrome" if word reads the same forwards and backwards.',
    'Word: level',
    'Palindrome',
    java: r'''String word = "level";
if (word.equals(new StringBuilder(word).reverse().toString())) {
  System.out.println("Palindrome");
}''',
    csharp: r'''string word = "level";
char[] letters = word.ToCharArray();
Array.Reverse(letters);
if (word == new string(letters)) Console.WriteLine("Palindrome");''',
    javascript: r'''const word = "level";
if (word === word.split("").reverse().join("")) console.log("Palindrome");''',
    python: r'''word = "level"
if word == word[::-1]:
    print("Palindrome")''',
  ),
  'count_vowels': _ModuleCase(
    'Store "banana" in word. Count the vowels (a, e, i, o, u) in it and display the count.',
    'Word: banana',
    '3',
    java: r'''String word = "banana";
int count = 0;
for (char letter : word.toCharArray()) {
  if ("aeiou".indexOf(letter) >= 0) count++;
}
System.out.println(count);''',
    csharp: r'''string word = "banana";
int count = 0;
foreach (char letter in word) {
  if ("aeiou".Contains(letter)) count++;
}
Console.WriteLine(count);''',
    javascript: r'''const word = "banana";
let count = 0;
for (const letter of word) {
  if ("aeiou".includes(letter)) count++;
}
console.log(count);''',
    python: r'''word = "banana"
count = 0
for letter in word:
    if letter in "aeiou":
        count += 1
print(count)''',
  ),
  'flatten': _ModuleCase(
    'Flatten the nested array [[1, 2], [3, 4]] stored in nested into one array, then display it joined with ", ".',
    'Nested array: [[1, 2], [3, 4]]',
    '1, 2, 3, 4',
    javascript: r'''const nested = [[1, 2], [3, 4]];
console.log(nested.flat().join(", "));''',
  ),

  // ───────── DEBUG-TOPIC CASES (same concept as the bug being fixed) ─────────
  'dbg_semicolon': _ModuleCase(
    'Store the ticket count 5 in a variable named ticketCount, then display it. Every statement must be properly terminated.',
    'Ticket count: 5',
    '5',
    java: r'''int ticketCount = 5;
System.out.println(ticketCount);''',
    csharp: r'''int ticketCount = 5;
Console.WriteLine(ticketCount);''',
    javascript: r'''const ticketCount = 5;
console.log(ticketCount);''',
    python: r'''ticket_count = 5
print(ticket_count)''',
  ),
  'dbg_type': _ModuleCase(
    'The ticket price is the whole number 100. Store it in price using the correct whole-number type, then display price.',
    'Ticket price: 100',
    '100',
    java: r'''int price = 100;
System.out.println(price);''',
    csharp: r'''int price = 100;
Console.WriteLine(price);''',
    javascript: r'''const price = 100;
console.log(price);''',
    python: r'''price = 100
print(price)''',
  ),
  'dbg_str_concat': _ModuleCase(
    'The guest is 20 years old. Store 20 in age as a number, then display "Age: " followed by age plus 5.',
    'Guest age: 20\nAdditional years: 5',
    'Age: 25',
    python: r'''age = 20
print("Age: " + str(age + 5))''',
  ),
  'dbg_indent': _ModuleCase(
    'Define greet() so that it displays "Hello" from inside the function body, then call greet().',
    'Message: Hello',
    'Hello',
    python: r'''def greet():
    print("Hello")

greet()''',
  ),
  'dbg_bounded_loop': _ModuleCase(
    'Display ticket numbers 1 through 5, one per line, with no extra numbers before or after.',
    'Ticket numbers: 1, 2, 3, 4, 5',
    '1\n2\n3\n4\n5',
    java: r'''for (int ticket = 1; ticket <= 5; ticket++) {
  System.out.println(ticket);
}''',
    csharp: r'''for (int ticket = 1; ticket <= 5; ticket++) {
  Console.WriteLine(ticket);
}''',
    javascript: r'''for (let ticket = 1; ticket <= 5; ticket++) {
  console.log(ticket);
}''',
    python: r'''for ticket in range(1, 6):
    print(ticket)''',
  ),
  'dbg_last_index': _ModuleCase(
    'The kiosk holds ticket numbers 4, 7 and 9 in tickets. Display the last one using the valid index 2.',
    'Ticket numbers: [4, 7, 9]\nValid indexes: 0, 1, 2',
    '9',
    java: r'''int[] tickets = {4, 7, 9};
System.out.println(tickets[2]);''',
    csharp: r'''int[] tickets = {4, 7, 9};
Console.WriteLine(tickets[2]);''',
    javascript: r'''const tickets = [4, 7, 9];
console.log(tickets[2]);''',
    python: r'''tickets = [4, 7, 9]
print(tickets[2])''',
  ),
  'dbg_return_type': _ModuleCase(
    'Create @add that takes two whole numbers and returns their sum using the correct return type, then display @add(2, 3).',
    'Morning tickets: 2\nAfternoon tickets: 3',
    '5',
    java: r'''static int add(int a, int b) {
  return a + b;
}
System.out.println(add(2, 3));''',
    csharp: r'''static int Add(int a, int b) {
  return a + b;
}
Console.WriteLine(Add(2, 3));''',
    javascript: r'''function add(a, b) {
  return a + b;
}
console.log(add(2, 3));''',
    python: r'''def add(a, b):
    return a + b

print(add(2, 3))''',
  ),
  'dbg_larger': _ModuleCase(
    'Create @maxOf(a, b) that returns the larger of two numbers, then display @maxOf(3, 7).',
    'First number: 3\nSecond number: 7',
    '7',
    java: r'''static int maxOf(int a, int b) {
  if (a > b) return a;
  return b;
}
System.out.println(maxOf(3, 7));''',
    csharp: r'''static int MaxOf(int a, int b) {
  if (a > b) return a;
  return b;
}
Console.WriteLine(MaxOf(3, 7));''',
    javascript: r'''function maxOf(a, b) {
  if (a > b) return a;
  return b;
}
console.log(maxOf(3, 7));''',
    python: r'''def max_of(a, b):
    if a > b:
        return a
    return b

print(max_of(3, 7))''',
  ),
  'dbg_missing_return': _ModuleCase(
    'Create @doubleIt(n) that RETURNS n times 2 (not just calculates it), then display @doubleIt(5).',
    'Input: 5',
    '10',
    java: r'''static int doubleIt(int n) {
  return n * 2;
}
System.out.println(doubleIt(5));''',
    csharp: r'''static int DoubleIt(int n) {
  return n * 2;
}
Console.WriteLine(DoubleIt(5));''',
    javascript: r'''function doubleIt(n) {
  return n * 2;
}
console.log(doubleIt(5));''',
    python: r'''def double_it(n):
    return n * 2

print(double_it(5))''',
  ),
  'dbg_multiply': _ModuleCase(
    'Create @multiply that takes two whole numbers and returns their product (not their sum), then display @multiply(4, 5).',
    'First number: 4\nSecond number: 5',
    '20',
    java: r'''static int multiply(int a, int b) {
  return a * b;
}
System.out.println(multiply(4, 5));''',
    csharp: r'''static int Multiply(int a, int b) {
  return a * b;
}
Console.WriteLine(Multiply(4, 5));''',
    javascript: r'''function multiply(a, b) {
  return a * b;
}
console.log(multiply(4, 5));''',
    python: r'''def multiply(a, b):
    return a * b

print(multiply(4, 5))''',
  ),
  'dbg_string_compare': _ModuleCase(
    'Two variables first and second both hold the text "Mia". Display "Match" when their contents are equal.',
    'First name: Mia\nSecond name: Mia',
    'Match',
    java: r'''String first = "Mia";
String second = "Mia";
if (first.equals(second)) System.out.println("Match");''',
    csharp: r'''string first = "Mia";
string second = "Mia";
if (first == second) Console.WriteLine("Match");''',
    javascript: r'''const first = "Mia";
const second = "Mia";
if (first === second) console.log("Match");''',
    python: r'''first = "Mia"
second = "Mia"
if first == second:
    print("Match")''',
  ),
  'dbg_loose_equal': _ModuleCase(
    'The form returns the text "5" and the kiosk expects the number 5. Display whether they are equal using loose equality (==).',
    'Form value: "5"\nExpected value: 5',
    'true',
    javascript: r'''console.log("5" == 5);''',
  ),
  'dbg_const': _ModuleCase(
    'The guest score starts at 0 and is later changed to 100. Declare score so it can be reassigned, update it to 100, then display it.',
    'Initial score: 0\nUpdated score: 100',
    '100',
    java: r'''int score = 0;
score = 100;
System.out.println(score);''',
    csharp: r'''int score = 0;
score = 100;
Console.WriteLine(score);''',
    javascript: r'''let score = 0;
score = 100;
console.log(score);''',
    python: r'''score = 0
score = 100
print(score)''',
  ),
  'dbg_arrow_map': _ModuleCase(
    'Double every number in nums = [1, 2, 3] with map and an arrow function that returns each result. Store it in doubled and display it joined with ", ".',
    'Numbers: [1, 2, 3]',
    '2, 4, 6',
    javascript: r'''const nums = [1, 2, 3];
const doubled = nums.map(n => n * 2);
console.log(doubled.join(", "));''',
  ),
  'dbg_file_mode': _ModuleCase(
    'Write "hello" into data.txt, then open the same file in READ mode and display its contents.',
    'File: data.txt\nText: hello',
    'hello',
    python: r'''with open("data.txt", "w") as file:
    file.write("hello")
with open("data.txt", "r") as file:
    print(file.read())''',
  ),
  'dbg_file_name': _ModuleCase(
    'Write "Hello" into note.txt, then read back the SAME file (note.txt) into text and display it.',
    'File: note.txt\nText: Hello',
    'Hello',
    java: r'''Files.writeString(Path.of("note.txt"), "Hello");
String text = Files.readString(Path.of("note.txt"));
System.out.println(text);''',
    csharp: r'''File.WriteAllText("note.txt", "Hello");
string text = File.ReadAllText("note.txt");
Console.WriteLine(text);''',
    javascript: r'''require("fs").writeFileSync("note.txt", "Hello");
const text = require("fs").readFileSync("note.txt", "utf8");
console.log(text);''',
    python: r'''with open("note.txt", "w") as file:
    file.write("Hello")
with open("note.txt", "r") as file:
    text = file.read()
print(text)''',
  ),

  // ───────── SQL ─────────
  'sql_select': _ModuleCase(
    'List every column of the students whose grade is above 85.',
    'students(id, name, grade): (1, Ana, 92), (2, Luis, 85), (3, Mei, 74)',
    'id | name | grade\n1 | Ana | 92',
    sql: r'''SELECT * FROM students WHERE grade > 85;''',
  ),
  'sql_select_columns': _ModuleCase(
    'List only the name and grade columns of the students whose grade is above 80.',
    'students(id, name, grade): (1, Ana, 92), (2, Luis, 85), (3, Mei, 74)',
    'name | grade\nAna | 92\nLuis | 85',
    sql: r'''SELECT name, grade FROM students WHERE grade > 80;''',
  ),
  'sql_insert': _ModuleCase(
    'Add a new student with id 4, name Juan and grade 88 to students(id, name, grade).',
    'Students before: (1, Ana, 92), (2, Luis, 85), (3, Mei, 74)',
    '1 row inserted\n(4, Juan, 88)',
    sql: r'''INSERT INTO students (id, name, grade) VALUES (4, 'Juan', 88);''',
  ),
  'sql_update': _ModuleCase(
    'Change the grade of student 3 to 80 without touching any other student.',
    'Target row: (id: 3, name: Mei, grade: 74)',
    '1 row updated\n(3, Mei, 80)',
    sql: r'''UPDATE students SET grade = 80 WHERE id = 3;''',
  ),
  'sql_delete': _ModuleCase(
    'Remove every student whose grade is below 75.',
    'Students before: (1, Ana, 92), (2, Luis, 85), (3, Mei, 74)',
    '1 row deleted\nRemaining: Ana (92), Luis (85)',
    sql: r'''DELETE FROM students WHERE grade < 75;''',
  ),
  'sql_order': _ModuleCase(
    'List each student name and grade from the highest grade to the lowest.',
    'Students: (Mei, 74), (Ana, 92), (Luis, 85)',
    'name | grade\nAna | 92\nLuis | 85\nMei | 74',
    sql: r'''SELECT name, grade FROM students ORDER BY grade DESC;''',
  ),
  'sql_limit': _ModuleCase(
    'Show only the top 2 students by grade (highest first).',
    'Students: (Mei, 74), (Ana, 92), (Luis, 85)',
    'name | grade\nAna | 92\nLuis | 85',
    sql: r'''SELECT name, grade FROM students ORDER BY grade DESC LIMIT 2;''',
  ),
  'sql_count': _ModuleCase(
    'Count how many students are enrolled in the "CS" course.',
    'Students: (Ana, CS), (Luis, IT), (Mei, CS)',
    'count\n2',
    sql: r'''SELECT COUNT(*) FROM students WHERE course = 'CS';''',
  ),
  'sql_join': _ModuleCase(
    'Pair each student name with the title of the course they are enrolled in (students.course_id matches courses.id).',
    'students: (Ana, course_id 1), (Luis, course_id 2)\ncourses: (1, Java), (2, SQL)',
    'name | title\nAna | Java\nLuis | SQL',
    sql:
        r'''SELECT s.name, c.title FROM students s JOIN courses c ON s.course_id = c.id;''',
  ),
  'sql_left_join': _ModuleCase(
    'List every student with their course title, including students who have no course yet.',
    'students: (Ana, course_id 1), (Joe, course_id NULL)\ncourses: (1, Java)',
    'name | title\nAna | Java\nJoe | NULL',
    sql:
        r'''SELECT s.name, c.title FROM students s LEFT JOIN courses c ON s.course_id = c.id;''',
  ),
  'sql_group': _ModuleCase(
    'Show how many students belong to each course.',
    'Students: (Ana, CS), (Luis, IT), (Mei, CS)',
    'course | count\nCS | 2\nIT | 1',
    sql: r'''SELECT course, COUNT(*) FROM students GROUP BY course;''',
  ),
  'sql_having': _ModuleCase(
    'Show only the courses that have more than one student, with their student count.',
    'Students: (Ana, CS), (Luis, IT), (Mei, CS)',
    'course | count\nCS | 2',
    sql:
        r'''SELECT course, COUNT(*) FROM students GROUP BY course HAVING COUNT(*) > 1;''',
  ),
  'sql_subquery': _ModuleCase(
    'List the name and grade of students whose grade is above the average grade of all students.',
    'Grades: Ana (92), Luis (85), Mei (74)\nAverage: 83.67',
    'name | grade\nAna | 92\nLuis | 85',
    sql:
        r'''SELECT name, grade FROM students WHERE grade > (SELECT AVG(grade) FROM students);''',
  ),
  'sql_aggregate': _ModuleCase(
    'Show the lowest, highest and average grade of all students in one row.',
    'Grades: Ana (92), Luis (85), Mei (74)',
    'min | max | avg\n74 | 92 | 83.67',
    sql: r'''SELECT MIN(grade), MAX(grade), AVG(grade) FROM students;''',
  ),
  'sql_case': _ModuleCase(
    'Show each student name with a result column: "Pass" when grade is at least 75, otherwise "Retry".',
    'Grades: Ana (92), Luis (85), Mei (74)',
    'name | result\nAna | Pass\nLuis | Pass\nMei | Retry',
    sql:
        r'''SELECT name, CASE WHEN grade >= 75 THEN 'Pass' ELSE 'Retry' END AS result FROM students;''',
  ),
  'sql_window': _ModuleCase(
    'Rank students from the highest grade to the lowest with ROW_NUMBER() over grade descending, as a column named position.',
    'Grades: Ana (92), Luis (85), Mei (74)',
    'name | position\nAna | 1\nLuis | 2\nMei | 3',
    sql:
        r'''SELECT name, ROW_NUMBER() OVER (ORDER BY grade DESC) AS position FROM students;''',
  ),
  'sql_partition': _ModuleCase(
    'Rank students inside each course by grade (highest first) using ROW_NUMBER() with PARTITION BY, as a column named position.',
    'students: (Ana, CS, 92), (Mei, CS, 74), (Luis, IT, 85)',
    'name | course | position\nAna | CS | 1\nMei | CS | 2\nLuis | IT | 1',
    sql:
        r'''SELECT name, course, ROW_NUMBER() OVER (PARTITION BY course ORDER BY grade DESC) AS position FROM students;''',
  ),
  'sql_recursive_cte': _ModuleCase(
    'Use a recursive CTE named numbers to generate the sequence 1 to 3, then select n from it.',
    'Sequence: 1, 2, 3',
    'n\n1\n2\n3',
    sql: r'''WITH RECURSIVE numbers(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM numbers WHERE n < 3
)
SELECT n FROM numbers;''',
  ),
  'sql_cte': _ModuleCase(
    'Use a CTE named high_scorers for students with grade at least 80, then select their name and grade from it.',
    'Grades: Ana (92), Luis (85), Mei (74)',
    'name | grade\nAna | 92\nLuis | 85',
    sql: r'''WITH high_scorers AS (
  SELECT name, grade FROM students WHERE grade >= 80
)
SELECT name, grade FROM high_scorers;''',
  ),
  'sql_procedure': _ModuleCase(
    'Create a stored procedure named GetTopStudents with an input parameter min_grade (INT) that returns the name and grade of students whose grade is at least min_grade.',
    'Grades: Ana (92), Luis (85), Mei (74)',
    'Procedure created\nCALL GetTopStudents(80) -> Ana (92), Luis (85)',
    sql: r'''CREATE PROCEDURE GetTopStudents(IN min_grade INT)
BEGIN
  SELECT name, grade FROM students WHERE grade >= min_grade;
END;''',
  ),
  'sql_trigger': _ModuleCase(
    'Create a trigger named trg_audit that fires AFTER INSERT on students and logs the action "INSERT" with the new student id into audit_log(action, student_id).',
    'New student: (4, Juan, 88)',
    'Trigger created\nInsert student 4 -> audit_log: (INSERT, 4)',
    sql: r'''CREATE TRIGGER trg_audit
AFTER INSERT ON students
FOR EACH ROW
INSERT INTO audit_log (action, student_id) VALUES ('INSERT', NEW.id);''',
  ),
  'sql_transaction': _ModuleCase(
    'Transfer 100 from account 1 to account 2 as one transaction that is saved at the end.',
    'accounts: (1, balance 500), (2, balance 300)',
    'Transaction committed\nAccount 1: 400\nAccount 2: 400',
    sql: r'''BEGIN TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;''',
  ),
  'sql_dbg_join': _ModuleCase(
    'Pair each student name with their course title by matching students.course_id to courses.id.',
    'students: (Ana, course_id 1)\ncourses: (1, Java)',
    'name | title\nAna | Java',
    sql:
        r'''SELECT s.name, c.title FROM students s INNER JOIN courses c ON s.course_id = c.id;''',
  ),
  'sql_dbg_having': _ModuleCase(
    'Show only the courses with more than 2 students. Filter on the aggregate with HAVING, not WHERE.',
    'Enrollments: Java (3), Python (2), SQL (4)',
    'course | cnt\nJava | 3\nSQL | 4',
    sql:
        r'''SELECT course, COUNT(*) AS cnt FROM students GROUP BY course HAVING COUNT(*) > 2;''',
  ),
  'sql_dbg_update': _ModuleCase(
    'Student 5 earned grade 100. Update only that student record.',
    'Target row: (id: 5, name: Juan, grade: 88)',
    '1 row updated\n(id: 5, name: Juan, grade: 100)',
    sql: r'''UPDATE students SET grade = 100 WHERE id = 5;''',
  ),
  'sql_dbg_insert': _ModuleCase(
    'Add Juan as student 201 with a grade of 88. The number of values must match the listed columns.',
    'Columns: id, name, grade\nNew row: 201, Juan, 88',
    '1 row inserted\n(201, Juan, 88)',
    sql:
        r'''INSERT INTO students (id, name, grade) VALUES (201, 'Juan', 88);''',
  ),
  'sql_dbg_subquery': _ModuleCase(
    'Select all students whose grade is above the average grade, reading the average from the students table.',
    'Grades: Ana (92), Luis (85), Mei (74)\nAverage: 83.67',
    'name | grade\nAna | 92\nLuis | 85',
    sql:
        r'''SELECT * FROM students WHERE grade > (SELECT AVG(grade) FROM students);''',
  ),
  'sql_dbg_cte': _ModuleCase(
    'Define a CTE named high_scorers, then select from that same CTE name in the outer query.',
    'Grades: Ana (92), Luis (85), Mei (74)',
    'name\nAna\nLuis',
    sql: r'''WITH high_scorers AS (
  SELECT name, grade FROM students WHERE grade >= 80
)
SELECT name FROM high_scorers;''',
  ),
};

/// Picks the case that matches the module topic (and title, where the same
/// topic name is reused with different lessons).
String _moduleCaseKey(String language, String moduleLabel, String title) {
  final l = moduleLabel.toUpperCase();
  final t = title.toUpperCase();
  final isSql = language.toUpperCase() == 'SQL';

  if (isSql) {
    if (l == 'DEBUG') {
      if (t.contains('SELECT')) return 'sql_select_columns';
      if (t.contains('UPDATE')) return 'sql_dbg_update';
      if (t.contains('INSERT')) return 'sql_dbg_insert';
      if (t.contains('JOIN')) return 'sql_dbg_join';
      if (t.contains('HAVING')) return 'sql_dbg_having';
      if (t.contains('SUBQUERY')) return 'sql_dbg_subquery';
      if (t.contains('WINDOW')) return 'sql_window';
      if (t.contains('TRANSACTION')) return 'sql_transaction';
      if (t.contains('CTE')) return 'sql_dbg_cte';
      return 'sql_select';
    }
    if (l.contains('RECURSIVE')) return 'sql_recursive_cte';
    if (l.contains('LEFT JOIN')) return 'sql_left_join';
    if (l.contains('JOIN')) return 'sql_join';
    if (l.contains('CTE')) return 'sql_cte';
    if (l.contains('PARTITION')) return 'sql_partition';
    if (l.contains('WINDOW')) return 'sql_window';
    if (l.contains('STORED')) return 'sql_procedure';
    if (l.contains('TRIGGER')) return 'sql_trigger';
    if (l.contains('TRANSACTION')) return 'sql_transaction';
    if (l.contains('GROUP')) return 'sql_group';
    if (l.contains('HAVING')) return 'sql_having';
    if (l.contains('SUBQUERY')) return 'sql_subquery';
    if (l.contains('AGGREGATE')) return 'sql_aggregate';
    if (l.contains('CASE')) return 'sql_case';
    if (l.contains('ORDER')) return 'sql_order';
    if (l.contains('LIMIT')) return 'sql_limit';
    if (l.contains('COUNT')) return 'sql_count';
    if (l.contains('INSERT')) return 'sql_insert';
    if (l.contains('UPDATE')) return 'sql_update';
    if (l.contains('DELETE')) return 'sql_delete';
    return 'sql_select';
  }

  if (l == 'DEBUG') {
    if (t.contains('SEMICOLON')) return 'dbg_semicolon';
    if (t.contains('RETURN TYPE')) return 'dbg_return_type';
    if (t.contains('MISSING RETURN')) return 'dbg_missing_return';
    if (t.contains('ARROW RETURN')) return 'dbg_arrow_map';
    if (t.contains('THE RETURN')) return 'dbg_larger';
    if (t.contains('TYPE ERROR')) return 'dbg_str_concat';
    if (t.contains('FIX TYPE')) return 'dbg_type';
    if (t.contains('FIX CASE')) return 'output';
    if (t.contains('INDENTATION')) return 'dbg_indent';
    if (t.contains('OFF-BY-ONE') ||
        t.contains('THE LOOP') ||
        t.contains('RANGE')) {
      return 'dbg_bounded_loop';
    }
    if (t.contains('INFINITE')) return 'while_up';
    if (t.contains('ARRAY INDEX') ||
        t.contains('ARRAY BOUNDS') ||
        t.contains('LIST INDEX')) {
      return 'dbg_last_index';
    }
    if (t.contains('STRING COMPAR')) return 'dbg_string_compare';
    if (t.contains('COMPARISON')) return 'dbg_loose_equal';
    if (t.contains('OPERATOR')) return 'dbg_multiply';
    if (t.contains('DECLARATION')) return 'dbg_const';
    if (t.contains('THIS IN CLASS')) return 'oop_class';
    if (t.contains('FILE MODE')) return 'dbg_file_mode';
    if (t.contains('FILE NAME')) return 'dbg_file_name';
    return 'output';
  }

  if (l.contains('PROBLEM SOLVING')) {
    if (t.contains('FIZZBUZZ')) return 'fizzbuzz';
    if (t.contains('REVERSE')) return 'reverse_array';
    if (t.contains('DUPLICATE')) return 'count_duplicates';
    if (t.contains('PALINDROME')) return 'palindrome';
    if (t.contains('VOWEL')) return 'count_vowels';
    if (t.contains('FLATTEN')) return 'flatten';
    return 'reverse_array';
  }
  if (l.contains('OUTPUT') || l.contains('PRINT')) return 'output';
  if (l.contains('TEMPLATE')) return 'template';
  if (l.contains('DATA TYPES')) return 'datatypes';
  if (l.contains('TYPE COERCION')) return 'coercion';
  if (l.contains('COMPARISON')) return 'comparison';
  if (l.contains('VARIABLE')) return 'variables';
  if (l.contains('ARITHMETIC')) return 'arithmetic';
  if (l.contains('IF-ELIF')) return 'ifelif';
  if (l.contains('IF-ELSE')) return 'ifelse';
  if (l.contains('IF STATEMENT')) return 'if';
  if (l.contains('SWITCH')) return 'switch';
  if (l.contains('FOR LOOP')) {
    if (t.contains('ARRAY')) return 'for_sum_array';
    if (t.contains('ITERATION')) return 'for_list';
    if (t.contains('SUM')) return 'for_sum';
    if (t.contains('COUNTDOWN')) return 'for_countdown';
    return 'for_print';
  }
  if (l.contains('FOREACH')) return 'foreach_average';
  if (l.contains('WHILE')) return t.contains('POWER') ? 'while_power' : 'while';
  if (l.contains('RANGE')) return 'range';
  if (l.contains('DEFAULT ARGS')) return 'default_args';
  if (l.contains('FIZZBUZZ')) return 'fizzbuzz';
  if (l.contains('RECURSION')) {
    return t.contains('FIBONACCI') ? 'recursion_fib' : 'recursion_factorial';
  }
  if (l.contains('TRY-CATCH') || l.contains('ERRORS')) return 'trycatch';
  if (l.contains('CALLBACK')) return 'callbacks';
  if (l.contains('SCOPE')) return 'scope';
  if (l.contains('FUNCTION') || l.contains('METHOD')) {
    if (l.contains('STRING')) return 'string_parse';
    if (t.contains('ARROW')) return 'function_arrow';
    if (t.contains('GREET')) return 'function_greet';
    return 'function';
  }
  if (l.contains('LIST COMPREHENSION')) return 'list_comprehension';
  if (l.contains('FILE WRITE')) return 'file_write';
  if (l.contains('FILE LINES')) return 'file_lines';
  if (l.contains('FILE')) return 'file_read';
  if (l.contains('STRING METHODS')) return 'string_parse';
  if (l.contains('STRINGS')) {
    if (t.contains('BUILDER')) return 'string_builder';
    if (t.contains('REVERSE')) return 'string_reverse';
    if (t.contains('MANIPULATION')) return 'string_manipulation';
    return 'strings_basic';
  }
  if (l.contains('REDUCE')) return 'reduce';
  if (l.contains('OBJECTS')) return 'objects';
  if (l.contains('SPREAD')) return 'spread';
  if (l.contains('CLASSES') || l.contains('OOP')) return 'oop_class';
  if (l.contains('PROMISES')) return 'promises';
  if (l.contains('DICT')) return 'dict';
  if (l.contains('ARRAY') || l.contains('LIST')) {
    if (t.contains('ACCESS')) return 'array_first';
    if (t.contains('BASICS')) return 'array_length';
    if (t.contains('MAX') || t.contains('MIN')) return 'array_max';
    if (t.contains('MAP') || t.contains('FILTER')) return 'map_filter';
    return 'list_add';
  }
  return 'output';
}

extension PracticeQuestionVariant on QuizQuestion {
  /// Builds the module-page case exercise. The scenario, sample data, expected
  /// output and answer all come from the SAME topic case (see [_moduleCases]).
  QuizQuestion forModuleCasePractice(String language) {
    var key = _moduleCaseKey(language, moduleLabel, title);
    var moduleCase = _moduleCases[key]!;
    var answer = moduleCase.answerFor(language);

    // This topic has no version in the requested language: fall back to the
    // simplest case that does exist, so the answer is never empty.
    if (answer.isEmpty) {
      key = language.toUpperCase() == 'SQL' ? 'sql_select' : 'output';
      moduleCase = _moduleCases[key]!;
      answer = moduleCase.answerFor(language);
    }

    final tip = moduleCase.tips[language.toUpperCase()];
    return QuizQuestion(
      module: module,
      title: 'Case practice: $title',
      description: _applyCaseNames(moduleCase.prompt, language) +
          (tip == null ? '' : '\n$tip'),
      filename: filename,
      starterCode: '',
      correctAnswer: answer,
      explanation:
          'This short case practices ${moduleLabel.toLowerCase()} in $language.',
      hint: 'Write a small $language solution for this case.'
          '${tip == null ? '' : ' $tip'}',
      highlightLines: highlightLines,
      sampleData: moduleCase.sample,
      expectedOutput: moduleCase.output,
    );
  }

  String get moduleLabel =>
      module.replaceFirst(RegExp(r'^Q\d+\s*//\s*'), '').trim();

  QuizQuestion forPractice() {
    final numberVariants = <String, String>{};
    final literalVariants = <String, String>{};
    final literalPattern = RegExp(r'''(["'])([^"'\\\r\n]{2,})\1''');
    for (final text in [
      description,
      starterCode,
      correctAnswer,
      explanation,
      hint
    ]) {
      for (final match in literalPattern.allMatches(text)) {
        final literal = match.group(2)!;
        literalVariants.putIfAbsent(literal, () => '$literal practice');
      }
    }
    final orderedLiteralVariants = literalVariants.entries.toList()
      ..sort((first, second) => second.key.length.compareTo(first.key.length));

    String vary(String value) {
      var transformed = value;
      for (final entry in orderedLiteralVariants) {
        transformed = transformed.replaceAll(entry.key, entry.value);
      }
      transformed = transformed.replaceAllMapped(
        RegExp(
          r'Hello, World!|Hello, File!|Hello from C#!|Hello World|Hello|hello|Hi|hi|Equal|Age:|data\.txt|CelsiusToFahrenheit|Java|Alice|Bob|Charlie|apple|banana|cherry|\bGetTopStudents\b|\bstudents\b|\bstudent\b|\bcourses\b|\bcourse\b|\bPerson\b|\bfruits\b|\bfruit\b|\bnames\b|\bname\b|\bscore\b|\bgrade\b|\bnums\b|\barr\b|\bnum\b|\bcount\b|\bcounter\b|\bsum\b|\bmax\b|\bmin\b|\bcsv\b|\bparts\b|\bline\b|\bsb\b|\bprice\b|\bage\b|\bbase\b|\bexp\b|\bday\b|\bindex\b|\bi\b|\bn\b|\bx\b|\bs\b|\bf\b|\be\b|\ba\b|\bb\b|\bc\b',
        ),
        (match) {
          if (match[0] == 'a' ||
              match[0] == 'b' ||
              match[0] == 'c' ||
              match[0] == 'e') {
            return match[0]!;
          }
          const replacements = {
            'Hello, World!': 'Welcome to Siklab!',
            'Hello, File!': 'Practice File!',
            'Hello from C#!': 'Learning C#!',
            'Hello World': 'Siklab Rocks',
            'Hello': 'Hi there',
            'hello': 'welcome',
            'Hi': 'Hello there',
            'hi': 'hey',
            'Equal': 'Match',
            'CelsiusToFahrenheit': 'convertTemperature',
            'Age:': 'Years:',
            'data.txt': 'practice.txt',
            'apple': 'mango',
            'banana': 'orange',
            'cherry': 'papaya',
            'Java': 'Siklab',
            'Alice': 'Lia',
            'Bob': 'Marco',
            'Charlie': 'Niko',
            'GetTopStudents': 'GetHighScorers',
            'students': 'learners',
            'student': 'learner',
            'courses': 'subjects',
            'course': 'subject',
            'Person': 'Learner',
            'names': 'learnerNames',
            'name': 'learnerName',
            'fruits': 'produce',
            'fruit': 'item',
            'score': 'points',
            'grade': 'score',
            'nums': 'numbers',
            'arr': 'values',
            'num': 'number',
            'count': 'matches',
            'counter': 'ticks',
            'sum': 'total',
            'max': 'largest',
            'min': 'smallest',
            'csv': 'records',
            'parts': 'items',
            'line': 'rowText',
            'sb': 'builder',
            'price': 'cost',
            'age': 'years',
            'base': 'number',
            'exp': 'exponent',
            'day': 'dayNumber',
            'index': 'position',
            'i': 'index',
            'n': 'limit',
            'x': 'value',
            's': 'text',
            'a': 'firstValue',
            'b': 'secondValue',
            'c': 'celsiusValue',
            'e': 'error',
            'f': 'file',
          };
          return replacements[match[0]]!;
        },
      );
      return transformed.replaceAllMapped(RegExp(r'\d+'), (match) {
        final number = match[0]!;
        return numberVariants.putIfAbsent(
          number,
          () => (int.parse(number) + 1).toString(),
        );
      });
    }

    return QuizQuestion(
      module: module,
      title: title,
      description: vary(description),
      filename: filename,
      starterCode: vary(starterCode),
      correctAnswer: vary(correctAnswer),
      explanation: vary(explanation),
      hint: vary(hint),
      highlightLines: highlightLines,
      sampleData: vary(description),
      expectedOutput: _expectedOutputForAnswer(
        vary(correctAnswer),
        _languageForAnswer(correctAnswer),
      ),
    );
  }
}

String _languageForAnswer(String answer) {
  if (answer.contains('System.out.')) return 'Java';
  if (answer.contains('Console.')) return 'C#';
  if (answer.contains('console.')) return 'JavaScript';
  if (answer.trimLeft().toUpperCase().startsWith('SELECT') ||
      answer.trimLeft().toUpperCase().startsWith('INSERT') ||
      answer.trimLeft().toUpperCase().startsWith('UPDATE') ||
      answer.trimLeft().toUpperCase().startsWith('DELETE')) {
    return 'SQL';
  }
  return 'Python';
}

String _expectedOutputForAnswer(String answer, String language) {
  if (language.toUpperCase() == 'SQL') {
    return 'Query results depend on the sample rows for this exercise.';
  }

  final variables = <String, String>{};
  final assignmentPattern = RegExp(
    r"""(\w+)\s*=\s*("[^"]*"|'[^']*'|\d+|true|false)(?!\s*[=!])""",
    caseSensitive: false,
  );
  for (final match in assignmentPattern.allMatches(answer)) {
    variables[match.group(1)!] = _unquote(match.group(2)!);
  }

  final outputPattern = RegExp(
    r'(?:System\.out\.println|Console\.WriteLine|console\.log|print)\s*\(([^()]*)\)',
  );
  final outputLines = <String>[];
  for (final match in outputPattern.allMatches(answer)) {
    final expression = match.group(1)!.trim();
    final quoted = RegExp(r"""^("[^"]*"|'[^']*')$""").firstMatch(expression);
    if (quoted != null) {
      outputLines.add(_unquote(quoted.group(0)!));
      continue;
    }
    if (variables.containsKey(expression)) {
      outputLines.add(variables[expression]!);
      continue;
    }
    final resolvedExpression = expression.replaceAllMapped(
      RegExp(r'\b[A-Za-z_]\w*\b'),
      (match) => variables[match[0]] ?? match[0]!,
    );
    final arithmetic =
        RegExp(r'^(\d+)\s*([+-])\s*(\d+)$').firstMatch(resolvedExpression);
    if (arithmetic != null) {
      final left = int.parse(arithmetic.group(1)!);
      final right = int.parse(arithmetic.group(3)!);
      outputLines.add(
        (arithmetic.group(2) == '+' ? left + right : left - right).toString(),
      );
      continue;
    }
    if (RegExp(r'^\d+$').hasMatch(expression)) {
      outputLines.add(expression);
    }
  }
  if (outputLines.isNotEmpty) return outputLines.join('\n');
  return 'Output preview is unavailable for this solution pattern.';
}

String _unquote(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 2 &&
      ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
          (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  return trimmed;
}

String simulateCodeOutput(
  String source, {
  required String language,
  required QuizQuestion question,
}) {
  final code = _stripCommentsPreservingStrings(
    source,
    isPython: language.toUpperCase() == 'PYTHON',
    isSql: language.toUpperCase() == 'SQL',
  );
  if (code.trim().isEmpty) return 'Start typing code to see output.';
  final expectedPreview = question.expectedOutput;
  if (expectedPreview.isNotEmpty &&
      !expectedPreview.startsWith('Output preview is unavailable') &&
      !expectedPreview.startsWith('Query results depend') &&
      checkAnswer(source, question.correctAnswer, language: language)) {
    // The learner typed the reference solution, so show its exact output
    // (covers functions, switch, try/catch, SQL joins, etc. that the light
    // line-by-line preview below cannot evaluate).
    return expectedPreview;
  }
  if (language.toUpperCase() == 'SQL') {
    return _simulateSqlOutput(code, question);
  }

  final variables = <String, String>{};
  final arrays = <String, List<String>>{};
  final assignmentPattern = RegExp(
    r"""(?:\b(?:int|double|float|String|string|var|let|const)\s+)?(\w+)\s*=\s*("[^"]*"|'[^']*'|\d+(?:\.\d+)?|true|false|True|False|\[[^\]]*\]|\{[^}]*\})""",
    caseSensitive: false,
  );
  for (final match in assignmentPattern.allMatches(code)) {
    final name = match.group(1)!;
    final value = match.group(2)!.trim();
    if ((value.startsWith('[') && value.endsWith(']')) ||
        (value.startsWith('{') && value.endsWith('}'))) {
      final items = value.substring(1, value.length - 1);
      arrays[name] = items
          .split(',')
          .map((item) => _unquote(item.trim()))
          .where((item) => item.isNotEmpty)
          .toList();
    } else {
      variables[name] = _unquote(value);
    }
  }

  String evaluate(String expression) {
    final trimmed = expression.trim();
    final quoted = RegExp(r"""^("[^"]*"|'[^']*')$""").firstMatch(trimmed);
    if (quoted != null) return _unquote(trimmed);
    final indexed = RegExp(r'^(\w+)\s*\[\s*(\d+)\s*\]$').firstMatch(trimmed);
    if (indexed != null) {
      final values = arrays[indexed.group(1)];
      final index = int.parse(indexed.group(2)!);
      if (values != null && index < values.length) return values[index];
      return '';
    }
    if (variables.containsKey(trimmed)) return variables[trimmed]!;
    final length = RegExp(r'^(\w+)\.length$').firstMatch(trimmed);
    if (length != null) {
      return arrays[length.group(1)]?.length.toString() ?? '';
    }

    final tokens = trimmed.split(RegExp(r'\s*[+-]\s*'));
    if (tokens.length > 1) {
      final operators = RegExp(r'\s*([+-])\s*')
          .allMatches(trimmed)
          .map((match) => match.group(1)!)
          .toList();
      var value = evaluate(tokens.first);
      for (var i = 0; i < operators.length; i++) {
        final right = evaluate(tokens[i + 1]);
        final leftNumber = num.tryParse(value);
        final rightNumber = num.tryParse(right);
        if (leftNumber != null && rightNumber != null) {
          value = (operators[i] == '+'
                  ? leftNumber + rightNumber
                  : leftNumber - rightNumber)
              .toString();
        } else if (operators[i] == '+') {
          value += right;
        } else {
          return '';
        }
      }
      return value;
    }
    return variables[trimmed] ?? num.tryParse(trimmed)?.toString() ?? '';
  }

  final output = <String>[];
  final consumedRanges = <({int start, int end})>[];

  void executeLoopBody(String body) {
    final statements = body
        .replaceAll('{', '')
        .replaceAll('}', '')
        .split(RegExp(r'[;\n]'))
        .map((statement) => statement.trim())
        .where((statement) => statement.isNotEmpty);
    for (final statement in statements) {
      final call = RegExp(
        r'(?:System\.out\.print(?:ln)?|Console\.Write(?:Line)?|console\.log|print)\s*\(([^()]*)\)',
      ).firstMatch(statement);
      if (call != null) {
        final values = call.group(1)!.split(',').map(evaluate);
        output.add(values.where((value) => value.isNotEmpty).join(' '));
        continue;
      }
      final update = RegExp(r'^(\w+)\s*(\+\+|--|\+=|-=|\*=|/=|=)\s*(.*?)$')
          .firstMatch(statement);
      if (update == null) continue;
      final name = update.group(1)!;
      final operator = update.group(2)!;
      final right = update.group(3)!.trim();
      final current = num.tryParse(variables[name] ?? '');
      if (operator == '++' && current != null) {
        variables[name] = (current + 1).toString();
      } else if (operator == '--' && current != null) {
        variables[name] = (current - 1).toString();
      } else if (operator == '=') {
        variables[name] = evaluate(right);
      } else if (current != null) {
        final value = num.tryParse(evaluate(right));
        if (value == null) continue;
        final next = switch (operator) {
          '+=' => current + value,
          '-=' => current - value,
          '*=' => current * value,
          '/=' => current / value,
          _ => current,
        };
        variables[name] = next.toString();
      }
    }
  }

  final cStyleLoop = RegExp(
    r'for\s*\(\s*(?:(?:int|long|double|float|var|let|const)\s+)?(\w+)\s*=\s*(-?\d+(?:\.\d+)?)\s*;\s*\1\s*(<=|<|>=|>)\s*([^;]+)\s*;\s*\1\s*(\+\+|--|\+=\s*-?\d+|-=\s*-?\d+)\s*\)\s*\{?',
  );
  for (final loop in cStyleLoop.allMatches(code)) {
    final variable = loop.group(1)!;
    final start = num.parse(loop.group(2)!);
    final operator = loop.group(3)!;
    final bound = num.tryParse(evaluate(loop.group(4)!));
    if (bound == null) continue;
    final update = loop.group(5)!.replaceAll(' ', '');
    final step = update == '++'
        ? 1
        : update == '--'
            ? -1
            : update.startsWith('+=')
                ? num.parse(update.substring(2))
                : -num.parse(update.substring(2));
    final bodyStart = loop.end;
    final close = code.indexOf('}', bodyStart);
    final bodyEnd = close == -1 ? code.length : close;
    final body = code.substring(bodyStart, bodyEnd);
    final previousValue = variables[variable];
    var value = start;
    for (var iteration = 0; iteration < 1000; iteration++) {
      final continues = switch (operator) {
        '<' => value < bound,
        '<=' => value <= bound,
        '>' => value > bound,
        '>=' => value >= bound,
        _ => false,
      };
      if (!continues) break;
      variables[variable] = value.toString();
      executeLoopBody(body);
      value += step;
    }
    if (previousValue == null) {
      variables.remove(variable);
    } else {
      variables[variable] = previousValue;
    }
    consumedRanges.add(
      (start: loop.start, end: close == -1 ? code.length : close + 1),
    );
  }

  final pythonLoop = RegExp(
    r'for\s+(\w+)\s+in\s+range\(\s*(-?\d+)\s*,\s*(-?\d+)(?:\s*,\s*(-?\d+))?\s*\)\s*:',
  );
  for (final loop in pythonLoop.allMatches(code)) {
    final variable = loop.group(1)!;
    final start = int.parse(loop.group(2)!);
    final stop = int.parse(loop.group(3)!);
    final step = int.tryParse(loop.group(4) ?? '') ?? 1;
    if (step == 0) continue;
    final lineEnd = code.indexOf('\n', loop.end);
    final bodyStart = lineEnd == -1 ? loop.end : lineEnd + 1;
    var bodyEnd = code.length;
    for (final line in code.substring(bodyStart).split('\n')) {
      if (line.trim().isNotEmpty &&
          !line.startsWith(' ') &&
          !line.startsWith('\t')) {
        bodyEnd = bodyStart + code.substring(bodyStart).indexOf(line);
        break;
      }
    }
    final body = code.substring(bodyStart, bodyEnd);
    final previousValue = variables[variable];
    for (var value = start, iteration = 0;
        iteration < 1000 && (step > 0 ? value < stop : value > stop);
        value += step, iteration++) {
      variables[variable] = value.toString();
      executeLoopBody(body);
    }
    if (previousValue == null) {
      variables.remove(variable);
    } else {
      variables[variable] = previousValue;
    }
    consumedRanges.add((start: loop.start, end: bodyEnd));
  }

  final pythonIterableLoop =
      RegExp(r'for\s+(\w+)\s+in\s+(\w+)\s*:', multiLine: true);
  for (final loop in pythonIterableLoop.allMatches(code)) {
    if (code.substring(loop.start, loop.end).contains('range')) continue;
    final values = arrays[loop.group(2)];
    if (values == null) continue;
    final lineEnd = code.indexOf('\n', loop.end);
    final bodyStart = lineEnd == -1 ? loop.end : lineEnd + 1;
    final bodyEnd = _pythonIndentedBlockEnd(code, bodyStart);
    final body = code.substring(bodyStart, bodyEnd);
    final iterator = loop.group(1)!;
    final previousValue = variables[iterator];
    for (final value in values) {
      variables[iterator] = value;
      executeLoopBody(body);
    }
    if (previousValue == null) {
      variables.remove(iterator);
    } else {
      variables[iterator] = previousValue;
    }
    consumedRanges.add((start: loop.start, end: bodyEnd));
  }

  final whileLoop =
      RegExp(r'while\s*\(([^()]*)\)|while\s+([^:\n]+):').allMatches(code);
  for (final loop in whileLoop) {
    final condition = (loop.group(1) ?? loop.group(2) ?? '').trim();
    final isPython = loop.group(2) != null;
    final bodyStart = isPython
        ? (() {
            final lineEnd = code.indexOf('\n', loop.end);
            return lineEnd == -1 ? loop.end : lineEnd + 1;
          })()
        : (() {
            final openingBrace = code.indexOf('{', loop.end);
            return openingBrace == -1 ? loop.end : openingBrace + 1;
          })();
    final bodyEnd = isPython
        ? _pythonIndentedBlockEnd(code, bodyStart)
        : _matchingBraceEnd(code, bodyStart);
    final body = code.substring(bodyStart, bodyEnd);

    for (var iteration = 0;
        iteration < 1000 &&
            _evaluateLoopCondition(condition, variables, evaluate);
        iteration++) {
      executeLoopBody(body);
    }
    consumedRanges.add((start: loop.start, end: bodyEnd));
  }

  final callPattern = RegExp(
    r'(?:System\.out\.print(?:ln)?|Console\.Write(?:Line)?|console\.log|print)\s*\(([^()\n]*)\)',
  );
  for (final call in callPattern.allMatches(code)) {
    if (consumedRanges.any(
      (range) => call.start >= range.start && call.end <= range.end,
    )) {
      continue;
    }
    if (!_isOutputConditionSatisfied(code, call.start, variables)) continue;
    final expressions = call.group(1)!.split(',');
    final values = expressions.map(evaluate).where((value) => value.isNotEmpty);
    output.add(values.join(' '));
  }

  if (output.isNotEmpty) return output.join('\n');
  if (RegExp(r'\b(print|println|WriteLine|console\.log)\b').hasMatch(code)) {
    return 'Output is incomplete or not supported by the preview yet.';
  }
  return 'No output yet.';
}

int _pythonIndentedBlockEnd(String code, int bodyStart) {
  final lines = code.substring(bodyStart).split('\n');
  final firstBodyLine = lines.indexWhere((line) => line.trim().isNotEmpty);
  if (firstBodyLine == -1) return code.length;
  final bodyIndent =
      RegExp(r'^\s*').firstMatch(lines[firstBodyLine])!.group(0)!.length;
  var offset = bodyStart;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isNotEmpty) {
      final indent = RegExp(r'^\s*').firstMatch(line)!.group(0)!.length;
      if (i > firstBodyLine && indent < bodyIndent) return offset;
    }
    offset += line.length + 1;
  }
  return code.length;
}

int _matchingBraceEnd(String code, int bodyStart) {
  var depth = 1;
  for (var i = bodyStart; i < code.length; i++) {
    if (code[i] == '{') depth++;
    if (code[i] == '}' && --depth == 0) return i;
  }
  return code.length;
}

bool _evaluateLoopCondition(
  String condition,
  Map<String, String> variables,
  String Function(String) evaluate,
) {
  final match = RegExp(
    r"""^(.+?)\s*(>=|<=|===|!==|==|!=|>|<)\s*(.+?)$""",
  ).firstMatch(condition);
  if (match == null) return false;
  final left = evaluate(match.group(1)!);
  final right = evaluate(match.group(3)!);
  final leftNumber = num.tryParse(left);
  final rightNumber = num.tryParse(right);
  if (leftNumber != null && rightNumber != null) {
    return switch (match.group(2)) {
      '>' => leftNumber > rightNumber,
      '>=' => leftNumber >= rightNumber,
      '<' => leftNumber < rightNumber,
      '<=' => leftNumber <= rightNumber,
      '==' || '===' => leftNumber == rightNumber,
      '!=' || '!==' => leftNumber != rightNumber,
      _ => false,
    };
  }
  return switch (match.group(2)) {
    '==' || '===' => left == right,
    '!=' || '!==' => left != right,
    _ => false,
  };
}

bool _isOutputConditionSatisfied(
  String code,
  int outputPosition,
  Map<String, String> variables,
) {
  final prefix = code.substring(0, outputPosition);
  final ifMatches =
      RegExp(r'if\s*\(([^()]*)\)|if\s+([^:\n]+):').allMatches(prefix).toList();
  if (ifMatches.isEmpty) return true;
  final condition =
      (ifMatches.last.group(1) ?? ifMatches.last.group(2) ?? '').trim();
  final comparison = RegExp(
    r"""^(\w+)\s*(>=|<=|==|!=|>|<)\s*(\w+|\d+|"[^"]*"|'[^']*')$""",
  ).firstMatch(condition);
  if (comparison == null) return true;
  final left = variables[comparison.group(1)] ?? comparison.group(1)!;
  final right =
      variables[comparison.group(3)] ?? _unquote(comparison.group(3)!);
  final leftNumber = num.tryParse(left);
  final rightNumber = num.tryParse(right);
  final result = leftNumber != null && rightNumber != null
      ? switch (comparison.group(2)) {
          '>=' => leftNumber >= rightNumber,
          '<=' => leftNumber <= rightNumber,
          '>' => leftNumber > rightNumber,
          '<' => leftNumber < rightNumber,
          '==' => leftNumber == rightNumber,
          '!=' => leftNumber != rightNumber,
          _ => false,
        }
      : switch (comparison.group(2)) {
          '==' => left == right,
          '!=' => left != right,
          _ => false,
        };
  return result;
}

String _simulateSqlOutput(String code, QuizQuestion question) {
  final normalizedCode = code.trim().toUpperCase();
  if (normalizedCode.isEmpty) return 'Start typing a query to see results.';

  final expected = question.expectedOutput;
  if (normalizedCode.startsWith('SELECT')) {
    if (!RegExp(r'\bFROM\b', caseSensitive: false).hasMatch(code)) {
      return 'Complete the SELECT query to see matching sample rows.';
    }
    if (normalizedCode.contains('COUNT(') &&
        expected.toLowerCase().startsWith('count')) {
      return expected;
    }
    if (normalizedCode.contains('JOIN') &&
        expected.toLowerCase().contains('name | title')) {
      return expected;
    }
    if (normalizedCode.contains('ORDER BY') &&
        expected.toLowerCase().startsWith('title')) {
      return expected;
    }
    if (normalizedCode.contains('SELECT') &&
        expected.toLowerCase().startsWith('title')) {
      return expected;
    }
    return 'Query entered. Check the selected columns and filters for sample results.';
  }
  if (normalizedCode.startsWith('INSERT') &&
      normalizedCode.contains('VALUES')) {
    return expected;
  }
  if (normalizedCode.startsWith('UPDATE') &&
      normalizedCode.contains('SET') &&
      normalizedCode.contains('WHERE')) {
    return expected;
  }
  if (normalizedCode.startsWith('DELETE') && normalizedCode.contains('WHERE')) {
    return expected;
  }
  return 'Complete the SQL statement to preview its sample result.';
}

String _stripCommentsPreservingStrings(String input,
    {required bool isPython, required bool isSql}) {
  final buffer = StringBuffer();
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var inBlockComment = false;
  var i = 0;

  while (i < input.length) {
    final current = input[i];
    final next = i + 1 < input.length ? input[i + 1] : null;

    if (inSingleQuote) {
      buffer.write(current);
      if (current == "'" && (i == 0 || input[i - 1] != '\\')) {
        inSingleQuote = false;
      }
      i++;
      continue;
    }
    if (inDoubleQuote) {
      buffer.write(current);
      if (current == '"' && (i == 0 || input[i - 1] != '\\')) {
        inDoubleQuote = false;
      }
      i++;
      continue;
    }
    if (inBlockComment) {
      if (current == '*' && next == '/') {
        inBlockComment = false;
        i += 2;
      } else {
        i++;
      }
      continue;
    }

    if (current == "'") {
      inSingleQuote = true;
      buffer.write(current);
      i++;
      continue;
    }
    if (current == '"') {
      inDoubleQuote = true;
      buffer.write(current);
      i++;
      continue;
    }
    if (isPython && current == '#') {
      while (i < input.length && input[i] != '\n') {
        i++;
      }
      continue;
    }
    if (current == '/' && next == '/') {
      while (i < input.length && input[i] != '\n') {
        i++;
      }
      continue;
    }
    if (current == '/' && next == '*') {
      inBlockComment = true;
      i += 2;
      continue;
    }
    if (isSql && current == '-' && next == '-') {
      while (i < input.length && input[i] != '\n') {
        i++;
      }
      continue;
    }

    buffer.write(current);
    i++;
  }

  return buffer.toString();
}

String _normalizePythonLine(String line) {
  final leadingWhitespace = RegExp(r'^\s*').firstMatch(line)!.group(0)!;
  final content = line.substring(leadingWhitespace.length);
  final normalized = <String>[];
  String? quote;
  var escaped = false;
  var pendingWhitespace = false;
  const punctuation = '()[]{},.:=+-*/%<>';

  for (final character in content.split('')) {
    if (quote != null) {
      normalized.add(character);
      if (escaped) {
        escaped = false;
      } else if (character == r'\') {
        escaped = true;
      } else if (character == quote) {
        quote = null;
      }
      continue;
    }

    if (character == "'" || character == '"') {
      if (pendingWhitespace &&
          normalized.isNotEmpty &&
          !punctuation.contains(normalized.last)) {
        normalized.add(' ');
      }
      normalized.add(character);
      quote = character;
      pendingWhitespace = false;
      continue;
    }

    if (character.trim().isEmpty) {
      pendingWhitespace = true;
      continue;
    }

    if (punctuation.contains(character)) {
      while (normalized.isNotEmpty && normalized.last == ' ') {
        normalized.removeLast();
      }
      normalized.add(character);
      pendingWhitespace = false;
      continue;
    }

    if (pendingWhitespace &&
        normalized.isNotEmpty &&
        !punctuation.contains(normalized.last)) {
      normalized.add(' ');
    }
    normalized.add(character);
    pendingWhitespace = false;
  }

  return '$leadingWhitespace${normalized.join()}';
}

String _normalizeLoopVariableNames(String code) {
  final variableNames = <String>[];
  final loopPatterns = [
    RegExp(
      r'for\s*\(\s*(?:(?:int|long|double|float|var|let|const)\s+)?(\w+)\s*=\s*[^;]+;\s*\1\s*(?:<=|<|>=|>)\s*[^;]+;\s*\1\s*(?:\+\+|--|\+=\s*\d+|-=\s*\d+)',
    ),
    RegExp(r'for\s+(\w+)\s+in\s+range\s*\('),
    RegExp(r'for\s+(\w+)\s+in\s+[A-Za-z_]\w*'),
    RegExp(
      r'foreach\s*\(\s*(?:(?:int|long|double|float|var|string|char)\s+)?(\w+)\s+in\s+',
      caseSensitive: false,
    ),
  ];
  for (final pattern in loopPatterns) {
    for (final match in pattern.allMatches(code)) {
      final variable = match.group(1)!;
      if (!variableNames.contains(variable)) variableNames.add(variable);
    }
  }
  if (variableNames.isEmpty) return code;

  final canonicalNames = {
    for (var i = 0; i < variableNames.length; i++)
      variableNames[i]: '__loopVariable$i',
  };
  final result = StringBuffer();
  var quote = '';
  var escaped = false;
  var index = 0;
  while (index < code.length) {
    final character = code[index];
    if (quote.isNotEmpty) {
      result.write(character);
      if (escaped) {
        escaped = false;
      } else if (character == r'\') {
        escaped = true;
      } else if (character == quote) {
        quote = '';
      }
      index++;
      continue;
    }
    if (character == '"' || character == "'") {
      quote = character;
      result.write(character);
      index++;
      continue;
    }
    if (RegExp(r'[A-Za-z_]').hasMatch(character)) {
      var end = index + 1;
      while (end < code.length && RegExp(r'[A-Za-z0-9_]').hasMatch(code[end])) {
        end++;
      }
      final identifier = code.substring(index, end);
      result.write(canonicalNames[identifier] ?? identifier);
      index = end;
      continue;
    }
    result.write(character);
    index++;
  }
  return result.toString();
}

bool checkAnswer(String submitted, String correct, {String? language}) {
  if (submitted.trim().isEmpty) return false;

  final isSql = language?.toUpperCase() == 'SQL';
  final isPython = language?.toUpperCase() == 'PYTHON';

  String normalize(String s) {
    String noComments = _stripCommentsPreservingStrings(
      s,
      isPython: isPython,
      isSql: isSql,
    );
    noComments = _normalizeLoopVariableNames(noComments);

    if (isSql) {
      noComments = noComments.toUpperCase();
    }

    if (isPython) {
      return noComments
          .replaceAll('\t', '    ')
          .split('\n')
          .map(_normalizePythonLine)
          .where((line) => line.isNotEmpty)
          .join('\n')
          .trim();
    }

    return noComments
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*([;{}()\[\]=+\-*/%&|<>!,\.])\s*'), r'$1')
        .trim();
  }

  final s = normalize(submitted);
  final c = normalize(correct);

  return s == c;
}

bool checkModuleCaseAnswer(
  String submitted,
  QuizQuestion question, {
  required String language,
}) {
  if (checkAnswer(
    submitted,
    question.correctAnswer,
    language: language,
  )) {
    return true;
  }

  final topicLabel =
      question.module.replaceFirst(RegExp(r'^Q\d+\s*//\s*'), '').toUpperCase();
  if (!RegExp(r'\bIF\b|\bIF-|CONDITION|SWITCH').hasMatch(topicLabel)) {
    return false;
  }

  String withoutSingleStatementIfBraces(String code) => code
      .replaceAllMapped(
        RegExp(r'\bif\s*\(([^{}]*)\)\s*\{\s*([^{}]+?)\s*\}', dotAll: true),
        (match) => 'if (${match[1]}) ${match[2]!.trim()}',
      )
      .replaceAllMapped(
        RegExp(r'\belse\s*\{\s*([^{}]+?)\s*\}', dotAll: true),
        (match) => 'else ${match[1]!.trim()}',
      );

  return checkAnswer(
    withoutSingleStatementIfBraces(submitted),
    withoutSingleStatementIfBraces(question.correctAnswer),
    language: language,
  );
}

final List<LanguageQuiz> languageQuizzes = [
  const LanguageQuiz(
    name: 'Java',
    tag: 'OOP',
    color: Color(0xFFFF9A3C),
    icon: Icons.coffee_outlined,
    categories: {
      QuizCategory.beginner: [
        QuizQuestion(
          module: 'Q01 // PRINT',
          title: 'Hello World',
          description: 'Print "Hello, World!" to the console.',
          filename: 'Main.java',
          starterCode: '// print here\n',
          correctAnswer: 'System.out.println("Hello, World!");',
          explanation:
              'System.out.println() prints text followed by a newline.',
          hint: 'Use System.out.println() with double quotes around the text.',
        ),
        QuizQuestion(
          module: 'Q02 // VARIABLES',
          title: 'Declare Integer',
          description:
              'Declare an integer variable x with value 10 and print it.',
          filename: 'Main.java',
          starterCode: '// declare x and print\n',
          correctAnswer: 'int x = 10;\nSystem.out.println(x);',
          explanation:
              'int declares an integer variable. Use = to assign value.',
          hint:
              'Use int x = 10; to declare and assign, then System.out.println(x); to print.',
        ),
        QuizQuestion(
          module: 'Q03 // STRINGS',
          title: 'Declare String',
          description:
              'Declare a string variable name with "Java" and print it.',
          filename: 'Main.java',
          starterCode: '// declare name and print\n',
          correctAnswer: 'String name = "Java";\nSystem.out.println(name);',
          explanation: 'String declares a text variable. Use double quotes.',
          hint:
              'Use String name = "Java"; to declare, then print with System.out.println(name);.',
        ),
        QuizQuestion(
          module: 'Q04 // ARITHMETIC',
          title: 'Add Numbers',
          description: 'Declare int a=5, b=3 and print their sum.',
          filename: 'Main.java',
          starterCode: 'int a = 5, b = 3;\n// print sum\n',
          correctAnswer: 'int a = 5, b = 3;\nSystem.out.println(a + b);',
          explanation: '+ operator adds two numbers.',
          hint: 'Use a + b inside System.out.println() to add and print.',
        ),
        QuizQuestion(
          module: 'Q05 // IF STATEMENT',
          title: 'Check Positive',
          description: 'Given int n=7, print "Positive" if n > 0.',
          filename: 'Main.java',
          starterCode: 'int n = 7;\n// if statement\n',
          correctAnswer:
              'int n = 7;\nif (n > 0) {\n  System.out.println("Positive");\n}',
          explanation:
              'if (condition) { code } executes when condition is true.',
          hint: 'Use if (n > 0) and curly braces for the print statement.',
        ),
        QuizQuestion(
          module: 'Q06 // FOR LOOP',
          title: 'Print 1 to 3',
          description: 'Use for loop to print numbers 1, 2, 3.',
          filename: 'Main.java',
          starterCode: '// for loop here\n',
          correctAnswer:
              'for (int i = 1; i <= 3; i++) {\n  System.out.println(i);\n}',
          explanation:
              'for(init; condition; update) loops while condition true.',
          hint: 'for (int i = 1; i <= 3; i++) with println(i) inside.',
        ),
        QuizQuestion(
          module: 'Q07 // ARRAYS',
          title: 'Array Access',
          description:
              'Declare int[] arr = {10,20,30}; print the first element.',
          filename: 'Main.java',
          starterCode: 'int[] arr = {10,20,30};\n// print first element\n',
          correctAnswer: 'int[] arr = {10,20,30};\nSystem.out.println(arr[0]);',
          explanation: 'Arrays are 0-indexed. arr[0] is the first element.',
          hint: 'Use arr[0] to access the first element (index 0).',
        ),
        QuizQuestion(
          module: 'Q08 // DEBUG',
          title: 'Fix Semicolon',
          description:
              'Fix — missing semicolon.\n\nint x = 5\nSystem.out.println(x);',
          filename: 'Main.java',
          starterCode: 'int x = 5\nSystem.out.println(x);\n',
          correctAnswer: 'int x = 5;\nSystem.out.println(x);',
          explanation: 'Java statements end with semicolons.',
          hint: 'Add a semicolon after int x = 5.',
        ),
        QuizQuestion(
          module: 'Q09 // DEBUG',
          title: 'Fix Type',
          description: 'Fix — wrong type.\n\nint price = "100";',
          filename: 'Main.java',
          starterCode: 'int price = "100";\n',
          correctAnswer: 'int price = 100;',
          explanation: 'Use integer literal without quotes for int.',
          hint: 'Remove the quotes to make it an integer.',
        ),
        QuizQuestion(
          module: 'Q10 // DEBUG',
          title: 'Fix Case',
          description:
              'Fix — Java is case-sensitive.\n\nsystem.out.println("Hi");',
          filename: 'Main.java',
          starterCode: 'system.out.println("Hi");\n',
          correctAnswer: 'System.out.println("Hi");',
          explanation: 'Correct class name is System with capital S.',
          hint: 'Capitalize the S in System.',
        ),
      ],
      QuizCategory.intermediate: [
        QuizQuestion(
          module: 'Q01 // IF-ELSE',
          title: 'Number Sign',
          description: 'Check if number is positive, negative, or zero.',
          filename: 'Main.java',
          starterCode: 'int num = -5;\n// check sign\n',
          correctAnswer:
              'int num = -5;\nif (num > 0) System.out.println("Positive");\nelse if (num < 0) System.out.println("Negative");\nelse System.out.println("Zero");',
          explanation: 'if/else if/else chain checks multiple conditions.',
          hint:
              'Use if-else if-else to check if num is greater than, less than, or equal to zero.',
        ),
        QuizQuestion(
          module: 'Q02 // SWITCH',
          title: 'Grade Switch',
          description: 'Convert score to grade A/B/C/D/F using switch.',
          filename: 'Main.java',
          starterCode: 'int score = 85;\n// convert to grade\n',
          correctAnswer:
              'int score = 85;\nchar grade;\nif (score >= 90) grade = \'A\';\nelse if (score >= 80) grade = \'B\';\nelse if (score >= 70) grade = \'C\';\nelse if (score >= 60) grade = \'D\';\nelse grade = \'F\';\nSystem.out.println(grade);',
          explanation: 'if/else if chain maps ranges to grades.',
          hint:
              'Use if-else if to check score ranges and assign the appropriate grade.',
        ),
        QuizQuestion(
          module: 'Q03 // FOR LOOP',
          title: 'Sum 1 to N',
          description: 'Calculate sum of numbers from 1 to n.',
          filename: 'Main.java',
          starterCode: 'int n = 10, sum = 0;\n// calculate sum\n',
          correctAnswer:
              'int n = 10, sum = 0;\nfor (int i = 1; i <= n; i++) {\n  sum += i;\n}\nSystem.out.println(sum);',
          explanation: 'for loop iterates 1 to n, adding each to sum.',
          hint: 'Use a for loop from 1 to n and add each number to sum.',
        ),
        QuizQuestion(
          module: 'Q04 // WHILE',
          title: 'Countdown',
          description: 'Print countdown from 5 to 1.',
          filename: 'Main.java',
          starterCode: 'int count = 5;\n// countdown\n',
          correctAnswer:
              'int count = 5;\nwhile (count > 0) {\n  System.out.println(count);\n  count--;\n}',
          explanation: 'while loop continues while condition is true.',
          hint:
              'Use a while loop that continues while count is greater than 0.',
        ),
        QuizQuestion(
          module: 'Q05 // METHOD',
          title: 'Average Method',
          description: 'Create method that returns average of two doubles.',
          filename: 'Main.java',
          starterCode: '// create average method\n',
          correctAnswer:
              'public static double average(double a, double b) {\n  return (a + b) / 2;\n}',
          explanation:
              'Methods encapsulate reusable logic. Return calculated value.',
          hint:
              'Create a method that takes two doubles, adds them, divides by 2, and returns the result.',
        ),
        QuizQuestion(
          module: 'Q06 // ARRAY',
          title: 'Find Max',
          description: 'Find maximum value in array.',
          filename: 'Main.java',
          starterCode: 'int[] nums = {3, 7, 2, 9, 1};\n// find max\n',
          correctAnswer:
              'int[] nums = {3, 7, 2, 9, 1};\nint max = nums[0];\nfor (int n : nums) {\n  if (n > max) max = n;\n}\nSystem.out.println(max);',
          explanation:
              'Initialize max with first element, update when larger found.',
          hint:
              'Start with max as the first element, then loop through comparing each element.',
        ),
        QuizQuestion(
          module: 'Q07 // DEBUG',
          title: 'Fix Off-by-One',
          description:
              'Fix — loop runs one too many times.\n\nfor (int i = 0; i <= 5; i++)',
          filename: 'Main.java',
          starterCode:
              'for (int i = 0; i <= 5; i++) {\n  System.out.println(i);\n}\n',
          correctAnswer:
              'for (int i = 0; i < 5; i++) {\n  System.out.println(i);\n}',
          explanation:
              '<= includes 5, making 6 iterations. Use < for 5 iterations.',
          hint: 'Change <= to < so the loop runs exactly 5 times instead of 6.',
        ),
        QuizQuestion(
          module: 'Q08 // DEBUG',
          title: 'Fix Array Index',
          description:
              'Fix — array index out of bounds.\n\nint[] arr = new int[5];\narr[5] = 10;',
          filename: 'Main.java',
          starterCode: 'int[] arr = new int[5];\narr[5] = 10;\n',
          correctAnswer: 'int[] arr = new int[5];\narr[4] = 10;',
          explanation:
              'Arrays are 0-indexed. arr[5] is out of bounds for size 5.',
          hint:
              'Arrays are 0-indexed. The last index of a 5-element array is 4, not 5.',
        ),
        QuizQuestion(
          module: 'Q09 // DEBUG',
          title: 'Fix Return Type',
          description:
              'Fix — method missing return type.\n\nadd(int a, int b) { return a + b; }',
          filename: 'Main.java',
          starterCode: 'add(int a, int b) {\n  return a + b;\n}\n',
          correctAnswer: 'int add(int a, int b) {\n  return a + b;\n}',
          explanation: 'Methods need explicit return type in Java.',
          hint: 'Add the return type "int" before the method name.',
        ),
        QuizQuestion(
          module: 'Q10 // DEBUG',
          title: 'Fix String Compare',
          description:
              'Fix — using == for string comparison.\n\nString s1 = "hi";\nString s2 = "hi";\nif (s1 == s2)',
          filename: 'Main.java',
          starterCode: 'String s1 = "hi";\nString s2 = "hi";\nif (s1 == s2)\n',
          correctAnswer:
              'String s1 = "hi";\nString s2 = "hi";\nif (s1.equals(s2)) System.out.println("Equal");',
          explanation: '== compares references. .equals() compares content.',
          hint:
              'Use .equals() method instead of == for comparing string content.',
        ),
      ],
      QuizCategory.upperIntermediate: [
        QuizQuestion(
          module: 'Q01 // ARRAYS',
          title: 'Array Basics',
          description:
              'Declare int[] nums = {10,20,30,40,50}. Print the 3rd element and the array length.',
          filename: 'Main.java',
          starterCode:
              'int[] nums = {10,20,30,40,50};\n// print 3rd element and length\n',
          correctAnswer:
              'int[] nums = {10,20,30,40,50};\nSystem.out.println(nums[2]);\nSystem.out.println(nums.length);',
          explanation: 'Array indices start at 0. nums[2] is the 3rd element.',
          hint:
              'Access the 3rd element using index 2 (0-based) and use .length for array size.',
        ),
        QuizQuestion(
          module: 'Q02 // STRINGS',
          title: 'String Builder',
          description:
              'Use StringBuilder to concatenate "Hello" and "World" efficiently.',
          filename: 'Main.java',
          starterCode: '// use StringBuilder\n',
          correctAnswer:
              'StringBuilder sb = new StringBuilder();\nsb.append("Hello");\nsb.append("World");\nSystem.out.println(sb.toString());',
          explanation:
              'StringBuilder is mutable and more efficient for concatenation.',
          hint:
              'Create a StringBuilder, use append() to add strings, then toString() to get result.',
        ),
        QuizQuestion(
          module: 'Q03 // FILE',
          title: 'Read File',
          description: 'Read all lines from "data.txt" and print them.',
          filename: 'Main.java',
          starterCode: 'import java.io.*;\n// read lines from data.txt\n',
          correctAnswer:
              'import java.io.*;\ntry (BufferedReader br = new BufferedReader(new FileReader("data.txt"))) {\n  String line;\n  while ((line = br.readLine()) != null) {\n    System.out.println(line);\n  }\n}',
          explanation:
              'BufferedReader reads text efficiently. readLine() returns null at EOF.',
          hint:
              'Use BufferedReader with FileReader, then readLine() in a loop until null.',
        ),
        QuizQuestion(
          module: 'Q04 // OOP',
          title: 'Class & Object',
          description:
              'Create a Person class with name and age fields, constructor, and introduce method.',
          filename: 'Main.java',
          starterCode: '// create Person class\n',
          correctAnswer:
              'class Person {\n  String name;\n  int age;\n  Person(String name, int age) {\n    this.name = name;\n    this.age = age;\n  }\n  void introduce() {\n    System.out.println("Hi, I am " + name);\n  }\n}',
          explanation:
              'Classes encapsulate data and behavior. Constructors initialize fields.',
          hint:
              'Define fields, a constructor that sets them, and a method that prints using the fields.',
        ),
        QuizQuestion(
          module: 'Q05 // LIST',
          title: 'ArrayList',
          description:
              'Create ArrayList of Strings, add 3 names, and print the list.',
          filename: 'Main.java',
          starterCode:
              'import java.util.ArrayList;\n// create and populate list\n',
          correctAnswer:
              'import java.util.ArrayList;\nArrayList<String> names = new ArrayList<>();\nnames.add("Alice");\nnames.add("Bob");\nnames.add("Charlie");\nSystem.out.println(names);',
          explanation:
              'ArrayList is a resizable array. Use .add() to insert and for-each to iterate.',
          hint:
              'Use the .add() method to add each language to the ArrayList. Then use a for-each loop to iterate through the list and print each language.',
        ),
        QuizQuestion(
          module: 'Q06 // FILE WRITE',
          title: 'Write to File',
          description: 'Write "Hello, File!" to output.txt using FileWriter.',
          filename: 'Main.java',
          starterCode:
              'import java.io.*;\npublic class Main {\n  public static void main(String[] args) throws IOException {\n    // write to output.txt\n  }\n}',
          correctAnswer:
              'import java.io.*;\npublic class Main {\n  public static void main(String[] args) throws IOException {\n    FileWriter fw = new FileWriter("output.txt");\n    fw.write("Hello, File!");\n    fw.close();\n  }\n}',
          explanation:
              'FileWriter opens a file for writing. Always call .close() to flush and release the file.',
          hint:
              'Create a FileWriter object with the filename, use .write() to write the content, and always call .close() to save and release the file.',
        ),
        QuizQuestion(
          module: 'Q07 // PROBLEM SOLVING',
          title: 'Reverse Array',
          description:
              'Given int[] arr = {1,2,3,4,5}, print it in reverse order.',
          filename: 'Main.java',
          starterCode:
              'public class Main {\n  public static void main(String[] args) {\n    int[] arr = {1, 2, 3, 4, 5};\n    // print in reverse\n  }\n}',
          correctAnswer:
              'public class Main {\n  public static void main(String[] args) {\n    int[] arr = {1, 2, 3, 4, 5};\n    for (int i = arr.length - 1; i >= 0; i--) {\n      System.out.println(arr[i]);\n    }\n  }\n}',
          explanation:
              'Start the loop at the last index (length-1) and decrement down to 0.',
          hint:
              'Use a for loop that starts at the last index (arr.length - 1) and decrements down to 0 to print the array in reverse order.',
        ),
        QuizQuestion(
          module: 'Q08 // PROBLEM SOLVING',
          title: 'FizzBuzz',
          description:
              'For 1-20: print "FizzBuzz" if divisible by 3 and 5, "Fizz" by 3, "Buzz" by 5, else number.',
          filename: 'Main.java',
          starterCode:
              'public class Main {\n  public static void main(String[] args) {\n    for (int i = 1; i <= 20; i++) {\n      // FizzBuzz logic\n    }\n  }\n}',
          correctAnswer:
              'public class Main {\n  public static void main(String[] args) {\n    for (int i = 1; i <= 20; i++) {\n      if (i % 15 == 0) System.out.println("FizzBuzz");\n      else if (i % 3 == 0) System.out.println("Fizz");\n      else if (i % 5 == 0) System.out.println("Buzz");\n      else System.out.println(i);\n    }\n  }\n}',
          explanation:
              'Check divisibility by 15 first, then 3, then 5. % returns 0 when divisible.',
          hint:
              'Use if-else chain checking divisibility: first check if divisible by both 3 and 5 (i % 15 == 0), then by 3, then by 5, else print the number.',
        ),
        QuizQuestion(
          module: 'Q09 // DEBUG',
          title: 'Fix Array Index',
          description:
              'Fix the ArrayIndexOutOfBoundsException.\n\nint[] arr = {10, 20, 30};\nSystem.out.println(arr[3]);',
          filename: 'Main.java',
          starterCode:
              'public class Main {\n  public static void main(String[] args) {\n    int[] arr = {10, 20, 30};\n    System.out.println(arr[3]);\n  }\n}',
          correctAnswer:
              'public class Main {\n  public static void main(String[] args) {\n    int[] arr = {10, 20, 30};\n    System.out.println(arr[2]);\n  }\n}',
          explanation:
              'Array has 3 elements at indices 0, 1, 2. Index 3 is out of bounds. Last valid index is length-1 = 2.',
          hint:
              'Arrays are zero-indexed, so the last valid index is length-1. For an array of 3 elements, valid indices are 0, 1, and 2. Change the index to 2.',
        ),
        QuizQuestion(
          module: 'Q10 // DEBUG',
          title: 'Fix String Comparison',
          description:
              'Fix so "Equal" is printed when both strings have the same content.\n\nString a = "hello";\nString b = new String("hello");\nif (a == b) System.out.println("Equal");',
          filename: 'Main.java',
          starterCode:
              'public class Main {\n  public static void main(String[] args) {\n    String a = "hello";\n    String b = new String("hello");\n    if (a == b) System.out.println("Equal");\n    else System.out.println("Not equal");\n  }\n}',
          correctAnswer:
              'public class Main {\n  public static void main(String[] args) {\n    String a = "hello";\n    String b = new String("hello");\n    if (a.equals(b)) System.out.println("Equal");\n    else System.out.println("Not equal");\n  }\n}',
          explanation:
              '== compares object references, not content. Use .equals() to compare String values.',
          hint:
              'The == operator compares object references, not string content. Use the .equals() method to compare the actual string values.',
        ),
      ],
    },
  ),

  // ══════════════════ PYTHON ════════════════════════════════════════════════
  const LanguageQuiz(
    name: 'Python',
    tag: 'PYTHON',
    color: Color(0xFF3572A5),
    icon: Icons.code_outlined,
    categories: {
      QuizCategory.beginner: [
        QuizQuestion(
            module: 'Q01 // OUTPUT',
            title: 'Hello World',
            description: 'Print "Hello, World!" to the console.',
            filename: 'main.py',
            starterCode: '# print here\n',
            correctAnswer: 'print("Hello, World!")',
            explanation:
                'print() outputs text to the console. No semicolons or imports needed in Python.',
            hint:
                'Use the print() function to output text to the console. Remember to use double quotes for strings.'),
        QuizQuestion(
            module: 'Q02 // VARIABLES',
            title: 'Assign Integer',
            description: 'Create variable x with value 42 and print it.',
            filename: 'main.py',
            starterCode: '# assign x and print\n',
            correctAnswer: 'x = 42\nprint(x)',
            explanation:
                'Python is dynamically typed — no type declaration needed. Just assign and use.',
            hint:
                'Assign values to variables using the = operator. Python is dynamically typed, so no type declaration is needed.'),
        QuizQuestion(
            module: 'Q03 // STRINGS',
            title: 'Assign String',
            description: 'Create variable name with "Python" and print it.',
            filename: 'main.py',
            starterCode: '# assign name and print\n',
            correctAnswer: 'name = "Python"\nprint(name)',
            explanation:
                'Strings use double quotes. No type declaration needed.',
            hint:
                'Assign a string to a variable using double quotes, then print it.'),
        QuizQuestion(
            module: 'Q04 // ARITHMETIC',
            title: 'Add Numbers',
            description: 'Print the sum of 7 and 3.',
            filename: 'main.py',
            starterCode: '# print sum\n',
            correctAnswer: 'print(7 + 3)',
            explanation: '+ operator adds numbers. Print the result directly.',
            hint: 'Use the + operator to add 7 and 3, then print the result.'),
        QuizQuestion(
            module: 'Q05 // IF STATEMENT',
            title: 'Check Positive',
            description: 'Given n=5, print "Positive" if n > 0.',
            filename: 'main.py',
            starterCode: 'n = 5\n# if statement\n',
            correctAnswer: 'n = 5\nif n > 0:\n    print("Positive")',
            explanation: 'if condition: followed by indented code block.',
            hint: 'Use if n > 0: with indented print("Positive").'),
        QuizQuestion(
            module: 'Q06 // FOR LOOP',
            title: 'Print 1 to 3',
            description: 'Use for loop to print numbers 1, 2, 3.',
            filename: 'main.py',
            starterCode: '# for loop\n',
            correctAnswer: 'for i in range(1, 4):\n    print(i)',
            explanation:
                'range(start, stop) generates numbers. stop is exclusive.',
            hint:
                'Use for i in range(1, 4): to loop from 1 to 3, printing i each time.'),
        QuizQuestion(
            module: 'Q07 // LISTS',
            title: 'List Access',
            description:
                'Create list fruits = ["apple","banana"]; print the first item.',
            filename: 'main.py',
            starterCode: 'fruits = ["apple", "banana"]\n# print first\n',
            correctAnswer: 'fruits = ["apple", "banana"]\nprint(fruits[0])',
            explanation: 'Lists are 0-indexed. fruits[0] is the first element.',
            hint: 'Access the first element using index 0: fruits[0].'),
        QuizQuestion(
            module: 'Q08 // DEBUG',
            title: 'Fix Indentation',
            description:
                'Fix so it prints "Hello".\n\ndef greet():\nprint("Hello")',
            filename: 'main.py',
            starterCode: 'def greet():\nprint("Hello")\n\ngreet()\n',
            correctAnswer: 'def greet():\n    print("Hello")\n\ngreet()',
            explanation:
                'Python uses indentation (4 spaces) to define code blocks.',
            hint:
                'Indent the print statement by 4 spaces inside the function.'),
        QuizQuestion(
            module: 'Q09 // DEBUG',
            title: 'Fix Type Error',
            description:
                'Fix the crash when printing.\n\nage = "20"\nprint("Age: " + age + 5)',
            filename: 'main.py',
            starterCode: 'age = "20"\nprint("Age: " + age + 5)\n',
            correctAnswer: 'age = 20\nprint("Age: " + str(age + 5))',
            explanation:
                'Cannot add int to string. Convert to string with str().',
            hint:
                'Change age to an integer, then use str() to convert the sum to string.'),
        QuizQuestion(
            module: 'Q10 // DEBUG',
            title: 'Fix Range',
            description:
                'Fix to print 1 to 5.\n\nfor i in range(6):\n    print(i)',
            filename: 'main.py',
            starterCode: 'for i in range(6):\n    print(i)\n',
            correctAnswer: 'for i in range(1, 6):\n    print(i)',
            explanation: 'range(6) gives 0-5. Use range(1, 6) for 1-5.',
            hint:
                'range(6) starts at 0. Use range(1, 6) to start at 1 and end before 6.'),
      ],
      QuizCategory.intermediate: [
        QuizQuestion(
            module: 'Q01 // IF-ELIF',
            title: 'Positive Negative',
            description:
                'Given n=-5, print "Positive" if n>0, "Negative" if n<0, else "Zero".',
            filename: 'main.py',
            starterCode: 'n = -5\n# if-elif-else here\n',
            correctAnswer:
                'n = -5\nif n > 0:\n    print("Positive")\nelif n < 0:\n    print("Negative")\nelse:\n    print("Zero")',
            explanation:
                'elif is Python\'s "else if". Indentation (4 spaces) defines the block.',
            hint:
                'Use an if-elif-else chain. Check if n > 0 first, then elif n < 0, and else for when n equals 0.'),
        QuizQuestion(
            module: 'Q02 // FOR LOOP',
            title: 'List Iteration',
            description:
                'Print each item in fruits = ["apple","banana","cherry"].',
            filename: 'main.py',
            starterCode: 'fruits = ["apple","banana","cherry"]\n# for loop\n',
            correctAnswer:
                'fruits = ["apple","banana","cherry"]\nfor fruit in fruits:\n    print(fruit)',
            explanation:
                '"for item in list:" iterates each element. The indented body runs once per element.',
            hint:
                'Use a for loop with the syntax "for item in list:" to iterate through each fruit in the list and print it.'),
        QuizQuestion(
            module: 'Q03 // WHILE',
            title: 'Sum While',
            description: 'Use while loop to sum 1 to 10 and print the result.',
            filename: 'main.py',
            starterCode: 'total = 0\ni = 1\n# while loop\nprint(total)\n',
            correctAnswer:
                'total = 0\ni = 1\nwhile i <= 10:\n    total += i\n    i += 1\nprint(total)',
            explanation:
                'while condition: runs while true. i += 1 increments. Result: 55.',
            hint:
                'Use a while loop with the condition i <= 10. Inside the loop, add i to total and increment i by 1.'),
        QuizQuestion(
            module: 'Q04 // RANGE',
            title: 'Range Loop',
            description:
                'Use range() to print even numbers from 2 to 10 inclusive.',
            filename: 'main.py',
            starterCode: '# use range with step\n',
            correctAnswer: 'for i in range(2, 11, 2):\n    print(i)',
            explanation:
                'range(start, stop, step) generates numbers. step=2 skips odds. stop is exclusive so use 11.',
            hint:
                'Use range(start, stop, step) with start=2, stop=11 (exclusive), and step=2 to generate even numbers.'),
        QuizQuestion(
            module: 'Q05 // FUNCTIONS',
            title: 'Greet Function',
            description: 'Write greet(name) that returns "Hello, <name>!".',
            filename: 'main.py',
            starterCode:
                'def greet(name):\n    # return greeting\n    pass\n\nprint(greet("Siklab"))\n',
            correctAnswer:
                'def greet(name):\n    return "Hello, " + name + "!"\n\nprint(greet("Siklab"))',
            explanation:
                'def defines a function. return sends back the value to the caller.',
            hint:
                'Use the return statement to send back the greeting string. Concatenate "Hello, " with the name and "!" using the + operator.'),
        QuizQuestion(
            module: 'Q06 // DEFAULT ARGS',
            title: 'Default Parameters',
            description:
                'Write power(base, exp=2) returning base**exp. power(3) should return 9.',
            filename: 'main.py',
            starterCode:
                'def power(base, exp=2):\n    pass\n\nprint(power(3))    # 9\nprint(power(2, 8)) # 256\n',
            correctAnswer:
                'def power(base, exp=2):\n    return base ** exp\n\nprint(power(3))\nprint(power(2, 8))',
            explanation:
                'Default parameters are used when the caller omits that argument.',
            hint:
                'Define the function with a default value for exp in the parameter list. Use the ** operator to calculate the power.'),
        QuizQuestion(
            module: 'Q07 // FIZZBUZZ',
            title: 'FizzBuzz',
            description:
                'For 1 to 15, print "FizzBuzz" if divisible by 3 and 5, "Fizz" by 3, "Buzz" by 5, else number.',
            filename: 'main.py',
            starterCode:
                'for i in range(1, 16):\n    # FizzBuzz logic\n    pass\n',
            correctAnswer:
                'for i in range(1, 16):\n    if i % 15 == 0:\n        print("FizzBuzz")\n    elif i % 3 == 0:\n        print("Fizz")\n    elif i % 5 == 0:\n        print("Buzz")\n    else:\n        print(i)',
            explanation:
                'Check divisibility by 15 first (both 3 and 5). % returns 0 when evenly divisible.',
            hint:
                'Use an if-elif-else chain checking divisibility. First check if divisible by both 3 and 5 (i % 15 == 0), then by 3, then by 5.'),
        QuizQuestion(
            module: 'Q08 // RECURSION',
            title: 'Fibonacci',
            description:
                'Write fib(n) returning the nth Fibonacci number recursively. fib(7)=13.',
            filename: 'main.py',
            starterCode: 'def fib(n):\n    pass\nprint(fib(7))\n',
            correctAnswer:
                'def fib(n):\n    if n <= 0: return 0\n    if n == 1: return 1\n    return fib(n-1) + fib(n-2)\nprint(fib(7))',
            explanation:
                'Base cases: fib(0)=0, fib(1)=1. Recursive: sum of two previous values.',
            hint:
                'Define base cases for n <= 0 and n == 1. For n > 1, recursively return fib(n-1) + fib(n-2).'),
        QuizQuestion(
            module: 'Q09 // DEBUG',
            title: 'Fix the Range',
            description:
                'The loop prints 0 to 4 instead of 1 to 5. Fix it.\n\nfor i in range(5):\n    print(i)',
            filename: 'main.py',
            starterCode: 'for i in range(5):\n    print(i)\n',
            correctAnswer: 'for i in range(1, 6):\n    print(i)',
            explanation:
                'range(5) generates 0,1,2,3,4. Use range(1, 6) to generate 1,2,3,4,5.',
            hint:
                'The range() function starts at 0 by default. To start at 1 and end at 5, use range(1, 6) since the stop value is exclusive.'),
        QuizQuestion(
            module: 'Q10 // DEBUG',
            title: 'Fix the Return',
            description:
                'The function should return the larger value but always returns a.\n\ndef max_of(a, b):\n    if a > b: return a\n    return a',
            filename: 'main.py',
            starterCode:
                'def max_of(a, b):\n    if a > b:\n        return a\n    return a\n\nprint(max_of(3, 7))  # should print 7\n',
            correctAnswer:
                'def max_of(a, b):\n    if a > b:\n        return a\n    return b\n\nprint(max_of(3, 7))',
            explanation:
                'The else branch returns a instead of b. When a is not greater, b is the larger value.',
            hint:
                'The function should return b when a is not greater than b. Change the last return statement from return a to return b.'),
      ],
      QuizCategory.upperIntermediate: [
        QuizQuestion(
            module: 'Q01 // LISTS',
            title: 'List Methods',
            description:
                'Create list nums=[3,1,4,1,5], append 9, sort it, then print.',
            filename: 'main.py',
            starterCode: 'nums = [3, 1, 4, 1, 5]\n# append 9, sort, print\n',
            correctAnswer:
                'nums = [3, 1, 4, 1, 5]\nnums.append(9)\nnums.sort()\nprint(nums)',
            explanation:
                '.append() adds to end. .sort() sorts in-place ascending.',
            hint:
                'Use the .append() method to add 9 to the list, then use .sort() to sort the list in ascending order.'),
        QuizQuestion(
            module: 'Q02 // LIST COMPREHENSION',
            title: 'List Comprehension',
            description:
                'Create squares of 1-5 using list comprehension and print.',
            filename: 'main.py',
            starterCode:
                'squares = []\n# replace with list comprehension\nprint(squares)\n',
            correctAnswer:
                'squares = [x**2 for x in range(1,6)]\nprint(squares)',
            explanation:
                '[expr for var in iterable] builds a list. x**2 raises to power 2.',
            hint:
                'Use list comprehension syntax: [expression for variable in iterable]. Use x**2 to square each number and range(1,6) to generate 1-5.'),
        QuizQuestion(
            module: 'Q03 // STRINGS',
            title: 'String Manipulation',
            description:
                'Given s="hello world", capitalise it, replace "world" with "Python", count letters "l".',
            filename: 'main.py',
            starterCode: 's = "hello world"\n# capitalise, replace, count\n',
            correctAnswer:
                's = "hello world"\nprint(s.capitalize())\nprint(s.replace("world", "Python"))\nprint(s.count("l"))',
            explanation:
                '.capitalize() uppercases first letter. .replace() swaps substrings. .count() counts occurrences.',
            hint:
                'Use .capitalize() to uppercase the first letter, .replace() to swap substrings, and .count() to count character occurrences.'),
        QuizQuestion(
            module: 'Q04 // DICT',
            title: 'Dictionary Operations',
            description:
                'Create dict person={"name":"Alex","age":20}. Add "city"="Manila", update age to 21, print all items.',
            filename: 'main.py',
            starterCode:
                'person = {"name": "Alex", "age": 20}\n# add city, update age, print items\n',
            correctAnswer:
                'person = {"name": "Alex", "age": 20}\nperson["city"] = "Manila"\nperson["age"] = 21\nfor k, v in person.items():\n    print(k, ":", v)',
            explanation:
                'dict["key"] = value adds or updates. .items() returns key-value pairs.',
            hint:
                'Use bracket notation to add/update dictionary entries. Use .items() to iterate through key-value pairs.'),
        QuizQuestion(
            module: 'Q05 // FILE WRITE',
            title: 'Write to File',
            description:
                'Write "Hello, File!\nLine 2" to output.txt, then read and print its contents.',
            filename: 'main.py',
            starterCode: '# write then read output.txt\n',
            correctAnswer:
                'with open("output.txt", "w") as f:\n    f.write("Hello, File!\\nLine 2")\nwith open("output.txt", "r") as f:\n    print(f.read())',
            explanation:
                'with open() auto-closes the file. "w" writes, "r" reads. \\n is a newline.',
            hint:
                'Use the with statement to open files. First open with mode "w" to write, then with mode "r" to read. Use \\n for newlines.'),
        QuizQuestion(
            module: 'Q06 // FILE LINES',
            title: 'Read Lines',
            description:
                'Write 3 names to names.txt (one per line), then read and print each line stripped.',
            filename: 'main.py',
            starterCode: '# write names, then read line by line\n',
            correctAnswer:
                'with open("names.txt", "w") as f:\n    f.write("Alice\\nBob\\nCharlie\\n")\nwith open("names.txt", "r") as f:\n    for line in f:\n        print(line.strip())',
            explanation:
                '.strip() removes trailing newline. Iterating over a file reads line by line.',
            hint:
                'Iterate over the file object to read line by line. Use .strip() on each line to remove the trailing newline character.'),
        QuizQuestion(
            module: 'Q07 // PROBLEM SOLVING',
            title: 'Count Duplicates',
            description:
                'Given lst=[1,2,2,3,3,3,4], print each number and how many times it appears.',
            filename: 'main.py',
            starterCode:
                'lst = [1, 2, 2, 3, 3, 3, 4]\n# count and print occurrences\n',
            correctAnswer:
                'lst = [1, 2, 2, 3, 3, 3, 4]\ncounts = {}\nfor n in lst:\n    counts[n] = counts.get(n, 0) + 1\nfor k, v in counts.items():\n    print(k, ":", v)',
            explanation:
                'Use a dict to tally counts. .get(key, default) returns 0 if key missing.',
            hint:
                'Use a dictionary to store counts. For each number in the list, increment its count using counts.get(n, 0) + 1.'),
        QuizQuestion(
            module: 'Q08 // PROBLEM SOLVING',
            title: 'Palindrome Check',
            description:
                'Write is_palindrome(s) that returns True if s reads the same forwards and backwards.',
            filename: 'main.py',
            starterCode:
                'def is_palindrome(s):\n    pass\n\nprint(is_palindrome("racecar"))  # True\nprint(is_palindrome("hello"))    # False\n',
            correctAnswer:
                'def is_palindrome(s):\n    return s == s[::-1]\n\nprint(is_palindrome("racecar"))\nprint(is_palindrome("hello"))',
            explanation:
                's[::-1] reverses a string using slice notation with step -1.',
            hint:
                'Use string slicing with step -1 to reverse the string. Compare the original string with its reversed version.'),
        QuizQuestion(
            module: 'Q09 // DEBUG',
            title: 'Fix File Mode',
            description:
                'The code crashes when reading. Fix the bug.\n\nwith open("data.txt", "w") as f:\n    f.write("hello")\nwith open("data.txt", "w") as f:\n    print(f.read())',
            filename: 'main.py',
            starterCode:
                'with open("data.txt", "w") as f:\n    f.write("hello")\n\nwith open("data.txt", "w") as f:\n    print(f.read())\n',
            correctAnswer:
                'with open("data.txt", "w") as f:\n    f.write("hello")\n\nwith open("data.txt", "r") as f:\n    print(f.read())',
            explanation:
                '"w" mode truncates and does not allow reading. Use "r" to read the file.',
            hint:
                'The second open uses mode "w" which is for writing. Change it to mode "r" to read the file.'),
        QuizQuestion(
            module: 'Q10 // DEBUG',
            title: 'Fix List Index',
            description:
                'Fix the code — it should print the last element.\n\nfruits = ["apple","banana","cherry"]\nprint(fruits[3])',
            filename: 'main.py',
            starterCode:
                'fruits = ["apple", "banana", "cherry"]\nprint(fruits[3])\n',
            correctAnswer:
                'fruits = ["apple", "banana", "cherry"]\nprint(fruits[-1])',
            explanation:
                'List has 3 items at indices 0, 1, 2. Index 3 is out of range. Use -1 for the last element in Python.',
            hint:
                'The list has 3 elements at indices 0, 1, and 2. Index 3 is out of range. Use -1 to access the last element, or use index 2.'),
      ],
    },
  ),

  // ══════════════════ C# ════════════════════════════════════════════════════
  const LanguageQuiz(
    name: 'C#',
    tag: 'C#',
    color: Color(0xFF9B4F96),
    icon: Icons.terminal_outlined,
    categories: {
      // ── Beginner ──────────────────────────────────────────────────────────
      QuizCategory.beginner: [
        QuizQuestion(
            module: 'Q01 // OUTPUT',
            title: 'Hello World',
            description: 'Print "Hello, C#!" to the console.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  // print here\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  Console.WriteLine("Hello, C#!");\n}}',
            explanation:
                'Console.WriteLine() outputs a line. using System; imports the Console class.',
            hint:
                'Use the Console.WriteLine() method to output text to the console. Remember to use double quotes for strings.'),
        QuizQuestion(
            module: 'Q02 // VARIABLES',
            title: 'Declare Integer',
            description: 'Declare int x = 10 and print it.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  // declare and print\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int x = 10;\n  Console.WriteLine(x);\n}}',
            explanation: 'int declares an integer. Use = to assign value.',
            hint: 'Declare int x = 10; then Console.WriteLine(x); to print.'),
        QuizQuestion(
            module: 'Q03 // STRINGS',
            title: 'Declare String',
            description: 'Declare string name = "C#"; print it.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  // declare and print\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  string name = "C#";\n  Console.WriteLine(name);\n}}',
            explanation: 'string declares text. Use double quotes.',
            hint:
                'Use string name = "C#"; then print with Console.WriteLine(name);.'),
        QuizQuestion(
            module: 'Q04 // ARITHMETIC',
            title: 'Add Numbers',
            description: 'Print the sum of 8 and 4.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  // print sum\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  Console.WriteLine(8 + 4);\n}}',
            explanation: '+ operator adds numbers. Print directly.',
            hint: 'Use 8 + 4 inside Console.WriteLine().'),
        QuizQuestion(
            module: 'Q05 // IF STATEMENT',
            title: 'Check Positive',
            description: 'Given int n=6, print "Positive" if n > 0.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  int n = 6;\n  // if statement\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int n = 6;\n  if (n > 0) Console.WriteLine("Positive");\n}}',
            explanation: 'if (condition) executes when true.',
            hint: 'Use if (n > 0) Console.WriteLine("Positive");'),
        QuizQuestion(
            module: 'Q06 // FOR LOOP',
            title: 'Print 1 to 3',
            description: 'Use for loop to print 1, 2, 3.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  // for loop\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  for (int i = 1; i <= 3; i++)\n    Console.WriteLine(i);\n}}',
            explanation: 'for(init; condition; update) loops.',
            hint: 'for (int i = 1; i <= 3; i++) Console.WriteLine(i);'),
        QuizQuestion(
            module: 'Q07 // ARRAYS',
            title: 'Array Access',
            description: 'Declare int[] arr = {5,10,15}; print first element.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  int[] arr = {5,10,15};\n  // print first\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int[] arr = {5,10,15};\n  Console.WriteLine(arr[0]);\n}}',
            explanation: 'Arrays 0-indexed. arr[0] is first.',
            hint: 'Use arr[0] to access the first element.'),
        QuizQuestion(
            module: 'Q08 // DEBUG',
            title: 'Fix Semicolon',
            description:
                'Fix — missing semicolon.\n\nint x = 5\nConsole.WriteLine(x);',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  int x = 5\n  Console.WriteLine(x);\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int x = 5;\n  Console.WriteLine(x);\n}}',
            explanation: 'Statements end with semicolons.',
            hint: 'Add semicolon after int x = 5.'),
        QuizQuestion(
            module: 'Q09 // DEBUG',
            title: 'Fix Type',
            description: 'Fix — wrong type.\n\nint num = "123";',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  int num = "123";\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int num = 123;\n}}',
            explanation: 'Use integer literal without quotes.',
            hint: 'Remove quotes to make it an integer.'),
        QuizQuestion(
            module: 'Q10 // DEBUG',
            title: 'Fix Case',
            description:
                'Fix — C# is case-sensitive.\n\nconsole.writeline("Hi");',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  console.writeline("Hi");\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  Console.WriteLine("Hi");\n}}',
            explanation: 'Correct is Console.WriteLine with capitals.',
            hint: 'Capitalize Console and WriteLine.'),
      ],

      // ── Intermediate ──────────────────────────────────────────────────────
      QuizCategory.intermediate: [
        QuizQuestion(
            module: 'Q01 // IF-ELSE',
            title: 'Odd or Even',
            description:
                'Given int n=7, print "Even" if divisible by 2, else "Odd".',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  int n = 7;\n  // if-else\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int n = 7;\n  if (n % 2 == 0) Console.WriteLine("Even");\n  else Console.WriteLine("Odd");\n}}',
            explanation: 'n % 2 == 0 checks divisibility by 2.',
            hint:
                'Use an if-else statement. Check if n % 2 == 0 to determine if even, otherwise it is odd.'),
        QuizQuestion(
            module: 'Q02 // SWITCH',
            title: 'Day Name',
            description: 'Given int day=3, use switch to print the day name.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  int day = 3;\n  // switch\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int day = 3;\n  switch(day) {\n    case 1: Console.WriteLine("Monday"); break;\n    case 2: Console.WriteLine("Tuesday"); break;\n    case 3: Console.WriteLine("Wednesday"); break;\n    default: Console.WriteLine("Unknown"); break;\n  }\n}}',
            explanation:
                'switch compares day to each case. break prevents fall-through.',
            hint:
                'Use a switch statement with case labels for each day. Remember to use break after each case to prevent fall-through.'),
        QuizQuestion(
            module: 'Q03 // FOR LOOP',
            title: 'Countdown',
            description: 'Use for loop to print 10 down to 1.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  // for loop\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  for (int i = 10; i >= 1; i--)\n    Console.WriteLine(i);\n}}',
            explanation:
                'for(init; condition; update) — i-- decrements each iteration.',
            hint:
                'Use a for loop with initialization at 10, condition i >= 1, and decrement i-- to count down.'),
        QuizQuestion(
            module: 'Q04 // WHILE',
            title: 'Power of 2',
            description:
                'Use while to print powers of 2 (1,2,4,8,...) below 100.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  int n = 1;\n  // while loop\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int n = 1;\n  while (n < 100) { Console.WriteLine(n); n *= 2; }\n}}',
            explanation:
                'n *= 2 doubles each iteration. Loop stops when n >= 100.',
            hint:
                'Use a while loop with condition n < 100. Print n, then multiply n by 2 to get the next power of 2.'),
        QuizQuestion(
            module: 'Q05 // FOREACH',
            title: 'Array Average',
            description:
                'Given int[] scores={85,92,78,96,88}, compute and print the average.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  int[] scores = {85,92,78,96,88};\n  double total = 0;\n  // compute average\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int[] scores = {85,92,78,96,88};\n  double total = 0;\n  foreach (int s in scores) total += s;\n  Console.WriteLine("Avg: " + (total/scores.Length));\n}}',
            explanation:
                'foreach iterates all elements. Divide by .Length for average.',
            hint:
                'Use foreach to iterate through the array and sum all elements. Divide the total by the array length (scores.Length) to get the average.'),
        QuizQuestion(
            module: 'Q06 // METHODS',
            title: 'Celsius to Fahrenheit',
            description:
                'Write static CelsiusToFahrenheit(double c) returning (c*9.0/5.0)+32.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P {\n  // write method here\n  static void Main() { Console.WriteLine(CelsiusToFahrenheit(100)); }\n}',
            correctAnswer:
                'using System;\nclass P {\n  static double CelsiusToFahrenheit(double c) => (c*9.0/5.0)+32;\n  static void Main() { Console.WriteLine(CelsiusToFahrenheit(100)); }\n}',
            explanation:
                'Expression-bodied method using =>. Use 9.0/5.0 to avoid integer division.',
            hint:
                'Use the formula (c * 9.0/5.0) + 32 to convert Celsius to Fahrenheit. Use 9.0 and 5.0 to ensure floating-point division.'),
        QuizQuestion(
            module: 'Q07 // TRY-CATCH',
            title: 'Parse Safely',
            description:
                'Try int.Parse("abc"), catch FormatException and print "Bad format".',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  // try-catch here\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  try { int n = int.Parse("abc"); Console.WriteLine(n); }\n  catch (FormatException) { Console.WriteLine("Bad format"); }\n}}',
            explanation:
                'int.Parse() throws FormatException for non-numeric strings.',
            hint:
                'Use a try block to attempt parsing, and catch FormatException to handle invalid input.'),
        QuizQuestion(
            module: 'Q08 // RECURSION',
            title: 'Factorial',
            description:
                'Write static int Factorial(int n) recursively. Factorial(5)=120.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P {\n  static int Factorial(int n) { /* base + recursion */ }\n  static void Main() { Console.WriteLine(Factorial(5)); }\n}',
            correctAnswer:
                'using System;\nclass P {\n  static int Factorial(int n) {\n    if (n <= 1) return 1;\n    return n * Factorial(n - 1);\n  }\n  static void Main() { Console.WriteLine(Factorial(5)); }\n}',
            explanation:
                'Base case: n<=1 returns 1. Recursive case: n * Factorial(n-1).',
            hint:
                'A recursive function needs a base case (n <= 1) and a recursive case that multiplies n by Factorial(n - 1).'),
        QuizQuestion(
            module: 'Q09 // DEBUG',
            title: 'Fix the Loop',
            description:
                'This loop skips 5. Fix it to print 1 to 5.\n\nfor (int i=1; i<5; i++) Console.WriteLine(i);',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  for (int i = 1; i < 5; i++)\n    Console.WriteLine(i);\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  for (int i = 1; i <= 5; i++)\n    Console.WriteLine(i);\n}}',
            explanation: 'i < 5 stops before 5. Use i <= 5 to include 5.',
            hint:
                'The condition i < 5 stops at 4, not including 5. Change the condition to include 5.'),
        QuizQuestion(
            module: 'Q10 // DEBUG',
            title: 'Fix the Operator',
            description:
                'The method should multiply a and b but adds instead.\n\nstatic int Multiply(int a, int b) { return a + b; }',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P {\n  static int Multiply(int a, int b) { return a + b; }\n  static void Main() { Console.WriteLine(Multiply(4, 5)); }\n}',
            correctAnswer:
                'using System;\nclass P {\n  static int Multiply(int a, int b) { return a * b; }\n  static void Main() { Console.WriteLine(Multiply(4, 5)); }\n}',
            explanation:
                'The method uses + (addition) instead of * (multiplication).',
            hint:
                'The method is named Multiply but uses the addition operator +. Change it to the multiplication operator *.'),
      ],

      // ── Advanced ─────────────────────────────────────────────────────────
      QuizCategory.upperIntermediate: [
        QuizQuestion(
            module: 'Q01 // ARRAYS',
            title: 'Array Min Max',
            description:
                'Given int[] nums={4,7,2,9,1}, find and print the min and max values.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  int[] nums = {4, 7, 2, 9, 1};\n  // find min and max\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int[] nums = {4, 7, 2, 9, 1};\n  int min = nums[0], max = nums[0];\n  foreach (int n in nums) { if (n < min) min=n; if (n > max) max=n; }\n  Console.WriteLine("Min: " + min);\n  Console.WriteLine("Max: " + max);\n}}',
            explanation:
                'Initialise min and max to first element, then compare each element to update.',
            hint:
                'Initialize min and max to the first element. Iterate through the array and update min when a smaller value is found, and update max when a larger value is found.'),
        QuizQuestion(
            module: 'Q02 // STRINGS',
            title: 'Reverse a String',
            description: 'Reverse the string "Siklab" and print it.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  string s = "Siklab";\n  // reverse and print\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  string s = "Siklab";\n  char[] arr = s.ToCharArray();\n  Array.Reverse(arr);\n  Console.WriteLine(new string(arr));\n}}',
            explanation:
                'ToCharArray() converts to char[]. Array.Reverse() reverses in-place. new string(arr) converts back.',
            hint:
                'Convert the string to a character array, use Array.Reverse() to reverse it, then convert back to a string.'),
        QuizQuestion(
            module: 'Q03 // STRING METHODS',
            title: 'String Parsing',
            description:
                'Split "one,two,three" by comma and print each word with its index.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  string csv = "one,two,three";\n  // split and print with index\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  string csv = "one,two,three";\n  string[] parts = csv.Split(\',\');\n  for (int i=0; i<parts.Length; i++)\n    Console.WriteLine(i + ": " + parts[i]);\n}}',
            explanation:
                '.Split(char) breaks a string into an array. Use a for loop with index to track position.',
            hint:
                'Use the Split method with a comma to break the string into an array. Then iterate with a for loop to print each part with its index.'),
        QuizQuestion(
            module: 'Q04 // LIST',
            title: 'List Operations',
            description:
                'Create List<int>, add 10,20,30, remove 20, then print all.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nusing System.Collections.Generic;\nclass P { static void Main() {\n  var nums = new List<int>();\n  // add, remove, print\n}}',
            correctAnswer:
                'using System;\nusing System.Collections.Generic;\nclass P { static void Main() {\n  var nums = new List<int>();\n  nums.Add(10); nums.Add(20); nums.Add(30);\n  nums.Remove(20);\n  foreach (int n in nums) Console.WriteLine(n);\n}}',
            explanation:
                '.Add() appends. .Remove() deletes first matching value. foreach iterates.',
            hint:
                'Use .Add() to add elements to the list, .Remove() to delete a specific value, and foreach to iterate and print the remaining elements.'),
        QuizQuestion(
            module: 'Q05 // FILE WRITE',
            title: 'Write to File',
            description:
                'Write "Hello from C#!" to hello.txt then read and print it.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nusing System.IO;\nclass P { static void Main() {\n  // write then read\n}}',
            correctAnswer:
                'using System;\nusing System.IO;\nclass P { static void Main() {\n  File.WriteAllText("hello.txt", "Hello from C#!");\n  string content = File.ReadAllText("hello.txt");\n  Console.WriteLine(content);\n}}',
            explanation:
                'File.WriteAllText() creates/overwrites. File.ReadAllText() reads the whole file.',
            hint:
                'Use File.WriteAllText() to write the entire string to a file. Use File.ReadAllText() to read the entire file content back.'),
        QuizQuestion(
            module: 'Q06 // FILE LINES',
            title: 'Read Lines',
            description:
                'Write 3 cities to cities.txt (one per line), then read and print each.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nusing System.IO;\nclass P { static void Main() {\n  // write lines then read\n}}',
            correctAnswer:
                'using System;\nusing System.IO;\nclass P { static void Main() {\n  File.WriteAllLines("cities.txt", new[]{"Manila","Cebu","Davao"});\n  foreach (string line in File.ReadAllLines("cities.txt"))\n    Console.WriteLine(line);\n}}',
            explanation:
                'WriteAllLines() writes string[]. ReadAllLines() returns string[] per line.',
            hint:
                'Use File.WriteAllLines() to write an array of strings to a file, one per line. Use File.ReadAllLines() to read all lines into an array, then iterate to print each.'),
        QuizQuestion(
            module: 'Q07 // PROBLEM SOLVING',
            title: 'Count Vowels',
            description:
                'Write static int CountVowels(string s) returning the number of vowels.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P {\n  static int CountVowels(string s) { /* count a,e,i,o,u */ }\n  static void Main() { Console.WriteLine(CountVowels("Hello World")); }\n}',
            correctAnswer:
                'using System;\nclass P {\n  static int CountVowels(string s) {\n    int count = 0;\n    foreach (char c in s.ToLower())\n      if ("aeiou".Contains(c)) count++;\n    return count;\n  }\n  static void Main() { Console.WriteLine(CountVowels("Hello World")); }\n}',
            explanation:
                'ToLower() normalises case. Check if each char is in "aeiou" using Contains().',
            hint:
                'Iterate through each character in the string. Convert to lowercase and check if the character is contained in the string "aeiou". Increment a counter for each match.'),
        QuizQuestion(
            module: 'Q08 // PROBLEM SOLVING',
            title: 'FizzBuzz',
            description:
                'Print FizzBuzz for 1-20: "Fizz" if divisible by 3, "Buzz" by 5, "FizzBuzz" by both, else number.',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  for (int i=1; i<=20; i++) {\n    // FizzBuzz\n  }\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  for (int i=1; i<=20; i++) {\n    if (i%15==0) Console.WriteLine("FizzBuzz");\n    else if (i%3==0) Console.WriteLine("Fizz");\n    else if (i%5==0) Console.WriteLine("Buzz");\n    else Console.WriteLine(i);\n  }\n}}',
            explanation:
                'Check divisibility by 15 first (both 3 and 5), then individually.',
            hint:
                'Check the most specific condition first: if divisible by both 3 and 5 (i % 15 == 0), then divisible by 3, then by 5. If none match, print the number.'),
        QuizQuestion(
            module: 'Q09 // DEBUG',
            title: 'Fix Array Bounds',
            description:
                'Fix the IndexOutOfRangeException.\n\nint[] arr = {1,2,3};\nfor (int i=0; i<=arr.Length; i++) Console.WriteLine(arr[i]);',
            filename: 'Program.cs',
            starterCode:
                'using System;\nclass P { static void Main() {\n  int[] arr = {1, 2, 3};\n  for (int i = 0; i <= arr.Length; i++)\n    Console.WriteLine(arr[i]);\n}}',
            correctAnswer:
                'using System;\nclass P { static void Main() {\n  int[] arr = {1, 2, 3};\n  for (int i = 0; i < arr.Length; i++)\n    Console.WriteLine(arr[i]);\n}}',
            explanation:
                'arr.Length is 3, valid indices are 0,1,2. i <= arr.Length reaches index 3 which is out of bounds. Use i < arr.Length.',
            hint:
                'The loop condition i <= arr.Length goes one index too far. Array indices start at 0 and go up to arr.Length - 1.'),
        QuizQuestion(
            module: 'Q10 // DEBUG',
            title: 'Fix File Name',
            description:
                'The code writes to one file but reads another. Fix it.\n\nFile.WriteAllText("note.txt","Hello");\nstring s = File.ReadAllText("notes.txt");',
            filename: 'Program.cs',
            starterCode:
                'using System;\nusing System.IO;\nclass P { static void Main() {\n  File.WriteAllText("note.txt", "Hello");\n  string s = File.ReadAllText("notes.txt");\n  Console.WriteLine(s);\n}}',
            correctAnswer:
                'using System;\nusing System.IO;\nclass P { static void Main() {\n  File.WriteAllText("note.txt", "Hello");\n  string s = File.ReadAllText("note.txt");\n  Console.WriteLine(s);\n}}',
            explanation:
                'Written to "note.txt" but read from "notes.txt" (extra s). Filenames must match.',
            hint:
                'The write and read filenames must match exactly. Check for any extra characters in the filename used for reading.'),
      ],
    },
  ),

  // ══════════════════ JAVASCRIPT ════════════════════════════════════════════
  const LanguageQuiz(
    name: 'JavaScript',
    tag: 'JS',
    color: Color(0xFFE8C84A),
    icon: Icons.javascript_outlined,
    categories: {
      // ── Beginner ──────────────────────────────────────────────────────────
      QuizCategory.beginner: [
        QuizQuestion(
            module: 'Q01 // OUTPUT',
            title: 'Hello World',
            description: 'Log "Hello, World!" to the console.',
            filename: 'solution.js',
            starterCode: '// log here\n',
            correctAnswer: 'console.log("Hello, World!");',
            explanation:
                'console.log() outputs to the browser/Node.js console.',
            hint:
                'Use the console.log() function to output text to the console.'),
        QuizQuestion(
            module: 'Q02 // VARIABLES',
            title: 'Let & Const',
            description:
                'Declare const PI=3.14159 and let counter=0. Increment counter 3x and log both.',
            filename: 'solution.js',
            starterCode: '// declare PI and counter\n',
            correctAnswer:
                'const PI = 3.14159;\nlet counter = 0;\ncounter++; counter++; counter++;\nconsole.log(PI);\nconsole.log(counter);',
            explanation: 'const is immutable. let is block-scoped and mutable.',
            hint:
                'Use const for the immutable value and let for the mutable counter. Use the ++ operator to increment.'),
        QuizQuestion(
            module: 'Q03 // DATA TYPES',
            title: 'Types & typeof',
            description:
                'Create a number, string, boolean, and null. Log each with typeof.',
            filename: 'solution.js',
            starterCode: '// create and log with typeof\n',
            correctAnswer:
                'let num = 42;\nlet str = "hello";\nlet flag = true;\nlet nothing = null;\nconsole.log(typeof num);\nconsole.log(typeof str);\nconsole.log(typeof flag);\nconsole.log(typeof nothing);',
            explanation:
                'typeof returns a string describing the type. Note: typeof null returns "object" (JS quirk).',
            hint:
                'Use the typeof operator followed by the variable name to get its type as a string.'),
        QuizQuestion(
            module: 'Q04 // ARITHMETIC',
            title: 'Basic Operators',
            description: 'Given a=10, b=3, log: a+b, a-b, a*b, a/b, a%b, a**b.',
            filename: 'solution.js',
            starterCode: 'const a = 10, b = 3;\n// log all\n',
            correctAnswer:
                'const a = 10, b = 3;\nconsole.log(a+b); console.log(a-b);\nconsole.log(a*b); console.log(a/b);\nconsole.log(a%b); console.log(a**b);',
            explanation:
                '** is exponentiation. / returns a float in JS unlike integer division.',
            hint:
                'Use the arithmetic operators: + for addition, - for subtraction, * for multiplication, / for division, % for modulus, and ** for exponentiation.'),
        QuizQuestion(
            module: 'Q05 // STRINGS',
            title: 'String Basics',
            description:
                'Given name="JavaScript", log uppercase, length, and first 4 characters.',
            filename: 'solution.js',
            starterCode:
                'const name = "JavaScript";\n// log upper, length, first 4\n',
            correctAnswer:
                'const name = "JavaScript";\nconsole.log(name.toUpperCase());\nconsole.log(name.length);\nconsole.log(name.slice(0, 4));',
            explanation:
                '.toUpperCase() capitalises. .length gives character count. .slice(start, end) extracts.',
            hint:
                'Use .toUpperCase() to convert to uppercase, .length to get the character count, and .slice(start, end) to extract a substring.'),
        QuizQuestion(
            module: 'Q06 // TEMPLATE LITERALS',
            title: 'Template Strings',
            description: 'Use template literal to log "Name: Alex, Age: 20".',
            filename: 'solution.js',
            starterCode:
                'const name = "Alex";\nconst age = 20;\n// template literal\n',
            correctAnswer: r'''const name = "Alex";
const age = 20;
console.log(`Name: ${name}, Age: ${age}`);''',
            explanation:
                'Template literals use backticks. \${expr} embeds expressions inline.',
            hint:
                'Use backticks for the string and \${variable} to embed variable values directly inside the template literal.'),
        QuizQuestion(
            module: 'Q07 // COMPARISON',
            title: 'Strict Equality',
            description:
                'Log the results of: 5 === "5", 5 == "5", 0 === false, 0 == false.',
            filename: 'solution.js',
            starterCode: '// log comparison results\n',
            correctAnswer:
                'console.log(5 === "5");\nconsole.log(5 == "5");\nconsole.log(0 === false);\nconsole.log(0 == false);',
            explanation:
                '=== checks value AND type (strict). == does type coercion. Always prefer === in JS.',
            hint:
                'Use === for strict equality (checks type too) and == for loose equality (does type coercion). Compare each pair and log the boolean result.'),
        QuizQuestion(
            module: 'Q08 // TYPE COERCION',
            title: 'String to Number',
            description:
                'Convert "42" using Number() and parseInt(). Log both results and their types.',
            filename: 'solution.js',
            starterCode:
                'const s = "42";\n// convert using Number() and parseInt()\n',
            correctAnswer:
                'const s = "42";\nconst a = Number(s);\nconst b = parseInt(s);\nconsole.log(a, typeof a);\nconsole.log(b, typeof b);',
            explanation:
                'Number() and parseInt() both convert strings to numbers.',
            hint:
                'Use the Number() constructor or parseInt() function to convert the string to a number. Use typeof to check the type after conversion.'),
        QuizQuestion(
            module: 'Q09 // DEBUG',
            title: 'Fix the Declaration',
            description:
                'Fix the crash caused by a variable declaration error.\n\nconst score = 0;\nscore = 100;\nconsole.log(score);',
            filename: 'solution.js',
            starterCode:
                'const score = 0;\nscore = 100;\nconsole.log(score);\n',
            correctAnswer: 'let score = 0;\nscore = 100;\nconsole.log(score);',
            explanation:
                'const variables cannot be reassigned. Use let if the value needs to change.',
            hint:
                'const variables are immutable and cannot be reassigned. Use let instead if you need to change the value later.'),
        QuizQuestion(
            module: 'Q10 // DEBUG',
            title: 'Fix the Comparison',
            description:
                'Fix so it logs true when comparing "5" to 5 loosely.\n\nconsole.log("5" === 5);',
            filename: 'solution.js',
            starterCode: 'console.log("5" === 5);\n',
            correctAnswer: 'console.log("5" == 5);',
            explanation:
                '=== checks type too — "5" (string) !== 5 (number). Use == for loose type coercion.',
            hint:
                'The strict equality operator (===) checks both value and type. Use the loose equality operator (==) which performs type coercion instead.'),
      ],

      // ── Intermediate ──────────────────────────────────────────────────────
      QuizCategory.intermediate: [
        QuizQuestion(
            module: 'Q01 // IF-ELSE',
            title: 'Grade Label',
            description:
                'Given score=78, log "A" if >=90, "B" if >=80, "C" if >=70, else "F".',
            filename: 'solution.js',
            starterCode: 'const score = 78;\n// if-else chain\n',
            correctAnswer:
                'const score = 78;\nif (score >= 90) console.log("A");\nelse if (score >= 80) console.log("B");\nelse if (score >= 70) console.log("C");\nelse console.log("F");',
            explanation:
                'if/else if chains evaluate top-to-bottom. First true condition executes.',
            hint:
                'Use an if-else if-else chain to check the score against each threshold in descending order.'),
        QuizQuestion(
            module: 'Q02 // SWITCH',
            title: 'Day Type',
            description:
                'Given day="Saturday", use switch to log "Weekend" or "Weekday".',
            filename: 'solution.js',
            starterCode: 'const day = "Saturday";\n// switch here\n',
            correctAnswer:
                'const day = "Saturday";\nswitch(day) {\n  case "Saturday":\n  case "Sunday":\n    console.log("Weekend"); break;\n  default:\n    console.log("Weekday");\n}',
            explanation:
                'Fall-through: two cases with no break share the same action.',
            hint:
                'Use a switch statement with case labels for each day. Group Saturday and Sunday together without a break to make them fall through to the same action.'),
        QuizQuestion(
            module: 'Q03 // FOR LOOP',
            title: 'Sum Array',
            description:
                'Use a for loop to sum [1,2,3,4,5] and log the result.',
            filename: 'solution.js',
            starterCode:
                'const nums = [1, 2, 3, 4, 5];\nlet sum = 0;\n// for loop\nconsole.log(sum);\n',
            correctAnswer:
                'const nums = [1, 2, 3, 4, 5];\nlet sum = 0;\nfor (let i = 0; i < nums.length; i++) { sum += nums[i]; }\nconsole.log(sum);',
            explanation: 'for(init; condition; update) iterates by index.',
            hint:
                'Use a for loop with an index variable that goes from 0 to nums.length - 1. Add each element to the sum inside the loop.'),
        QuizQuestion(
            module: 'Q04 // WHILE',
            title: 'Collatz Sequence',
            description:
                'From n=6: if even divide by 2, if odd multiply by 3 and add 1. Stop at 1. Log each step.',
            filename: 'solution.js',
            starterCode: 'let n = 6;\n// while loop\n',
            correctAnswer:
                'let n = 6;\nwhile (n !== 1) {\n  console.log(n);\n  if (n % 2 === 0) n = n / 2;\n  else n = n * 3 + 1;\n}\nconsole.log(1);',
            explanation:
                'The Collatz conjecture: any starting number eventually reaches 1.',
            hint:
                'Use a while loop that continues while n is not equal to 1. Inside, check if n is even (n % 2 === 0) or odd and update n accordingly.'),
        QuizQuestion(
            module: 'Q05 // FUNCTIONS',
            title: 'Arrow Function',
            description: 'Write arrow function multiply(a,b) returning a*b.',
            filename: 'solution.js',
            starterCode:
                'const multiply = // your code\nconsole.log(multiply(3,4)); // 12\n',
            correctAnswer:
                'const multiply = (a,b) => a * b;\nconsole.log(multiply(3,4));',
            explanation:
                'Arrow syntax: (params) => expression. Single-expression body has implicit return.',
            hint:
                'Use the arrow function syntax with parentheses for parameters, the fat arrow =>, and the return expression after it.'),
        QuizQuestion(
            module: 'Q06 // CALLBACKS',
            title: 'Callback Function',
            description:
                'Write doTwice(fn) that calls fn twice. Test with ()=>console.log("Hi!").',
            filename: 'solution.js',
            starterCode:
                'function doTwice(fn) {\n  // call fn twice\n}\ndoTwice(() => console.log("Hi!"));\n',
            correctAnswer:
                'function doTwice(fn) { fn(); fn(); }\ndoTwice(() => console.log("Hi!"));',
            explanation:
                'Callbacks are functions passed as arguments and invoked later.',
            hint:
                'Define a function that accepts a parameter fn. Inside the function body, call fn() twice.'),
        QuizQuestion(
            module: 'Q07 // SCOPE',
            title: 'Closure Counter',
            description:
                'Write makeCounter() returning a function that increments and returns a count.',
            filename: 'solution.js',
            starterCode:
                'function makeCounter() {\n  // return a closure\n}\nconst c = makeCounter();\nconsole.log(c()); // 1\nconsole.log(c()); // 2\n',
            correctAnswer:
                'function makeCounter() {\n  let count = 0;\n  return () => ++count;\n}\nconst c = makeCounter();\nconsole.log(c()); console.log(c());',
            explanation:
                'Closures capture variables from their enclosing scope. count persists between calls.',
            hint:
                'Declare a local variable count inside makeCounter, then return an arrow function that increments and returns count. The count variable will be preserved between calls.'),
        QuizQuestion(
            module: 'Q08 // ERRORS',
            title: 'Try-Catch',
            description:
                'Try JSON.parse("{bad json}") and catch SyntaxError, logging "Parse failed".',
            filename: 'solution.js',
            starterCode: '// try-catch here\n',
            correctAnswer:
                'try {\n  JSON.parse("{bad json}");\n} catch (e) {\n  if (e instanceof SyntaxError) console.log("Parse failed");\n}',
            explanation:
                'try/catch handles runtime errors. instanceof checks the error type.',
            hint:
                'Wrap the JSON.parse() call in a try block. Use a catch block to handle the error, checking if it\'s an instance of SyntaxError.'),
        QuizQuestion(
            module: 'Q09 // DEBUG',
            title: 'Fix Infinite Loop',
            description:
                'The loop runs forever. Fix it to print 1 to 5.\n\nlet i=1; while(i<=5) { console.log(i); }',
            filename: 'solution.js',
            starterCode: 'let i = 1;\nwhile (i <= 5) {\n  console.log(i);\n}\n',
            correctAnswer:
                'let i = 1;\nwhile (i <= 5) {\n  console.log(i);\n  i++;\n}',
            explanation:
                'i is never incremented so the condition is always true. Add i++ inside the loop.',
            hint:
                'The loop condition never becomes false because i is not being updated. Add an increment statement inside the loop body.'),
        QuizQuestion(
            module: 'Q10 // DEBUG',
            title: 'Fix Missing Return',
            description:
                'The function always returns undefined. Fix it.\n\nfunction double(n) { const result = n * 2; }\nconsole.log(double(5));',
            filename: 'solution.js',
            starterCode: 'function double(n) {\n  const result = n * 2;\n',
            correctAnswer:
                'function double(n) {\n  const result = n * 2;\n  return result;\n}\nconsole.log(double(5));',
            explanation:
                'Without return, a function returns undefined. Add return result to send the value back.',
            hint:
                'The function calculates the result but doesn\'t return it. Add a return statement to send the result back to the caller.'),
      ],

      // ── Advanced ─────────────────────────────────────────────────────────
      QuizCategory.upperIntermediate: [
        QuizQuestion(
            module: 'Q01 // ARRAYS',
            title: 'Map & Filter',
            description:
                'From [1..5] use .map() to get squares and .filter() to keep values > 10.',
            filename: 'solution.js',
            starterCode: 'const nums = [1,2,3,4,5];\n// map then filter\n',
            correctAnswer:
                'const nums = [1,2,3,4,5];\nconst squares = nums.map(n => n*n);\nconst big = squares.filter(n => n > 10);\nconsole.log(big);',
            explanation:
                '.map() transforms each element. .filter() keeps matching ones.',
            hint:
                'Use .map() with an arrow function to transform each element to its square, then chain .filter() to keep only values greater than 10.'),
        QuizQuestion(
            module: 'Q02 // REDUCE',
            title: 'Reduce to Sum',
            description:
                'Use .reduce() to compute the sum of [10,20,30,40,50].',
            filename: 'solution.js',
            starterCode: 'const nums = [10, 20, 30, 40, 50];\n// use reduce\n',
            correctAnswer:
                'const nums = [10, 20, 30, 40, 50];\nconst sum = nums.reduce((acc, n) => acc + n, 0);\nconsole.log(sum);',
            explanation:
                '.reduce(fn, initialValue) accumulates. acc is the running total.',
            hint:
                'Use .reduce() with an accumulator and current element. The second parameter is the initial value (0). Return the sum of accumulator and current element.'),
        QuizQuestion(
            module: 'Q03 // STRINGS',
            title: 'String Manipulation',
            description:
                'Given str="hello world", capitalise first letter, split into words, and reverse word order.',
            filename: 'solution.js',
            starterCode:
                'const str = "hello world";\n// capitalise, split, reverse\n',
            correctAnswer:
                'const str = "hello world";\nconst cap = str[0].toUpperCase() + str.slice(1);\nconst words = cap.split(" ");\nconsole.log(words.reverse().join(" "));',
            explanation:
                '.split(" ") breaks into words. .reverse() reverses. .join(" ") reassembles.',
            hint:
                'Use .toUpperCase() on the first character, concatenate with .slice(1). Then use .split(" ") to break into words, .reverse() to reverse the array, and .join(" ") to reassemble.'),
        QuizQuestion(
            module: 'Q04 // OBJECTS',
            title: 'Destructuring',
            description:
                'Destructure name and age from {name:"Alex",age:20,city:"Manila"} and log them.',
            filename: 'solution.js',
            starterCode:
                'const person = { name: "Alex", age: 20, city: "Manila" };\n// destructure\n',
            correctAnswer:
                'const person = { name: "Alex", age: 20, city: "Manila" };\nconst { name, age } = person;\nconsole.log(name, age);',
            explanation:
                'Object destructuring extracts named properties into variables.',
            hint:
                'Use const with curly braces containing the property names you want to extract from the object.'),
        QuizQuestion(
            module: 'Q05 // SPREAD',
            title: 'Spread & Rest',
            description:
                'Merge a=[1,2,3] and b=[4,5,6] using spread. Write sum(...nums) using rest params.',
            filename: 'solution.js',
            starterCode:
                'const a=[1,2,3], b=[4,5,6];\n// merge using spread\nfunction sum(...nums) {\n  // return total\n}\nconsole.log(sum(1,2,3,4,5));\n',
            correctAnswer:
                'const a=[1,2,3], b=[4,5,6];\nconst merged = [...a,...b];\nconsole.log(merged);\nfunction sum(...nums) {\n  return nums.reduce((t,n)=>t+n,0);\n}\nconsole.log(sum(1,2,3,4,5));',
            explanation:
                '...arr spreads elements. ...nums in params collects all arguments.',
            hint:
                'Use the spread operator ... to merge arrays into a new array. For the function, use ...nums in the parameters to collect all arguments into an array.'),
        QuizQuestion(
            module: 'Q06 // CLASSES',
            title: 'ES6 Class',
            description:
                'Create class Animal(name) with speak(). Extend with Dog overriding speak to bark.',
            filename: 'solution.js',
            starterCode:
                'class Animal {\n  // constructor + speak\n}\nclass Dog extends Animal {\n  // override speak\n}\nnew Dog("Rex").speak();\n',
            correctAnswer:
                'class Animal {\n  constructor(name){this.name=name;}\n  speak(){console.log(this.name+" makes a sound");}\n}\nclass Dog extends Animal {\n  speak(){console.log(this.name+" barks");}\n}\nnew Dog("Rex").speak();',
            explanation:
                'ES6 classes. extends inherits. Override replaces the parent method.',
            hint:
                'Use the class keyword with a constructor to initialize properties. Use extends for inheritance and define a method with the same name in the child class to override it.'),
        QuizQuestion(
            module: 'Q07 // PROMISES',
            title: 'Promise Chain',
            description:
                'Create Promise resolving "data", chain .then() to uppercase it and log.',
            filename: 'solution.js',
            starterCode:
                'const p = new Promise(resolve => resolve("data"));\n// chain\n',
            correctAnswer:
                'const p = new Promise(resolve => resolve("data"));\np.then(v => v.toUpperCase()).then(console.log);',
            explanation:
                'Promises represent async values. .then() chains transformations.',
            hint:
                'Create a Promise with a resolve function. Chain .then() handlers to transform the value and use console.log as the final handler.'),
        QuizQuestion(
            module: 'Q08 // PROBLEM SOLVING',
            title: 'Flatten Array',
            description: 'Flatten [[1,2],[3,4],[5,6]] into a single array.',
            filename: 'solution.js',
            starterCode: 'const nested = [[1,2],[3,4],[5,6]];\n// flatten\n',
            correctAnswer:
                'const nested = [[1,2],[3,4],[5,6]];\nconsole.log(nested.flat());',
            explanation: '.flat() flattens one level of nesting.',
            hint:
                'Use the .flat() method on the nested array to flatten it by one level of nesting.'),
        QuizQuestion(
            module: 'Q09 // DEBUG',
            title: 'Fix Arrow Return',
            description:
                'Fix the map — it returns undefined for each element.\n\nconst doubled = nums.map(n => { n * 2; });',
            filename: 'solution.js',
            starterCode:
                'const nums = [1, 2, 3];\nconst doubled = nums.map(n => {\n  n * 2;\n});\nconsole.log(doubled);\n',
            correctAnswer:
                'const nums = [1, 2, 3];\nconst doubled = nums.map(n => {\n  return n * 2;\n});\nconsole.log(doubled);',
            explanation:
                'When using {} in an arrow function, return must be explicit. Without it the function returns undefined.',
            hint:
                'When an arrow function uses curly braces, the return keyword is required. Add return before the expression.'),
        QuizQuestion(
            module: 'Q10 // DEBUG',
            title: 'Fix this in Class',
            description:
                'Fix so dog.speak() logs "Rex barks".\n\nspeak() { console.log(name + " barks"); }',
            filename: 'solution.js',
            starterCode:
                'class Dog {\n  constructor(name) { this.name = name; }\n  speak() { console.log(name + " barks"); }\n}\nnew Dog("Rex").speak();\n',
            correctAnswer:
                'class Dog {\n  constructor(name) { this.name = name; }\n  speak() { console.log(this.name + " barks"); }\n}\nnew Dog("Rex").speak();',
            explanation:
                'Inside a class method, instance properties need this. name alone is an undefined variable.',
            hint:
                'Inside class methods, you need to use this to access instance properties. Prepend this. before the property name.'),
      ],
    },
  ),

  // ══════════════════ SQL ═══════════════════════════════════════════════════
  const LanguageQuiz(
    name: 'SQL',
    tag: 'SQL',
    color: Color(0xFF00B4D8),
    icon: Icons.storage_outlined,
    categories: {
      QuizCategory.beginner: [
        QuizQuestion(
          module: 'Q01 // SELECT',
          title: 'Basic SELECT',
          description: 'Select all columns from students where grade > 85.',
          filename: 'query.sql',
          starterCode:
              '-- students(id,name,age,grade,course)\nSELECT\nFROM\nWHERE;\n',
          correctAnswer: 'SELECT * FROM students WHERE grade > 85;',
          explanation:
              'SELECT * retrieves all columns. WHERE filters rows by condition.',
          hint:
              'Use SELECT * to get all columns, FROM to specify the table, and WHERE to filter by grade condition.',
        ),
        QuizQuestion(
          module: 'Q02 // INSERT',
          title: 'Insert Row',
          description:
              'Insert id=101, name="Maria Cruz", age=19, grade=92, course="CS" into students.',
          filename: 'query.sql',
          starterCode: '-- insert here\n',
          correctAnswer:
              'INSERT INTO students (id,name,age,grade,course) VALUES (101,\'Maria Cruz\',19,92,\'CS\');',
          explanation:
              'INSERT INTO lists columns; VALUES provides matching data.',
          hint:
              'Use INSERT INTO with the table name and column list, then VALUES with the corresponding values in the same order.',
        ),
        QuizQuestion(
          module: 'Q03 // UPDATE',
          title: 'Update Record',
          description: 'Set grade=95 for student id=101.',
          filename: 'query.sql',
          starterCode: '-- update here\n',
          correctAnswer: 'UPDATE students SET grade=95 WHERE id=101;',
          explanation:
              'UPDATE modifies rows. Always use WHERE to avoid updating all rows!',
          hint:
              'Use UPDATE with the table name, SET with the column and new value, and WHERE to specify which row to update.',
        ),
        QuizQuestion(
          module: 'Q04 // DELETE',
          title: 'Delete Record',
          description: 'Delete from students where grade < 50.',
          filename: 'query.sql',
          starterCode: '-- delete here\n',
          correctAnswer: 'DELETE FROM students WHERE grade < 50;',
          explanation:
              'DELETE removes rows matching WHERE. Without WHERE, all rows are deleted!',
          hint:
              'Use DELETE FROM with the table name and WHERE to specify which rows to delete.',
        ),
        QuizQuestion(
          module: 'Q05 // ORDER BY',
          title: 'Sort Results',
          description: 'Select all students ordered by grade descending.',
          filename: 'query.sql',
          starterCode: '-- select ordered\n',
          correctAnswer: 'SELECT * FROM students ORDER BY grade DESC;',
          explanation:
              'ORDER BY sorts results. DESC = descending (highest first).',
          hint:
              'Use SELECT * FROM students followed by ORDER BY grade DESC to sort from highest to lowest grade.',
        ),
        QuizQuestion(
          module: 'Q06 // LIMIT',
          title: 'Top N Records',
          description: 'Select the top 3 students by grade.',
          filename: 'query.sql',
          starterCode: '-- top 3 by grade\n',
          correctAnswer: 'SELECT * FROM students ORDER BY grade DESC LIMIT 3;',
          explanation:
              'LIMIT restricts row count. Combine with ORDER BY for top-N.',
          hint:
              'Order the students by grade descending, then use LIMIT to get only the top 3 results.',
        ),
        QuizQuestion(
          module: 'Q07 // COUNT',
          title: 'Count Rows',
          description: 'Count how many students are enrolled in "CS".',
          filename: 'query.sql',
          starterCode: '-- count CS students\n',
          correctAnswer: 'SELECT COUNT(*) FROM students WHERE course=\'CS\';',
          explanation: 'COUNT(*) counts all matching rows.',
          hint: 'Use COUNT(*) with WHERE to filter for the specific course.',
        ),
        QuizQuestion(
          module: 'Q08 // DEBUG',
          title: 'Fix the SELECT',
          description:
              'Fix the query — missing comma causes a syntax error.\n\nSELECT name grade FROM students WHERE grade > 80;',
          filename: 'query.sql',
          starterCode: 'SELECT name grade FROM students WHERE grade > 80;\n',
          correctAnswer: 'SELECT name, grade FROM students WHERE grade > 80;',
          explanation: 'Column names in SELECT must be separated by commas.',
          hint:
              'Column names in the SELECT clause must be separated by commas. Add a comma between name and grade.',
        ),
        QuizQuestion(
          module: 'Q09 // DEBUG',
          title: 'Fix the UPDATE',
          description:
              'Fix — this updates ALL rows instead of just id=5.\n\nUPDATE students SET grade=100;',
          filename: 'query.sql',
          starterCode: 'UPDATE students SET grade=100;\n',
          correctAnswer: 'UPDATE students SET grade=100 WHERE id=5;',
          explanation:
              'UPDATE without WHERE modifies every row. Always add WHERE to target specific rows.',
          hint:
              'The UPDATE is missing a WHERE clause to target specific rows. Add WHERE id=5 to only update the student with id 5.',
        ),
        QuizQuestion(
          module: 'Q10 // DEBUG',
          title: 'Fix the INSERT',
          description:
              'Fix — column count does not match values.\n\nINSERT INTO students (id, name, grade) VALUES (201, \'Juan\');',
          filename: 'query.sql',
          starterCode:
              'INSERT INTO students (id, name, grade) VALUES (201, \'Juan\');\n',
          correctAnswer:
              'INSERT INTO students (id, name, grade) VALUES (201, \'Juan\', 88);',
          explanation:
              '3 columns listed but only 2 values provided. Add the missing grade value.',
          hint:
              'The column list has 3 columns but VALUES only has 2 values. Add the missing grade value to match the column count.',
        ),
      ],
      QuizCategory.intermediate: [
        QuizQuestion(
          module: 'Q01 // JOIN',
          title: 'INNER JOIN',
          description:
              'Join students and courses on course_id. Show student name and course title.',
          filename: 'query.sql',
          starterCode: '-- students(id,name,course_id)  courses(id,title)\n',
          correctAnswer:
              'SELECT s.name, c.title FROM students s INNER JOIN courses c ON s.course_id=c.id;',
          explanation:
              'INNER JOIN returns rows where both tables have matching keys.',
          hint:
              'Use INNER JOIN to combine tables, specifying the join condition with ON to link the matching columns.',
        ),
        QuizQuestion(
          module: 'Q02 // LEFT JOIN',
          title: 'LEFT JOIN',
          description:
              'List all students and their course title (NULL if not enrolled).',
          filename: 'query.sql',
          starterCode: '-- show all students even without course\n',
          correctAnswer:
              'SELECT s.name, c.title FROM students s LEFT JOIN courses c ON s.course_id=c.id;',
          explanation:
              'LEFT JOIN keeps all rows from the left table; NULLs where no match.',
          hint:
              'Use LEFT JOIN instead of INNER JOIN to keep all rows from the left table even when there is no match in the right table.',
        ),
        QuizQuestion(
          module: 'Q03 // GROUP BY',
          title: 'Group & Count',
          description: 'Show each course with the count of enrolled students.',
          filename: 'query.sql',
          starterCode: '-- group by course\n',
          correctAnswer:
              'SELECT course, COUNT(*) as student_count FROM students GROUP BY course;',
          explanation:
              'GROUP BY collapses rows into groups. COUNT(*) counts per group.',
          hint:
              'Use GROUP BY on the course column, then use COUNT(*) to count how many students are in each group.',
        ),
        QuizQuestion(
          module: 'Q04 // HAVING',
          title: 'HAVING Filter',
          description: 'Show courses with more than 3 enrolled students.',
          filename: 'query.sql',
          starterCode: '-- group and filter with HAVING\n',
          correctAnswer:
              'SELECT course, COUNT(*) as cnt FROM students GROUP BY course HAVING COUNT(*) > 3;',
          explanation:
              'HAVING filters after grouping (like WHERE but for aggregate results).',
          hint:
              'Group by course, then use HAVING to filter the groups where the count is greater than 3.',
        ),
        QuizQuestion(
          module: 'Q05 // SUBQUERY',
          title: 'Subquery',
          description: 'Select students with grade above average.',
          filename: 'query.sql',
          starterCode: '-- use a subquery for AVG\n',
          correctAnswer:
              'SELECT * FROM students WHERE grade > (SELECT AVG(grade) FROM students);',
          explanation:
              'Subqueries run first and their result feeds the outer query.',
          hint:
              'Use a subquery in the WHERE clause to calculate the average grade, then compare each student\'s grade to that value.',
        ),
        QuizQuestion(
          module: 'Q06 // AGGREGATE',
          title: 'MIN MAX AVG',
          description:
              'Return min grade, max grade, and avg grade from students.',
          filename: 'query.sql',
          starterCode: '-- all three aggregates\n',
          correctAnswer:
              'SELECT MIN(grade), MAX(grade), AVG(grade) FROM students;',
          explanation:
              'MIN/MAX/AVG compute statistics across all matching rows.',
          hint:
              'Use the aggregate functions MIN(), MAX(), and AVG() on the grade column in a single SELECT statement.',
        ),
        QuizQuestion(
          module: 'Q07 // CASE',
          title: 'CASE Expression',
          description:
              'Label each student\'s grade: \'A\' >=90, \'B\' >=80, else \'C\'.',
          filename: 'query.sql',
          starterCode: '-- CASE expression\n',
          correctAnswer:
              'SELECT name, grade,\n  CASE\n    WHEN grade>=90 THEN \'A\'\n    WHEN grade>=80 THEN \'B\'\n    ELSE \'C\'\n  END AS letter\nFROM students;',
          explanation:
              'CASE is SQL\'s if-else. WHEN/THEN pairs evaluated top-to-bottom.',
          hint:
              'Use CASE with WHEN/THEN pairs to check conditions in order, and ELSE for the default case.',
        ),
        QuizQuestion(
          module: 'Q08 // DEBUG',
          title: 'Fix the JOIN Condition',
          description:
              'Fix — wrong key causes no results.\n\nSELECT s.name, c.title FROM students s INNER JOIN courses c ON s.id = c.id;',
          filename: 'query.sql',
          starterCode:
              'SELECT s.name, c.title\nFROM students s\nINNER JOIN courses c ON s.id = c.id;\n',
          correctAnswer:
              'SELECT s.name, c.title\nFROM students s\nINNER JOIN courses c ON s.course_id = c.id;',
          explanation:
              'The JOIN should link students.course_id to courses.id, not students.id to courses.id.',
          hint:
              'The JOIN is using the wrong column. Change s.id to s.course_id in the ON condition to link the foreign key correctly.',
        ),
        QuizQuestion(
          module: 'Q09 // DEBUG',
          title: 'Fix WHERE vs HAVING',
          description:
              'Fix — WHERE cannot filter on aggregate functions.\n\nSELECT course, COUNT(*) AS cnt FROM students WHERE COUNT(*) > 2 GROUP BY course;',
          filename: 'query.sql',
          starterCode:
              'SELECT course, COUNT(*) AS cnt\nFROM students\nWHERE COUNT(*) > 2\nGROUP BY course;\n',
          correctAnswer:
              'SELECT course, COUNT(*) AS cnt\nFROM students\nGROUP BY course\nHAVING COUNT(*) > 2;',
          explanation:
              'WHERE runs before grouping so it cannot reference aggregates. Use HAVING after GROUP BY.',
          hint:
              'WHERE cannot filter on aggregate functions like COUNT(). Move the filter to after GROUP BY and use HAVING instead.',
        ),
        QuizQuestion(
          module: 'Q10 // DEBUG',
          title: 'Fix the Subquery Table',
          description:
              'Fix — wrong table name inside subquery.\n\nSELECT * FROM students WHERE grade > (SELECT AVG(grade) FROM student);',
          filename: 'query.sql',
          starterCode:
              'SELECT * FROM students\nWHERE grade > (SELECT AVG(grade) FROM student);\n',
          correctAnswer:
              'SELECT * FROM students\nWHERE grade > (SELECT AVG(grade) FROM students);',
          explanation:
              'The subquery references "student" (singular) which does not exist. Table is "students".',
          hint:
              'The table name in the subquery is incorrect. Change "student" to "students" to match the actual table name.',
        ),
      ],
      QuizCategory.upperIntermediate: [
        QuizQuestion(
          module: 'Q01 // WINDOW',
          title: 'Window Functions',
          description:
              'Add ROW_NUMBER() over grades descending to rank each student.',
          filename: 'query.sql',
          starterCode: '-- window function\n',
          correctAnswer:
              'SELECT name, grade,\n  ROW_NUMBER() OVER (ORDER BY grade DESC) AS rank\nFROM students;',
          explanation:
              'Window functions operate per row without collapsing rows like GROUP BY.',
          hint:
              'Use the ROW_NUMBER() window function with OVER clause containing ORDER BY to rank rows based on grade.',
        ),
        QuizQuestion(
          module: 'Q02 // PARTITION',
          title: 'PARTITION BY',
          description:
              'Show each student with AVG grade per course using PARTITION BY.',
          filename: 'query.sql',
          starterCode: '-- partition by course\n',
          correctAnswer:
              'SELECT name, course, grade,\n  AVG(grade) OVER (PARTITION BY course) AS course_avg\nFROM students;',
          explanation:
              'PARTITION BY splits the window per group; each row keeps individual values.',
          hint:
              'Use PARTITION BY inside the OVER clause to calculate the average separately for each course while keeping all rows.',
        ),
        QuizQuestion(
          module: 'Q03 // RECURSIVE CTE',
          title: 'Recursive CTE',
          description: 'Use recursive CTE to generate sequence 1 to 5.',
          filename: 'query.sql',
          starterCode: '-- recursive WITH\n',
          correctAnswer:
              'WITH RECURSIVE seq(n) AS (\n  SELECT 1\n  UNION ALL\n  SELECT n+1 FROM seq WHERE n < 5\n)\nSELECT n FROM seq;',
          explanation:
              'Recursive CTEs have an anchor member and a recursive member joined by UNION ALL.',
          hint:
              'Use WITH RECURSIVE with an anchor (SELECT 1) and a recursive member (SELECT n+1) connected by UNION ALL.',
        ),
        QuizQuestion(
          module: 'Q04 // CTE',
          title: 'Common Table Expression',
          description:
              'Use CTE to get students with grade>85, then select their names.',
          filename: 'query.sql',
          starterCode: '-- WITH cte AS (...)\n',
          correctAnswer:
              'WITH top_students AS (\n  SELECT * FROM students WHERE grade > 85\n)\nSELECT name FROM top_students;',
          explanation:
              'CTEs (WITH) give a named subquery for readability and reuse.',
          hint:
              'Use WITH to define a named subquery (CTE), then reference that name in the main SELECT statement.',
        ),
        QuizQuestion(
          module: 'Q05 // STORED PROC',
          title: 'Stored Procedure',
          description:
              'Create procedure GetTopStudents(IN min_grade INT) that returns students above min_grade.',
          filename: 'query.sql',
          starterCode: '-- stored procedure\n',
          correctAnswer:
              'CREATE PROCEDURE GetTopStudents(IN min_grade INT)\nBEGIN\n  SELECT * FROM students WHERE grade >= min_grade;\nEND;',
          explanation:
              'Stored procedures encapsulate SQL logic. IN parameters accept caller values.',
          hint:
              'Use CREATE PROCEDURE with a parameter list, then BEGIN/END block containing the SELECT statement.',
        ),
        QuizQuestion(
          module: 'Q06 // TRIGGER',
          title: 'CREATE TRIGGER',
          description:
              'Create trigger trg_audit firing AFTER INSERT on students to log into audit_log.',
          filename: 'query.sql',
          starterCode: '-- create trigger\n',
          correctAnswer:
              'CREATE TRIGGER trg_audit\nAFTER INSERT ON students\nFOR EACH ROW\nINSERT INTO audit_log(action,student_id) VALUES (\'INSERT\',NEW.id);',
          explanation:
              'Triggers execute automatically on DML events. NEW refers to the inserted row.',
          hint:
              'Use CREATE TRIGGER with timing (AFTER INSERT), the table name, FOR EACH ROW, and the action to take using NEW to reference the inserted row.',
        ),
        QuizQuestion(
          module: 'Q07 // TRANSACTION',
          title: 'Transaction',
          description: 'Wrap two UPDATE statements in a transaction.',
          filename: 'query.sql',
          starterCode: '-- transaction\n',
          correctAnswer:
              'BEGIN TRANSACTION;\nUPDATE accounts SET balance=balance-100 WHERE id=1;\nUPDATE accounts SET balance=balance+100 WHERE id=2;\nCOMMIT;',
          explanation: 'Transactions ensure atomicity — all or nothing.',
          hint:
              'Use BEGIN TRANSACTION to start, execute your statements, then use COMMIT to save or ROLLBACK to undo.',
        ),
        QuizQuestion(
          module: 'Q08 // DEBUG',
          title: 'Fix Window Syntax',
          description:
              'Fix — missing parentheses in OVER clause.\n\nSELECT name, ROW_NUMBER() OVER ORDER BY grade DESC AS rank FROM students;',
          filename: 'query.sql',
          starterCode:
              'SELECT name, ROW_NUMBER() OVER ORDER BY grade DESC AS rank\nFROM students;\n',
          correctAnswer:
              'SELECT name, ROW_NUMBER() OVER (ORDER BY grade DESC) AS rank\nFROM students;',
          explanation:
              'The OVER clause requires parentheses. OVER (ORDER BY ...) is correct syntax.',
          hint:
              'The OVER clause requires parentheses. Wrap the ORDER BY clause in parentheses: OVER (ORDER BY grade DESC).',
        ),
        QuizQuestion(
          module: 'Q09 // DEBUG',
          title: 'Fix the Transaction',
          description:
              'The transaction never saves changes. Fix it.\n\nBEGIN TRANSACTION;\nUPDATE accounts SET balance=balance-200 WHERE id=1;\nROLLBACK;',
          filename: 'query.sql',
          starterCode:
              'BEGIN TRANSACTION;\nUPDATE accounts SET balance=balance-200 WHERE id=1;\nUPDATE accounts SET balance=balance+200 WHERE id=2;\nROLLBACK;\n',
          correctAnswer:
              'BEGIN TRANSACTION;\nUPDATE accounts SET balance=balance-200 WHERE id=1;\nUPDATE accounts SET balance=balance+200 WHERE id=2;\nCOMMIT;',
          explanation:
              'ROLLBACK undoes all changes. To save permanently, use COMMIT.',
          hint:
              'ROLLBACK undoes changes. Replace ROLLBACK with COMMIT to save the transaction permanently.',
        ),
        QuizQuestion(
          module: 'Q10 // DEBUG',
          title: 'Fix the CTE Name',
          description:
              'Fix — outer SELECT references wrong CTE name.\n\nWITH high_scorers AS (...)\nSELECT name FROM top_students;',
          filename: 'query.sql',
          starterCode:
              'WITH high_scorers AS (\n  SELECT * FROM students WHERE grade >= 90\n)\nSELECT name FROM top_students;\n',
          correctAnswer:
              'WITH high_scorers AS (\n  SELECT * FROM students WHERE grade >= 90\n)\nSELECT name FROM high_scorers;',
          explanation:
              'The CTE is named "high_scorers" but the outer SELECT uses "top_students" which does not exist.',
          hint:
              'The CTE name in the WITH clause does not match the name used in the SELECT. Change top_students to high_scorers.',
        ),
      ],
    },
  ),
];
