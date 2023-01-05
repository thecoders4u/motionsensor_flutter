
import 'package:image/image.dart';
import 'package:meta/meta.dart';

/// Model to encapsulate the results of a difference between images
/// query.
class DiffImgResult {
  DiffImgResult({
    required this.diffImg,
    required this.diffValue,
  });

  final Image diffImg;
  final num diffValue;
}// TODO Implement this library.