export 'package:hand_landmarker/hand_landmarker_pigeon.dart';
export 'hand.dart';

import 'dart:typed_data';

import 'package:hand_landmarker/hand.dart';
import 'package:hand_landmarker/hand_landmarker_pigeon.dart';
import 'package:jni/jni.dart';
import 'hand_landmarker_bindings.dart';

/// The main class for the Hand Landmarker plugin.
class HandLandmarkerPlugin {
  final MyHandLandmarker _landmarker;
  HandLandmarkerPlugin._(this._landmarker);

  /// Creates and initializes the Hand Landmarker.
  static HandLandmarkerPlugin create({
    int numHands = 2,
    double minHandDetectionConfidence = 0.5,
    HandLandmarkerDelegate delegate = HandLandmarkerDelegate.gpu,
  }) {
    // Create the native MyHandLandmarker object.
    final contextObj = Jni.androidApplicationContext;
    final landmarker = MyHandLandmarker(contextObj);
    landmarker.initialize(
      numHands,
      minHandDetectionConfidence,
      delegate == HandLandmarkerDelegate.gpu,
    );
    return HandLandmarkerPlugin._(landmarker);
  }

  /// Stream of hand landmark results from the native side.
  /// Results are pushed asynchronously after [detectFromCameraImage] is called (native runs in LIVE_STREAM mode).
  /// Listen to this stream to receive [HandLandmarkerEventResult] data instead of using the synchronous [detectFromCameraImage] return value.
  static Stream<HandLandmarkerEventResult> get resultStream =>
      handLandmarkerEventStream();

  /// Detects hand landmarks from YUV planes.
  /// To detect from a CameraImage, use this
  /// ```dart
  /// _plugin!.detect(
  ///   yPlaneBytes: image.planes[0].bytes,
  ///   uPlaneBytes: image.planes[1].bytes,
  ///   vPlaneBytes: image.planes[2].bytes,
  ///   yRowStride: image.planes[0].bytesPerRow,
  ///   uvRowStride: image.planes[1].bytesPerRow,
  ///   bytesPerPixel: image.planes[1].bytesPerPixel!,
  ///   width: image.width,
  ///   height: image.height,
  ///   sensorOrientation: _controller!.description.sensorOrientation,
  /// );
  /// ```
  void detectFromCameraImage({
    required Uint8List yPlaneBytes,
    required Uint8List uPlaneBytes,
    required Uint8List vPlaneBytes,
    required int yRowStride,
    required int uvRowStride,
    required int bytesPerPixel,
    required int width,
    required int height,
    required int sensorOrientation,
  }) {
    final yBuffer = JByteBuffer.fromList(yPlaneBytes);
    final uBuffer = JByteBuffer.fromList(uPlaneBytes);
    final vBuffer = JByteBuffer.fromList(vPlaneBytes);
    _landmarker.detectFromYuv(
      yBuffer,
      uBuffer,
      vBuffer,
      width,
      height,
      yRowStride,
      uvRowStride,
      bytesPerPixel,
      sensorOrientation,
    );
    yBuffer.release();
    uBuffer.release();
    vBuffer.release();
  }

  /// Releases the native landmarker resources.
  void dispose() => _landmarker.release();
}
