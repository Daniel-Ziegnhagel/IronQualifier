//MainActivity
package com.iron.qualifier

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Starten der CalculateActivity
        val intent = Intent(this, CalculateActivity::class.java)
        startActivity(intent)
        finish() // Schließt MainActivity, sodass sie nicht im Back-Stack bleibt
    }
}