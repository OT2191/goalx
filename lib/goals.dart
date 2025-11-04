import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class Goal {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String priority;
  final IconData icon;
  final List<String> milestones;

  Goal({
    String? id,
    required this.title,
    required this.description,
    this.dueDate,
    this.priority = 'normal',
    this.icon = Icons.flag,
    List<String>? milestones,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(), milestones = milestones ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'icon': icon.codePoint,
      'milestones': milestones,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'])
        : null,
      priority: json['priority'] ?? 'normal',
      icon: IconData(
        json['icon'],
        fontFamily: 'MaterialIcons',
      ),
      milestones: List<String>.from(json['milestones'] ?? []),
    );
  }
}

class MyGoals extends StatefulWidget {
  const MyGoals({super.key});

  @override
  State<MyGoals> createState() => _MyGoalsState();
}

class _MyGoalsState extends State<MyGoals> {
  static const String goalsKey = 'goals';
  final List<Goal> goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getString(goalsKey);
    if (goalsJson != null) {
      final goalsList = jsonDecode(goalsJson) as List;
      setState(() {
        goals.clear();
        goals.addAll(
          goalsList.map((g) => Goal.fromJson(g)).toList(),
        );
      });
    }
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = jsonEncode(
      goals.map((g) => g.toJson()).toList(),
    );
    await prefs.setString(goalsKey, goalsJson);
  }

  void _addGoal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
    String priority = 'normal';
    // Temporary storage for milestones while creating a goal
    final List<String> tempMilestones = [];
    final milestoneController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Type your goal',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe the goal',
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Due date',
            hintText: selectedDate == null
              ? 'Select due date'
              : '${selectedDate!.toLocal()}'.split(' ')[0],
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        setState(() {
                          priority = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Milestones', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // List existing milestones
                    Column(
                      children: [
                        for (int i = 0; i < tempMilestones.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Expanded(child: Text(tempMilestones[i])),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      tempMilestones.removeAt(i);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        // Input to add a new milestone
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: milestoneController,
                                decoration: const InputDecoration(
                                  labelText: 'New milestone',
                                  hintText: 'Describe a milestone',
                                ),
                                onSubmitted: (_) {
                                  final text = milestoneController.text.trim();
                                  if (text.isNotEmpty) {
                                    setState(() {
                                      tempMilestones.add(text);
                                      milestoneController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final text = milestoneController.text.trim();
                                if (text.isNotEmpty) {
                                  setState(() {
                                    tempMilestones.add(text);
                                    milestoneController.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final description = descController.text.trim();
                    
                    if (title.isNotEmpty && description.isNotEmpty && selectedDate != null) {
                      final newGoal = Goal(
                        title: title,
                        description: description,
                        dueDate: selectedDate!,
                        priority: priority,
                        icon: Icons.flag, // Default icon
                        milestones: List<String>.from(tempMilestones), // Use milestones added in dialog
                      );
                      
                      // Update state and close dialog
                      setState(() {
                        goals.add(newGoal);
                      });
                      Navigator.of(dialogContext).pop();
                      
                      // Save goals in background and show confirmation safely
                      final messenger = ScaffoldMessenger.of(context);
                      _saveGoals().then((_) {
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Goal saved')),
                          );
                        }
                      });
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editGoal(Goal goal, int index) {
    final titleController = TextEditingController(text: goal.title);
    final descController = TextEditingController(text: goal.description);
    DateTime? selectedDate = goal.dueDate;
    String priority = goal.priority;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Type your goal',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe the goal',
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Due date',
                        hintText: selectedDate == null
                            ? 'Select due date'
                            : '${selectedDate?.toLocal()}'.split(' ')[0],
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        setState(() {
                          priority = newSelection.first;
                        });
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
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final description = descController.text.trim();
                    
                    if (title.isNotEmpty && description.isNotEmpty && selectedDate != null) {
                      final updatedGoal = Goal(
                        title: title,
                        description: description,
                        dueDate: selectedDate!,
                        priority: priority,
                        icon: goal.icon, // Preserve the original icon
                        milestones: goal.milestones, // Preserve existing milestones
                      );
                      
                      // Close dialog first
                      Navigator.of(dialogContext).pop();
                      
                      // Then update state and save
                      if (mounted) {
                        setState(() {
                          goals[index] = updatedGoal;
                        });
                        await _saveGoals();
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
        centerTitle: true,
      ),
      body: goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No goals yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first goal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () => _editGoal(goal, index),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                goal.icon,
                                color: {
                                  'high': Colors.red[400],
                                  'normal': Colors.blue[400],
                                  'low': Colors.green[400],
                                }[goal.priority],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  goal.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editGoal(goal, index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(goal.description),
                          const SizedBox(height: 8),
                          // Show milestones as chips when present
                          if (goal.milestones.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: goal.milestones.map((m) => Chip(
                                label: Text(
                                  m,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              )).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Due: ${DateFormat('MMM d, y').format(goal.dueDate!)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: {
                                    'high': Colors.red[100],
                                    'normal': Colors.blue[100],
                                    'low': Colors.green[100],
                                  }[goal.priority],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  goal.priority.toUpperCase(),
                                  style: TextStyle(
                                    color: {
                                      'high': Colors.red[900],
                                      'normal': Colors.blue[900],
                                      'low': Colors.green[900],
                                    }[goal.priority],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        child: const Text(
          '+',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}