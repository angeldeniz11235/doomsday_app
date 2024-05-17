import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doomsday_app/add_doomsday.dart';
import 'package:doomsday_app/doomsday.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
    child: ChangeNotifierProvider(
        create: (context) => FilterSortModel(), child: const MyApp()),
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
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 0, 0)),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Clock(),
              SortFilter(),
              UpcomingDoomsdays(),
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
      return clockModel._hidden
          ? const SizedBox()
          : Container(
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
            );
    });
  }
}

class FilterSortModel extends ChangeNotifier {
  bool _ascending = true;
  String _filter = "";
  String _field = "date";
  bool _isHidden = true;

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSort(bool ascending) {
    _ascending = ascending;
    notifyListeners();
  }

  void setField(String field) {
    _field = field;
    notifyListeners();
  }

  void setIsHidden(bool value) {
    _isHidden = value;
    notifyListeners();
  }

  bool get ascending => _ascending;
  String get filter => _filter;
  String get field => _field;
  bool get isHidden => _isHidden;
}

class SortFilter extends StatefulWidget {
  const SortFilter({super.key});

  @override
  State<SortFilter> createState() => _SortFilterState();
}

class _SortFilterState extends State<SortFilter> {
  bool _isHidden = true;
  @override
  Widget build(BuildContext context) {
    logger.i('Building SortFilter');
    return Consumer<FilterSortModel>(
        builder: (context, filterSortModel, child) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            child: const Icon(Icons.filter_list),
            onTap: () {
              _isHidden = !_isHidden;
              filterSortModel.setIsHidden(_isHidden);
              setState(() {
                logger.i('Filter and sort options toggled.');
              });
            },
          ),
          _isHidden
              ? const SizedBox(height: 0)
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Text('Sort by: '),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: filterSortModel.field,
                              items: <String>[
                                'date',
                                'title',
                                'category'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                filterSortModel.setField(value!);
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Text('Order: '),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: filterSortModel.ascending
                                  ? 'ascending'
                                  : 'descending',
                              items: <String>[
                                'ascending',
                                'descending'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                filterSortModel.setSort(value == 'ascending');
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Text('Filter: '),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                onChanged: (String value) {
                                  filterSortModel.setFilter(value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
  final storageRef = FirebaseStorage.instance.ref();
  final Set<int> _selectedIndices = {};
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isHidden = !(Provider.of<FilterSortModel>(context).isHidden);
    return isHidden
        ? const SizedBox()
        : StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('doomsday').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                logger.i('Building UpcomingDoomsdays');
                final doomsdays = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Doomsday(
                    category: data['category'],
                    title: data['title'],
                    date: data['date'] != null
                        ? DateTime.parse(data['date'])
                        : null,
                    description: data['description'],
                    image: data['image'],
                    icon: data['icon'],
                    docId: doc.id,
                  );
                }).toList();
                final filterSortModel = Provider.of<FilterSortModel>(context);
                if (filterSortModel.filter.isNotEmpty) {
                  doomsdays.retainWhere((doomsday) {
                    return doomsday.title!.contains(filterSortModel.filter) ||
                        doomsday.category!.contains(filterSortModel.filter) ||
                        doomsday.description!.contains(filterSortModel.filter);
                  });
                }
                if (filterSortModel.field == 'date') {
                  doomsdays.sort((a, b) {
                    if (filterSortModel.ascending) {
                      return a.date!.compareTo(b.date!);
                    } else {
                      return b.date!.compareTo(a.date!);
                    }
                  });
                } else if (filterSortModel.field == 'title') {
                  doomsdays.sort((a, b) {
                    if (filterSortModel.ascending) {
                      return a.title!.compareTo(b.title!);
                    } else {
                      return b.title!.compareTo(a.title!);
                    }
                  });
                } else if (filterSortModel.field == 'category') {
                  doomsdays.sort((a, b) {
                    if (filterSortModel.ascending) {
                      return a.category!.compareTo(b.category!);
                    } else {
                      return b.category!.compareTo(a.category!);
                    }
                  });
                }
                return ListView.builder(
                  shrinkWrap:
                      true, // Added this to limit the height of ListView
                  itemCount: doomsdays.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3.0,
                      child: ListTile(
                        selected: _selectedIndices.contains(index),
                        selectedTileColor:
                            theme.colorScheme.surface.withAlpha(25),
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
                                              errorBuilder: (context, exception,
                                                  stackTrace) {
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
                                    return const Icon(Icons.error,
                                        color: Colors.red);
                                  },
                                )
                              : null,
                          onTap: () {
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
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress ==
                                                        null) {
                                                      return child;
                                                    }
                                                    return const CircularProgressIndicator();
                                                  },
                                                  errorBuilder: (context,
                                                      exception, stackTrace) {
                                                    return const Icon(
                                                        Icons.error,
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
                                        : const Icon(Icons.error,
                                            color: Colors.red),
                                  );
                                },
                              );
                            }
                          },
                        ),
                        title: Text(doomsdays[index].title!),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doomsdays[index].category!),
                            Text(
                              doomsdays[index].date != null
                                  ? '${doomsdays[index].date!.year}-${doomsdays[index].date!.month.toString().padLeft(2, '0')}-${doomsdays[index].date!.day.toString().padLeft(2, '0')}'
                                  : 'No date',
                            ),
                            Text(doomsdays[index].description ?? ''),
                          ],
                        ),
                        trailing: GestureDetector(
                          child: const Icon(Icons.delete, color: Colors.red),
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection('doomsday')
                                .doc(doomsdays[index].docId)
                                .delete();
                            setState(() {
                              logger.i('Deleted doomsday: $index');
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            _selectedIndices.contains(index)
                                ? _selectedIndices.remove(index)
                                : _selectedIndices.add(index);
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
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
  }
}

class _FloatingActionButton extends StatelessWidget {
  const _FloatingActionButton();

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
