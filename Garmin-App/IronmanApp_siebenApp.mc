// IronmanApp_siebenApp.mc

import Toybox.Application;
import Toybox.System;
import Toybox.Communications;       // Korrektes Kommunikationsmodul
import Toybox.Application.Storage;  // Korrektes Storage-Modul
import Toybox.Lang;

class IronmanApp_siebenApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();

        // Registrierung für eingehende Nachrichten vom Telefon
        Communications.registerForPhoneAppMessages(method(:onReceive));
    }

    // Callback-Funktion für eingehende Nachrichten
    function onReceive(message as Communications.PhoneAppMessage) as Void {
        System.println("Nachricht vom Telefon empfangen.");

        var data = message.data as Lang.Dictionary;

        if (data != null) {
            // Speichern der empfangenen Daten im Storage
            Application.Storage.setValue("results", data);
            System.println("Daten im Storage gespeichert.");
        } else {
            System.println("Empfangene Daten sind null.");
        }
    }

    // Korrekte onStart-Methode
    function onStart(state as Lang.Dictionary or Null) as Void {
        AppBase.onStart(state);
        // Hier können Sie zusätzlichen Code hinzufügen, falls erforderlich
    }

    // Korrekte onStop-Methode
    function onStop(state as Lang.Dictionary or Null) as Void {
        // Hier können Sie zusätzlichen Code hinzufügen, falls erforderlich
        AppBase.onStop(state);
    }

    function getInitialView() {
        return [ new IronmanApp_siebenView(), new IronmanApp_siebenDelegate() ];
    }
}
