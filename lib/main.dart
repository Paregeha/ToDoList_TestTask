import 'package:flutter/material.dart';
import 'DataBase.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'To Do List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _tasks = [];

  double progress = 0.0;
  Color dynamicColor = Colors.red.withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseHelper.instance
        .getTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _addTask() async {
    String task = _controller.text.trim();
    if (task.isNotEmpty) {
      int counter = 1;
      String newTask = task;

      while (_tasks.any((existingTask) => existingTask['task'] == newTask)) {
        newTask = '$task ($counter)';
        counter++;
      }

      try {
        await DatabaseHelper.instance.updateAllTaskOrder();

        await DatabaseHelper.instance.insertTask(newTask, taskOrder: 0);

        _controller.clear();
        _loadTasks();
      } catch (e) {
        print('Error adding task: $e');
      }
    }
  }

  Future<void> _removeTask(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    _loadTasks();
  }

  Future<void> _updateTaskOrder() async {
    for (int i = 0; i < _tasks.length; i++) {
      final taskId = _tasks[i]['id'];
      final taskOrder = i;
      await DatabaseHelper.instance.updateTaskOrder(
          taskId, taskOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text("Ведіть назву!")),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTask,
                  icon: const Icon(
                    Icons.add_circle,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _tasks.isEmpty
              ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Divider(
                color: Colors.grey,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              SizedBox(height: 10),
              Text(
                'Empty List',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ):  ReorderableListView(
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  final List<Map<String, dynamic>> updatedTasks =
                  List.from(_tasks);

                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }

                  final task = updatedTasks.removeAt(oldIndex);
                  updatedTasks.insert(newIndex, task);

                  _tasks = updatedTasks;
                });

                await _updateTaskOrder();

                await _loadTasks();
              },
              children: _tasks.map((task) {
                return Dismissible(
                  key: Key(task['id'].toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _removeTask(task['id']);

                    Future.delayed(Duration(milliseconds: 500), () {
                      setState(() {
                        _tasks.removeWhere(
                                (t) =>
                            t['id'] == task['id']);
                        progress = 0.0;
                        dynamicColor = Colors.red.withOpacity(0.1);
                      });
                    });
                  },
                  onUpdate: (details) {
                    setState(() {
                      progress = details.progress.clamp(0.0, 1.0);
                      dynamicColor = Color.lerp(
                        Colors.red.withOpacity(0.1),
                        Colors.red,
                        progress,
                      )!;
                    });
                  },
                  background: Container(
                    color: dynamicColor,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 5, 10, 0),
                    child: Card(
                      elevation: 10,
                      shadowColor: Colors.green,
                      child: ListTile(
                        title: Text(task['task']),
                        trailing: Icon(Icons.drag_handle),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
