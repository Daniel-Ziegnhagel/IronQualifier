// Extensions.kt
package com.iron.qualifier

import org.json.JSONArray
import org.json.JSONObject

// Erweiterungsfunktion zum Konvertieren von JSON in Map
fun JSONObject.toMap(): Map<String, Any?> = keys().asSequence().associateWith { key ->
    when (val value = this[key]) {
        is JSONArray -> value.toList()
        is JSONObject -> value.toMap()
        JSONObject.NULL -> null
        else -> value
    }
}

// Erweiterungsfunktion zum Konvertieren von JSONArray in List<Any?>
fun JSONArray.toList(): List<Any?> = (0 until length()).map { i ->
    when (val value = get(i)) {
        is JSONArray -> value.toList()
        is JSONObject -> value.toMap()
        JSONObject.NULL -> null
        else -> value
    }
}
