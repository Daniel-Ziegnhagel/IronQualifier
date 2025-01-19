// siebenViewDelegate.mc

import Toybox.WatchUi;

class IronmanApp_siebenViewDelegate extends WatchUi.BehaviorDelegate {
    hidden var stopwatch;
    hidden var logger;

    function initialize(stopwatchInstance) {
        WatchUi.BehaviorDelegate.initialize();
        self.stopwatch = stopwatchInstance;
        // logger = Log.getLogger("IronmanApp_siebenViewDelegate");
    }

    function onKey(evt) {
        logger.debug("Key press: " + evt.getKey());
        if (WatchUi.KEY_START == evt.getKey()) {
            stopwatch.startOrStop();
        } else if (WatchUi.KEY_UP == evt.getKey() || WatchUi.KEY_MENU == evt.getKey()) {
            
        }
        return true;
    }
}