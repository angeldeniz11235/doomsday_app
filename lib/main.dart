import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doomsday_app/doomsday.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:logger/logger.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

var logger = Logger(
  printer: PrettyPrinter(), // Use the PrettyPrinter to format and print log
  level: Level.info, // Print only info level logs
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ChangeNotifierProvider(
    create: (context) => ClockModel(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          backgroundColor: Colors.grey,
          accentColor: Colors.orange,
          errorColor: Colors.red,
          cardColor: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const MyHomePage(title: 'Doomsday Clock'),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Clock(),
            Expanded(
              child: UpcomingDoomsdays(),
            ),
          ],
        ),
      ),
    );
  }
}

class ClockModel extends ChangeNotifier {
  Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});
  DateTime _targetDate = DateTime(2030, 12, 31);
  Duration _countdownDuration = const Duration();
  String _title = "";

  ClockModel() {
    _timer.cancel();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void setTimer(DateTime targetDate) {
    // cancel the previous timer if it is running
    if (_timer.isActive) _timer.cancel();
    _targetDate = targetDate;
    _countdownDuration = _targetDate.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _countdownDuration = _targetDate.difference(DateTime.now());
      notifyListeners();
    });
  }

  void changeTarget(Doomsday doomsday) {
    _targetDate = doomsday.date!;
    _title = doomsday.title!;
    notifyListeners();
    setTimer(_targetDate);
  }

  String get title => _title;

  Duration get countdownDuration => _countdownDuration;
}

class Clock extends StatefulWidget {
  const Clock({super.key});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  // late Timer _timer;
  // late DateTime _targetDate;
  // late Duration _countdownDuration;
  // String _title = 'Doomsday Event Name';

  // @override
  // void initState() {
  //   super.initState();
  //   // Set the target date to a future date
  //   _targetDate = DateTime(2030, 12, 31);
  //   // Calculate the initial countdown duration
  //   // _countdownDuration = _targetDate.difference(DateTime.now());
  //   // Start the countdown timer
  //   _timer = Timer.periodic(const Duration(seconds: 1), (_) {
  //     setState(() {
  //       _countdownDuration = _targetDate.difference(DateTime.now());
  //     });
  //     // _title = "Choose a doomsday event from the list below";
  //   });
  // }

  // @override
  // void dispose() {
  //   _timer.cancel();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClockModel>(builder: (context, clockModel, child) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${clockModel._countdownDuration.inDays} days ${clockModel._countdownDuration.inHours.remainder(24).toString().padLeft(2, '0')}:${clockModel._countdownDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${clockModel._countdownDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            clockModel._title,
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ],
      );
    });
  }
}

class UpcomingDoomsdays extends StatefulWidget {
  const UpcomingDoomsdays({super.key});

  @override
  State<UpcomingDoomsdays> createState() => _UpcomingDoomsdaysState();
}

class _UpcomingDoomsdaysState extends State<UpcomingDoomsdays> {
  //base url for the images
  final String _appBaseIMGUrl = 'https://doomsday-app.web.app/images/';
  @override
  Widget build(BuildContext context) {
    //get the theme of the app
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('doomsday').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final doomsdays = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Doomsday(
              category: data['category'],
              title: data['title'],
              date: data['date'] != null ? DateTime.parse(data['date']) : null,
              description: data['description'],
              image: _appBaseIMGUrl + data['image'],
              icon: _appBaseIMGUrl + data['icon'],
            );
          }).toList();
          return ListView.builder(
            itemCount: doomsdays.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: doomsdays[index].icon != null
                      ? Image.network(
                          doomsdays[index].icon!,
                          width: 50,
                          height: 50,
                          errorBuilder: (context, exception, stackTrace) {
                            return const Icon(Icons.error, color: Colors.red);
                          },
                        )
                      : null,
                  title: Text(
                    doomsdays[index].date.toString(),
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(doomsdays[index].description ?? ""),
                  tileColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                  onTap: () {
                    // Show a dialog with the image if available
                    if (doomsdays[index].image != null) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          logger.i(
                              'Showing image for doomsday: ${doomsdays[index].description}');
                          return AlertDialog(
                            content: Image.network(doomsdays[index].image!),
                          );
                        },
                      );
                    }
                    // Change the target date and title
                    Provider.of<ClockModel>(context, listen: false)
                        .changeTarget(doomsdays[index]);
                    logger.i(
                        'Changing target to ${doomsdays[index].title} on ${doomsdays[index].date}');
                  },
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
