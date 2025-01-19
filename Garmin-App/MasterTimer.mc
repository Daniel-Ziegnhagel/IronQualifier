//MasterTimer.mc

import Toybox.System;
import Toybox.Timer;
import Toybox.Lang;

class MasterTimer {
    hidden var timer;
    hidden var isRunning = false;
    hidden var observers = [];  // Array von Beobachtern
    hidden static var instance;  // Singleton-Instanz

    // Singleton-Muster, um sicherzustellen, dass nur eine Instanz von MasterTimer existiert
    public static function getInstance() as MasterTimer {
        if (MasterTimer.instance == null) {
            MasterTimer.instance = new MasterTimer();  // Erstelle die Singleton-Instanz
            MasterTimer.instance.initialize();
        }
        return MasterTimer.instance;
    }

    // Initialisierung des Timers
    function initialize() {
        if (timer == null) {
            timer = new Timer.Timer();
        }
        System.println("MasterTimer initialized");
    }

    // Überprüfen, ob der Observer bereits in der Liste ist
    function containsObserver(observer) as Boolean {
        for (var i = 0; i < observers.size(); i++) {
            if (observers[i] == observer) {
                return true;
            }
        }
        return false;
    }

    // Beobachter hinzufügen
    function addObserver(observer) {
        if (!containsObserver(observer)) {
            observers.add(observer);  // Beobachter zum Array hinzufügen
            System.println("Observer added");
        }
    }

    // Beobachter entfernen
    function removeObserver(observer) {
        var index = -1;
        for (var i = 0; i < observers.size(); i++) {
            if (observers[i] == observer) {
                index = i;
                break;
            }
        }

        if (index != -1) {
            // Beobachter aus dem Array entfernen
            observers.remove(index);
            System.println("Observer removed");

            if (observers.size() == 0) {
                stop();  // Stoppe den Timer, wenn keine Beobachter mehr vorhanden sind
            }
        } else {
            System.println("Observer not found");
        }
    }

    // Starte den Timer
    function start() {
        if (!isRunning) {
            timer.start(method(:onTimerTick), 1000, true);  // Alle 1 Sekunde ticken
            isRunning = true;
            System.println("MasterTimer gestartet");
        }
    }

    // Stoppe den Timer
    function stop() {
        if (isRunning) {
            timer.stop();
            isRunning = false;
            System.println("MasterTimer gestoppt");
        }
    }

    // Timer-Tick-Methode (wird jede Sekunde aufgerufen)
    function onTimerTick() {
        System.println("MasterTimer tick");

        // Über alle Beobachter iterieren und updateOnMasterTimer aufrufen
        for (var i = 0; i < observers.size(); i++) {
            var observer = observers[i];
            observer.updateOnMasterTimer();
        }
    }
}