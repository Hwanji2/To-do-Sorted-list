import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '할일 관리 앱',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      home: const MyHomePage(title: '할일 관리 앱'),
    );
  }
}

class Todo {
  String title;
  DateTime time;
  bool completed;
  Todo({required this.title, required this.time, this.completed = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'time': time.toIso8601String(),
    'completed': completed,
  };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    title: json['title'],
    time: DateTime.parse(json['time']),
    completed: json['completed'],
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController taskTitleController = TextEditingController();
  String goal = "";
  final List<Todo> _todoList = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  String animatedText = "";
  String inputAnimatedText = "";
  String currentTime = "";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _startTypingAnimation("할일 관리 앱에 오신 것을 환영합니다!");
    _startCurrentTimeUpdate();
    _startDeadlineCheck();
    _loadDataFromDB();
  }

  void _initializeNotifications() {
    tz_data.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);
    _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _loadDataFromDB() async {
    final prefs = await SharedPreferences.getInstance();
    final todoData = prefs.getString('todoList');
    final savedGoal = prefs.getString('goal') ?? "";
    if (todoData != null) {
      final List<dynamic> jsonData = jsonDecode(todoData);
      setState(() {
        _todoList.clear();
        _todoList.addAll(jsonData.map((item) => Todo.fromJson(item)).toList());
        goal = savedGoal;
      });
    }
  }

  Future<void> _saveDataToDB() async {
    final prefs = await SharedPreferences.getInstance();
    final todoData = jsonEncode(_todoList.map((todo) => todo.toJson()).toList());
    await prefs.setString('todoList', todoData);
    await prefs.setString('goal', goal);
  }

  void _startCurrentTimeUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      });
    });
  }

  void _startDeadlineCheck() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      for (var todo in _todoList) {
        if (!todo.completed) {
          final remaining = todo.time.difference(now);
          if (remaining.inSeconds == 30) {
            _showNotification("기한 30초 전!", "${todo.title}: ${_formatRemainingTime(todo.time)} 남음");
          } else if (remaining.isNegative) {
            _showNotification("기한 만료!", "${todo.title}: 기한이 지났습니다");
          }
        }
      }
    });
  }

  void _showNotification(String title, String body) async {
    var androidDetails = const AndroidNotificationDetails(
      'deadline_channel',
      '기한 알림',
      importance: Importance.max,
      priority: Priority.high,
    );
    var platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, title, body, platformDetails);
  }

  void _startTypingAnimation(String message) {
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (index < message.length) {
        setState(() {
          animatedText += message[index];
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  void _showAddTodoDialog() {
    taskTitleController.clear();
    inputAnimatedText = "";
    showDialog(
      context: context,
      builder: (context) {
        _startInputTypingAnimation("할일 제목과 시간을 입력하세요");
        return AlertDialog(
          title: Text(animatedText),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(inputAnimatedText),
              TextField(
                controller: taskTitleController,
                decoration: const InputDecoration(
                  hintText: '할일 제목 입력',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    locale: const Locale("ko"),
                  );

                  if (selectedDate == null) return;

                  TimeOfDay? selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (selectedTime == null) return;

                  final DateTime dateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  final newTodo = Todo(
                      title: taskTitleController.text, time: dateTime);
                  setState(() {
                    _todoList.add(newTodo);
                    _saveDataToDB();
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('날짜와 시간 선택'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  void _startInputTypingAnimation(String message) {
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (index < message.length) {
        setState(() {
          inputAnimatedText += message[index];
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  void _removeTodo(int index) {
    setState(() {
      _todoList.removeAt(index);
      _saveDataToDB();
    });
  }

  List<Todo> _sortTodosByPriority() {
    List<Todo> sortedList = List.from(_todoList);
    sortedList.sort((a, b) {
      if (a.title.contains(goal) && !b.title.contains(goal)) {
        return -1;
      } else if (!a.title.contains(goal) && b.title.contains(goal)) {
        return 1;
      } else {
        return a.time.compareTo(b.time);
      }
    });
    return sortedList;
  }

  String _formatRemainingTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    if (difference.isNegative) {
      return "기한이 지났습니다";
    } else {
      return "${difference.inDays}일 ${difference.inHours % 24}시간 ${difference.inMinutes % 60}분 ${difference.inSeconds % 60}초 남음";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              currentTime,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              animatedText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                setState(() {
                  goal = value;
                });
              },
              decoration: const InputDecoration(
                labelText: '목표 입력 (우선순위 정렬)',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _todoList.isEmpty
                  ? const Center(
                child: Text(
                  '추가된 할일이 없습니다.',
                  style: TextStyle(fontSize: 18),
                ),
              )
                  : ListView.builder(
                itemCount: _sortTodosByPriority().length,
                itemBuilder: (context, index) {
                  final todo = _sortTodosByPriority()[index];
                  return ListTile(
                    leading: Checkbox(
                      value: todo.completed,
                      onChanged: (value) {
                        setState(() {
                          todo.completed = value ?? false;
                          if (todo.completed) {
                            _removeTodo(index);
                          }
                        });
                      },
                    ),
                    title: Text(todo.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('yyyy-MM-dd HH:mm:ss')
                            .format(todo.time)),
                        Text(_formatRemainingTime(todo.time)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
