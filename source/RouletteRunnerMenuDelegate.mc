using Toybox.Attention;
using Toybox.Math;
using Toybox.System;
using Toybox.WatchUi;

public var randomIndex = 3;
public var timer;
public var isAnimating = false;
public var animationFinished = false;
public var interval = 50;
public var wheelOffset = 0.0;
public var spinStep = 0.0;

class RouletteRunnerMenuDelegate extends WatchUi.MenuInputDelegate {
	var mainView;

	function initialize(v) {
		MenuInputDelegate.initialize();
		mainView = v;
	}

	function startRouletteSpin() {
        isAnimating = true;
        animationFinished = false;
        selectedIndex = null;
        wheelOffset = (Math.rand() % 360).toFloat();
        spinStep = 15.0 + (Math.rand() % 15).toFloat();
        timer.start(method(:spinRoulette), interval, true);
    }

    function spinRoulette() {
        wheelOffset += spinStep;
        spinStep *= 0.96;

        // Update highlighted segment during spin
        var segAngle = 360.0 / itemSize;
        var normalized = wheelOffset - (wheelOffset / 360.0).toNumber() * 360.0;
        if (normalized < 0) { normalized += 360.0; }
        selectedIndex = ((normalized / segAngle) + 0.5).toNumber() % itemSize;

        WatchUi.requestUpdate();

        if (spinStep < 0.5) {
            timer.stop();
            isAnimating = false;
            animationFinished = true;
            mainView.setSelectedIndex(selectedIndex);
        }
    }

	function onMenuItem( item ) {
		if ( item == :spin ) {
			startRouletteSpin();
        }
		else if (item == :distance) {
        WatchUi.pushView(
            new Rez.Menus.RouletteRunnerDistancesMenu(),
            new RouletteRunnerMenuDistancesDelegate(mainView),
            WatchUi.SLIDE_IMMEDIATE
        );
		} else if ( item == :exit ) {
			System.exit();
		}
	}
}