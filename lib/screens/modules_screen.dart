import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/navigation_intents.dart';
import '../models/quiz_data.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/code_answer_field.dart';
import '../navigation/shell_navigator.dart';
import 'practice_screen.dart';

class ModulesScreen extends StatefulWidget {
  final String? languageFilter;

  const ModulesScreen({super.key, this.languageFilter});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  static const modules = <_LanguageModule>[
    _LanguageModule('Java', Icons.coffee_outlined, SiklabColors.orange,
        'Core syntax, OOP, and problem solving.'),
    _LanguageModule('Python', Icons.code, SiklabColors.cyan,
        'Beginner-friendly scripting and data handling.'),
    _LanguageModule('C#', Icons.terminal, SiklabColors.purple,
        'Strong typed programming with .NET basics.'),
    _LanguageModule('JavaScript', Icons.javascript_outlined,
        SiklabColors.success, 'Web fundamentals, logic, and async patterns.'),
    _LanguageModule('SQL', Icons.storage_outlined, SiklabColors.cyan,
        'Queries, joins, and relational data modeling.'),
  ];

  bool _loadingLessons = true;
  List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();
    _fetchLessons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final wanted =
          widget.languageFilter ?? NavigationIntents().consumeModuleLanguage();
      if (wanted == null) return;
      for (final module in modules) {
        if (module.name == wanted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _LessonScreen(module: module),
            ),
          );
          break;
        }
      }
    });
  }

  Future<void> _fetchLessons() async {
    setState(() {
      _loadingLessons = true;
    });
    final res = await ApiService.listLessons();
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _loadingLessons = false;
        _lessons = [];
      });
      return;
    }
    final raw = (res.data!['lessons'] as List?) ?? [];
    setState(() {
      _loadingLessons = false;
      _lessons = raw.cast<Map<String, dynamic>>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.clBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SiklabBackButton(),
                    SizedBox(width: 8),
                    SiklabLogo(),
                  ],
                ),
                SiklabHamburgerMenu(),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'MODULES',
              style: GoogleFonts.sourceCodePro(
                color: SiklabColors.cyan,
                fontSize: 10,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Language Lessons',
              style: GoogleFonts.spaceGrotesk(
                color: context.clTextPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...modules.map(
              (module) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModuleCard(module: module),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'LESSONS_FROM_DATABASE',
              style: GoogleFonts.sourceCodePro(
                color: context.clTextMuted,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            if (_loadingLessons)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: CircularProgressIndicator(color: SiklabColors.cyan),
                ),
              )
            else ...[
              ..._lessons.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                _DbLessonScreen(lessonId: l['id'] as int),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.clBgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.clBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l['language']} • ${l['level']}',
                                    style: GoogleFonts.sourceCodePro(
                                      color: SiklabColors.cyan,
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (l['title'] as String?) ?? 'Lesson',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: context.clTextPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if ((l['topic'] as String?) != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      (l['topic'] as String?) ?? '',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: context.clTextSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: context.clTextMuted),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _DbLessonScreen extends StatefulWidget {
  final int lessonId;
  const _DbLessonScreen({required this.lessonId});

  @override
  State<_DbLessonScreen> createState() => _DbLessonScreenState();
}

class _DbLessonScreenState extends State<_DbLessonScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _lesson;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final res = await ApiService.getLesson(widget.lessonId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _lesson = res.data;
      } else {
        _error = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.clBg,
      appBar: AppBar(
        backgroundColor: context.clBg,
        foregroundColor: context.clTextPrimary,
        title: Text('Lesson',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: SiklabColors.cyan))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                            color: context.clTextSecondary)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      (_lesson?['title'] as String?) ?? 'Lesson',
                      style: GoogleFonts.spaceGrotesk(
                        color: context.clTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_lesson?['language']} • ${_lesson?['level']} • ${_lesson?['topic']}',
                      style: GoogleFonts.sourceCodePro(
                        color: SiklabColors.cyan,
                        fontSize: 11,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...((_lesson?['sections'] as List?) ?? [])
                        .cast<Map<String, dynamic>>()
                        .map((s) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.clBgCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.clBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((s['heading'] as String?) != null &&
                                      (s['heading'] as String).isNotEmpty)
                                    Text(
                                      s['heading'] as String,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: context.clTextPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    (s['body'] as String?) ?? '',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: context.clTextSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                  if ((s['code_block'] as String?) != null &&
                                      (s['code_block'] as String)
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    CodeBlock(
                                      filename:
                                          (s['code_filename'] as String?) ??
                                              'code',
                                      code: s['code_block'] as String,
                                    ),
                                  ],
                                ],
                              ),
                            )),
                    const SizedBox(height: 14),
                    CyanButton(
                      label: 'OPEN PRACTICE',
                      onTap: () {
                        ShellNavigator.goPractice(context);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _LanguageModule module;
  const _ModuleCard({required this.module});

  void _openLessons(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LessonScreen(module: module),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PracticeScreen(
              initialLanguage: module.name,
              categorySubtitle: 'LEARN ${module.name.toUpperCase()}',
              moduleMode: true,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.clBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.clBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: module.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(module.icon, color: module.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: GoogleFonts.spaceGrotesk(
                      color: context.clTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    module.description,
                    style: GoogleFonts.spaceGrotesk(
                      color: context.clTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'View lessons',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
              onPressed: () => _openLessons(context),
              icon: Icon(Icons.menu_book_outlined,
                  color: context.clTextSecondary, size: 18),
            ),
            Icon(Icons.chevron_right, color: context.clTextMuted),
          ],
        ),
      ),
    );
  }
}

class _LessonScreen extends StatelessWidget {
  final _LanguageModule module;
  const _LessonScreen({required this.module});

  @override
  Widget build(BuildContext context) {
    final lessons = _languageLessons(module.name);

    return Scaffold(
      backgroundColor: context.clBg,
      appBar: AppBar(
        backgroundColor: context.clBg,
        foregroundColor: context.clTextPrimary,
        title: Text('${module.name} Lessons',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.clBgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.clBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildLanguageIntro(context),
            ),
          ),
          const SizedBox(height: 14),
          ...lessons.map(
            (lesson) => _InteractiveLessonCard(lesson: lesson),
          ),
          const SizedBox(height: 20),
          CyanButton(
            label: 'START LINKED PRACTICE',
            onTap: () {
              // Push practice screen with the specific language
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PracticeScreen(initialLanguage: module.name),
                ),
              );
            },
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  List<Widget> _buildLanguageIntro(BuildContext context) {
    final sections = _languageIntroSections(module.name);
    final widgets = <Widget>[];

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      widgets.add(
        Text(
          section.title,
          style: GoogleFonts.spaceGrotesk(
            color: context.clTextPrimary,
            fontSize: section.title.startsWith('Why') ? 30 : 36,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));

      for (final paragraph in section.paragraphs) {
        widgets.add(
          Text(
            paragraph,
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextSecondary,
              height: 1.5,
              fontSize: 16,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }

      if (section.bullets.isNotEmpty) {
        widgets.add(const SizedBox(height: 6));
        for (final item in section.bullets) {
          widgets.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 10),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: module.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.spaceGrotesk(
                      color: context.clTextSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
          widgets.add(const SizedBox(height: 2));
        }
      }

      if (i < sections.length - 1) {
        widgets.add(const SizedBox(height: 18));
      }
    }

    return widgets;
  }

  List<_LanguageIntroSection> _languageIntroSections(String name) {
    switch (name) {
      case 'Java':
        return [
          const _LanguageIntroSection(
            title: 'What is Java?',
            paragraphs: [
              'Java is a popular and powerful programming language, created in 1995.',
              'It is owned by Oracle, and more than 3 billion devices run Java.',
              'It is used for:',
            ],
            bullets: [
              'Mobile applications (especially Android apps)',
              'Desktop applications',
              'Web applications',
              'Web servers and application servers',
              'Games',
              'Database connection',
              'And much, much more!',
            ],
          ),
          const _LanguageIntroSection(
            title: 'Why Use Java?',
            paragraphs: [],
            bullets: [
              'Java works on different platforms (Windows, Mac, Linux, Raspberry Pi, etc.)',
              'It is one of the most popular programming languages in the world',
              'It has a large demand in the current job market',
              'It is easy to learn and simple to use',
              'It is open-source and free',
              'It is secure, fast and powerful',
              'It has huge community support (tens of millions of developers)',
              'Java is an object-oriented language which gives a clear structure to programs and allows code to be reused, lowering development costs',
              'As Java is close to C++ and C#, it makes it easy for programmers to switch to Java or vice versa',
            ],
          ),
        ];
      case 'Python':
        return [
          const _LanguageIntroSection(
            title: 'What is Python?',
            paragraphs: [
              'Python is a beginner-friendly programming language created by Guido van Rossum in 1991.',
              'It is known for its simple syntax and readable code.',
              'It is used for:',
            ],
            bullets: [
              'Web development',
              'Automation and scripting',
              'Data analysis and science',
              'Machine learning and AI',
              'Game development',
              'And many other practical tools',
            ],
          ),
          const _LanguageIntroSection(
            title: 'Why Use Python?',
            paragraphs: [],
            bullets: [
              'Python is easy to read and write',
              'It has a huge community of developers',
              'It is great for beginners and fast prototyping',
              'It works across operating systems',
              'It is used in schools, startups, and large companies',
              'It integrates with data science and AI tools smoothly',
            ],
          ),
        ];
      case 'C#':
        return [
          const _LanguageIntroSection(
            title: 'What is C#?',
            paragraphs: [
              'C# is a modern programming language developed by Microsoft and introduced in 2000.',
              'It is commonly used for building Windows applications, web services, and enterprise systems.',
              'It is used for:',
            ],
            bullets: [
              'Desktop applications',
              'Web applications with ASP.NET',
              'Cloud and backend services',
              'Game development with Unity',
              'Business software and APIs',
            ],
          ),
          const _LanguageIntroSection(
            title: 'Why Use C#?',
            paragraphs: [],
            bullets: [
              'It is strongly typed and safer than many dynamic languages',
              'It works well with the .NET ecosystem',
              'It has excellent tooling and debugging support',
              'It is widely used in enterprise software',
              'It is a great choice for full-stack and backend work',
            ],
          ),
        ];
      case 'JavaScript':
        return [
          const _LanguageIntroSection(
            title: 'What is JavaScript?',
            paragraphs: [
              'JavaScript is the main language used to build interactive web pages and modern apps.',
              'It was created in 1995 and is now used on both the frontend and backend.',
              'It is used for:',
            ],
            bullets: [
              'Website interactivity',
              'Frontend frameworks and interfaces',
              'Backend services with Node.js',
              'Mobile apps with frameworks like React Native',
              'Browser automation and tooling',
            ],
          ),
          const _LanguageIntroSection(
            title: 'Why Use JavaScript?',
            paragraphs: [],
            bullets: [
              'It runs in all modern browsers',
              'It powers the web and many developer tools',
              'It supports fast UI development',
              'It has a huge ecosystem of libraries and frameworks',
              'It is the easiest entry point for web development',
            ],
          ),
        ];
      case 'SQL':
        return [
          const _LanguageIntroSection(
            title: 'What is SQL?',
            paragraphs: [
              'SQL is a standard language used to communicate with relational databases.',
              'It helps developers store, retrieve, update, and manage structured data efficiently.',
              'It is used for:',
            ],
            bullets: [
              'Querying customer and product data',
              'Creating reports and dashboards',
              'Managing application data',
              'Joining tables and analyzing records',
              'Backing business systems and analytics tools',
            ],
          ),
          const _LanguageIntroSection(
            title: 'Why Use SQL?',
            paragraphs: [],
            bullets: [
              'It is the standard language for relational databases',
              'It is essential for data-driven applications',
              'It helps organize and query large datasets',
              'It works with most relational database systems',
              'It is a must-have skill for analysts and developers',
            ],
          ),
        ];
      default:
        return [
          _LanguageIntroSection(
            title: 'What is $name?',
            paragraphs: ['This module introduces the fundamentals of $name.'],
            bullets: [
              'Learn the basics',
              'Practice hands-on examples',
              'Build real-world confidence'
            ],
          ),
        ];
    }
  }

  List<_LessonExample> _languageLessons(String name) {
    final quiz = languageQuizzes.firstWhere(
      (item) => item.name == name,
      orElse: () => languageQuizzes.first,
    );
    return quiz.categories.values
        .expand((questions) => questions)
        .map(
          (question) => _LessonExample(
            title:
                '${question.module.replaceFirst(RegExp(r'^Q\d+ // '), '')}: ${question.title}',
            description: 'Explanation: ${question.explanation}',
            explanation: question.explanation,
            filename: question.filename,
            code: _lessonExampleCode(name, question),
            language: name,
            topic: question.module,
          ),
        )
        .toList();
  }

  String _lessonExampleCode(String language, QuizQuestion question) {
    final topic = question.module.toUpperCase();

    switch (language) {
      case 'Java':
        if (topic.contains('PRINT')) {
          return 'String greeting = "Welcome to Siklab";\nSystem.out.println(greeting);';
        }
        if (topic.contains('VARIABLE')) {
          return 'double price = 19.99;\nint quantity = 2;\nSystem.out.println(price * quantity);';
        }
        if (topic.contains('STRING')) {
          return 'String city = "Manila";\nSystem.out.println(city.toUpperCase());';
        }
        if (topic.contains('ARITHMETIC')) {
          return 'int width = 8;\nint height = 5;\nSystem.out.println(width * height);';
        }
        if (topic.contains('IF')) {
          return 'int temperature = 31;\nif (temperature > 30) {\n  System.out.println("Warm day");\n}';
        }
        if (topic.contains('SWITCH')) {
          return 'int month = 12;\nswitch (month) {\n  case 12: System.out.println("December"); break;\n  default: System.out.println("Another month");\n}';
        }
        if (topic.contains('LOOP') || topic.contains('RANGE')) {
          return 'for (int i = 2; i <= 8; i += 2) {\n  System.out.println(i);\n}';
        }
        if (topic.contains('ARRAY')) {
          return 'int[] scores = {88, 91, 76};\nSystem.out.println(scores[1]);';
        }
        if (topic.contains('METHOD') || topic.contains('FUNCTION')) {
          return 'static int triple(int value) {\n  return value * 3;\n}';
        }
        return 'String[] tools = {"Compiler", "Debugger"};\nSystem.out.println(tools.length);';
      case 'Python':
        if (topic.contains('OUTPUT') || topic.contains('PRINT')) {
          return 'message = "Welcome to Siklab"\nprint(message)';
        }
        if (topic.contains('VARIABLE')) {
          return 'price = 19.99\nquantity = 2\nprint(price * quantity)';
        }
        if (topic.contains('STRING')) {
          return 'city = "Manila"\nprint(city.upper())';
        }
        if (topic.contains('ARITHMETIC')) {
          return 'width = 8\nheight = 5\nprint(width * height)';
        }
        if (topic.contains('IF')) {
          return 'temperature = 31\nif temperature > 30:\n    print("Warm day")';
        }
        if (topic.contains('LOOP') || topic.contains('RANGE')) {
          return 'for number in range(2, 9, 2):\n    print(number)';
        }
        if (topic.contains('LIST')) {
          return 'scores = [88, 91, 76]\nprint(scores[1])';
        }
        if (topic.contains('DICT')) {
          return 'profile = {"name": "Alex", "active": True}\nprint(profile["name"])';
        }
        if (topic.contains('FUNCTION') || topic.contains('RECURSION')) {
          return 'def triple(value):\n    return value * 3\n\nprint(triple(4))';
        }
        return 'tools = ["compiler", "debugger"]\nprint(len(tools))';
      case 'C#':
        if (topic.contains('OUTPUT') || topic.contains('PRINT')) {
          return 'string greeting = "Welcome to Siklab";\nConsole.WriteLine(greeting);';
        }
        if (topic.contains('VARIABLE')) {
          return 'double price = 19.99;\nint quantity = 2;\nConsole.WriteLine(price * quantity);';
        }
        if (topic.contains('STRING')) {
          return 'string city = "Manila";\nConsole.WriteLine(city.ToUpper());';
        }
        if (topic.contains('ARITHMETIC')) {
          return 'int width = 8;\nint height = 5;\nConsole.WriteLine(width * height);';
        }
        if (topic.contains('IF')) {
          return 'int temperature = 31;\nif (temperature > 30)\n    Console.WriteLine("Warm day");';
        }
        if (topic.contains('LOOP') || topic.contains('RANGE')) {
          return 'for (int i = 2; i <= 8; i += 2)\n    Console.WriteLine(i);';
        }
        if (topic.contains('ARRAY')) {
          return 'int[] scores = { 88, 91, 76 };\nConsole.WriteLine(scores[1]);';
        }
        if (topic.contains('METHOD') || topic.contains('FUNCTION')) {
          return 'static int Triple(int value) => value * 3;\nConsole.WriteLine(Triple(4));';
        }
        return 'string[] tools = { "Compiler", "Debugger" };\nConsole.WriteLine(tools.Length);';
      case 'JavaScript':
        if (topic.contains('OUTPUT') || topic.contains('PRINT')) {
          return 'const greeting = "Welcome to Siklab";\nconsole.log(greeting);';
        }
        if (topic.contains('VARIABLE')) {
          return 'const price = 19.99;\nconst quantity = 2;\nconsole.log(price * quantity);';
        }
        if (topic.contains('STRING')) {
          return 'const city = "Manila";\nconsole.log(city.toUpperCase());';
        }
        if (topic.contains('ARITHMETIC')) {
          return 'const width = 8;\nconst height = 5;\nconsole.log(width * height);';
        }
        if (topic.contains('IF')) {
          return 'const temperature = 31;\nif (temperature > 30) {\n  console.log("Warm day");\n}';
        }
        if (topic.contains('LOOP') || topic.contains('RANGE')) {
          return 'for (let i = 2; i <= 8; i += 2) {\n  console.log(i);\n}';
        }
        if (topic.contains('ARRAY')) {
          return 'const scores = [88, 91, 76];\nconsole.log(scores[1]);';
        }
        if (topic.contains('FUNCTION') || topic.contains('CALLBACK')) {
          return 'const triple = value => value * 3;\nconsole.log(triple(4));';
        }
        return 'const tools = ["compiler", "debugger"];\nconsole.log(tools.length);';
      case 'SQL':
        if (topic.contains('SELECT')) {
          return 'SELECT name, email\nFROM users\nWHERE active = 1;';
        }
        if (topic.contains('INSERT')) {
          return 'INSERT INTO courses (title, credits)\nVALUES (\'Algorithms\', 3);';
        }
        if (topic.contains('UPDATE')) {
          return 'UPDATE courses\nSET credits = 4\nWHERE title = \'Databases\';';
        }
        if (topic.contains('DELETE')) {
          return 'DELETE FROM sessions\nWHERE expires_at < CURRENT_DATE;';
        }
        if (topic.contains('ORDER')) {
          return 'SELECT title, credits\nFROM courses\nORDER BY credits DESC;';
        }
        if (topic.contains('LIMIT')) {
          return 'SELECT title\nFROM courses\nORDER BY created_at DESC\nLIMIT 5;';
        }
        if (topic.contains('COUNT')) {
          return 'SELECT department, COUNT(*) AS total\nFROM courses\nGROUP BY department;';
        }
        if (topic.contains('JOIN')) {
          return 'SELECT u.name, e.course_id\nFROM users u\nJOIN enrollments e ON e.user_id = u.id;';
        }
        if (topic.contains('GROUP') || topic.contains('HAVING')) {
          return 'SELECT department, AVG(credits) AS average_credits\nFROM courses\nGROUP BY department\nHAVING AVG(credits) > 2;';
        }
        if (topic.contains('WINDOW') || topic.contains('PARTITION')) {
          return 'SELECT name, score,\n  RANK() OVER (ORDER BY score DESC) AS position\nFROM results;';
        }
        if (topic.contains('CTE') || topic.contains('SUBQUERY')) {
          return 'WITH recent AS (\n  SELECT * FROM courses WHERE created_at >= CURRENT_DATE - INTERVAL 30 DAY\n)\nSELECT title FROM recent;';
        }
        if (topic.contains('TRANSACTION')) {
          return 'START TRANSACTION;\nUPDATE wallets SET balance = balance + 25 WHERE id = 7;\nCOMMIT;';
        }
        return 'SELECT title\nFROM courses\nWHERE credits >= 3;';
      default:
        return question.correctAnswer;
    }
  }
}

class _LanguageIntroSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const _LanguageIntroSection({
    required this.title,
    required this.paragraphs,
    required this.bullets,
  });
}

class _LessonExample {
  final String title;
  final String description;
  final String explanation;
  final String filename;
  final String code;
  final String language;
  final String topic;
  const _LessonExample({
    required this.title,
    required this.description,
    required this.explanation,
    required this.filename,
    required this.code,
    required this.language,
    required this.topic,
  });
}

class _InteractiveLessonCard extends StatefulWidget {
  final _LessonExample lesson;

  const _InteractiveLessonCard({required this.lesson});

  @override
  State<_InteractiveLessonCard> createState() => _InteractiveLessonCardState();
}

class _InteractiveLessonCardState extends State<_InteractiveLessonCard> {
  late final TextEditingController _controller;
  String? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runInput() {
    final input = _controller.text.trim();
    setState(() {
      _result = _rateInput(input);
    });
  }

  List<Widget> _buildDetailedExplanation(BuildContext context) {
    final language = widget.lesson.language;
    final paragraphs = _exampleExplanationParagraphs(language);
    final note = _exampleExplanationNote(language);

    return [
      Text.rich(
        TextSpan(
          style: GoogleFonts.spaceGrotesk(
            color: context.clTextPrimary,
            height: 1.65,
            fontSize: 16,
          ),
          children: paragraphs,
        ),
      ),
      const SizedBox(height: 12),
      Text.rich(
        TextSpan(
          style: GoogleFonts.spaceGrotesk(
            color: context.clTextPrimary,
            height: 1.65,
            fontSize: 16,
          ),
          children: note,
        ),
      ),
    ];
  }

  List<TextSpan> _exampleExplanationParagraphs(String language) {
    final topic = widget.lesson.topic.toUpperCase();
    final baseText = widget.lesson.explanation;

    if (language == 'Java' &&
        (topic.contains('CLASS') || topic.contains('FILE'))) {
      return [
        const TextSpan(
            text: 'Every line of code that runs in Java must be inside a '),
        TextSpan(
          text: 'class',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const TextSpan(
            text:
                '. The class name should always start with an uppercase first letter. In our example, we named the '),
        TextSpan(
          text: 'class Main',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const TextSpan(text: '.\n\n'),
        const TextSpan(
            text:
                'The name of the Java file must match the class name. So if your class is called '),
        TextSpan(
          text: 'Main',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const TextSpan(text: ', the file must be saved as '),
        TextSpan(
          text: 'Main.java',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const TextSpan(
            text:
                '. This is because Java uses the class name to find and run your code. If the names don\'t match, Java will give an error and the program will not run.\n\n'),
        const TextSpan(
            text:
                'When saving the file, save it using the class name and add '),
        TextSpan(
          text: '.java',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const TextSpan(
            text:
                ' to the end of the filename. To run the example above on your computer, make sure that Java is properly installed. Go to the "Get Started" chapter for how to install Java. The output should be:'),
      ];
    }

    if (topic.contains('PRINT') || topic.contains('OUTPUT')) {
      return [
        TextSpan(
            text:
                'This statement sends output to the console so the result can be seen immediately. In $language, the print command is one of the simplest ways to test code and confirm values.')
      ];
    }

    if (topic.contains('VARIABLE')) {
      return [
        const TextSpan(
            text:
                'A variable stores a value so it can be reused later in the program. You declare the variable name and assign it a value, then the program can work with that saved data.')
      ];
    }

    if (topic.contains('STRING')) {
      return [
        TextSpan(
            text:
                'A string is a sequence of characters used to store text. In $language, strings are wrapped in quotes so the program knows the value should be treated as text instead of code.')
      ];
    }

    if (topic.contains('IF')) {
      return [
        const TextSpan(
            text:
                'An if statement checks a condition and only runs the code inside it when the condition is true. This helps the program make decisions based on values or user input.')
      ];
    }

    if (topic.contains('LOOP')) {
      return [
        const TextSpan(
            text:
                'A loop repeats a block of code until a condition is met. This is useful when you want to process many values or run the same action multiple times without rewriting the code.')
      ];
    }

    if (topic.contains('ARRAY')) {
      return [
        const TextSpan(
            text:
                'An array stores multiple values in one variable. Each item has an index, which lets the program access the values in order when it needs them.')
      ];
    }

    if (topic.contains('FUNCTION') || topic.contains('METHOD')) {
      return [
        const TextSpan(
            text:
                'A function or method groups code into a reusable block. This keeps the program organized and lets the same logic run again with different inputs.')
      ];
    }

    if (language == 'SQL' &&
        (topic.contains('SELECT') || topic.contains('FROM'))) {
      return [
        const TextSpan(
            text:
                'The SELECT statement tells the database which columns to read and FROM tells it which table to read from. This is the foundation of query-based data retrieval.')
      ];
    }

    if (topic.contains('JOIN')) {
      return [
        const TextSpan(
            text:
                'A JOIN combines rows from different tables based on a shared relationship. This lets you connect data from several sources and answer more complete questions.')
      ];
    }

    if (topic.contains('WHERE')) {
      return [
        const TextSpan(
            text:
                'The WHERE clause filters rows so only matching records are included. It narrows the result set to the records that meet the condition you care about.')
      ];
    }

    return [TextSpan(text: baseText)];
  }

  List<TextSpan> _exampleExplanationNote(String language) {
    final topic = widget.lesson.topic.toUpperCase();

    if (language == 'Java' &&
        (topic.contains('CLASS') || topic.contains('FILE'))) {
      return [
        const TextSpan(text: 'Note: Java is case-sensitive. '),
        TextSpan(
          text: 'MyClass',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const TextSpan(text: ' and '),
        TextSpan(
          text: 'myclass',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const TextSpan(
            text: ' would be treated as two completely different names.'),
      ];
    }

    if (topic.contains('VARIABLE')) {
      return [
        const TextSpan(
            text:
                'Note: Choose clear names and keep them consistent so the code is easier to understand and maintain.')
      ];
    }

    if (topic.contains('STRING')) {
      return [
        const TextSpan(
            text:
                'Note: Strings must follow the language’s text rules, usually with quotes around the content.')
      ];
    }

    if (topic.contains('IF') || topic.contains('LOOP')) {
      return [
        const TextSpan(
            text:
                'Note: The condition must be written correctly, otherwise the code may run the wrong block or not run at all.')
      ];
    }

    if (language == 'SQL') {
      return [
        const TextSpan(
            text:
                'Note: SQL is structured around clauses like SELECT, FROM, WHERE, and ORDER BY, each serving a different part of the query.')
      ];
    }

    return [
      const TextSpan(
          text:
              'Note: Follow the syntax rules for your language, and keep your statements readable and consistent.')
    ];
  }

  String _rateInput(String input) {
    if (input.isEmpty) return 'Enter your own solution before running it.';

    final topic = widget.lesson.topic.toUpperCase();
    final language = widget.lesson.language;
    final checks = <bool>[];

    if (language == 'Python') {
      checks.add(!input.contains(';'));
      if (topic.contains('LOOP')) {
        checks.add(input.contains('for') || input.contains('while'));
      }
      if (topic.contains('FUNCTION')) checks.add(input.contains('def '));
      if (topic.contains('LIST')) {
        checks.add(input.contains('[') && input.contains(']'));
      }
      if (topic.contains('STRING')) {
        checks.add(input.contains('"') || input.contains("'"));
      }
    } else if (language == 'SQL') {
      checks.add(
          RegExp(r'\b(SELECT|INSERT|UPDATE|DELETE)\b', caseSensitive: false)
              .hasMatch(input));
      if (topic.contains('JOIN')) {
        checks.add(input.toUpperCase().contains('JOIN'));
      }
      if (topic.contains('GROUP')) {
        checks.add(input.toUpperCase().contains('GROUP BY'));
      }
      if (topic.contains('ORDER')) {
        checks.add(input.toUpperCase().contains('ORDER BY'));
      }
      if (topic.contains('WHERE')) {
        checks.add(input.toUpperCase().contains('WHERE'));
      }
    } else {
      checks.add(
          input.contains(';') || input.contains('{') || input.contains('=>'));
      if (topic.contains('LOOP')) {
        checks.add(input.contains('for') || input.contains('while'));
      }
      if (topic.contains('FUNCTION') || topic.contains('METHOD')) {
        checks.add(input.contains('(') && input.contains(')'));
      }
      if (topic.contains('ARRAY')) {
        checks.add(input.contains('[') && input.contains(']'));
      }
      if (topic.contains('STRING')) {
        checks.add(input.contains('"') || input.contains("'"));
      }
    }

    final passed = checks.where((check) => check).length;
    final percentage = ((passed / checks.length) * 100).round();
    if (percentage >= 80) {
      return 'Rating: $percentage% - Strong ${widget.lesson.language} ${topic.toLowerCase()} practice.';
    }
    if (percentage >= 50) {
      return 'Rating: $percentage% - Good start. Add the missing ${topic.toLowerCase()} structure.';
    }
    return 'Rating: $percentage% - Review the ${topic.toLowerCase()} concept and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.clBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.clBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lesson.title,
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lesson.description,
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'EXAMPLE',
            style: GoogleFonts.sourceCodePro(
              color: SiklabColors.cyan,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          CodeBlock(filename: widget.lesson.filename, code: widget.lesson.code),
          const SizedBox(height: 12),
          Text(
            'Example explained',
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildDetailedExplanation(context),
          ),
          const SizedBox(height: 14),
          Text(
            'TRY THIS TOPIC',
            style: GoogleFonts.sourceCodePro(
              color: context.clTextMuted,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          CodeAnswerField(
            controller: _controller,
            language: widget.lesson.language,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            showSnackBarOnBlock: false,
            style: GoogleFonts.sourceCodePro(
              color: context.clTextSecondary,
              fontSize: 12,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: 'Write ${widget.lesson.language} code here...',
              filled: true,
              fillColor: context.clBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.clBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.clBorder),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CyanButton(
              label: 'RUN ${widget.lesson.language.toUpperCase()} INPUT',
              icon: Icons.play_arrow_rounded,
              onTap: _runInput,
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            Text(
              _result!,
              style: GoogleFonts.sourceCodePro(
                color: SiklabColors.success,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageModule {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  const _LanguageModule(this.name, this.icon, this.color, this.description);
}
