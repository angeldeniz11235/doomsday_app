import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doomsday_app/add_doomsday.dart';
import 'package:doomsday_app/doomsday.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:logger/logger.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';

var logger = Logger(
  printer: PrettyPrinter(), // Use the PrettyPrinter to format and print log
  level: Level.debug, // Print at debug and above
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
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
    logger.i('Building MyApp');
    return MaterialApp(
      title: 'Doomsday Clock',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 255, 0, 0)!),
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
    logger.i('Building MyHomePage');
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
            Align(
              alignment: Alignment.center,
              child: Clock(),
            ),
            Expanded(
              child: UpcomingDoomsdays(),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: _FloatingActionButton(),
              ),
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
  bool _hidden = true;

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
    logger.i('Target changed to ${doomsday.title} on ${doomsday.date}');
  }

  void isHidden(bool value) {
    _hidden = value;
    notifyListeners();
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
  @override
  Widget build(BuildContext context) {
    logger.i('Building Clock');
    return Consumer<ClockModel>(builder: (context, clockModel, child) {
      return
          // If the countdown is hidden, return an empty container
          clockModel._hidden
              ? const SizedBox()
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${clockModel._countdownDuration.inDays} days ${clockModel._countdownDuration.inHours.remainder(24).toString().padLeft(2, '0')}:${clockModel._countdownDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${clockModel._countdownDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          Text(
                            "Until ${clockModel._title}",
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ],
                      ),
                    )
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
  // Create a reference to the Firebase Storage
  final storageRef = FirebaseStorage.instance.ref();

  //selected list tile
  final Set<int> _selectedIndices = {};
  @override
  Widget build(BuildContext context) {
    //get the theme of the app
    final theme = Theme.of(context);
    logger.i('Building UpcomingDoomsdays');
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
              image: data['image'],
              icon: data['icon'],
              docId: doc.id,
            );
          }).toList();
          return ListView.builder(
            controller: ScrollController(),
            itemCount: doomsdays.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 3.0,
                child: ListTile(
                  selected: _selectedIndices.contains(index),
                  selectedTileColor: theme.colorScheme.surface.withAlpha(25),
                  leading: GestureDetector(
                    child: doomsdays[index].icon != null
                        ? FutureBuilder(
                            future: storageRef
                                .child(doomsdays[index].icon!)
                                .getDownloadURL(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                return snapshot.data != null
                                    ? Image.network(
                                        snapshot.data as String,
                                        width: 50,
                                        height: 50,
                                        errorBuilder:
                                            (context, exception, stackTrace) {
                                          return const Icon(Icons.error,
                                              color: Colors.red);
                                        },
                                      )
                                    : const Icon(Icons.error,
                                        color: Colors.red);
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              return const Icon(Icons.error, color: Colors.red);
                            },
                          )
                        : null,
                    onTap: () {
                      // Show a dialog with the image if available
                      if (doomsdays[index].image != null) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            logger.i(
                                'Showing image for doomsday: ${doomsdays[index].description}');
                            return AlertDialog(
                              content: doomsdays[index].image != null
                                  ? FutureBuilder(
                                      future: storageRef
                                          .child(doomsdays[index].image!)
                                          .getDownloadURL(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.done) {
                                          return Image.network(
                                            snapshot.data as String,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const CircularProgressIndicator();
                                            },
                                            errorBuilder: (context, exception,
                                                stackTrace) {
                                              return const Icon(Icons.error,
                                                  color: Colors.red);
                                            },
                                          );
                                        }
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }
                                        return const Icon(Icons.error,
                                            color: Colors.red);
                                      },
                                    )
                                  : null,
                            );
                          },
                        );
                      }
                    },
                  ),
                  title: Text(
                    "${doomsdays[index].date!.year} ${doomsdays[index].title} ",
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
                  trailing: GestureDetector(
                    child: const Icon(Icons.delete, color: Colors.red),
                    onTap: () {
                      logger.i(
                          'Deleting doomsday: ${doomsdays[index].description}');
                      // Delete the doomsday
                      FirebaseFirestore.instance
                          .collection('doomsday')
                          .doc(doomsdays[index].docId)
                          .delete();
                      logger.i(
                          'Doomsday ${doomsdays[index].title} deleted from firestore.');
                      //show a message to confirm deletion
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Doomsday ${doomsdays[index].title} deleted.'),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    // When a doomsday is tapped change the selected card
                    setState(() {
                      _selectedIndices.clear();
                      if (_selectedIndices.contains(index)) {
                        _selectedIndices.remove(index);
                      } else {
                        _selectedIndices.add(index);
                      }
                    });

                    // Change the target date and title
                    Provider.of<ClockModel>(context, listen: false)
                        .changeTarget(doomsdays[index]);
                    // unhide the countdown
                    Provider.of<ClockModel>(context, listen: false)
                        .isHidden(false);
                    logger.i(
                        'Changing target to ${doomsdays[index].title} on ${doomsdays[index].date}');
                  },
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          logger.e('Error: ${snapshot.error}');
          return Text('Error: ${snapshot.error}');
        } else {
          logger.i('Loading data...');
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  const _FloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    logger.i('Building _FloatingActionButton');
    return FloatingActionButton(
      onPressed: () {
        //navigate to the add doomsday screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddDoomsdayPage()),
        );
        logger.d('Add Doomsday button pressed.');
      },
      tooltip: 'Add Doomsday',
      child: const Icon(Icons.add),
    );
  }
}
