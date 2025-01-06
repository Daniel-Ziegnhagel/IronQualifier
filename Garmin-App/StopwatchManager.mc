// StopwatchManager.mc

import Toybox.Lang;
import Toybox.System;
using Log4MonkeyC as Log;

module StopwatchManager {
    var activeStopwatch = null;
    var logger = null;

    function initialize() {
        if (logger == null) {
            var config = new Log.Config();
            config.setLogLevel(Log.WARN);
            Log.setLogConfig(config);
            logger = Log.getLogger("StopwatchManager");
        }
    }

    public function startStopwatch(sw) {
        initialize();
        if (activeStopwatch != null) {
            if (activeStopwatch == sw) {
                // Toggle die Stoppuhr
                sw.startOrStop();
                if (!sw.isRunning()) {
                    activeStopwatch = null;
                    logger.debug("StopwatchManager: Stopped the active stopwatch.");
                } else {
                    logger.debug("StopwatchManager: Continued the active stopwatch.");
                }
            } else {
                // Stoppe die aktuelle aktive Stoppuhr und starte die neue
                activeStopwatch.stopTimer();
                logger.debug("StopwatchManager: Stopped previous stopwatch.");
                activeStopwatch = sw;
                sw.startOrStop();
                logger.debug("StopwatchManager: Started new stopwatch.");
            }
        } else {
            // Keine aktive Stoppuhr, starte die neue
            activeStopwatch = sw;
            sw.startOrStop();
            logger.debug("StopwatchManager: Started new stopwatch.");
        }
    }

    public function stopActiveStopwatch() {
        initialize();
        if (activeStopwatch != null) {
            activeStopwatch.stopTimer();
            logger.debug("StopwatchManager: Stopped active stopwatch.");
            activeStopwatch = null;
        }
    }

    public function getActiveStopwatch() {
        initialize();
        return activeStopwatch;
    }
}