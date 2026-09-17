// android/app/src/main/kotlin/com/example/niceplace_app/MainApplication.kt
// POORA FILE REPLACE KARO:

package com.example.niceplace_app

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        registerActivityLifecycleCallbacks(object : ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                // targetSdk 36 makes edge-to-edge mandatory - opting out via the
                // window theme/flag no longer works. Instead, we directly pad
                // UCropActivity's root content view by the system bar insets, so
                // its toolbar and bottom controls are pushed clear of them.
                if (activity.javaClass.name == "com.yalantis.ucrop.UCropActivity") {
                    val content = activity.findViewById<View>(android.R.id.content)
                    if (content != null) {
                        ViewCompat.setOnApplyWindowInsetsListener(content) { view, insets ->
                            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
                            view.setPadding(0, systemBars.top, 0, systemBars.bottom)
                            insets
                        }
                        ViewCompat.requestApplyInsets(content)
                    }
                }
            }

            override fun onActivityStarted(activity: Activity) {}
            override fun onActivityResumed(activity: Activity) {}
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivityStopped(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {}
        })
    }
}