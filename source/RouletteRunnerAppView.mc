using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Math;
using Toybox.System;
using Toybox.Application;
using Toybox.Lang;
using Toybox.Timer;


public var rouletteNumbers as Lang.Array<Lang.String> = [];
public var selectedIndex = null;
public var itemSize as Lang.Number = 0;

class RouletteConfettiParticle {
    var x;
    var y;
    var velocityX;
    var velocityY;
    var size;
    var color;

    function initialize(vx, vy, particleSize, particleColor) {
        x = 0.0;
        y = 0.0;
        velocityX = vx;
        velocityY = vy;
        size = particleSize;
        color = particleColor;
    }
}


class RouletteRunnerView extends WatchUi.View {
    private var _confettiParticles as Lang.Array<RouletteConfettiParticle> = [];
    private var _confettiTimer;
    private var _confettiFrame = 0;
    private var _confettiActive = false;
    private var _successBadge;

    function initialize() {
        View.initialize();
        _confettiTimer = new Timer.Timer();
    }

    function onShow() {
    var app = Application.getApp();
    rouletteNumbers = app.getSelectedRouletteData();

        if (rouletteNumbers == null || rouletteNumbers.size() == 0) {
            // Fallback to default if nothing selected
            rouletteNumbers = Application.loadResource(Rez.JsonData.fiveKm);
        }

        itemSize = rouletteNumbers.size();

        _successBadge = WatchUi.loadResource(Rez.Drawables.SuccessBadge);
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function setSelectedIndex(index) {
        selectedIndex = index;
        requestUpdate();
    }

    function startSuccessEffect() {
        stopSuccessEffect();

        var colors = [
            0xFFAA00, // yellow
            0x00AAFF, // blue
            0x00AA00, // green
            0xFF00FF, // pink
            0xFF5500, // orange
            Graphics.COLOR_WHITE
        ];

        _confettiParticles = [];
        _confettiFrame = 0;

        for (var i = 0; i < 40; i++) {
            var velocityX = ((Math.rand() % 21) - 10).toFloat() / 100.0;
            var velocityY = -((Math.rand() % 11) + 6).toFloat() / 100.0;
            var particleSize = (Math.rand() % 3) + 2;
            var particleColor = colors[Math.rand() % colors.size()];

            _confettiParticles.add(new RouletteConfettiParticle(
                velocityX,
                velocityY,
                particleSize,
                particleColor
            ));
        }

        _confettiActive = true;
        _confettiTimer.start(method(:advanceConfetti), 40, true);
        requestUpdate();
    }

    function stopSuccessEffect() {
        if (_confettiTimer != null) {
            _confettiTimer.stop();
        }
        _confettiActive = false;
        _confettiParticles = [];
        _confettiFrame = 0;
    }

    function advanceConfetti() {
        for (var i = 0; i < _confettiParticles.size(); i++) {
            var particle = _confettiParticles[i];
            particle.x += particle.velocityX;
            particle.y += particle.velocityY;
            particle.velocityY += 0.008;
        }

        _confettiFrame++;
        if (_confettiFrame >= 45) {
            stopSuccessEffect();
        }

        requestUpdate();
    }

    function drawConfetti(dc, centerX, centerY, screenR) {
        for (var i = 0; i < _confettiParticles.size(); i++) {
            var particle = _confettiParticles[i];
            var particleX = centerX + particle.x * screenR;
            var particleY = centerY + particle.y * screenR;
            var halfSize = particle.size;

            dc.setColor(particle.color, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([
                [particleX - halfSize, particleY - halfSize],
                [particleX + halfSize, particleY - halfSize],
                [particleX + halfSize, particleY + halfSize],
                [particleX - halfSize, particleY + halfSize]
            ]);
        }
    }

    function drawSuccessBadge(dc, centerX, centerY) {
        var badgeWidth = 168;
        var badgeHeight = 168;
        var badgeX = centerX - badgeWidth / 2;
        var badgeY = centerY - badgeHeight / 2;

        if (_successBadge != null) {
            dc.drawBitmap(badgeX, badgeY, _successBadge);
        }

        // Render the winning distance over the brown trophy base.
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY + 51,
            Graphics.FONT_SYSTEM_SMALL,
            (rouletteNumbers[selectedIndex] as Lang.String),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
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
        // Keep the center hub compact beneath the success badge.
        var innerR = (screenR * 0.18).toNumber();
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

        // Draw the success effect over the hub, but under the result text.
        if (_confettiActive) {
            drawConfetti(dc, centerX, centerY, screenR);
        }

        // Center result text
        if (animationFinished && selectedIndex != null) {
            drawSuccessBadge(dc, centerX, centerY);
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
        stopSuccessEffect();

        requestUpdate();
    }

}
