package io.github.iot_gamer.hand_landmarker

import com.google.mediapipe.tasks.components.containers.Category
import com.google.mediapipe.tasks.components.containers.Landmark
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import io.flutter.plugin.common.EventChannel
import java.util.ArrayList
import kotlin.jvm.optionals.getOrNull

/**
 * Bridge used by [MyHandLandmarker] to send results to Dart via [EventChannel.EventSink].
 * The plugin sets the sink when Dart subscribes to the results stream.
 */
object HandLandmarkerResultBridge {
    @Volatile
    var resultSink: PigeonEventSink<HandLandmarkerEventResult>? = null
        private set

    fun setSink(sink: PigeonEventSink<HandLandmarkerEventResult>?) {
        resultSink = sink
    }

    fun sendResult(result: HandLandmarkerResult) {
        val sink = resultSink ?: return
        sink.success(result.toDartEvent())
    }
}


// Convert MediaPipe Object to Dart Object
fun HandLandmarkerResult.toDartEvent(): HandLandmarkerEventResult {
    return HandLandmarkerEventResult(
        timestampMs = this.timestampMs(),
        landmarks = this.landmarks().map { landmarks ->
            HandLandmarkList(
                landmarks.map { it.toDartLandmark() }
            )
        },
        worldLandmarks = this.worldLandmarks().map { landmarks ->
            HandLandmarkList(
                landmarks.map { it.toDartLandmark() }
            )
        },
        handedness = this.handedness().map { handedness ->
            HandLandmarkCategoryList(
                handedness.map { it.toDartCategory() }
            )
        }
    )
}

fun NormalizedLandmark.toDartLandmark(): HandLandmark {
    return HandLandmark(
        this.x().toDouble(),
        this.y().toDouble(),
        this.z().toDouble(),
        this.visibility().getOrNull()?.toDouble(),
        this.presence().getOrNull()?.toDouble()
    )
}

fun Landmark.toDartLandmark(): HandLandmark {
    return HandLandmark(
        this.x().toDouble(),
        this.y().toDouble(),
        this.z().toDouble(),
        this.visibility().getOrNull()?.toDouble(),
        this.presence().getOrNull()?.toDouble()
    )
}

fun Category.toDartCategory(): HandLandmarkCategory {
    return HandLandmarkCategory(
        this.score().toDouble(),
        this.index().toLong(),
        this.categoryName(),
        this.displayName()
    )
}