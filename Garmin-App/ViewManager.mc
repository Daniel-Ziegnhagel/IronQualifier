// ViewManager.mc

using Toybox.Lang;
using Toybox.WatchUi;
import Toybox.Lang;

class ViewManager {
    hidden var swimView;
    hidden var bikeView;
    hidden var runView;
    hidden var activeStopwatch;

    function initialize() {
        // Initialisiere die Views
        swimView = new IronmanApp_siebenSwimView();
        swimView.initialize();
        
        bikeView = new IronmanApp_siebenBikeView();
        bikeView.initialize();
        
        runView = new IronmanApp_siebenRunView();
        runView.initialize();
    }

    function getView(viewSymbol as Symbol) {
        if (viewSymbol == :swim) {
            return swimView;
        } else if (viewSymbol == :bike) {
            return bikeView;
        } else if (viewSymbol == :run) {
            return runView;
        }
        return null;
    }

    function stopAllStopwatchesExcept(currentStopwatch) {
        if (currentStopwatch != swimView.swimStopwatch && swimView.swimStopwatch != null) {
            swimView.swimStopwatch.stopTimer();
        }
        if (currentStopwatch != bikeView.bikeStopwatch && bikeView.bikeStopwatch != null) {
            bikeView.bikeStopwatch.stopTimer();
        }
        if (currentStopwatch != runView.runStopwatch && runView.runStopwatch != null) {
            runView.runStopwatch.stopTimer();
        }
        activeStopwatch = currentStopwatch;
    }
}