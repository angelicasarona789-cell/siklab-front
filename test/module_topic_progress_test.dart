import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siklab/models/user_session.dart';
import 'package:siklab/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserSession().clearAll();
  });

  test('module topic completion is stored separately from practice answers',
      () async {
    SharedPreferences.setMockInitialValues({
      'correct_questions_java': ['beginner_1'],
    });

    expect(await ApiService.getCompletedModuleTopicIds('Java'), isEmpty);

    await ApiService.markModuleTopicCompleted(
      language: 'Java',
      topicId: 'beginner_2',
    );
    await ApiService.markModuleTopicCompleted(
      language: 'Java',
      topicId: 'beginner_2',
    );

    expect(
      await ApiService.getCompletedModuleTopicIds('Java'),
      {'beginner_2'},
    );
    expect(
      await ApiService.getAnsweredQuestionIds('Java'),
      {'beginner_1'},
    );
  });

  test('module completion is isolated and restored per account', () async {
    final session = UserSession();
    session.setUser(id: 701, name: 'First', email: 'first@example.com');
    await ApiService.markModuleTopicCompleted(
      language: 'Java',
      topicId: 'beginner_1',
    );

    session.setUser(id: 702, name: 'Second', email: 'second@example.com');
    expect(await ApiService.getCompletedModuleTopicIds('Java'), isEmpty);

    session.setUser(id: 701, name: 'First', email: 'first@example.com');
    expect(
      await ApiService.getCompletedModuleTopicIds('Java'),
      {'beginner_1'},
    );
    expect(await ApiService.getModuleTopicCompletionCount('Java'), 1);
  });

  test('practice unlock count is scoped to the selected language', () async {
    SharedPreferences.setMockInitialValues({
      'completed_module_topics_java': ['beginner_1', 'beginner_2'],
      'completed_module_topics_python': [
        'beginner_1',
        'beginner_2',
        'intermediate_1'
      ],
      'completed_module_topics_csharp': ['beginner_1'],
      'completed_module_topics_c#': ['beginner_1'],
      'correct_questions_javascript': ['beginner_1', 'beginner_2'],
    });

    expect(await ApiService.getModuleTopicCompletionCount('Java'), 2);
    expect(await ApiService.getModuleTopicCompletionCount('Python'), 3);
    expect(await ApiService.getModuleTopicCompletionCount('JavaScript'), 0);
    expect(await ApiService.getModuleTopicCompletionCount('C#'), 1);
  });

  test('language aliases and duplicate topic IDs are counted once', () async {
    SharedPreferences.setMockInitialValues({
      'completed_module_topics_csharp': ['beginner_1', 'beginner_2'],
      'completed_module_topics_c#': ['beginner_1'],
    });

    expect(await ApiService.getModuleTopicCompletionCount('C#'), 2);
  });
}
