package ir.psdkjoon.tasian

import android.app.Application

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        EngineHolder.ensure(this)
    }
}
