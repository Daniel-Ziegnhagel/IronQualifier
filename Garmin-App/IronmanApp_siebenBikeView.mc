// IronmanApp_siebenBikeView.mc

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

using Rez;              // Für Drawables (Kreise, Herz)
using Log4MonkeyC as Log;
using StopwatchManager;

class IronmanApp_siebenBikeView extends WatchUi.View {
    var bikeStopwatch;
    var logger;
    var bikeTime;
    var bikeTargetSpeed as Float;  // berechnete Soll-Geschwindigkeit km/h
    var results;                   // Dictionary aus Storage
    var masterTimer;               // MasterTimer-Instanz

    // Bitmap-Ressourcen (grüner/roter/gelber Kreis, Herz)
    var greenCircle;
    var redCircle;
    var yellowCircle;
    var heartBitmap;

    // Vibrationsprofil
    var longVibration;  // Lange Vibration (3s)

    // Variablen für die Vibrationslogik
    var underSpeedStartTime as Number = -1;
    var vibrationInterval as Number = 20000;  // 20s in Millisekunden

    function initialize() {
        View.initialize();

        // Logger-Konfiguration
        var config = new Log.Config();
        config.setLogLevel(Log.DEBUG);
        Log.setLogConfig(config);
        logger = Log.getLogger("IronmanApp_siebenBikeView");

        // MasterTimer
        masterTimer = MasterTimer.getInstance();

        // Stoppuhr
        if (bikeStopwatch == null) {
            bikeStopwatch = new Stopwatch();
            bikeStopwatch.initialize();
            bikeStopwatch.setMasterTimer(masterTimer);
        }

        // Kreise laden
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

        // Herzsymbol
        heartBitmap = new WatchUi.Bitmap({
            :rezId => Rez.Drawables.Heart,
            :locX => 0,
            :locY => 0
        });

        // Vibration
        longVibration = new Attention.VibeProfile(100, 3000);

        // +++ Neu: Daten aus dem Storage holen +++
        results = Application.Storage.getValue("results") as Lang.Dictionary;

        if (results != null) {
            // Bike-Zeit (String)
            if (results.hasKey("bike_time")) {
                bikeTime = results.get("bike_time") as String;
                System.println("Geladene bikeTime: " + bikeTime);
            } else {
                bikeTime = "0:00:00";  // Fallback
            }

            // Bike-Zeit in Sekunden => bikeTargetSpeed
            if (results.hasKey("bike_time_seconds")) {
                var bikeTimeInSeconds = (results.get("bike_time_seconds") as Number).toFloat();
                System.println("Geladene bikeTimeInSeconds: " + bikeTimeInSeconds);

                if (bikeTimeInSeconds > 0.0) {
                    // Für den Ironman: 180 km Raddistanz
                    bikeTargetSpeed = calculateTargetSpeed(180.0 as Float, bikeTimeInSeconds);
                    System.println("Berechnete bikeTargetSpeed: " + bikeTargetSpeed + " km/h");
                } else {
                    System.println("bike_time_seconds ist 0 oder ungültig, setze bikeTargetSpeed auf 0.");
                    bikeTargetSpeed = 0.0;
                }
            } else {
                System.println("bike_time_seconds nicht in Daten gefunden, setze bikeTargetSpeed auf 0.");
                bikeTargetSpeed = 0.0;
            }

        } else {
            System.println("Keine gespeicherten Daten vorhanden. Bitte synchronisieren.");
            bikeTime = "0:00:00";
            bikeTargetSpeed = 0.0;
        }

        // GPS aktivieren (Geschwindigkeit)
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onShow() as Void {
        logger.debug("IronmanApp_siebenBikeView onShow called");
        masterTimer.addObserver(self);
        masterTimer.start();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        logger.debug("IronmanApp_siebenBikeView onUpdate called");
        View.onUpdate(dc);

        // Hintergrund
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Titel + Target
        var centerX = Math.round(dc.getWidth() / 2);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(centerX, 30, Graphics.FONT_LARGE, "Bike", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, 90, Graphics.FONT_SMALL, "Target: " + bikeTime, Graphics.TEXT_JUSTIFY_CENTER);

        // Zeichne Stoppuhr
        bikeStopwatch.drawStopwatch(dc);

        // Anzeige der aktuellen Geschwindigkeit
        var positionInfo = Position.getInfo();
        var currentSpeed = 0.0;

        if (positionInfo != null && positionInfo.speed != null) {
            var rawSpeed = positionInfo.speed; // m/s
            logger.debug("Rohgeschwindigkeit (m/s): " + rawSpeed);

            currentSpeed = rawSpeed * 3.6; // in km/h
            logger.debug("Umgerechnete Geschwindigkeit (km/h): " + currentSpeed);

            // Validierung
            if (currentSpeed < 0 || currentSpeed > 1000) {
                logger.warn("Unrealistische Geschwindigkeit: " + currentSpeed);
                currentSpeed = 0.0;
            }
        }

        // Geschwindigkeit ausgeben
        var formattedSpeed = currentSpeed.format("%.1f");
        var speedStr = Lang.format("$1$ km/h", [formattedSpeed]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(125, 155, Graphics.FONT_MEDIUM, speedStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Herzfrequenz
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

        // Herzsymbol platzieren
        heartBitmap.setLocation(245, 170);
        heartBitmap.draw(dc);

        // Rot/Grün-Kreisanzeige
        if (bikeTargetSpeed > 0.0) {
            var xPos = centerX - 40;
            var yPos = 220;

            if (currentSpeed <= bikeTargetSpeed) {
                // Roter Kreis
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
                // Grüner Kreis
                greenCircle.setLocation(xPos, yPos);
                greenCircle.draw(dc);

                // Reset
                if (underSpeedStartTime != -1) {
                    underSpeedStartTime = -1;
                }
            }
        } else {
            // Keine Kreisanzeige, wenn bikeTargetSpeed = 0.0
            underSpeedStartTime = -1;
        }
    }

    function onHide() as Void {
        logger.debug("IronmanApp_siebenBikeView onHide called.");
        if (masterTimer != null) {
            masterTimer.removeObserver(self);
        }
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        logger.debug("IronmanApp_siebenBikeView onKey called: " + evt.getKey().toString());
        System.println("Key pressed: " + evt.getKey().toString());

        if (evt.getKey() == WatchUi.KEY_START) {
            // Start/Stop
            StopwatchManager.startStopwatch(bikeStopwatch);
            return true;
        }
        return false;
    }

    // Vom MasterTimer aufgerufen
    function updateOnMasterTimer() {
        System.println("MasterTimer tick - BikeView updated.");
        WatchUi.requestUpdate();
    }

    // Positionsdaten
    function onPosition(info as Position.Info) as Void {
        if (info != null && info.position != null) {
            var myLocation = info.position.toDegrees();
            System.println("Lat: " + myLocation[0] + ", Lon: " + myLocation[1]);
            System.println("Speed: " + (info.speed * 3.6) + " km/h");
        }
    }

    // Berechnet die Soll-Geschwindigkeit (km/h)
    // z.B. distance=180.0 km (Ironman-Bike), targetTime=bikeTimeInSec
    function calculateTargetSpeed(distance as Float, targetTime as Float) as Float {
        System.println("Calculating bike target speed...");
        System.println("Distance: " + distance + " km, Target Time: " + targetTime + " seconds");

        if (distance <= 0.0 || targetTime <= 0.0) {
            return 0.0 as Float;
        }

        var hours = targetTime / 3600.0;
        if (hours < 0.001) {
            return 0.0 as Float;
        }

        var targetSpeed = distance / hours;
        System.println("Calculated bike target speed: " + targetSpeed + " km/h");
        return targetSpeed.toFloat();
    }
}
