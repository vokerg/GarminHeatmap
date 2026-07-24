using Toybox.Activity as Activity;
using Toybox.Graphics as Graphics;
using Toybox.Lang as Lang;
using Toybox.WatchUi as WatchUi;

class GarminHeatmapView extends WatchUi.DataField {
    const DEFAULT_CENTER = [55.67668, 12.56834];
    const METERS_ACROSS = 1200.0;
    const MAX_BREADCRUMB_POINTS = 120;
    const MIN_BREADCRUMB_MOVE_E5 = 2;

    var _currentDegrees = null;
    var _breadcrumb = [];
    var _gpsReady = false;

    function initialize() {
        DataField.initialize();
    }

    function compute(info as Activity.Info) {
        if (info != null && info has :currentLocation && info.currentLocation != null) {
            _currentDegrees = info.currentLocation.toDegrees();
            _gpsReady = true;
            appendBreadcrumb(_currentDegrees);
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var center = (_currentDegrees == null) ? DEFAULT_CENTER : _currentDegrees;
        var projector = new GeoProjector(center, METERS_ACROSS, width, height);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        drawHistory(dc, projector, width, height);
        drawBreadcrumb(dc, projector, width, height);
        drawHud(dc, width, height);
        drawCurrentPosition(dc, width, height);
    }

    private function drawHistory(dc, projector, width, height) {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.setPenWidth(1);
        drawTracks(dc, projector, HeatmapData.tracks(), width, height);
    }

    private function drawBreadcrumb(dc, projector, width, height) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.setPenWidth(2);
        drawTracks(dc, projector, [_breadcrumb], width, height);
    }

    private function drawTracks(dc, projector, tracks, width, height) {
        for (var trackIndex = 0; trackIndex < tracks.size(); trackIndex += 1) {
            var track = tracks[trackIndex];
            if (track.size() < 2) {
                continue;
            }

            var previous = projector.projectE5(track[0]);
            for (var pointIndex = 1; pointIndex < track.size(); pointIndex += 1) {
                var current = projector.projectE5(track[pointIndex]);
                if (segmentMayBeVisible(previous, current, width, height)) {
                    dc.drawLine(previous[0], previous[1], current[0], current[1]);
                }
                previous = current;
            }
        }
    }

    private function segmentMayBeVisible(a, b, width, height) {
        if (a[0] < 0 && b[0] < 0) { return false; }
        if (a[0] >= width && b[0] >= width) { return false; }
        if (a[1] < 0 && b[1] < 0) { return false; }
        if (a[1] >= height && b[1] >= height) { return false; }
        return true;
    }

    private function drawCurrentPosition(dc, width, height) {
        var x = width / 2;
        var y = height / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(x, y, 7);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.fillCircle(x, y, 4);
    }

    private function drawHud(dc, width, height) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(width / 2, 5, Graphics.FONT_XTINY, "N", Graphics.TEXT_JUSTIFY_CENTER);

        var scaleMeters = (METERS_ACROSS / 4).toNumber();
        var scalePixels = width / 4;
        var y = height - 16;
        var x1 = width - scalePixels - 10;
        var x2 = width - 10;
        dc.drawLine(x1, y, x2, y);
        dc.drawLine(x1, y - 3, x1, y + 3);
        dc.drawLine(x2, y - 3, x2, y + 3);
        dc.drawText((x1 + x2) / 2, y - 14, Graphics.FONT_XTINY, scaleMeters.format("%d") + "m", Graphics.TEXT_JUSTIFY_CENTER);

        if (!_gpsReady) {
            dc.drawText(width / 2, height - 35, Graphics.FONT_XTINY, "WAITING FOR GPS", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function appendBreadcrumb(degrees) {
        var point = [
            (degrees[0] * 100000.0).toNumber(),
            (degrees[1] * 100000.0).toNumber()
        ];

        if (_breadcrumb.size() > 0) {
            var last = _breadcrumb[_breadcrumb.size() - 1];
            var latDelta = point[0] - last[0];
            var lonDelta = point[1] - last[1];
            if (Lang.abs(latDelta) < MIN_BREADCRUMB_MOVE_E5 && Lang.abs(lonDelta) < MIN_BREADCRUMB_MOVE_E5) {
                return;
            }
        }

        _breadcrumb.add(point);
        if (_breadcrumb.size() > MAX_BREADCRUMB_POINTS) {
            _breadcrumb.remove(0);
        }
    }
}
