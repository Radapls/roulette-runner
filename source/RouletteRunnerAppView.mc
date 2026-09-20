using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Math;
using Toybox.System;
using Toybox.Application;
using Toybox.Lang;


public var rouletteNumbers as Lang.Array<Lang.String> = [];
public var selectedIndex = null;
public var itemSize as Lang.Number = 0;

// Wheel geometry is cached per distance profile so the spin animation
// draws from precomputed polygons instead of rebuilding them every frame.
class RouletteRunnerView extends WatchUi.View {
    private var _centerX = 0;
    private var _centerY = 0;
    private var _wheelR = 0;
    private var _innerR = 0;
    private var _segAngle = 0.0;
    private var _segPolys as Lang.Array<Lang.Array<Lang.Array<Graphics.Point2D>>> = [];  // per segment: sub-polygons, ready for fillPolygon
    private var _dividerLines as Lang.Array<Lang.Array<Lang.Number>> = [];  // per segment: [x1, y1, x2, y2]
    private var _labelPos as Lang.Array<Lang.Array<Lang.Number>> = [];      // per segment: [x, y]
    private var _geomStale = true;

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

    function buildGeometry(dc) {
        _centerX = dc.getWidth() / 2;
        _centerY = dc.getHeight() / 2;
        var screenR = dc.getWidth() < dc.getHeight() ? dc.getWidth() / 2 : dc.getHeight() / 2;
        _wheelR = screenR - 1;
        // Keep the center hub compact for the result text.
        _innerR = (screenR * 0.18).toNumber();
        var labelR = (screenR * 0.78).toNumber();
        _segAngle = 360.0 / itemSize;

        // Two sub-polygons per segment is enough for the chord to stay under
        // the 2px gold ring (three for the wide 10-segment 5K wheel).
        var steps = _segAngle > 30.0 ? 3 : 2;

        _segPolys = [];
        _dividerLines = [];
        _labelPos = [];

        for (var i = 0; i < itemSize; i++) {
            var startDeg = getPositionAngle(i) - _segAngle / 2;
            var stepDeg = _segAngle / steps;
            var polys = [];
            for (var s = 0; s < steps; s++) {
                var a1 = (startDeg + s * stepDeg) * Math.PI / 180;
                var a2 = (startDeg + (s + 1) * stepDeg) * Math.PI / 180;
                polys.add([
                    [_centerX + _innerR * Math.cos(a1), _centerY + _innerR * Math.sin(a1)],
                    [_centerX + _wheelR * Math.cos(a1), _centerY + _wheelR * Math.sin(a1)],
                    [_centerX + _wheelR * Math.cos(a2), _centerY + _wheelR * Math.sin(a2)],
                    [_centerX + _innerR * Math.cos(a2), _centerY + _innerR * Math.sin(a2)]
                ]);
            }
            _segPolys.add(polys);

            var divRad = startDeg * Math.PI / 180;
            _dividerLines.add([
                _centerX + _innerR * Math.cos(divRad),
                _centerY + _innerR * Math.sin(divRad),
                _centerX + _wheelR * Math.cos(divRad),
                _centerY + _wheelR * Math.sin(divRad)
            ]);

            var labRad = getPositionAngle(i) * Math.PI / 180;
            _labelPos.add([
                _centerX + labelR * Math.cos(labRad),
                _centerY + labelR * Math.sin(labRad)
            ]);
        }
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_geomStale) {
            buildGeometry(dc);
            _geomStale = false;
        }

        // Draw filled segments (alternating colors like a roulette)
        for (var i = 0; i < itemSize; i++) {
            var segColor;
            if (i == selectedIndex) {
                segColor = 0x444400; // dark yellow highlight
            } else if (i % 2 == 0) {
                segColor = 0xCC0000; // red
            } else {
                segColor = 0x1A1A1A; // near-black
            }
            dc.setColor(segColor, Graphics.COLOR_TRANSPARENT);
            var polys = _segPolys[i];
            for (var s = 0; s < polys.size(); s++) {
                dc.fillPolygon(polys[s]);
            }
        }

        // Draw segment divider lines
        dc.setColor(0x888800, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < itemSize; i++) {
            var line = _dividerLines[i];
            dc.drawLine(line[0], line[1], line[2], line[3]);
        }

        // Outer gold ring
        dc.drawCircle(_centerX, _centerY, _wheelR);
        dc.drawCircle(_centerX, _centerY, _wheelR - 1);
        dc.drawCircle(_centerX, _centerY, _innerR);
        dc.drawCircle(_centerX, _centerY, _innerR + 1);

        // Draw labels on segments (horizontal, near outer edge)
        for (var i = 0; i < itemSize; i++) {
            if (i == selectedIndex) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }

            var pos = _labelPos[i];
            dc.drawText(
                pos[0],
                pos[1],
                Graphics.FONT_SYSTEM_XTINY,
                rouletteNumbers[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        // Draw rotating pointer triangle
        var pRad = (wheelOffset - 90) * Math.PI / 180;
        var pTip = _wheelR - 14;
        var pBase = _wheelR + 6;
        var pSide = 8;
        var cosP = Math.cos(pRad);
        var sinP = Math.sin(pRad);
        var perpCos = Math.cos(pRad + Math.PI / 2);
        var perpSin = Math.sin(pRad + Math.PI / 2);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [_centerX + pTip * cosP, _centerY + pTip * sinP],
            [_centerX + pBase * cosP + pSide * perpCos, _centerY + pBase * sinP + pSide * perpSin],
            [_centerX + pBase * cosP - pSide * perpCos, _centerY + pBase * sinP - pSide * perpSin]
        ]);

        // Center hub
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX, _centerY, _innerR);
    }

    function updateDistanceData() {
        var app = Application.getApp();
        rouletteNumbers = app.getSelectedRouletteData();

        if (rouletteNumbers == null || rouletteNumbers.size() == 0) {
            rouletteNumbers = Application.loadResource(Rez.JsonData.fiveKm);
        }

        itemSize = rouletteNumbers.size();
        selectedIndex = null;
        _geomStale = true; // rebuild geometry for the new profile

        requestUpdate();
    }

}
