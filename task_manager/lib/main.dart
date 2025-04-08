import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Madhuri Tumula-002892521

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskListScreen(),
    );
  }
}

class Task {
  String id;
  String name;
  bool iscompleted;
  List<dynamic> subtasks;

  Task({required this.id, required this.name, this.iscompleted = false, this.subtasks = const []});
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _taskController = TextEditingController();
  final CollectionReference tasksCollection = FirebaseFirestore.instance.collection('tasks');

  Future<void> _addTask(String name) async {
    if (name.isNotEmpty) {
      await tasksCollection.add({
        'name': name,
        'iscompleted': false,
        'subtasks': [],
      });
      _taskController.clear();
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    await tasksCollection.doc(task.id).update({
      'iscompleted': !task.iscompleted,
    });
  }

  Future<void> _deleteTask(Task task) async {
    await tasksCollection.doc(task.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(labelText: 'Enter Task'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _addTask(_taskController.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: tasksCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final tasks = snapshot.data!.docs.map((doc) {
                  return Task(
                    id: doc.id,
                    name: doc['name'],
                    iscompleted: doc['iscompleted'],
                    subtasks: doc['subtasks'],
                  );
                }).toList();

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Checkbox(
                              value: task.iscompleted,
                              onChanged: (value) {
                                _toggleTaskCompletion(task);
                              },
                            ),
                            Expanded(child: Text(task.name)),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteTask(task),
                            ),
                          ],
                        ),
                        children: task.subtasks.isNotEmpty
                            ? task.subtasks.map((subtask) => ListTile(
                                  title: Text(subtask),
                                )).toList()
                            : [ListTile(title: Text('No subtasks'))],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}