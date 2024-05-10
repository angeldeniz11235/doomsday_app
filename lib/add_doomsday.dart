import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doomsday_app/main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AddDoomsdayPage extends StatefulWidget {
  const AddDoomsdayPage({super.key});
  @override
  State<AddDoomsdayPage> createState() => _AddDoomsdayPageState();
}

class _AddDoomsdayPageState extends State<AddDoomsdayPage> {
  late DateTime selectedDate;
  late String description;
  late ImageData? selectedImage;
  late String? selectedCategory;
  late String? title;

  // list of available categories
  final _categoryList = <String>[];

  //Constructor to initialize the state
  _AddDoomsdayPageState() {
    selectedDate = DateTime.now();
    description = '';
    selectedImage = null;
    selectedCategory = '';
    title = '';
  }

  final imageDropdownItems = <DropdownMenuItem<ImageData>>[];

  final FirebaseStorage storage = FirebaseStorage.instance;

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
                  ? selectedDate.toLocal().toString().split(' ')[0]
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
                      value: selectedCategory == '' ? null : selectedCategory,
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
              child: FutureBuilder<List<ImageData>>(
                future: _loadImageData(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final imageData = snapshot.data!;
                    imageDropdownItems.clear();
                    imageDropdownItems.addAll(imageData.map((item) {
                      return DropdownMenuItem<ImageData>(
                        value: item,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              item.image,
                              const SizedBox(width: 16.0),
                              Text(item.imageName),
                            ],
                          ),
                        ),
                      );
                    }).toList());

                    return DropdownButton<ImageData>(
                      items: imageDropdownItems,
                      onChanged: (value) {
                        selectedImage = null;
                        // Handle dropdown item selection
                        if (value != null) {
                          selectedImage = imageData.firstWhere(
                            (element) => element.id == value.id,
                          );
                          logger
                              .d('Selected image: ${selectedImage!.imageName}');
                        }
                        // update the widget
                        setState(() {});
                      },
                      value: selectedImage,
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Add logic for 'add' button
                    //check that all fields are filled
                    if (selectedCategory == '' ||
                        title == '' ||
                        description == '' ||
                        selectedImage == '' ||
                        (selectedDate.difference(DateTime.now()) <
                            const Duration(days: 1))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields.'),
                        ),
                      );
                      return;
                    }
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

  Future<List<ImageData>> _loadImageData() async {
    // if imageDropdownItems is not empty, return it (to avoid reloading the images every time the widget is rebuilt)
    if (imageDropdownItems.isNotEmpty) {
      logger.d('Loading images from memory');
      return imageDropdownItems.map((e) => e.value!).toList();
    } else {
      logger.d('Loading images from storage');
      String path = 'images/icons';
      final listOfIconsRef = await storage.ref(path).listAll();
      final List<ImageData> imageData = [];
      for (final iconRef in listOfIconsRef.items) {
        final downloadUrl = await iconRef.getDownloadURL();
        final imageName = iconRef.name;
        imageData.add(ImageData(
          imageName: imageName,
          image: Image.network(downloadUrl),
          id: iconRef.fullPath,
        ));
      }
      return imageData;
    }
  }
}

class ImageData {
  final String imageName;
  // final String imageStoragePath;
  final Image image;
  final String id;

  ImageData(
      {required this.imageName,
      // required this.imageStoragePath,
      required this.image,
      String? id})
      : id = id ?? const Uuid().v4();

// == and hashCode methods are required to compare objects in the list
// or else the dropdownbutton will not work properly
  @override
  bool operator ==(Object other) => other is ImageData && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
