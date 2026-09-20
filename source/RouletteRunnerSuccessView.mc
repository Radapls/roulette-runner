using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Math;
using Toybox.System;
using Toybox.Lang;
using Toybox.Timer;

// ponytail: plain data holder, no getters
class RouletteConfettiParticle {
    var x;
    var y;
    var velocityX;
    var velocityY;
    var size;
    var color;
    var life; // remaining ticks; <= 0 means dead and undrawn

    function initialize(particleSize, particleColor) {
        x = 0.0;
        y = 0.0;
        velocityX = 0.0;
        velocityY = 0.0;
        size = particleSize;
        color = particleColor;
        life = 0;
    }
}

// Full-screen celebration shown after the wheel stops, in the style of
// Garmin's goal-achievement screens. Popped with the back key.
class RouletteSuccessView extends WatchUi.View {
    private var _particles as Lang.Array<RouletteConfettiParticle> = [];
    private var _timer;
    private var _frame = 0;
    private var _raysAngle = 0.0;
    private var _distance as Lang.String;
    private var _youWonText;
    private var _goRunText;
    private var _runnerIcon;

    function initialize(distance as Lang.String) {
        View.initialize();
        _distance = distance;
        _timer = new Timer.Timer();
    }

    function onShow() {
        _youWonText = WatchUi.loadResource(Rez.Strings.YouWonLabel);
        _goRunText = WatchUi.loadResource(Rez.Strings.GoRunLabel);
        _runnerIcon = WatchUi.loadResource(Rez.Drawables.RunnerIcon);
        startConfetti();
    }

    function onHide() {
        if (_timer != null) {
            _timer.stop();
        }
    }

    function startConfetti() {
        var colors = [
            0xFFAA00, // yellow
            0x00AAFF, // blue
            0x00AA00, // green
            0xFF00FF, // pink
            0xFF5500, // orange
            Graphics.COLOR_WHITE
        ];

        _particles = [];

        for (var i = 0; i < 36; i++) {
            _particles.add(new RouletteConfettiParticle(
                (Math.rand() % 3) + 2,
                colors[Math.rand() % colors.size()]
            ));
        }

        _frame = 0;
        launchBurst();
        _timer.start(method(:advanceConfetti), 33, true);
        WatchUi.requestUpdate();
    }

    // Reuse the whole particle pool as one explosion at a random spot.
    // Every particle gets its own color so bursts read as multicolor.
    function launchBurst() {
        var colors = [
            0xFFAA00, // yellow
            0x00AAFF, // blue
            0x00AA00, // green
            0xFF00FF, // pink
            0xFF5500, // orange
            Graphics.COLOR_WHITE
        ];
        var burstX = ((Math.rand() % 101) - 50).toFloat() / 100.0;   // -0.5..0.5
        var burstY = ((Math.rand() % 101) - 70).toFloat() / 100.0;   // -0.7..0.3

        for (var i = 0; i < _particles.size(); i++) {
            var particle = _particles[i];
            var angle = (Math.rand() % 360).toFloat() * Math.PI / 180;
            var speed = ((Math.rand() % 14) + 4).toFloat() / 100.0;

            particle.x = burstX;
            particle.y = burstY;
            particle.velocityX = speed * Math.cos(angle);
            particle.velocityY = speed * Math.sin(angle);
            particle.color = colors[Math.rand() % colors.size()];
            particle.life = 35 + (Math.rand() % 20);
        }
    }

    function advanceConfetti() {
        _frame++;
        _raysAngle += 0.6;

        // Sequential fireworks: a new burst every ~1.8s
        if (_frame % 55 == 0) {
            launchBurst();
        }

        for (var i = 0; i < _particles.size(); i++) {
            var particle = _particles[i];
            if (particle.life > 0) {
                particle.x += particle.velocityX;
                particle.y += particle.velocityY;
                particle.velocityY += 0.004;
                particle.life--;
            }
        }

        WatchUi.requestUpdate();
    }

    // Slowly rotating fan of dim rays, the signature of Garmin's native
    // celebration screens
    function drawLightRays(dc, cx, cy, maxR) {
        var rayCount = 12;
        var spreadDeg = 360.0 / rayCount;
        var halfWidth = spreadDeg * 0.18 * Math.PI / 180;

        dc.setColor(0x443300, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < rayCount; i++) {
            var a = (_raysAngle + i * spreadDeg) * Math.PI / 180;
            dc.fillPolygon([
                [cx, cy],
                [cx + maxR * Math.cos(a - halfWidth), cy + maxR * Math.sin(a - halfWidth)],
                [cx + maxR * Math.cos(a + halfWidth), cy + maxR * Math.sin(a + halfWidth)]
            ]);
        }
    }

    // Icon drops in from above and settles with a small overshoot bounce
    function getIconY(centerY, h) {
        var finalY = centerY + h * 0.24;
        if (_frame >= 22) {
            return finalY;
        }

        var fromY = centerY - h * 0.45;
        var k = _frame / 22.0;
        var c1 = 1.70158;
        var c3 = c1 + 1.0;
        var eased = 1.0 + c3 * Math.pow(k - 1.0, 3) + c1 * Math.pow(k - 1.0, 2);
        return fromY + (finalY - fromY) * eased;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var screenR = dc.getWidth() < dc.getHeight() ? dc.getWidth() / 2 : dc.getHeight() / 2;
        var h = dc.getHeight();
        var diagR = Math.sqrt(dc.getWidth() * dc.getWidth() + h * h) / 2;

        drawLightRays(dc, centerX, centerY, diagR);

        // Stacked message: "You won" / distance / "GO RUN!" / runner icon,
        // positioned relative to the screen so it scales across devices
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY - h * 0.18,
            Graphics.FONT_SYSTEM_MEDIUM,
            _youWonText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Distance in the biggest font available: digits in NUMBER_HOT
        // (number fonts carry no letters), "K" beside it in LARGE
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        var digits = _distance.substring(0, _distance.length() - 1);
        var suffix = _distance.substring(_distance.length() - 1, _distance.length());
        var bigFont = Graphics.FONT_SYSTEM_NUMBER_HOT;
        var kFont = Graphics.FONT_SYSTEM_LARGE;
        var numW = dc.getTextWidthInPixels(digits, bigFont);
        var totalW = numW + dc.getTextWidthInPixels(suffix, kFont);
        var startX = centerX - totalW / 2;
        var distY = centerY - h * 0.02;
        dc.drawText(startX, distY, bigFont, digits, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(startX + numW, distY, kFont, suffix, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY + h * 0.14,
            Graphics.FONT_SYSTEM_SMALL,
            _goRunText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        if (_runnerIcon != null) {
            var iconSize = 48;
            var iconY = getIconY(centerY, h);
            dc.drawBitmap(centerX - iconSize / 2, (iconY - iconSize / 2).toNumber(), _runnerIcon);
        }

        drawConfetti(dc, centerX, centerY, screenR);
    }

    function drawConfetti(dc, centerX, centerY, screenR) {
        for (var i = 0; i < _particles.size(); i++) {
            var particle = _particles[i];
            if (particle.life <= 0) {
                continue;
            }
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
}

class RouletteSuccessDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
