// Ironman_siebenView.mc

import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;
import Toybox.Application;


class IronmanApp_siebenView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
    }

    function onHide() as Void {
    }

    // Methode zum Abfangen der Tastendrücke
    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        if (evt.getKey() == WatchUi.KEY_START) {
            System.println("KEY_START pressed in Welcome View");

            // Navigiere zum Auswahlmenü und ersetze das Begrüßungsfenster
            var menuView = new Rez.Menus.MainMenu();
            var menuDelegate = new IronmanApp_siebenMenuDelegate();
            menuView.initialize();
            WatchUi.switchToView(menuView, menuDelegate, WatchUi.SLIDE_LEFT);

            return true;  // Ereignis behandelt
        }
        return false;  // Ereignis nicht behandelt, KEY_ESC wird im Delegate behandelt
    }
}
