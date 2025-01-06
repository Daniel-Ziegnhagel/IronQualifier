// JsonUtils.kt
package com.iron.qualifier

import android.content.Context
import org.json.JSONObject
import java.io.File

fun createJson(medians: Map<String, Any>): String {
    val jsonObject = JSONObject()

    // Fügen alle Schlüssel-Wert-Paare aus medians hinzu
    for ((key, value) in medians) {
        jsonObject.put(key, value)
    }

    return jsonObject.toString()
}

fun saveJsonToFile(context: Context, fileName: String, jsonData: String) {
    val file = File(context.filesDir, fileName)
    file.writeText(jsonData)
}
