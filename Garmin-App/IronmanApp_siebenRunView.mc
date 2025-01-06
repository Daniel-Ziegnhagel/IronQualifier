// IronmanApp_siebenRunView.mc

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

class IronmanApp_siebenRunView extends WatchUi.View {
    var runStopwatch;
    var logger;
    var runTime;
    var runTargetSpeed as Float;  // berechnete Soll-Geschwindigkeit in km/h
    var results;                  // Dictionary aus dem Storage
    var masterTimer;              // MasterTimer-Instanz

    // Bitmap-Ressourcen (grüner/roter/gelber Kreis, Herzsymbol)
    var greenCircle;
    var redCircle;
    var yellowCircle;
    var heartBitmap;

    // Vibrationsprofil
    var longVibration; // 3 Sekunden

    // Vibrationslogik
    var underSpeedStartTime as Number = -1;
    var vibrationInterval as Number = 20000; // 20s in Millisekunden

    function initialize() {
        View.initialize();

        // Logger einrichten
        var config = new Log.Config();
        config.setLogLevel(Log.DEBUG);
        Log.setLogConfig(config);
        logger = Log.getLogger("IronmanApp_siebenRunView");

        // MasterTimer
        masterTimer = MasterTimer.getInstance();

        // Stoppuhr
        if (runStopwatch == null) {
            runStopwatch = new Stopwatch();
            runStopwatch.initialize();
            runStopwatch.setMasterTimer(masterTimer);
        }

        // Kreise und Herz laden
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

        heartBitmap = new WatchUi.Bitmap({
            :rezId => Rez.Drawables.Heart,
            :locX => 0,
            :locY => 0
        });

        // Vibration
        longVibration = new Attention.VibeProfile(100, 3000);

        // Daten aus dem Storage laden
        results = Application.Storage.getValue("results") as Lang.Dictionary;

        if (results != null) {
            // Run-Zeit (String)
            if (results.hasKey("run_time")) {
                runTime = results.get("run_time") as String;
                System.println("Geladene runTime: " + runTime);
            } else {
                runTime = "0:00:00";
            }

            // run_time_seconds => runTargetSpeed
            if (results.hasKey("run_time_seconds")) {
                var runTimeInSeconds = (results.get("run_time_seconds") as Number).toFloat();
                System.println("Geladene runTimeInSeconds: " + runTimeInSeconds);

                if (runTimeInSeconds > 0.0) {
                    // Für den Ironman-Marathon: 42.195 km
                    runTargetSpeed = calculateTargetSpeed(42.195 as Float, runTimeInSeconds);
                    System.println("Berechnete runTargetSpeed: " + runTargetSpeed + " km/h");
                } else {
                    System.println("run_time_seconds ist 0 oder ungültig, setze runTargetSpeed auf 0.");
                    runTargetSpeed = 0.0;
                }
            } else {
                System.println("run_time_seconds nicht in Daten gefunden, setze runTargetSpeed auf 0.");
                runTargetSpeed = 0.0;
            }

        } else {
            System.println("Keine gespeicherten Daten gefunden. Bitte synchronisieren.");
            runTime = "0:00:00";
            runTargetSpeed = 0.0;
        }

        // GPS-Ortung
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onShow() as Void {
        logger.debug("IronmanApp_siebenRunView onShow called");
        masterTimer.addObserver(self);
        masterTimer.start();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        logger.debug("IronmanApp_siebenRunView onUpdate called");
        View.onUpdate(dc);

        // Hintergrund
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Titel + Target
        var centerX = Math.round(dc.getWidth() / 2);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(centerX, 30, Graphics.FONT_LARGE, "Run", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, 90, Graphics.FONT_SMALL, "Target: " + runTime, Graphics.TEXT_JUSTIFY_CENTER);

        // Stoppuhr
        runStopwatch.drawStopwatch(dc);

        // Geschwindigkeit
        var positionInfo = Position.getInfo();
        var currentSpeed = 0.0;

        if (positionInfo != null && positionInfo.speed != null) {
            var rawSpeed = positionInfo.speed;  // m/s
            logger.debug("Rohgeschwindigkeit (m/s): " + rawSpeed);

            currentSpeed = rawSpeed * 3.6;       // in km/h
            logger.debug("Umgerechnete Geschwindigkeit (km/h): " + currentSpeed);

            // Validierung
            if (currentSpeed < 0 || currentSpeed > 1000) {
                logger.warn("Unrealistische Geschwindigkeit erkannt: " + currentSpeed);
                currentSpeed = 0.0;
            }
        }

        // Formatierte Geschwindigkeit
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

        // Herzsymbol
        heartBitmap.setLocation(245, 170);
        heartBitmap.draw(dc);

        // Rot/Grün-Kreis
        if (runTargetSpeed > 0.0) {
            var xPos = centerX - 40;
            var yPos = 220;

            if (currentSpeed <= runTargetSpeed) {
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

                // Zurücksetzen
                if (underSpeedStartTime != -1) {
                    underSpeedStartTime = -1;
                }
            }
        } else {
            underSpeedStartTime = -1;
        }
    }

    function onHide() as Void {
        logger.debug("IronmanApp_siebenRunView onHide called.");
        if (masterTimer != null) {
            masterTimer.removeObserver(self);
        }
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        logger.debug("IronmanApp_siebenRunView onKey called: " + evt.getKey().toString());
        System.println("Key pressed: " + evt.getKey().toString());

        if (evt.getKey() == WatchUi.KEY_START) {
            StopwatchManager.startStopwatch(runStopwatch);
            return true;
        }
        return false;
    }

    // Vom MasterTimer getriggert
    function updateOnMasterTimer() {
        System.println("MasterTimer tick - RunView updated.");
        WatchUi.requestUpdate();
    }

    // Positions-Callback
    function onPosition(info as Position.Info) as Void {
        if (info != null && info.position != null) {
            var myLocation = info.position.toDegrees();
            System.println("Latitude: " + myLocation[0]);
            System.println("Longitude: " + myLocation[1]);
            System.println("Speed: " + (info.speed * 3.6) + " km/h");
        }
    }

    // Berechnet Zielgeschwindigkeit (km/h), hier auf Grundlage von 42.195 km
    function calculateTargetSpeed(distance as Float, targetTime as Float) as Float {
        System.println("Calculating run target speed...");
        System.println("Distance: " + distance + " km, Target Time: " + targetTime + " seconds");

        if (distance <= 0.0 || targetTime <= 0.0) {
            return 0.0 as Float;
        }

        var hours = targetTime / 3600.0;
        if (hours < 0.001) {
            return 0.0 as Float;
        }

        var targetSpeed = distance / hours;
        System.println("Calculated run target speed: " + targetSpeed + " km/h");
        return targetSpeed.toFloat();
    }
}
