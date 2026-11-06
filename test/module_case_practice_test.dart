import 'package:flutter_test/flutter_test.dart';
import 'package:siklab/models/quiz_data.dart';

void main() {
  test('module case exercises are simple and separate from practice questions',
      () {
    for (final quiz in languageQuizzes) {
      for (final questions in quiz.categories.values) {
        for (final lesson in questions) {
          final caseExercise = lesson.forModuleCasePractice(quiz.name);

          expect(
            caseExercise.description,
            isNot(lesson.description),
            reason: '${quiz.name}: ${lesson.title} reused its lesson prompt.',
          );
          expect(
            caseExercise.starterCode,
            isEmpty,
            reason: '${quiz.name}: ${lesson.title} includes a solution hint.',
          );
          expect(
            caseExercise.correctAnswer,
            isNot(lesson.correctAnswer),
            reason: '${quiz.name}: ${lesson.title} reused its lesson answer.',
          );
          expect(
            checkAnswer(
              caseExercise.correctAnswer,
              caseExercise.correctAnswer,
              language: quiz.name,
            ),
            isTrue,
          );
          expect(
            checkAnswer(
              lesson.correctAnswer,
              caseExercise.correctAnswer,
              language: quiz.name,
            ),
            isFalse,
            reason:
                '${quiz.name}: ${lesson.title} accepts the module lesson answer.',
          );
        }
      }
    }
  });

  test('every module case has a matching sample and expected result', () {
    for (final quiz in languageQuizzes) {
      for (final topics in quiz.categories.values) {
        for (final topic in topics) {
          final exercise = topic.forModuleCasePractice(quiz.name);
          expect(
            exercise.sampleData,
            isNotEmpty,
            reason: '${quiz.name}: ${topic.title} is missing sample data.',
          );
          expect(
            exercise.sampleData,
            isNot(exercise.description),
            reason:
                '${quiz.name}: ${topic.title} repeats its prompt as sample data.',
          );
          expect(
            exercise.expectedOutput,
            isNotEmpty,
            reason: '${quiz.name}: ${topic.title} is missing expected output.',
          );
          expect(
            exercise.expectedOutput,
            isNot(contains('unavailable')),
            reason:
                '${quiz.name}: ${topic.title} does not have a verified output.',
          );
          expect(
            checkModuleCaseAnswer(
              exercise.correctAnswer,
              exercise,
              language: quiz.name,
            ),
            isTrue,
            reason:
                '${quiz.name}: ${topic.title} sample does not match its correct answer.',
          );

          final label = topic.module.toUpperCase();
          if (quiz.name == 'SQL') {
            if (label.contains('JOIN')) {
              expect(
                exercise.expectedOutput,
                'name | title\nAna | Dune\nLuis | Foundation',
              );
            } else if (label.contains('INSERT')) {
              expect(
                exercise.expectedOutput,
                '1 row inserted\nBooks after: (1, The Hobbit), (2, Dune)',
              );
            } else if (label.contains('UPDATE')) {
              expect(
                exercise.expectedOutput,
                '1 row updated\n(id: 2, title: Dune, available: 1)',
              );
            } else if (label.contains('DELETE')) {
              expect(
                exercise.expectedOutput,
                '1 row deleted\nRemaining book: (1, The Hobbit)',
              );
            } else if (label.contains('COUNT') ||
                label.contains('GROUP') ||
                label.contains('HAVING') ||
                label.contains('AGGREGATE')) {
              expect(exercise.expectedOutput, 'count\n3');
            } else if (label.contains('ORDER')) {
              expect(
                exercise.expectedOutput,
                'title\nDune\nFoundation\nThe Hobbit',
              );
            } else {
              expect(
                exercise.expectedOutput,
                'title\nDune\nFoundation\nThe Hobbit',
              );
            }
          } else if (label.contains('LOOP') || label.contains('WHILE')) {
            expect(exercise.expectedOutput, '1\n2');
          } else if (label.contains('ARITHMETIC') ||
              label.contains('OPERATOR')) {
            expect(exercise.expectedOutput, '5');
          } else if (label.contains('VARIABLE')) {
            expect(exercise.expectedOutput, '5');
          } else if (label.contains('STRING')) {
            expect(exercise.expectedOutput, 'Mia');
          } else if (label.contains('IF') ||
              label.contains('CONDITION') ||
              label.contains('SWITCH')) {
            expect(exercise.expectedOutput, 'Allowed');
          } else if (label.contains('ARRAY') || label.contains('LIST')) {
            expect(exercise.expectedOutput, '4');
          } else if (label.contains('FUNCTION') || label.contains('METHOD')) {
            expect(exercise.expectedOutput, '5');
          } else if (label.contains('DEBUG')) {
            expect(exercise.expectedOutput, '4');
          } else if (label.contains('PRINT') || label.contains('OUTPUT')) {
            expect(exercise.expectedOutput, 'Welcome!');
          } else {
            expect(exercise.expectedOutput, 'Ready!');
          }
        }
      }
    }
  });

  test('case prompts state the scenario without prescribing implementation',
      () {
    final javaQuiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final arithmeticTopic = javaQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('ARITHMETIC'));
    final arithmeticCase = arithmeticTopic.forModuleCasePractice(javaQuiz.name);

    expect(
      arithmeticCase.description,
      'The kiosk records 2 tickets in the morning and 3 in the afternoon. '
      'The combined ticket total should be displayed.',
    );
    expect(arithmeticCase.description, isNot(contains('variable')));
    expect(arithmeticCase.description, isNot(contains('print')));
  });

  test('string case requires displaying the variable rather than its name', () {
    final javaQuiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final stringTopic = javaQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('STRINGS'));
    final caseExercise = stringTopic.forModuleCasePractice(javaQuiz.name);

    expect(
      checkAnswer(
        'String name = "Mia";\nSystem.out.println(name);',
        caseExercise.correctAnswer,
        language: javaQuiz.name,
      ),
      isTrue,
    );
    expect(
      checkAnswer(
        'String name = "Mia";\nSystem.out.println("name");',
        caseExercise.correctAnswer,
        language: javaQuiz.name,
      ),
      isFalse,
    );
  });

  test('arithmetic case uses the variables named in its prompt', () {
    final javaQuiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final arithmeticTopic = javaQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('ARITHMETIC'));
    final caseExercise = arithmeticTopic.forModuleCasePractice(javaQuiz.name);

    expect(
      checkAnswer(
        'int morning = 2, afternoon = 3;\n'
        'System.out.println(morning + afternoon);',
        caseExercise.correctAnswer,
        language: javaQuiz.name,
      ),
      isTrue,
    );
    expect(
      checkAnswer(
        'int a = 2, b = 3;\nSystem.out.println(a + b);',
        caseExercise.correctAnswer,
        language: javaQuiz.name,
      ),
      isFalse,
    );
  });

  test('module case preview shows its sample and expected output', () {
    final javaQuiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final arithmeticTopic = javaQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('ARITHMETIC'));
    final caseExercise = arithmeticTopic.forModuleCasePractice(javaQuiz.name);

    expect(
      caseExercise.sampleData,
      'Morning tickets: 2\nAfternoon tickets: 3',
    );
    expect(caseExercise.expectedOutput, '5');
  });

  test('Java loop case expects both ticket numbers on separate lines', () {
    final javaQuiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final loopTopic = javaQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('LOOP'));
    final caseExercise = loopTopic.forModuleCasePractice(javaQuiz.name);

    expect(caseExercise.sampleData, 'Ticket numbers to display: 1, 2');
    expect(caseExercise.expectedOutput, '1\n2');
    expect(
      caseExercise.correctAnswer,
      contains('System.out.println(ticket)'),
    );
  });

  test('live preview simulates loops for Java, C#, JavaScript, and Python', () {
    const codeByLanguage = {
      'Java': 'for (int ticket = 1; ticket <= 2; ticket++) {\n'
          '  System.out.println(ticket);\n'
          '}',
      'C#': 'for (int ticket = 1; ticket <= 2; ticket++) {\n'
          '  Console.WriteLine(ticket);\n'
          '}',
      'JavaScript': 'for (let ticket = 1; ticket <= 2; ticket++) {\n'
          '  console.log(ticket);\n'
          '}',
      'Python': 'for ticket in range(1, 3):\n    print(ticket)',
    };
    for (final entry in codeByLanguage.entries) {
      final quiz = languageQuizzes.firstWhere((quiz) => quiz.name == entry.key);
      final topic = quiz.categories.values
          .expand((questions) => questions)
          .firstWhere((question) => question.module.contains('LOOP'));
      expect(
        simulateCodeOutput(
          entry.value,
          language: entry.key,
          question: topic.forModuleCasePractice(entry.key),
        ),
        '1\n2',
        reason: '${entry.key} should show both loop iterations.',
      );
    }
  });

  test('live preview updates output for partially typed code', () {
    final quiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final topic = quiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('LOOP'));
    final caseExercise = topic.forModuleCasePractice(quiz.name);

    expect(
      simulateCodeOutput(
        'for (int ticket = 1; ticket <= 2; ticket++) {\n'
        '  System.out.println(ticket);',
        language: quiz.name,
        question: caseExercise,
      ),
      '1\n2',
    );
  });

  test('live preview simulates descending and stepped loops', () {
    final javaQuiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final javaTopic = javaQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('LOOP'));
    final javaCase = javaTopic.forModuleCasePractice(javaQuiz.name);
    expect(
      simulateCodeOutput(
        'for (int count = 3; count >= 1; count--) {\n'
        '  System.out.println(count);\n'
        '}',
        language: javaQuiz.name,
        question: javaCase,
      ),
      '3\n2\n1',
    );

    final pythonQuiz =
        languageQuizzes.firstWhere((quiz) => quiz.name == 'Python');
    final pythonTopic = pythonQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('RANGE'));
    expect(
      simulateCodeOutput(
        'for number in range(2, 11, 2):\n    print(number)',
        language: pythonQuiz.name,
        question: pythonTopic.forModuleCasePractice(pythonQuiz.name),
      ),
      '2\n4\n6\n8\n10',
    );
  });

  test('live preview carries accumulator state through loop iterations', () {
    final javaQuiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final javaTopic = javaQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('LOOP'));
    expect(
      simulateCodeOutput(
        'int sum = 0;\n'
        'for (int i = 1; i <= 3; i++) {\n'
        '  sum += i;\n'
        '}\n'
        'System.out.println(sum);',
        language: javaQuiz.name,
        question: javaTopic.forModuleCasePractice(javaQuiz.name),
      ),
      '6',
    );

    final pythonQuiz =
        languageQuizzes.firstWhere((quiz) => quiz.name == 'Python');
    final whileTopic = pythonQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('WHILE'));
    final whileCase = whileTopic.forModuleCasePractice(pythonQuiz.name);
    expect(
      simulateCodeOutput(
        'total = 0\n'
        'i = 1\n'
        'while i <= 3:\n'
        '    total += i\n'
        '    i += 1\n'
        'print(total)',
        language: pythonQuiz.name,
        question: whileCase,
      ),
      '6',
    );
  });

  test('live preview simulates list iteration and countdown while loops', () {
    final pythonQuiz =
        languageQuizzes.firstWhere((quiz) => quiz.name == 'Python');
    final pythonTopic = pythonQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('LOOP'));
    final caseExercise = pythonTopic.forModuleCasePractice(pythonQuiz.name);
    expect(
      simulateCodeOutput(
        'fruits = ["apple", "banana"]\n'
        'for fruit in fruits:\n'
        '    print(fruit)',
        language: pythonQuiz.name,
        question: caseExercise,
      ),
      'apple\nbanana',
    );
    expect(
      simulateCodeOutput(
        'count = 3\n'
        'while count > 0:\n'
        '    print(count)\n'
        '    count -= 1',
        language: pythonQuiz.name,
        question: caseExercise,
      ),
      '3\n2\n1',
    );
  });

  test('live SQL preview uses the case sample result when query is entered',
      () {
    final quiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'SQL');
    final topic = quiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('ORDER'));
    final caseExercise = topic.forModuleCasePractice(quiz.name);

    expect(
      simulateCodeOutput(
        'SELECT title FROM books ORDER BY title;',
        language: quiz.name,
        question: caseExercise,
      ),
      'title\nDune\nFoundation\nThe Hobbit',
    );
  });

  test('live preview substitutes the exact Java loop variable from the editor',
      () {
    final quiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final topic = quiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('LOOP'));
    final caseExercise = topic.forModuleCasePractice(quiz.name);

    expect(
      simulateCodeOutput(
        'for(int i = 1; i <= 2; i++){\n'
        '  System.out.println(i);\n'
        '}',
        language: quiz.name,
        question: caseExercise,
      ),
      '1\n2',
    );
  });

  test('conditional case accepts equivalent Java if statement syntax', () {
    final javaQuiz = languageQuizzes.firstWhere((quiz) => quiz.name == 'Java');
    final conditionalTopic = javaQuiz.categories.values
        .expand((questions) => questions)
        .firstWhere((question) => question.module.contains('IF'));
    final caseExercise = conditionalTopic.forModuleCasePractice(javaQuiz.name);

    expect(
      checkModuleCaseAnswer(
        'int guest = 20;\n'
        'if (guest >= 18) System.out.println("Allowed");',
        caseExercise,
        language: javaQuiz.name,
      ),
      isTrue,
    );
    expect(
      checkModuleCaseAnswer(
        'int guest = 20;\n'
        'if (guest >= 18) {\n'
        '  System.out.println("Allowed");\n'
        '}',
        caseExercise,
        language: javaQuiz.name,
      ),
      isTrue,
    );
    expect(
      checkModuleCaseAnswer(
        'int guest = 20;\n'
        'if (guest > 18) System.out.println("Allowed");',
        caseExercise,
        language: javaQuiz.name,
      ),
      isFalse,
    );
    expect(
      checkModuleCaseAnswer(
        'int age = 20;\n'
        'if (age >= 18) System.out.println("Allowed");',
        caseExercise,
        language: javaQuiz.name,
      ),
      isFalse,
    );
  });
}
