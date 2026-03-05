using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Math;
using Toybox.System;
using Toybox.Application;
using Toybox.Lang;


public var rouletteNumbers as Lang.Array<Lang.String> = [];
public var selectedIndex = null;
public var itemSize as Lang.Number = 0;
public var winText;


class RouletteRunnerView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onShow() {
    var app = Application.getApp();
    rouletteNumbers = app.getSelectedRouletteData();

        if (rouletteNumbers == null || rouletteNumbers.size() == 0) {
            // Fallback to default if nothing selected
            rouletteNumbers = Application.loadResource(Rez.JsonData.fiveKm);
        }

        itemSize = rouletteNumbers.size();

        winText = WatchUi.loadResource(Rez.Strings.WinTextLabel);
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function setSelectedIndex(index) {
        selectedIndex = index;
        requestUpdate();
    }

    function getPositionAngle(pos) {
        return (pos * 360.0 / itemSize) - 90;
    }

    function drawSegment(dc, cx, cy, innerR, outerR, startDeg, endDeg, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        // Fill segment with thin triangles from center
        var steps = 8;
        var stepDeg = (endDeg - startDeg).toFloat() / steps;
        for (var s = 0; s < steps; s++) {
            var a1 = (startDeg + s * stepDeg) * Math.PI / 180;
            var a2 = (startDeg + (s + 1) * stepDeg) * Math.PI / 180;
            dc.fillPolygon([
                [cx + innerR * Math.cos(a1), cy + innerR * Math.sin(a1)],
                [cx + outerR * Math.cos(a1), cy + outerR * Math.sin(a1)],
                [cx + outerR * Math.cos(a2), cy + outerR * Math.sin(a2)],
                [cx + innerR * Math.cos(a2), cy + innerR * Math.sin(a2)]
            ]);
        }
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var screenR = dc.getWidth() < dc.getHeight() ? dc.getWidth() / 2 : dc.getHeight() / 2;
        var wheelR = screenR - 1;
        var innerR = (screenR * 0.28).toNumber();
        var labelR = (screenR * 0.78).toNumber();
        var segAngle = 360.0 / itemSize;

        // Draw filled segments (alternating colors like a roulette)
        for (var i = 0; i < itemSize; i++) {
            var startDeg = getPositionAngle(i) - segAngle / 2;
            var endDeg = startDeg + segAngle;
            var segColor;
            if (i == selectedIndex) {
                segColor = 0x444400; // dark yellow highlight
            } else if (i % 2 == 0) {
                segColor = 0xCC0000; // red
            } else {
                segColor = 0x1A1A1A; // near-black
            }
            drawSegment(dc, centerX, centerY, innerR, wheelR, startDeg, endDeg, segColor);
        }

        // Draw segment divider lines
        for (var i = 0; i < itemSize; i++) {
            var divAngle = getPositionAngle(i) - segAngle / 2;
            var divRad = divAngle * Math.PI / 180;
            dc.setColor(0x888800, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(
                centerX + innerR * Math.cos(divRad),
                centerY + innerR * Math.sin(divRad),
                centerX + wheelR * Math.cos(divRad),
                centerY + wheelR * Math.sin(divRad)
            );
        }

        // Outer gold ring
        dc.setColor(0x888800, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(centerX, centerY, wheelR);
        dc.drawCircle(centerX, centerY, wheelR - 1);
        dc.drawCircle(centerX, centerY, innerR);
        dc.drawCircle(centerX, centerY, innerR + 1);

        // Draw labels on segments (horizontal, near outer edge)
        for (var i = 0; i < itemSize; i++) {
            var angle = getPositionAngle(i);
            var rad = angle * Math.PI / 180;

            if (i == selectedIndex) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }

            dc.drawText(
                centerX + labelR * Math.cos(rad),
                centerY + labelR * Math.sin(rad),
                Graphics.FONT_SYSTEM_XTINY,
                (rouletteNumbers[i] as Lang.String),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        // Draw rotating pointer triangle
        var pRad = (wheelOffset - 90) * Math.PI / 180;
        var pTip = wheelR - 14;
        var pBase = wheelR + 6;
        var pSide = 8;
        var cosP = Math.cos(pRad);
        var sinP = Math.sin(pRad);
        var perpCos = Math.cos(pRad + Math.PI / 2);
        var perpSin = Math.sin(pRad + Math.PI / 2);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [centerX + pTip * cosP, centerY + pTip * sinP],
            [centerX + pBase * cosP + pSide * perpCos, centerY + pBase * sinP + pSide * perpSin],
            [centerX + pBase * cosP - pSide * perpCos, centerY + pBase * sinP - pSide * perpSin]
        ]);

        // Center hub
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, innerR);

        // Center result text
        if (animationFinished && selectedIndex != null) {
            // Gold ring highlight
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(centerX, centerY, innerR);
            dc.drawCircle(centerX, centerY, innerR - 1);

            var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

            // Distance value
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 12, Graphics.FONT_SYSTEM_SMALL,
                (rouletteNumbers[selectedIndex] as Lang.String), justify);

            // Action label
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY + 22, Graphics.FONT_SYSTEM_XTINY,
                winText, justify);
        } else if (selectedIndex != null) {
            // During spin: show cycling number in center
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY, Graphics.FONT_SYSTEM_SMALL,
                (rouletteNumbers[selectedIndex] as Lang.String),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function updateDistanceData() {
        var app = Application.getApp();
        rouletteNumbers = app.getSelectedRouletteData();

        if (rouletteNumbers == null || rouletteNumbers.size() == 0) {
            rouletteNumbers = Application.loadResource(Rez.JsonData.fiveKm);
        }

        itemSize = rouletteNumbers.size();
        selectedIndex = null;

        requestUpdate();
    }

}