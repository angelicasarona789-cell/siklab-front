import 'package:flutter_test/flutter_test.dart';
import 'package:siklab/models/quiz_data.dart';

void main() {
  test('practice questions use different answers from module lessons', () {
    for (final quiz in languageQuizzes) {
      for (final questions in quiz.categories.values) {
        for (final moduleQuestion in questions) {
          final practiceQuestion = moduleQuestion.forPractice();

          expect(
            practiceQuestion.correctAnswer,
            isNot(moduleQuestion.correctAnswer),
            reason:
                '${quiz.name}: ${moduleQuestion.title} still uses the module answer.',
          );
          expect(
            checkAnswer(
              moduleQuestion.correctAnswer,
              practiceQuestion.correctAnswer,
              language: quiz.name,
            ),
            isFalse,
            reason:
                '${quiz.name}: ${moduleQuestion.title} accepts the module answer in practice.',
          );
          expect(
            checkAnswer(
              practiceQuestion.correctAnswer,
              practiceQuestion.correctAnswer,
              language: quiz.name,
            ),
            isTrue,
          );
        }
      }
    }
  });

  test('each language practice question retains its own specific hint', () {
    final firstQuestionHints = languageQuizzes.map((quiz) {
      final question = quiz.categories[QuizCategory.beginner]!.first;
      return question.forPractice().hint;
    }).toList();

    expect(firstQuestionHints.toSet(), hasLength(languageQuizzes.length));
    expect(
      firstQuestionHints.every((hint) => hint.trim().isNotEmpty),
      isTrue,
    );
    expect(firstQuestionHints.join(' '),
        isNot(contains('Focus on the key concept')));

    final javaHint = languageQuizzes
        .firstWhere((quiz) => quiz.name == 'Java')
        .categories[QuizCategory.beginner]!
        .first
        .forPractice()
        .hint;
    final pythonHint = languageQuizzes
        .firstWhere((quiz) => quiz.name == 'Python')
        .categories[QuizCategory.beginner]!
        .first
        .forPractice()
        .hint;
    expect(javaHint, contains('System.out.println'));
    expect(pythonHint, contains('print()'));
  });

  test('every practice category has question-specific hints', () {
    for (final quiz in languageQuizzes) {
      for (final category in QuizCategory.values) {
        final questions = quiz.categories[category]!;
        expect(questions, isNotEmpty, reason: '${quiz.name} ${category.label}');

        for (final question in questions) {
          final hint = question.forPractice().hint.trim();
          expect(
            hint,
            isNotEmpty,
            reason: '${quiz.name} ${category.label}: ${question.title}',
          );
          expect(
            hint,
            isNot(
                'Focus on the key concept and syntax for this task; avoid copying full lines.'),
            reason:
                '${quiz.name} ${category.label}: ${question.title} has a generic hint.',
          );
        }
      }
    }
  });

  test('practice arithmetic prompt and answer preserve declared variables', () {
    final javaQuiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final arithmetic = javaQuiz.categories[QuizCategory.beginner]!
        .firstWhere((question) => question.title == 'Add Numbers')
        .forPractice();

    expect(arithmetic.description, contains('a=6, b=4'));
    expect(arithmetic.correctAnswer, contains('int a = 6, b = 4;'));
    expect(arithmetic.correctAnswer, contains('a + b'));
  });

  test('checkAnswer ignores comments without treating quoted text as comments',
      () {
    expect(
      checkAnswer(
        "print('# not a comment')",
        "print('# not a comment')",
        language: 'Python',
      ),
      isTrue,
    );

    expect(
      checkAnswer(
        "SELECT * FROM users -- trailing comment\n;",
        "SELECT * FROM users;",
        language: 'SQL',
      ),
      isTrue,
    );
  });

  test('checkAnswer accepts Python whitespace around expressions', () {
    expect(
      checkAnswer(
        'print ("Welcome!")',
        'print("Welcome!")',
        language: 'Python',
      ),
      isTrue,
    );
    expect(
      checkAnswer(
        'age=20\nif age>=18:\n    print ("Allowed")',
        'age = 20\nif age >= 18:\n    print("Allowed")',
        language: 'Python',
      ),
      isTrue,
    );
  });

  test('checkAnswer preserves Python indentation and string contents', () {
    expect(
      checkAnswer(
        'if age >= 18:\nprint("Allowed")',
        'if age >= 18:\n    print("Allowed")',
        language: 'Python',
      ),
      isFalse,
    );
    expect(
      checkAnswer(
        'print("Welcome !")',
        'print("Welcome!")',
        language: 'Python',
      ),
      isFalse,
    );
  });

  test('loop answers accept equivalent iterator names but preserve loop logic',
      () {
    const javaExpected = 'for (int ticket = 1; ticket <= 3; ticket++) {\n'
        '  System.out.println(ticket);\n'
        '}';
    expect(
      checkAnswer(
        'for (int i = 1; i <= 3; i++) {\n'
        '  System.out.println(i);\n'
        '}',
        javaExpected,
        language: 'Java',
      ),
      isTrue,
    );
    expect(
      checkAnswer(
        'for (int i = 1; i < 3; i++) {\n'
        '  System.out.println(i);\n'
        '}',
        javaExpected,
        language: 'Java',
      ),
      isFalse,
    );

    expect(
      checkAnswer(
        'for value in range(1, 4):\n    print(value)',
        'for ticket in range(1, 4):\n    print(ticket)',
        language: 'Python',
      ),
      isTrue,
    );
  });

  test('loop answers accept different iterators without ignoring loop bounds',
      () {
    expect(
      checkAnswer(
        'for (int i = 1; i <= 3; i++) {\n'
            '  System.out.println(i);\n'
            '}',
        'for (int ticket = 1; ticket <= 3; ticket++) {\n'
            '  System.out.println(ticket);\n'
            '}',
        language: 'Java',
      ),
      isTrue,
    );
    expect(
      checkAnswer(
        'for (int i = 1; i < 3; i++) {\n'
            '  System.out.println(i);\n'
            '}',
        'for (int ticket = 1; ticket <= 3; ticket++) {\n'
            '  System.out.println(ticket);\n'
            '}',
        language: 'Java',
      ),
      isFalse,
    );
    expect(
      checkAnswer(
        'for value in range(1, 4):\n    print(value)',
        'for ticket in range(1, 4):\n    print(ticket)',
        language: 'Python',
      ),
      isTrue,
    );
  });
}
