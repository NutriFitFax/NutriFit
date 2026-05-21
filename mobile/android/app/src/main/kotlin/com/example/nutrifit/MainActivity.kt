package com.example.nutrifit

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
    }

    // Some devices reset the preferred mode before onResume, so apply it again.
    override fun onResume() {
        super.onResume()
        enableHighRefreshRate()
    }

    private fun enableHighRefreshRate() {
        val attrs = window.attributes

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val modes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display?.supportedModes
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.supportedModes
            }

            val best = modes?.maxByOrNull { it.refreshRate }
            if (best != null) {
                attrs.preferredDisplayModeId = best.modeId
                attrs.preferredRefreshRate = best.refreshRate
            } else {
                // No mode enumeration — request highest rate as a float hint.
                attrs.preferredRefreshRate = Float.MAX_VALUE
            }
        } else {
            // API 21-22: preferredRefreshRate only, no mode IDs.
            attrs.preferredRefreshRate = Float.MAX_VALUE
        }

        window.attributes = attrs
    }
}
