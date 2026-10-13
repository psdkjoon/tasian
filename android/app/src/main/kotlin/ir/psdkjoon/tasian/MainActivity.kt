package ir.psdkjoon.tasian

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return EngineHolder.ensure(context)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        EngineHolder.activity = this
    }

    override fun onPostResume() {
        super.onPostResume()
        EngineHolder.activity = this
        EngineHolder.installIfWaiting()
    }

    override fun onDestroy() {
        if (EngineHolder.activity === this) EngineHolder.activity = null
        super.onDestroy()
    }
}
