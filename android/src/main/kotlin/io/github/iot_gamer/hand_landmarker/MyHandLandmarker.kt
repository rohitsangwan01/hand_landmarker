package io.github.iot_gamer.hand_landmarker

import android.content.Context
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.os.Handler
import android.os.SystemClock
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.ImageProcessingOptions
import com.google.mediapipe.tasks.core.OutputHandler
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

class MyHandLandmarker(private val context: Context) :
    OutputHandler.ResultListener<HandLandmarkerResult, MPImage> {

    private var handLandmarker: HandLandmarker? = null
    private var handler: Handler? = null

    fun initialize(
        numHands: Int,
        minHandDetectionConfidence: Float,
        useGpu: Boolean,
    ) {
        val delegate = if (useGpu) Delegate.GPU else Delegate.CPU
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("hand_landmarker.task")
            .setDelegate(delegate)
            .build()
        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setNumHands(numHands)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setMinHandDetectionConfidence(minHandDetectionConfidence)
            .setResultListener(this)
            .build()
        handLandmarker = HandLandmarker.createFromOptions(context, options)
        handler = Handler(context.mainLooper)
    }

    override fun run(
        result: HandLandmarkerResult?,
        input: MPImage?,
    ) {
        if (result != null && !result.landmarks().isEmpty()) {
            handler?.post {
                HandLandmarkerResultBridge.sendResult(result)
            }
        }
    }

    /**
     * Detects hand landmarks from a NV21 video frame.
     */
    fun detectFromNv21VideoFrame(
        data: ByteArray,
        width: Int,
        height: Int,
        rotation: Int,
    ) {
        if (handLandmarker == null) {
            initialize(2, 0.5f, true)
        }
        val yuvImage = YuvImage(data, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, out)
        val imageBytes = out.toByteArray()
        val bitmap =
            android.graphics.BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        val mpImage = BitmapImageBuilder(bitmap).build()
        val imageProcessingOptions = ImageProcessingOptions.builder()
            .setRotationDegrees(rotation)
            .build()
        val frameTime = SystemClock.uptimeMillis()
        handLandmarker?.detectAsync(mpImage, imageProcessingOptions, frameTime)
        bitmap.recycle()
        mpImage.close()
    }

    /**
     * Detects hand landmarks from YUV image planes.
     * This method is more efficient as it avoids YUV->RGBA conversion in Dart.
     */
    fun detectFromYuv(
        yBuffer: ByteBuffer,
        uBuffer: ByteBuffer,
        vBuffer: ByteBuffer,
        width: Int,
        height: Int,
        yRowStride: Int,
        uvRowStride: Int,
        uvPixelStride: Int,
        rotation: Int,
    ) {
        if (handLandmarker == null) {
            // Default initialization if not already configured
            initialize(2, 0.5f, true)
        }
        // 1. Convert YUV planes to a Bitmap.
        val yuvBytes = convertYuvToNv21(
            yBuffer,
            uBuffer,
            vBuffer,
            width,
            height,
            yRowStride,
            uvRowStride,
            uvPixelStride
        )
        detectFromNv21VideoFrame(
            yuvBytes,
            width,
            height,
            rotation
        )
    }

    /**
     * Helper function to convert YUV planes from Flutter's CameraImage to a single NV21 byte array.
     * NV21 format is required by Android's YuvImage class.
     */
    private fun convertYuvToNv21(
        yBuffer: ByteBuffer,
        uBuffer: ByteBuffer,
        vBuffer: ByteBuffer,
        width: Int,
        height: Int,
        yRowStride: Int,
        uvRowStride: Int,
        uvPixelStride: Int,
    ): ByteArray {
        val nv21Bytes = ByteArray(width * height * 3 / 2)
        var yIndex = 0
        val yPlaneSize = width * height

        // Copy Y plane
        for (y in 0 until height) {
            val yRow = y * yRowStride
            yBuffer.position(yRow)
            yBuffer.get(nv21Bytes, yIndex, width)
            yIndex += width
        }

        // Copy U and V planes
        var uvIndex = yPlaneSize
        val uvHeight = height / 2
        val uvWidth = width / 2

        for (y in 0 until uvHeight) {
            for (x in 0 until uvWidth) {
                val uIndex = y * uvRowStride + x * uvPixelStride
                val vIndex = y * uvRowStride + x * uvPixelStride
                // In NV21, V plane comes first, then U plane
                nv21Bytes[uvIndex++] = vBuffer[vIndex]
                nv21Bytes[uvIndex++] = uBuffer[uIndex]
            }
        }
        return nv21Bytes
    }
}