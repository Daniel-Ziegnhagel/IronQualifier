// XmlParser.kt
package com.iron.qualifier

import android.content.Context
import org.xmlpull.v1.XmlPullParser
import java.io.InputStream

fun parseXml(context: Context, fileName: String): List<RaceResult> {
    val results = mutableListOf<RaceResult>()
    try {
        val inputStream: InputStream = context.assets.open(fileName)
        val parser = org.xmlpull.v1.XmlPullParserFactory.newInstance().newPullParser()
        parser.setInput(inputStream, null)

        var eventType = parser.eventType
        var currentResult: MutableMap<String, String> = mutableMapOf()
        var currentTag: String? = null

        while (eventType != XmlPullParser.END_DOCUMENT) {
            val tagName = parser.name
            when (eventType) {
                XmlPullParser.START_TAG -> {
                    currentTag = tagName
                    if (tagName == "result") {
                        currentResult = mutableMapOf()
                    }
                }
                XmlPullParser.TEXT -> {
                    val text = parser.text.trim()
                    if (currentTag != null && text.isNotEmpty()) {
                        currentResult[currentTag!!] = text
                    }
                }
                XmlPullParser.END_TAG -> {
                    if (tagName == "result") {
                        val result = RaceResult(
                            overallTime = currentResult["overall_time"] ?: "",
                            swimTime = currentResult["swim_time"] ?: "",
                            bikeTime = currentResult["bike_time"] ?: "",
                            runTime = currentResult["run_time"] ?: "",
                            ageGroup = currentResult["age_group"] ?: "",
                            gender = currentResult["gender"] ?: ""
                        )
                        results.add(result)
                    }
                    currentTag = null
                }
            }
            eventType = parser.next()
        }
        inputStream.close()
    } catch (e: Exception) {
        e.printStackTrace()
    }
    return results
}