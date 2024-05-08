import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doomsday_app/main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AddDoomsdayPage extends StatefulWidget {
  const AddDoomsdayPage({super.key});
  @override
  State<AddDoomsdayPage> createState() => _AddDoomsdayPageState();
}

class _AddDoomsdayPageState extends State<AddDoomsdayPage> {
  late DateTime selectedDate;
  late String description;
  late String? selectedImage;
  late String? selectedCategory;

  //map of image names to their urls
  final Map<String, Image> _iconImageMap = {};

  // list of available categories
  final _categoryList = <String>[];

  //Constructor to initialize the state
  _AddDoomsdayPageState() {
    selectedDate = DateTime.now();
    description = '';
    selectedImage = '';
    selectedCategory = '';
    loadIconsToMap();
  }

//load the icons from firebase storage
  void loadIconsToMap() async {
    final storageRef = FirebaseStorage.instance.ref();
    final ListResult result = await storageRef.child('images/icons').list();
    for (final Reference ref in result.items) {
      final String name = ref.name;
      final String url = await ref.getDownloadURL();
      _iconImageMap[name] = Image.network(
        url,
        width: 50,
        height: 50,
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          return const Icon(Icons.error, color: Colors.red);
        },
      );
    }
    selectedImage = _iconImageMap.keys.first;
  }

  List<String> images = [
    'image1.jpg',
    'image2.jpg',
    'image3.jpg',
    // Add more image paths here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Doomsday',
          style: Theme.of(context).textTheme.displayLarge!,
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Select Date:'),
            ElevatedButton(
              onPressed: () {
                // Show date picker and update selectedDate
                showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365 * 100)),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365 * 1000)),
                ).then((pickedDate) {
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                });
              },
              child: Text(selectedDate.difference(DateTime.now()) >
                      const Duration(minutes: 5)
                  ? selectedDate.toString()
                  : 'Select a date'),
            ),
            const SizedBox(height: 16.0),
            const Text('Select Category:'),
            StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final List<DocumentSnapshot> documents =
                        snapshot.data!.docs;
                    _categoryList.clear();
                    for (final DocumentSnapshot document in documents) {
                      _categoryList.add(document['category'] as String);
                    }
                    return DropdownButton(
                      isExpanded: true,
                      onChanged: (value) {
                        // Update category
                        setState(() {
                          selectedCategory = value as String;
                        });
                      },
                      value: selectedCategory == ''
                          ? _categoryList.first
                          : selectedCategory,
                      items: _categoryList.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    );
                  }
                  return const CircularProgressIndicator();
                }),
            const SizedBox(height: 16.0),
            TextField(
              onChanged: (value) {
                // Update description
              },
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              onChanged: (value) {
                // Update description
              },
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 24.0),
            const Text('Select Image:'),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              height: 80.0,
              child: DropdownButton(
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    selectedImage = value!;
                  });
                  logger.i('Selected Image: $value');
                },
                value: selectedImage,
                items: _iconImageMap.entries.map((entry) {
                  final String imageName = entry.key;
                  final Image image = entry.value;
                  logger.d('Adding image: $imageName to dropdown.');
                  return DropdownMenuItem<String>(
                    value: imageName,
                    child: Row(
                      children: [
                        image,
                        const SizedBox(width: 16.0),
                        Text(imageName),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Add logic for 'add' button
                  },
                  child: const Text('Add'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // return to the previous page
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
