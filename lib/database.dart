// Class to handle firestore database operations
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(), // Use the PrettyPrinter to format and print log
  level: Level.info, // Print only info level logs
);

class Database {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Download all documents from a collection
  Future<List<Map<String, dynamic>>> downloadCollection(
      String collection) async {
    logger.i('Downloading collection $collection');
    var collectionRef = _firestore.collection(collection);
    var snapshot = await collectionRef.get();
    var documents = snapshot.docs;
    var data = documents.map((doc) => doc.data()).toList();
    return data;
  }
}
