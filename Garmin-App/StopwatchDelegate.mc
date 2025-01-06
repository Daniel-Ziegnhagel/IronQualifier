// StopwatchDelegate.mc

import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
using Log4MonkeyC as Log;
import StopwatchManager; // Importiere das StopwatchManager-Modul
// import HeartRateManager; // Importiere die HeartRateManager-Klasse

class StopwatchDelegate extends WatchUi.BehaviorDelegate {
    hidden var swimView;
    hidden var bikeView;
    hidden var runView;
    hidden var viewIndex;
    hidden var logger;

    function initialize() {
        BehaviorDelegate.initialize();
        viewIndex = 0;

        // Logger initialisieren
        var config = new Log.Config();
        config.setLogLevel(Log.INFO);
        Log.setLogConfig(config);
        logger = Log.getLogger("StopwatchDelegate");

        // Entferne die Initialisierung des HeartRateManager
        // HeartRateManager.getInstance();

        // Initialisiere die Views nur einmal und speichere sie
        if (swimView == null) {
            swimView = new IronmanApp_siebenSwimView();
            swimView.initialize();
        }

        if (bikeView == null) {
            bikeView = new IronmanApp_siebenBikeView();
            bikeView.initialize();
        }

        if (runView == null) {
            runView = new IronmanApp_siebenRunView();
            runView.initialize();
        }

        logger.info("StopwatchDelegate initialisiert");
    }

    function onKey(evt) as Boolean {
        logger.debug("Taste gedrückt: " + evt.getKey().toString());
        System.println("StopwatchDelegate Taste gedrückt: " + evt.getKey().toString());

        if (WatchUi.KEY_ENTER == evt.getKey()) {
            logger.info("KEY_ENTER erkannt");

            // Starte die Stoppuhr für die aktuelle View und stoppe andere über StopwatchManager
            if (viewIndex == 0 && swimView.swimStopwatch != null) {
                StopwatchManager.startStopwatch(swimView.swimStopwatch);
            } else if (viewIndex == 1 && bikeView.bikeStopwatch != null) {
                StopwatchManager.startStopwatch(bikeView.bikeStopwatch);
            } else if (viewIndex == 2 && runView.runStopwatch != null) {
                StopwatchManager.startStopwatch(runView.runStopwatch);
            }
        } else if (WatchUi.KEY_ESC == evt.getKey()) {
            logger.info("KEY_ESC erkannt");
            handleEscPress();
        } else if (WatchUi.KEY_UP == evt.getKey()) {
            navigateToPreviousView();
        } else if (WatchUi.KEY_DOWN == evt.getKey()) {
            navigateToNextView();
        }

        return true;
    }

    function handleEscPress() as Void {
        // Entferne die aktuelle View, um zum Auswahlmenü zurückzukehren
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        logger.info("Zurück zum Auswahlmenü von einer View.");
    }

    function onSwipe(evt) as Boolean {
        logger.debug("Wisch erkannt: " + evt.getDirection().toString());
        System.println("Wisch erkannt: " + evt.getDirection().toString());

        if (evt.getDirection() == WatchUi.SWIPE_UP) {
            navigateToNextView();  // Zu nächster View navigieren
        } else if (evt.getDirection() == WatchUi.SWIPE_DOWN) {
            navigateToPreviousView();  // Zu vorheriger View navigieren
        }

        return true;  // Zeigt an, dass das Ereignis verarbeitet wurde
    }

    function navigateToPreviousView() as Void {
        var previousViewIndex = (viewIndex + 2) % 3;  // Zyklische Navigation rückwärts (zwischen 3 Views)
        changeView(previousViewIndex);
    }

    function navigateToNextView() as Void {
        var nextViewIndex = (viewIndex + 1) % 3;  // Zyklische Navigation vorwärts (zwischen 3 Views)
        changeView(nextViewIndex);
    }

    function changeView(index as Number) as Void {
        viewIndex = index;

        var newView;

        if (index == 0) {
            if (swimView == null) {
                swimView = new IronmanApp_siebenSwimView();
                swimView.initialize();
            }
            newView = swimView;
        } else if (index == 1) {
            if (bikeView == null) {
                bikeView = new IronmanApp_siebenBikeView();
                bikeView.initialize();
            }
            newView = bikeView;
        } else if (index == 2) {
            if (runView == null) {
                runView = new IronmanApp_siebenRunView();
                runView.initialize();
            }
            newView = runView;
        } else {
            // Fallback für ungültige Indizes
            logger.warn("Ungültiger View-Index: " + index.toString());
            newView = swimView; // Standardmäßig zur SwimView wechseln
        }

        // Verwende switchToView, um die aktuelle View zu ersetzen
        WatchUi.switchToView(newView, self, WatchUi.SLIDE_LEFT);
        logger.info("Zur View mit Index gewechselt: " + index.toString());
    }
}