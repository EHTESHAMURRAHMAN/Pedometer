import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:step_pedometer/home.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Step Counter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StepCounterPage(),
    );
  }
}

class StepCounterPage extends StatefulWidget {
  const StepCounterPage({super.key});

  @override
  StepCounterPageState createState() => StepCounterPageState();
}

class StepCounterPageState extends State<StepCounterPage> {
  final RxInt _stepCountToday = 0.obs;
  final RxInt _initialStepCount = 0.obs; // Initial step count for the day
  StreamSubscription<StepCount>? _stepCountStreamSubscription;
  Timer? _dailyResetTimer;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInit();
  }

  Future<void> _requestPermissionsAndInit() async {
    var status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _initStepCounter();
    } else {
      // Handle permission denied
      print('Permission denied');
    }
  }

  void _initStepCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    String todayKey = _getKeyForDate(now);
    String initialStepKey = _getInitialStepKeyForDate(now);

    int savedStepCount = prefs.getInt(todayKey) ?? 0;
    int initialStep = prefs.getInt(initialStepKey) ?? 0;

    _stepCountToday.value = savedStepCount;
    _initialStepCount.value = initialStep;

    _stepCountStreamSubscription =
        Pedometer.stepCountStream.listen((StepCount stepCount) async {
      // Calculate today's steps by subtracting the initial step count from the current step count
      int stepsToday = stepCount.steps - _initialStepCount.value;
      _stepCountToday.value =
          stepsToday < 0 ? 0 : stepsToday; // Prevent negative steps

      // Save today's step count
      await prefs.setInt(todayKey, _stepCountToday.value);
    });

    _scheduleDailyReset();
  }

  String _getKeyForDate(DateTime date) {
    return 'step_count_${date.year}_${date.month}_${date.day}';
  }

  String _getInitialStepKeyForDate(DateTime date) {
    return 'initial_step_${date.year}_${date.month}_${date.day}';
  }

  void _scheduleDailyReset() {
    DateTime now = DateTime.now();
    DateTime nextReset = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    Duration durationUntilMidnight = nextReset.difference(now);

    _dailyResetTimer = Timer(durationUntilMidnight, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      DateTime newDay = DateTime.now();
      String newDayKey = _getKeyForDate(newDay);
      String newInitialStepKey = _getInitialStepKeyForDate(newDay);

      // Store current step count as the new initial step count for the new day
      int currentStepCount =
          await Pedometer.stepCountStream.first.then((value) => value.steps);
      _initialStepCount.value = currentStepCount;

      // Reset step count for the new day
      await prefs.setInt(newInitialStepKey, _initialStepCount.value);
      await prefs.setInt(newDayKey, 0);

      _stepCountToday.value = 0;

      // Schedule the reset again for the next day
      _scheduleDailyReset();
    });
  }

  @override
  void dispose() {
    _stepCountStreamSubscription?.cancel();
    _dailyResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Counter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Text(
                  'Steps Today: ${_stepCountToday.value}',
                  style: const TextStyle(fontSize: 24),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryPage()),
                );
              },
              child: const Text('View Historical Data'),
            ),
          ],
        ),
      ),
    );
  }
}
