import 'package:pigeon/pigeon.dart';

// dart run pigeon --input pigeon/hand_landmark.dart
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'hand_landmarker',
    dartOut: 'lib/hand_landmarker_pigeon.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/io/github/iot_gamer/hand_landmarker/HandLandmarkerPlugin.g.kt',
    kotlinOptions:
        KotlinOptions(package: 'io.github.iot_gamer.hand_landmarker'),
    debugGenerators: true,
  ),
)

/// Event channel methods for the Hand Landmarker plugin.
@EventChannelApi()
abstract class HandLandmarkerEventChannel {
  HandLandmarkerEventResult handLandmarkerEventStream();
}

/// Pigeon not able to decode List<List.., so we need to wrap the inner list in a class.
class HandLandmarkerEventResult {
  final int timestampMs;
  final List<HandLandmarkList> landmarks;
  final List<HandLandmarkList> worldLandmarks;
  final List<HandLandmarkCategoryList> handedness;

  HandLandmarkerEventResult(
    this.timestampMs,
    this.landmarks,
    this.worldLandmarks,
    this.handedness,
  );
}

class HandLandmarkList {
  final List<HandLandmark> data;
  HandLandmarkList(this.data);
}

class HandLandmarkCategoryList {
  final List<HandLandmarkCategory> data;
  HandLandmarkCategoryList(this.data);
}

class HandLandmark {
  final double x;
  final double y;
  final double z;
  final double? visibility;
  final double? presence;
  HandLandmark(this.x, this.y, this.z, this.visibility, this.presence);
}

class HandLandmarkCategory {
  final double score;
  final int index;
  final String categoryName;
  final String displayName;

  HandLandmarkCategory(
    this.score,
    this.index,
    this.categoryName,
    this.displayName,
  );
}
