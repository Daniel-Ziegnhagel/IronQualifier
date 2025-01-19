import Toybox.Lang;
import Toybox.System;

module StopwatchManager {
    var activeStopwatch = null;

    function initialize() {
    }

    public function startStopwatch(sw) {
        initialize();
        if (activeStopwatch != null) {
            if (activeStopwatch == sw) {
                // Toggle die Stoppuhr
                sw.startOrStop();
                if (!sw.isRunning()) {
                    activeStopwatch = null;
                    System.println("StopwatchManager: Stopped the active stopwatch.");
                } else {
                    System.println("StopwatchManager: Continued the active stopwatch.");
                }
            } else {
                // Stoppe die aktuelle aktive Stoppuhr und starte die neue
                activeStopwatch.stopTimer();
                System.println("StopwatchManager: Stopped previous stopwatch.");
                activeStopwatch = sw;
                sw.startOrStop();
                System.println("StopwatchManager: Started new stopwatch.");
            }
        } else {
            // Keine aktive Stoppuhr, starte die neue
            activeStopwatch = sw;
            sw.startOrStop();
            System.println("StopwatchManager: Started new stopwatch.");
        }
    }

    public function stopActiveStopwatch() {
        initialize();
        if (activeStopwatch != null) {
            activeStopwatch.stopTimer();
            System.println("StopwatchManager: Stopped active stopwatch.");
            activeStopwatch = null;
        }
    }

    public function getActiveStopwatch() {
        initialize();
        return activeStopwatch;
    }
}
