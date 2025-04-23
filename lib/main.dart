import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/task.dart';
import 'services/notification_service.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasks');
  await NotificationService.init();

  runApp(ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, theme, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: const Color.fromRGBO(121, 210, 160, 1),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(121, 210, 160, 1),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromRGBO(121, 210, 160, 1),
              foregroundColor: Colors.white,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color.fromRGBO(121, 210, 160, 1),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: const Color.fromRGBO(121, 210, 160, 1),
            colorScheme: ColorScheme.dark().copyWith(
              primary: const Color.fromRGBO(121, 210, 160, 1),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Color.fromRGBO(121, 210, 160, 1),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color.fromRGBO(121, 210, 160, 1),
            ),
          ),
          themeMode: theme.currentTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final taskBox = Hive.box<Task>('tasks');
  final controller = TextEditingController();
  bool showCompleted = false;

  void addTask(String title) {
    if (title.trim().isEmpty) return;
    final task = Task(title: title);
    taskBox.add(task);
    NotificationService.showSimpleNotification(title);
    controller.clear();
    setState(() {});
  }

  void toggleDone(Task task) {
    task.isDone = !task.isDone;
    task.save();
    setState(() {});
  }

  void deleteCompletedTasks() {
    final completedTasks = taskBox.values.where((t) => t.isDone).toList();
    for (var task in completedTasks) {
      task.delete();
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Completed tasks deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;

    final tasks = taskBox.values.toList();
    final activeTasks = tasks.where((t) => !t.isDone).toList();
    final completedTasks = tasks.where((t) => t.isDone).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("ToDooliCo"),
        actions: [
          TextButton(
            onPressed: completedTasks.isEmpty ? null : deleteCompletedTasks,
            child: const Text("🗑", style: TextStyle(fontSize: 22)),
          ),
          IconButton(
            onPressed: themeProvider.toggleTheme,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  RotationTransition(turns: animation, child: child),
              child: Text(
                isDark ? "🌛" : "🌞",
                key: ValueKey(isDark),
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "New task",
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(121, 210, 160, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => addTask(controller.text),
                  child: Text(
                    "✓",
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onPrimary, // Адаптация цвета текста
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ...activeTasks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final task = entry.value;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + index * 100),
                    builder: (_, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: TaskTile(task: task, onChanged: () => toggleDone(task)),
                  );
                }),
                if (completedTasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: ExpansionTile(
                      title: const Text("Completed"),
                      trailing: const SizedBox.shrink(),
                      initiallyExpanded: showCompleted,
                      onExpansionChanged: (val) => setState(() => showCompleted = val),
                      children: completedTasks.map((task) {
                        return TaskTile(task: task, onChanged: () => toggleDone(task));
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onChanged;

  const TaskTile({super.key, required this.task, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Checkbox(
            key: ValueKey(task.isDone),
            value: task.isDone,
            activeColor: const Color.fromRGBO(121, 210, 160, 1),
            onChanged: (_) => onChanged(),
          ),
        ),
      ),
    );
  }
}
