//Class to represent a particular doomsday
// including the date, description, and a possible image.

import 'package:flutter/material.dart';

class Doomsday {
  final DateTime date;
  final String description;
  final String? imageUrl;

  const Doomsday({
    required this.date,
    required this.description,
    this.imageUrl,
  });

  // load the image from the network
  // Future<Image> loadImage() async {
  //   return Image.network(imageUrl!);
  // }

  // create an icon sized image
  Future<Image> loadIcon() async {
    return Image.network(
      imageUrl!,
      width: 50,
      height: 50,
      errorBuilder:
          (BuildContext context, Object exception, StackTrace? stackTrace) {
        return const Icon(Icons.error, color: Colors.red);
      },
    );
  }
}
