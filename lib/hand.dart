enum HandLandmarkerDelegate { cpu, gpu }

/// Represents the keyPoints of the MediaPipe Hand Landmarker model.
///
/// Each enum value corresponds to a specific landmark on the hand and holds its
/// integer index according to the model's output.
///
/// Reference: https://ai.google.dev/edge/mediapipe/solutions/vision/hand_landmarker#models
enum HandLandmarkIndex {
  wrist(0),
  thumbCmc(1),
  thumbMcp(2),
  thumbIp(3),
  thumbTip(4),
  indexFingerMcp(5),
  indexFingerPip(6),
  indexFingerDip(7),
  indexFingerTip(8),
  middleFingerMcp(9),
  middleFingerPip(10),
  middleFingerDip(11),
  middleFingerTip(12),
  ringFingerMcp(13),
  ringFingerPip(14),
  ringFingerDip(15),
  ringFingerTip(16),
  pinkyMcp(17),
  pinkyPip(18),
  pinkyDip(19),
  pinkyTip(20);

  final int value;
  const HandLandmarkIndex(this.value);
}
