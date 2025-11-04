import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_provider.dart';
import 'goals.dart';
import 'timelog.dart';
import 'tasks.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {

  int current = 1;

  static final List<Widget> _pages =
  [
    const TimeLog(),
    const Tasks(),
    const MyGoals()
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body: _pages[navigationProvider.currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationProvider.currentIndex,
            onTap: (index) => navigationProvider.updateIndex(index),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time),
                label: 'TimeLog',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.task),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.flag),
                label: 'Goals',
              ),
            ],
            ),
          );
        },
      );
    }
  }