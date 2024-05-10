//Class to represent a particular doomsday
// including the date, description, and a possible image.

class Doomsday {
  final String? category;
  final String? title;
  final DateTime? date;
  final String? description;
  final String? image;
  final String? icon;
  final String? docId;

  const Doomsday({
    this.category,
    this.title,
    this.date,
    this.description,
    this.image,
    this.icon,
    required this.docId,
  });

  // load the image from the network
  // Future<Image> loadImage() async {
  //   return Image.network(imageUrl!);
  // }

  // create an icon sized image
  // Future<Image> loadIcon() async {
  //   return Image.network(
  //     imageUrl!,
  //     width: 50,
  //     height: 50,
  //     errorBuilder:
  //         (BuildContext context, Object exception, StackTrace? stackTrace) {
  //       return const Icon(Icons.error, color: Colors.red);
  //     },
  //   );
}
