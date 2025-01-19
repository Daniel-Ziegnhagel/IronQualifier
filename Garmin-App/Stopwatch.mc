import Toybox.Math;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Timer;
import Toybox.Lang;

class Stopwatch {
    hidden var stopwatchTime = 0;   // Zeit in Sekunden
    hidden var running = false;
    hidden var masterTimer;         // Referenz auf den MasterTimer
    // hidden var logger;          <--- Entfernt

    function initialize() {
        System.println("Stopwatch initialized");
    }

    // Methode zum Setzen des MasterTimers
    function setMasterTimer(masterTimerInstance) {
        masterTimer = masterTimerInstance;
        System.println("MasterTimer set in Stopwatch");
    }

    function isRunning() as Boolean {
        return running;
    }

    function startOrStop() {
        running = !running;
        if (running) {
            System.println("Stopwatch started");
            if (masterTimer != null) {
                masterTimer.addObserver(self);  // Als Beobachter registrieren
            } else {
                System.println("Error: masterTimer is null in startOrStop");
            }
        } else {
            System.println("Stopwatch stopped");
            if (masterTimer != null) {
                masterTimer.removeObserver(self);  // Beobachter entferne
            } else {
                System.println("Error: masterTimer is null in startOrStop");
            }
        }
    }

    function stopTimer() {
        // Methode zum manuellen Stoppen der Stoppuhr
        if (running) {
            running = false;
            if (masterTimer != null) {
                masterTimer.removeObserver(self);  // Beobachter entfernen
                System.println("Stopwatch timer stopped manually");
            } else {
                System.println("Error: masterTimer is null in stopTimer");
            }
        }
    }

    function updateOnMasterTimer() {
        // Diese Methode wird vom MasterTimer jede Sekunde aufgerufen
        if (running) {
            stopwatchTime += 1;  // Zeit um eine Sekunde erhöhen
            System.println("Stopwatch time updated: " + stopwatchTime.toString());

            // Die View, die diese Stoppuhr verwendet, muss aktualisiert werden
            WatchUi.requestUpdate();
        } else {
            System.println("Stopwatch is not running.");
        }
    }

    function drawStopwatch(dc as Graphics.Dc) {
        // Zeichnet die Stoppuhr auf dem Display
        System.println("Stopwatch drawStopwatch called");

        var hours = Math.floor(stopwatchTime / 3600);
        var minutes = Math.floor((stopwatchTime % 3600) / 60);
        var seconds = stopwatchTime % 60;

        var timeString = formatTime(hours, minutes, seconds);

        System.println("Drawing time: " + timeString);  // Debug-Ausgabe

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, 290, Graphics.FONT_LARGE, timeString, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function formatTime(hours as Number, minutes as Number, seconds as Number) as String {
        var hoursStr = (hours < 10) ? "0" + hours.toString() : hours.toString();
        var minutesStr = (minutes < 10) ? "0" + minutes.toString() : minutes.toString();
        var secondsStr = (seconds < 10) ? "0" + seconds.toString() : seconds.toString();
        return hoursStr + ":" + minutesStr + ":" + secondsStr;
    }
}