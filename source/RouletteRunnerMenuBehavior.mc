using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Timer;
using Toybox.Math;

class RouletteRunnerDelegate extends WatchUi.BehaviorDelegate {
    var mainView;

    function initialize(v as RouletteRunnerView) {
        BehaviorDelegate.initialize();
        mainView = v;
        timer = new Timer.Timer();
    }

    function onKey(key) {
        if (isAnimating) {
            return false;
        }

        if (key.getKey() == 4) {
            WatchUi.pushView( new Rez.Menus.RouletteRunnerMenu(), new RouletteRunnerMenuDelegate(mainView), WatchUi.SLIDE_RIGHT);
            return true;
        }

        return false;
    }
}
