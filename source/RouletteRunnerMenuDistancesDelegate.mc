using Toybox.Attention;
using Toybox.Application;
using Toybox.System;
using Toybox.WatchUi;

class RouletteRunnerMenuDistancesDelegate extends WatchUi.MenuInputDelegate {

    var mainView; // Hold reference to your main view

    function initialize(view) {
        MenuInputDelegate.initialize();
        mainView = view;
    }

	function onMenuItem(item) {
        var app = Application.getApp();
        var currentData = app.getSelectedRouletteData();

        if (item == :marathon) {
            currentData = Application.loadResource(Rez.JsonData.marathon);
        } else if (item == :halfMarathon) {
            currentData = Application.loadResource(Rez.JsonData.halfMarathon);
        } else if (item == :tenKm) {
            currentData = Application.loadResource(Rez.JsonData.tenKm);
        } else if (item == :fiveKm) {
            currentData = Application.loadResource(Rez.JsonData.fiveKm);
        }

		app.setSelectedRouletteData(currentData);

        WatchUi.popView(WatchUi.SLIDE_RIGHT);

        // Call the method on the passed view instance
        if (mainView != null) {
            mainView.updateDistanceData();
        }
    }
}
