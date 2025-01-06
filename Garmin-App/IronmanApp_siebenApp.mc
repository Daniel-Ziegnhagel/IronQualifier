// IronmanApp_siebenApp.mc

import Toybox.Application;
import Toybox.System;
import Toybox.Communications;       
import Toybox.Application.Storage;  
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

    function onStart(state as Lang.Dictionary or Null) as Void {
        AppBase.onStart(state);
    }

    function onStop(state as Lang.Dictionary or Null) as Void {
        AppBase.onStop(state);
    }

    function getInitialView() {
        return [ new IronmanApp_siebenView(), new IronmanApp_siebenDelegate() ];
    }
}
