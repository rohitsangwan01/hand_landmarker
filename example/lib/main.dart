import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Hand Landmarker Example',
      home: HandTrackerView(),
    );
  }
}

class HandTrackerView extends StatefulWidget {
  const HandTrackerView({super.key});

  @override
  State<HandTrackerView> createState() => _HandTrackerViewState();
}

class _HandTrackerViewState extends State<HandTrackerView> {
  CameraController? _controller;
  HandLandmarkerPlugin? _plugin;
  HandLandmarkerEventResult? _latestResult;
  bool _isInitialized = false;
  bool _isDetecting = false;
  StreamSubscription<HandLandmarkerEventResult>? _resultSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final camera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _plugin = HandLandmarkerPlugin.create(
      numHands: 2,
      minHandDetectionConfidence: 0.7,
      delegate: HandLandmarkerDelegate.gpu,
    );

    _resultSubscription = HandLandmarkerPlugin.resultStream.listen((result) {
      debugPrint('HandLandmarkerEventResult: $result');
      if (mounted) {
        setState(() => _latestResult = result);
      }
    });

    await _controller!.initialize();
    await _controller!.startImageStream(_processCameraImage);

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _resultSubscription?.cancel();
    _controller?.stopImageStream();
    _controller?.dispose();
    _plugin?.dispose();
    super.dispose();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !_isInitialized || _plugin == null) return;

    _isDetecting = true;
    try {
      _plugin!.detectFromYuv(
        yPlaneBytes: image.planes[0].bytes,
        uPlaneBytes: image.planes[1].bytes,
        vPlaneBytes: image.planes[2].bytes,
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: image.planes[1].bytesPerRow,
        bytesPerPixel: image.planes[1].bytesPerPixel!,
        width: image.width,
        height: image.height,
        sensorOrientation: _controller!.description.sensorOrientation,
      );
    } catch (e) {
      debugPrint('Error detecting landmarks: $e');
    } finally {
      _isDetecting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = _controller!;
    final previewSize = controller.value.previewSize!;
    final previewAspectRatio = previewSize.height / previewSize.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Hand Tracking')),
      body: Center(
        child: AspectRatio(
          aspectRatio: previewAspectRatio,
          child: Stack(
            children: [
              CameraPreview(controller),
              CustomPaint(
                size: Size.infinite,
                painter: LandmarkPainter(
                  result: _latestResult,
                  previewSize: previewSize,
                  lensDirection: controller.description.lensDirection,
                  sensorOrientation: controller.description.sensorOrientation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom painter that renders the hand landmarks and connections from [HandLandmarkerEventResult].
class LandmarkPainter extends CustomPainter {
  LandmarkPainter({
    required this.result,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
  });

  final HandLandmarkerEventResult? result;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;

  @override
  void paint(Canvas canvas, Size size) {
    List<List<HandLandmark>> hands =
        result?.landmarks.map((e) => e.data).toList() ?? [];
    if (hands.isEmpty) return;

    final scale = size.width / previewSize.height;

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 8 / scale
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 4 / scale;

    canvas.save();

    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sensorOrientation * math.pi / 180);

    if (lensDirection == CameraLensDirection.front) {
      canvas.scale(-1, 1);
      canvas.rotate(math.pi);
    }

    canvas.scale(scale);

    final logicalWidth = previewSize.width;
    final logicalHeight = previewSize.height;
    for (var hand in hands) {
      for (HandLandmark landmark in hand) {
        final dx = (landmark.x - 0.5) * logicalWidth;
        final dy = (landmark.y - 0.5) * logicalHeight;
        canvas.drawCircle(Offset(dx, dy), 8 / scale, paint);
      }
      if (hand.length >= 21) {
        for (List<int> connection in HandLandmarkConnections.connections) {
          final start = hand[connection[0]];
          final end = hand[connection[1]];
          final startDx = (start.x - 0.5) * logicalWidth;
          final startDy = (start.y - 0.5) * logicalHeight;
          final endDx = (end.x - 0.5) * logicalWidth;
          final endDy = (end.y - 0.5) * logicalHeight;
          canvas.drawLine(
            Offset(startDx, startDy),
            Offset(endDx, endDy),
            linePaint,
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LandmarkPainter oldDelegate) =>
      oldDelegate.result != result;
}

/// Helper class.
class HandLandmarkConnections {
  static const List<List<int>> connections = [
    [0, 1], [1, 2], [2, 3], [3, 4], // Thumb
    [0, 5], [5, 6], [6, 7], [7, 8], // Index finger
    [5, 9], [9, 10], [10, 11], [11, 12], // Middle finger
    [9, 13], [13, 14], [14, 15], [15, 16], // Ring finger
    [13, 17], [0, 17], [17, 18], [18, 19], [19, 20], // Pinky
  ];
}
