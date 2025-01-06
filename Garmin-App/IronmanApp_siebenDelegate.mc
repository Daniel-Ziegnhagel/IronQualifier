// IronmanApp_siebenDelegate.mc

import Toybox.Lang;
import Toybox.WatchUi;

class IronmanApp_siebenDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        // Alle Views schließen, um zum Hauptmenü zurückzukehren
        while (WatchUi.getCurrentView() != null) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        return true;  // Zeigt an, dass die Rückwärts-Aktion verarbeitet wurde
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new IronmanApp_siebenMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}