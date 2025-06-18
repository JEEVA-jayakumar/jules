import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'task_model.dart';
import 'dart:async'; // For FutureBuilder or async operations

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver { // Add with WidgetsBindingObserver
  bool _isDarkMode = false;
  late DatabaseHelper _dbHelper;
  List<Task> _todayTasks = [];
  DateTime _currentDate = DateTime.now(); // To track the current day
  bool _isLoadingTasks = true; // To show a loading indicator

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register observer
    _dbHelper = DatabaseHelper();
    _currentDate = _getDateOnly(DateTime.now()); // Ensure _currentDate is date-only
    _loadTasksForCurrentDate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Unregister observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final DateTime now = DateTime.now();
      final DateTime today = _getDateOnly(now);
      if (_currentDate.isBefore(today)) { // Check if the date has changed
        setState(() {
          _currentDate = today;
        });
        _loadTasksForCurrentDate(); // Reload tasks for the new current date
      }
    }
  }

  DateTime _getDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  Future<void> _loadTasksForCurrentDate() async {
    setState(() {
      _isLoadingTasks = true;
    });
    // Ensure date is date-only, no time component for consistent querying
    DateTime dateOnly = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    final tasks = await _dbHelper.getTasksForDate(dateOnly);
    setState(() {
      _todayTasks = tasks;
      _isLoadingTasks = false;
    });
  }

  Future<void> _addTask(String description) async {
    if (description.isEmpty) return;
    DateTime now = DateTime.now();
    Task newTask = Task(
      description: description,
      creationDate: DateTime(now.year, now.month, now.day), // Store date part only
      isCompleted: false,
    );
    await _dbHelper.insertTask(newTask);
    _loadTasksForCurrentDate(); // Reload tasks to include the new one
  }

  Future<void> _toggleTaskCompleted(Task task) async {
    task.isCompleted = !task.isCompleted;
    await _dbHelper.updateTask(task);
    _loadTasksForCurrentDate(); // Reload tasks to reflect the change
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Tasks', // Updated title
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MyHomePage(
        title: 'Daily Tasks', // Updated title
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
        tasks: _todayTasks,
        onAddTask: _addTask,
        onToggleTaskCompleted: _toggleTaskCompleted,
        isLoadingTasks: _isLoadingTasks,
        currentDate: _currentDate,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final bool isDarkMode;
  final VoidCallback onThemeChanged;
  final List<Task> tasks;
  final Function(String) onAddTask;
  final Function(Task) onToggleTaskCompleted;
  final bool isLoadingTasks;
  final DateTime currentDate;

  const MyHomePage({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.tasks,
    required this.onAddTask,
    required this.onToggleTaskCompleted,
    required this.isLoadingTasks,
    required this.currentDate,
  });

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _taskInputController = TextEditingController();

  @override
  void dispose() {
    _taskInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                Text(widget.isDarkMode ? "Dark" : "Light", style: Theme.of(context).textTheme.bodySmall),
                Switch(
                  value: widget.isDarkMode,
                  onChanged: (value) {
                    widget.onThemeChanged();
                  },
                ),
              ],
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch horizontally
          children: <Widget>[
            Text(
              "Tasks for: ${widget.currentDate.toLocal().toString().split(' ')[0]}",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: widget.isLoadingTasks
                  ? const Center(child: CircularProgressIndicator())
                  : widget.tasks.isEmpty
                      ? const Center(
                          child: Text(
                            "No tasks for today. Add one below!",
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: widget.tasks.length,
                          itemBuilder: (context, index) {
                            final task = widget.tasks[index];
                            return Card(
                              elevation: 2.0,
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                title: Text(
                                  task.description,
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: task.isCompleted
                                        ? Colors.grey
                                        : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                leading: Checkbox(
                                  value: task.isCompleted,
                                  onChanged: (bool? value) {
                                    widget.onToggleTaskCompleted(task);
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16), // Spacing before add task UI

            Padding(
              padding: const EdgeInsets.only(top: 8.0), // Add some space above the input field
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _taskInputController,
                      decoration: InputDecoration(
                        hintText: 'Enter new task...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      ),
                      onSubmitted: (value) { // Allow submitting with keyboard action
                        if (value.isNotEmpty) {
                          widget.onAddTask(value);
                          _taskInputController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      final String taskDescription = _taskInputController.text;
                      if (taskDescription.isNotEmpty) {
                        widget.onAddTask(taskDescription);
                        _taskInputController.clear();
                      }
                    },
                    child: const Text('Add Task'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // FloatingActionButton removed as per instructions
    );
  }
}
