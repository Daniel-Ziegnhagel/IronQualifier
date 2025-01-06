import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Position;
import Toybox.Math;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Application.Storage;  
using Rez;
using Log4MonkeyC as Log;
using StopwatchManager;

class IronmanApp_siebenSwimView extends WatchUi.View {
    var swimStopwatch;
    var logger;
    var swimTime;
    var swimTargetSpeed as Float;  // Soll-Geschwindigkeit in km/h
    var results;
    var masterTimer;  // MasterTimer-Instanz

    // Bitmap-Ressourcen für farbige Kreise und Herzsymbol
    var greenCircle;
    var redCircle;
    var yellowCircle;
    var heartBitmap;

    // Vibrationsprofil definieren
    var longVibration;       // Lange Vibration für 3 Sekunden

    // Variablen für die Vibrationslogik
    var underSpeedStartTime as Number = -1; // Zeitpunkt, an dem man unter die Zielgeschwindigkeit gefallen ist
    var vibrationInterval as Number = 20000; // 20 Sekunden in Millisekunden

    function initialize() {
        View.initialize();

        // Logger-Konfiguration initialisieren
        var config = new Log.Config();
        config.setLogLevel(Log.DEBUG); // Setze auf DEBUG für detaillierte Logs
        Log.setLogConfig(config);

        // Logger initialisieren
        logger = Log.getLogger("IronmanApp_siebenSwimView");

        // MasterTimer-Instanz erhalten
        masterTimer = MasterTimer.getInstance();

        // Initialisierung der Stoppuhr
        if (swimStopwatch == null) {
            swimStopwatch = new Stopwatch();
            swimStopwatch.initialize();
            swimStopwatch.setMasterTimer(masterTimer);
        }

        // Laden der farbigen Kreise als Bitmap-Objekte
        greenCircle = new WatchUi.Bitmap({
            :rezId => Rez.Drawables.GreenCircle,
            :locX => 0,
            :locY => 0
        });

        redCircle = new WatchUi.Bitmap({
            :rezId => Rez.Drawables.RedCircle,
            :locX => 0,
            :locY => 0
        });

        yellowCircle = new WatchUi.Bitmap({
            :rezId => Rez.Drawables.YellowCircle,
            :locX => 0,
            :locY => 0
        });

        // Laden des Herz-Symbols als Bitmap-Objekt
        heartBitmap = new WatchUi.Bitmap({
            :rezId => Rez.Drawables.Heart,
            :locX => 0, // später anpassen
            :locY => 0
        });

        // Vibrationsprofil initialisieren
        longVibration = new Attention.VibeProfile(100, 3000);

        // Daten aus dem Storage laden
        results = Application.Storage.getValue("results") as Dictionary;

        if (results != null) {
            if (results.hasKey("swim_time")) {
                swimTime = results.get("swim_time") as String;
                System.println("Geladene swimTime: " + swimTime);
            } else {
                swimTime = "0:00:00";
            }

            // Berechnung der Zielgeschwindigkeit
            if (results.hasKey("swim_time_seconds")) {
                var swimTimeInSeconds = (results.get("swim_time_seconds") as Number).toFloat();
                System.println("Geladene swimTimeInSeconds: " + swimTimeInSeconds);

                if (swimTimeInSeconds > 0.0) {
                    swimTargetSpeed = calculateTargetSpeed(3.8 as Float, swimTimeInSeconds);
                    System.println("Berechnete swimTargetSpeed: " + swimTargetSpeed + " km/h");
                } else {
                    System.println("Ungültige swimTimeInSeconds, setze swimTargetSpeed auf 0.");
                    swimTargetSpeed = 0.0;
                }
            } else {
                System.println("swim_time_seconds nicht in Daten gefunden, setze swimTargetSpeed auf 0.");
                swimTargetSpeed = 0.0;
            }
        } else {
            System.println("Keine gespeicherten Daten gefunden. Bitte synchronisieren Sie die App.");
            swimTime = "0:00:00";
            swimTargetSpeed = 0.0;
        }

        // GPS-Ortung aktivieren
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onShow() as Void {
        logger.debug("IronmanApp_siebenSwimView onShow called");
        masterTimer.addObserver(self);
        masterTimer.start();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        logger.debug("IronmanApp_siebenSwimView onUpdate called");
        View.onUpdate(dc);

        // Hintergrund
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Titel + Target
        var centerX = Math.round(dc.getWidth() / 2);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(centerX, 30, Graphics.FONT_LARGE, "Swim", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, 90, Graphics.FONT_SMALL, "Target: " + swimTime, Graphics.TEXT_JUSTIFY_CENTER);

        // Stoppuhr
        swimStopwatch.drawStopwatch(dc);

        // Aktuelle Geschwindigkeit
        var positionInfo = Position.getInfo();
        var currentSpeed = 0.0;

        if (positionInfo != null && positionInfo.speed != null) {
            var rawSpeed = positionInfo.speed; // m/s
            logger.debug("Rohgeschwindigkeit (m/s): " + rawSpeed);
            currentSpeed = rawSpeed * 3.6;  // in km/h
            logger.debug("Umgerechnete Geschwindigkeit (km/h): " + currentSpeed);

            // Validierung
            if (currentSpeed < 0 || currentSpeed > 1000) {
                logger.warn("Unrealistische Geschwindigkeit erkannt: " + currentSpeed);
                currentSpeed = 0.0;
            }
        }

        var formattedSpeed = currentSpeed.format("%.1f");
        var speedStr = Lang.format("$1$ km/h", [formattedSpeed]);
        dc.drawText(125, 155, Graphics.FONT_MEDIUM, speedStr, Graphics.TEXT_JUSTIFY_CENTER);

        // BPM + Herz
        var activityInfo = Activity.getActivityInfo();
        var currentBPM = activityInfo != null ? activityInfo.currentHeartRate : null;
        if (currentBPM == null) {
            currentBPM = 0;
        } else {
            currentBPM = currentBPM.toNumber();
        }
        if (currentBPM < 30 || currentBPM > 220) {
            currentBPM = 0;
        }

        var bpmStr = Lang.format("$1$", [currentBPM]);
        dc.drawText(330, 155, Graphics.FONT_MEDIUM, bpmStr, Graphics.TEXT_JUSTIFY_CENTER);

        heartBitmap.setLocation(245, 170);
        heartBitmap.draw(dc);

        // Roter/Grüner Kreis
        if (swimTargetSpeed > 0.0) {
            var xPos = centerX - 40;
            var yPos = 220;

            // if (swimStopwatch.isRunning()) { ... } // optional

            if (currentSpeed <= swimTargetSpeed) {
                redCircle.setLocation(xPos, yPos);
                redCircle.draw(dc);

                var currentTime = System.getTimer();
                if (underSpeedStartTime == -1) {
                    underSpeedStartTime = currentTime;
                } else {
                    var elapsedTime = currentTime - underSpeedStartTime;
                    if (elapsedTime >= vibrationInterval && currentSpeed > 0.0) {
                        Attention.vibrate([longVibration]);
                        underSpeedStartTime = currentTime;
                    }
                }

            } else {
                greenCircle.setLocation(xPos, yPos);
                greenCircle.draw(dc);
                if (underSpeedStartTime != -1) {
                    underSpeedStartTime = -1;
                }
            }
        } else {
            // Entfernt: Kein "Zielgeschwindigkeit ungültig"-Text mehr
            underSpeedStartTime = -1;
        }
    }

    function onHide() as Void {
        logger.debug("IronmanApp_siebenSwimView onHide called.");
        if (masterTimer != null) {
            masterTimer.removeObserver(self);
        }
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        logger.debug("IronmanApp_siebenSwimView onKey called: " + evt.getKey().toString());

        if (evt.getKey() == WatchUi.KEY_START) {
            StopwatchManager.startStopwatch(swimStopwatch);
            return true;
        }
        return false;
    }

    // Timer-Update
    function updateOnMasterTimer() {
        System.println("MasterTimer tick - SwimView updated.");
        WatchUi.requestUpdate();
    }

    // Position
    function onPosition(info as Position.Info) as Void {
        if (info != null && info.position != null) {
            var myLocation = info.position.toDegrees();
            System.println("Latitude: " + myLocation[0]);
            System.println("Longitude: " + myLocation[1]);
            System.println("Speed: " + (info.speed * 3.6) + " km/h");
        }
    }

    // Berechnung
    function calculateTargetSpeed(distance as Float, targetTime as Float) as Float {
        if (distance <= 0.0 || targetTime <= 0.0) {
            return 0.0 as Float;
        }
        var hours = targetTime / 3600.0;
        if (hours < 0.001) {
            return 0.0 as Float;
        }
        return (distance / hours).toFloat();
    }
}
