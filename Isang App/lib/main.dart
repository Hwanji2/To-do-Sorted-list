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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String animatedBannerText = "";
  final String fullBannerText = '할일 관리 앱 made by Jihwan';

  @override
  void initState() {
    super.initState();
    _startBannerTypingAnimation();
  }

  void _startBannerTypingAnimation() {
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (index < fullBannerText.length) {
        setState(() {
          animatedBannerText += fullBannerText[index];
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '할일 관리 앱 Isang',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: _buildAnimatedBannerText(),
        ),
        body: const MyHomePage(title: '목표'),
      ),
    );
  }

  Widget _buildAnimatedBannerText() {
    final splitIndex = animatedBannerText.indexOf('made by');
    if (splitIndex == -1) {
      return Text(
        animatedBannerText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      );
    }

    final mainText = animatedBannerText.substring(0, splitIndex);
    final subText = animatedBannerText.substring(splitIndex);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: mainText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          TextSpan(
            text: subText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 20,
            ),
          ),
        ],
      ),
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
  TextEditingController goalController = TextEditingController();
  String goal = "";
  final List<Todo> _todoList = [];
  final List<String> _goals = [];
  final Map<String, int> _goalScores = {};
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  String animatedText = "";
  String inputAnimatedText = "";
  String currentTime = "";
  bool _notificationPermissionGranted = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _checkNotificationPermission();
    _startTypingAnimation("할일을 추가해보세요!");
    _startCurrentTimeUpdate();
    _startDeadlineCheck();
    _loadDataFromDB();
  }

  void _initializeNotifications() {
    tz_data.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );
    _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _checkNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    bool? granted = prefs.getBool('notificationPermissionGranted');
    if (granted == null || !granted) {
      bool permissionGranted = await _requestNotificationPermission();
      if (permissionGranted) {
        await prefs.setBool('notificationPermissionGranted', true);
        setState(() {
          _notificationPermissionGranted = true;
        });
      }
    } else {
      setState(() {
        _notificationPermissionGranted = true;
      });
    }
  }

  Future<bool> _requestNotificationPermission() async {
    return true;
  }

  Future<void> _loadDataFromDB() async {
    final prefs = await SharedPreferences.getInstance();
    final todoData = prefs.getString('todoList');
    final goalData = prefs.getStringList('goals') ?? [];
    final goalScoresData = prefs.getString('goalScores');

    setState(() {
      _goals.clear();
      _goals.addAll(goalData);
      if (goalScoresData != null) {
        _goalScores.clear();
        _goalScores.addAll(Map<String, int>.from(jsonDecode(goalScoresData)));
      }
    });

    if (todoData != null) {
      final List<dynamic> jsonData = jsonDecode(todoData);
      setState(() {
        _todoList.clear();
        _todoList.addAll(jsonData.map((item) => Todo.fromJson(item)).toList());
      });
    }
  }

  Future<void> _saveDataToDB() async {
    final prefs = await SharedPreferences.getInstance();
    final todoData =
    jsonEncode(_todoList.map((todo) => todo.toJson()).toList());
    await prefs.setString('todoList', todoData);
    await prefs.setStringList('goals', _goals);
    await prefs.setString('goalScores', jsonEncode(_goalScores));
  }

  void _startCurrentTimeUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
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
            _showNotification(
                "기한 30초 전!", "${todo.title}: ${_formatRemainingTime(todo.time)} 남음");
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

    var darwinDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    var platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(0, title, body, platformDetails);
  }

  void _removeTodoAt(int index) {
    setState(() {
      _todoList.removeAt(index);
      _saveDataToDB();
    });
  }

  void _increaseScore(String goal, int score) {
    setState(() {
      _goalScores[goal] = (_goalScores[goal] ?? 0) + score;
    });
    _saveDataToDB();
  }

  void _handleTodoCompletion(int index) {
    final todo = _todoList[index];
    final now = DateTime.now();
    final remainingTime = todo.time.difference(now);
    int score = 10;

    for (var goalItem in _goals) {
      if (todo.title.contains(goalItem)) {
        score += 20;
        _increaseScore(goalItem, score);
      }
    }

    if (!remainingTime.isNegative) {
      score += 10;
    }

    _removeTodoAt(index);
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

  void _showAddGoalDialog() {
    goalController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('목표 추가하기'),
          content: TextField(
            controller: goalController,
            decoration: const InputDecoration(
              hintText: '목표 내용 입력',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _goals.add(goalController.text);
                  _goalScores[goalController.text] = 0;
                  _saveDataToDB();
                });
                Navigator.of(context).pop();
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
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
              const SizedBox(height: 8),
              TextField(
                controller: taskTitleController,
                decoration: const InputDecoration(
                  hintText: '할일 제목 입력',
                ),
              ),
              const SizedBox(height: 24),
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

  void _showAddOptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('추가 옵션'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddGoalDialog();
                },
                child: const Text('목표 추가하기'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddTodoDialog();
                },
                child: const Text('할일 추가하기'),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _getPriorityList() {
    List<Todo> sortedList = _sortTodosByPriority();
    return sortedList.map((todo) => todo.title).toList();
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

  void _startInputTypingAnimation(String message) {
    int index = 0;
    inputAnimatedText = "";
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

  @override
  Widget build(BuildContext context) {
    List<Todo> sortedList = _sortTodosByPriority();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _goals
                  .asMap()
                  .entries
                  .map((entry) {
                int index = entry.key;
                String goalItem = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: false,
                        onChanged: (value) {
                          if (value == true) {
                            setState(() {
                              _goals.removeAt(index);
                              _saveDataToDB();
                            });
                          }
                        },
                      ),
                      ActionChip(
                        label: Text("$goalItem: ${_goalScores[goalItem] ?? 0}점"),
                        onPressed: () {
                          setState(() {
                            goal = goalItem;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: _getPriorityList()
                  .map((title) => Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right),
                ],
              ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(
              currentTime,
              style:
              const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                itemCount: sortedList.length,
                itemBuilder: (context, index) {
                  final todo = sortedList[index];
                  final originalIndex = _todoList.indexOf(todo);
                  return ListTile(
                    leading: Checkbox(
                      value: todo.completed,
                      onChanged: (value) {
                        setState(() {
                          todo.completed = value ?? false;
                          if (todo.completed) {
                            _handleTodoCompletion(originalIndex);
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
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _removeTodoAt(originalIndex);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptionDialog,
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
