// Calculator.kt
package com.iron.qualifier

import kotlin.math.roundToLong

fun parseTime(timeStr: String): Long? {
    return try {
        val parts = timeStr.split(":").map { it.toInt() }
        when (parts.size) {
            3 -> parts[0] * 3600L + parts[1] * 60L + parts[2]
            2 -> parts[0] * 60L + parts[1]
            else -> null
        }
    } catch (e: Exception) {
        null
    }
}

fun medianTimes(results: List<RaceResult>, ageGroup: String): Map<String, Any> {
    val filteredResults = results.filter { it.ageGroup == ageGroup }

    if (filteredResults.isEmpty()) {
        return mapOf(
            "swim_time" to "nicht vorhanden",
            "bike_time" to "nicht vorhanden",
            "run_time" to "nicht vorhanden"
        )
    }

    val swimTimes = filteredResults.mapNotNull { parseTime(it.swimTime) }
    val bikeTimes = filteredResults.mapNotNull { parseTime(it.bikeTime) }
    val runTimes = filteredResults.mapNotNull { parseTime(it.runTime) }

    val medianSwimTime = swimTimes.median()
    val medianBikeTime = bikeTimes.median()
    val medianRunTime = runTimes.median()

    fun formatSecondsToTime(seconds: Long): String {
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        val secs = seconds % 60
        return String.format("%d:%02d:%02d", hours, minutes, secs)
    }

    return mapOf(
        "swim_time" to formatSecondsToTime(medianSwimTime),
        "bike_time" to formatSecondsToTime(medianBikeTime),
        "run_time" to formatSecondsToTime(medianRunTime)
    )
}

fun List<Long>.median(): Long {
    if (this.isEmpty()) return 0L
    val sortedList = this.sorted()
    val middle = size / 2
    return if (size % 2 == 0) {
        ((sortedList[middle - 1] + sortedList[middle]) / 2.0).roundToLong()
    } else {
        sortedList[middle]
    }
}