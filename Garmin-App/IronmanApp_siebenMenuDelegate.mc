// IronmanApp_siebenMenuDelegate.mc

import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
// Entferne alle ungültigen Import-Anweisungen für Klassen

class IronmanApp_siebenMenuDelegate extends WatchUi.MenuInputDelegate {
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        System.println("Menu item selected: " + item.toString());

        if (item == :item_1) {  // Kona Auswahl
            System.println("Kona selected, navigating to SwimView.");
            var swimView = new IronmanApp_siebenSwimView(); 
            swimView.initialize(); 
            var delegate = new StopwatchDelegate(); // Neue Delegate-Instanz
            WatchUi.pushView(swimView, delegate, WatchUi.SLIDE_UP);
        } else if (item == :item_2) {  // 70.3 Auswahl
            System.println("70.3 selected, but currently not implemented.");
            // Aktuell keine Aktion. In Zukunft kann hier eine andere View oder ein anderer View-Stack implementiert werden.
            // Optional: Zeige eine Toast-Nachricht an
            // WatchUi.showToast("70.3 ist noch nicht verfügbar.", { :icon := WatchUi.BITMAP_NONE });
        } else {
            System.println("Unknown item selected.");
        }
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        System.println("MenuDelegate onKey called: " + evt.getKey().toString());

        if (evt.getKey() == WatchUi.KEY_ESC) {
            System.println("Exiting the app from selection menu.");
            System.exit(); // Beende die App direkt
        }

        return false;
    }
}