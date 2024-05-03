import 'package:doomsday_app/doomsday.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(), // Use the PrettyPrinter to format and print log
  level: Level.info, // Print only info level logs
);

void main() {
  runApp(const MyApp());
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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
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

class Clock extends StatefulWidget {
  const Clock({super.key});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  late Timer _timer;
  late DateTime _targetDate;
  late Duration _countdownDuration;

  @override
  void initState() {
    super.initState();
    // Set the target date to a future date
    _targetDate = DateTime(2030, 12, 31);
    // Calculate the initial countdown duration
    _countdownDuration = _targetDate.difference(DateTime.now());
    // Start the countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _countdownDuration = _targetDate.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${_countdownDuration.inDays} days ${_countdownDuration.inHours.remainder(24).toString().padLeft(2, '0')}:${_countdownDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_countdownDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.displayLarge,
      ),
    );
  }
}

class UpcomingDoomsdays extends StatefulWidget {
  const UpcomingDoomsdays({super.key});

  @override
  State<UpcomingDoomsdays> createState() => _UpcomingDoomsdaysState();
}

class _UpcomingDoomsdaysState extends State<UpcomingDoomsdays> {
  final List<Doomsday> _doomsdays = <Doomsday>[
    Doomsday(
        date: DateTime.parse('2022-12-31'),
        description: 'Possible asteroid impact',
        imageUrl: 'https://example.com/asteroid.jpg'),
    Doomsday(
        date: DateTime.parse('2023-01-01'),
        description: 'Alien invasion',
        imageUrl: 'https://example.com/alien.jpg'),
    Doomsday(
        date: DateTime.parse('2024-01-01'),
        description: 'Zombie apocalypse',
        imageUrl: 'https://example.com/zombie.jpg'),
    Doomsday(
        date: DateTime.parse('2025-01-01'),
        description: 'Nuclear war',
        imageUrl: 'https://example.com/nuclear.jpg'),
    Doomsday(
        date: DateTime.parse('2026-01-01'),
        description: 'Artificial intelligence uprising',
        imageUrl: 'https://example.com/ai.jpg'),
    Doomsday(
        date: DateTime.parse('2027-01-01'),
        description: 'Global pandemic',
        imageUrl: 'https://example.com/pandemic.jpg'),
    Doomsday(
        date: DateTime.parse('2028-01-01'),
        description: 'Climate catastrophe',
        imageUrl:
            'https://static.scientificamerican.com/sciam/cache/file/9593645C-DD5F-4387-B84EDEA9B63E9338_source.jpg?w=900'),
    Doomsday(
        date: DateTime.parse('2029-01-01'),
        description: 'Robot uprising',
        imageUrl: 'https://example.com/robot.jpg'),
    Doomsday(
        date: DateTime.parse('2030-01-01'),
        description: 'Supervolcano eruption',
        imageUrl: 'https://example.com/supervolcano.jpg'),
    Doomsday(
        date: DateTime.parse('2031-01-01'),
        description: 'Worldwide economic collapse',
        imageUrl: 'https://example.com/economic.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    //get the theme of the app
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: _doomsdays.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: _doomsdays[index].imageUrl != null
                ? FutureBuilder<Image>(
                    future: _doomsdays[index].loadIcon(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return snapshot.data!;
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  )
                : null,
            title: Text(
              _doomsdays[index].date.toString(),
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(_doomsdays[index].description),
            tileColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.all(10),
            onTap: () {
              // Show a dialog with the image if available
              if (_doomsdays[index].imageUrl != null) {
                showDialog(
                  context: context,
                  builder: (context) {
                    logger.i(
                        'Showing image for doomsday: ${_doomsdays[index].description}');
                    return AlertDialog(
                      content: Image.network(_doomsdays[index].imageUrl!),
                    );
                  },
                );
              }
            },
          ),
        );
      },
    );
  }
}
