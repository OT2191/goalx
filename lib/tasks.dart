import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'goals.dart';

class Task {
  final String title;
  final String description;
  final DateTime? dueDate;
  final String priority;
  final bool isCompleted;
  final String? goalId; // To link tasks to goals
  final DateTime? completedAt; // To track when a task was completed

  Task({
    required this.title,
    required this.description,
    this.dueDate,
    this.priority = 'normal',
    this.isCompleted = false,
    this.goalId,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority,
    'isCompleted': isCompleted,
    'goalId': goalId,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    title: json['title'],
    description: json['description'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    priority: json['priority'] ?? 'normal',
    isCompleted: json['isCompleted'] ?? false,
    goalId: json['goalId'],
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
  );

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    bool? isCompleted,
    String? goalId,
    DateTime? completedAt,
  }) {
    return Task(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      goalId: goalId ?? this.goalId,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class Tasks extends StatefulWidget {
  const Tasks({super.key});

  @override
  State<Tasks> createState() => _TasksState();
}

class _TasksState extends State<Tasks> {
  static const String tasksKey = 'tasks';
  static const String activeExpandedKey = 'tasks_active_expanded';
  static const String completedExpandedKey = 'tasks_completed_expanded';
  final List<Task> tasks = [];
  bool _activeExpanded = true;
  bool _completedExpanded = false;
  List<Goal> _availableGoals = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadAvailableGoals();
  }

  Future<void> _loadAvailableGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getString('goals');
    if (goalsJson != null) {
      final list = jsonDecode(goalsJson) as List;
      setState(() {
        _availableGoals = list.map((g) => Goal.fromJson(g)).toList();
      });
    } else {
      setState(() => _availableGoals = []);
    }
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(tasksKey);
    final activeExpanded = prefs.getBool(activeExpandedKey);
    final completedExpanded = prefs.getBool(completedExpandedKey);

    if (tasksJson != null) {
      final tasksList = jsonDecode(tasksJson) as List;
      setState(() {
        tasks.clear();
        tasks.addAll(
          tasksList.map((t) => Task.fromJson(t)).toList(),
        );
        if (activeExpanded != null) _activeExpanded = activeExpanded;
        if (completedExpanded != null) _completedExpanded = completedExpanded;
      });
    } else {
      // still apply persisted expansion state even if no tasks stored
      if (activeExpanded != null || completedExpanded != null) {
        setState(() {
          if (activeExpanded != null) _activeExpanded = activeExpanded;
          if (completedExpanded != null) _completedExpanded = completedExpanded;
        });
      }
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(
      tasks.map((t) => t.toJson()).toList(),
    );
    await prefs.setString(tasksKey, tasksJson);
    // persist UI state for expanded/collapsed sections
    await prefs.setBool(activeExpandedKey, _activeExpanded);
    await prefs.setBool(completedExpandedKey, _completedExpanded);
  }

  Future<void> _addTask() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
    String priority = 'normal';
    String? selectedGoalId;
  // ensure available goals are fresh
  await _loadAvailableGoals();
  if (!mounted) return;

  // capture messenger and host context after awaits (and after mounted check)
  final messenger = ScaffoldMessenger.of(context);
  final hostContext = context;

    // Schedule dialog to show after this frame to avoid using BuildContext across async gaps
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: hostContext,
        builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'What needs to be done?',
                      ),
                      maxLength: 50, // Character limit
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Add details about this task',
                        alignLabelWithHint: true,
                      ),
                      maxLength: 200, // Character limit
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          hintText: selectedDate == null
                              ? 'When is it due?'
                              : '${selectedDate!.toLocal()}'.split(' ')[0],
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: selectedDate == null
                            ? const Text('Select a date')
                            : Text('${selectedDate!.toLocal()}'.split(' ')[0]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 16),
                    const Text(
                      'Priority',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedGoalId,
                      decoration: const InputDecoration(labelText: 'Attach to goal'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('None')),
                        ..._availableGoals.map((g) => DropdownMenuItem<String?>(
                              value: g.id,
                              child: Row(children: [Icon(g.icon, size: 16), const SizedBox(width: 8), Text(g.title)]),
                            )),
                      ],
                      onChanged: (v) => setState(() { selectedGoalId = v; }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Priority',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'high',
                          label: Text('High'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment<String>(
                          value: 'normal',
                          label: Text('Normal'),
                          icon: Icon(Icons.remove),
                        ),
                        ButtonSegment<String>(
                          value: 'low',
                          label: Text('Low'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {priority},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => priority = newSelection.first);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }

                    final newTask = Task(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      dueDate: selectedDate,
                      priority: priority,
                      goalId: selectedGoalId,
                    );

                    // Close dialog first, then update state
                    Navigator.of(dialogContext).pop();
                    
                    setState(() {
                      tasks.add(newTask);
                    });

                    _saveTasks().then((_) {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Task added')),
                        );
                      }
                    });
                  },
                  child: const Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
    });
  }

  Future<void> _editTask(Task task, int index) async {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    DateTime? selectedDate = task.dueDate;
    String priority = task.priority;
    String? selectedGoalId = task.goalId;

  await _loadAvailableGoals();
  if (!mounted) return;

  // capture messenger and host context after awaits (and after mounted check)
  final messenger = ScaffoldMessenger.of(context);
  final hostContext = context;

    // Schedule dialog to show after this frame to avoid using BuildContext across async gaps
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: hostContext,
        builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'What needs to be done?',
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Add details about this task',
                        alignLabelWithHint: true,
                      ),
                      maxLength: 200,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          hintText: selectedDate == null
                              ? 'When is it due?'
                              : '${selectedDate!.toLocal()}'.split(' ')[0],
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: selectedDate == null
                            ? const Text('Select a date')
                            : Text('${selectedDate!.toLocal()}'.split(' ')[0]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedGoalId,
                      decoration: const InputDecoration(labelText: 'Attach to goal'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('None')),
                        ..._availableGoals.map((g) => DropdownMenuItem<String?>(
                              value: g.id,
                              child: Row(children: [Icon(g.icon, size: 16), const SizedBox(width: 8), Text(g.title)]),
                            )),
                      ],
                      onChanged: (v) => setState(() { selectedGoalId = v; }),
                    ),
                    const Text(
                      'Priority',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'high',
                          label: Text('High'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment<String>(
                          value: 'normal',
                          label: Text('Normal'),
                          icon: Icon(Icons.remove),
                        ),
                        ButtonSegment<String>(
                          value: 'low',
                          label: Text('Low'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {priority},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => priority = newSelection.first);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }

                    final updatedTask = Task(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      dueDate: selectedDate,
                      priority: priority,
                      isCompleted: task.isCompleted,
                      goalId: selectedGoalId,
                    );

                    // Update the parent widget's state to reflect changes
                    Navigator.of(dialogContext).pop();
                    
                    setState(() {
                      tasks[index] = updatedTask;
                    });

                    _saveTasks().then((_) {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Task updated')),
                        );
                      }
                    });
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
    });
  }


  Widget _buildTaskCard(Task task, int index) {
    Goal? goal;
    if (task.goalId != null) {
      try {
        goal = _availableGoals.firstWhere((g) => g.id == task.goalId);
      } catch (_) {
        goal = null;
      }
    }
    return Dismissible(
      key: Key(task.title + (task.completedAt?.toString() ?? '')),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _toggleTaskCompletion(index);
        } else {
          setState(() {
            tasks.removeAt(index);
          });
          _saveTasks().then((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
            }
          });
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: InkWell(
            onTap: () => _toggleTaskCompletion(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted
                    ? Colors.green[100]
                    : {
                        'high': Colors.red[100],
                        'normal': Colors.blue[100],
                        'low': Colors.green[100],
                      }[task.priority],
              ),
              child: Center(
                child: Icon(
                  task.isCompleted
                      ? Icons.check
                      : {
                          'high': Icons.arrow_upward,
                          'normal': Icons.remove,
                          'low': Icons.arrow_downward,
                        }[task.priority],
                  size: 16,
                  color: task.isCompleted
                      ? Colors.green[900]
                      : {
                          'high': Colors.red[900],
                          'normal': Colors.blue[900],
                          'low': Colors.green[900],
                        }[task.priority],
                ),
              ),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? Colors.grey : null,
                  ),
                ),
              if (task.completedAt != null)
                Text(
                  'Completed ${DateFormat('MMM d, y').format(task.completedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              if (goal != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(goal.icon, size: 14, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text(goal.title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.dueDate != null)
                Text(
                  DateFormat('MMM d').format(task.dueDate!),
                  style: TextStyle(
                    color: task.isCompleted
                        ? Colors.grey
                        : task.dueDate!.isBefore(DateTime.now())
                            ? Colors.red
                            : Colors.grey,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editTask(task, index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTaskCompletion(int index) {
    final task = tasks[index];
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: task.isCompleted ? null : DateTime.now(),
    );

    setState(() {
      tasks[index] = updatedTask;
    });

    final messenger = ScaffoldMessenger.of(context);
    _saveTasks().then((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            updatedTask.isCompleted ? 'Task completed' : 'Task marked as incomplete',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        centerTitle: true,
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first task',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              children: () {
                // Build lists of entries with original indices so actions work on the master list
                final entries = tasks.asMap().entries.toList();

                int taskCompare(Task a, Task b) {
                  const priorities = {'high': 0, 'normal': 1, 'low': 2};
                  final p = priorities[a.priority]!.compareTo(priorities[b.priority]!);
                  if (p != 0) return p;
                  if (a.dueDate != null && b.dueDate != null) return a.dueDate!.compareTo(b.dueDate!);
                  if (a.dueDate != null) return -1;
                  if (b.dueDate != null) return 1;
                  return a.title.compareTo(b.title);
                }

                final activeEntries = entries.where((e) => !e.value.isCompleted).toList()
                  ..sort((a, b) => taskCompare(a.value, b.value));

                final completedEntries = entries.where((e) => e.value.isCompleted).toList()
                  ..sort((a, b) => (b.value.completedAt ?? DateTime.now()).compareTo(a.value.completedAt ?? DateTime.now()));

                final children = <Widget>[];

                if (activeEntries.isNotEmpty) {
                  children.add(
                    ExpansionTile(
                      initiallyExpanded: _activeExpanded,
                      onExpansionChanged: (v) => setState(() => _activeExpanded = v),
                      title: Row(
                        children: [
                          const Text('Active Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                            child: Text(activeEntries.length.toString(), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          ),
                        ],
                      ),
                      children: activeEntries.map((e) => _buildTaskCard(e.value, e.key)).toList(),
                    ),
                  );
                }

                if (completedEntries.isNotEmpty) {
                  children.add(
                    ExpansionTile(
                      initiallyExpanded: _completedExpanded,
                      onExpansionChanged: (v) => setState(() => _completedExpanded = v),
                      title: Row(
                        children: [
                          const Text('Completed Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                            child: Text(completedEntries.length.toString(), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          ),
                        ],
                      ),
                      children: completedEntries.map((e) => _buildTaskCard(e.value, e.key)).toList(),
                    ),
                  );
                }

                return children;
              }(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Text(
          '+',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}