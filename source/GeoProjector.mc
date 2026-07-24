using Toybox.Math as Math;

class GeoProjector {
    const EARTH_RADIUS_M = 6371000.0;

    var _centerLatRad;
    var _centerLonRad;
    var _cosLat;
    var _pixelsPerMeter;
    var _centerX;
    var _centerY;

    function initialize(centerDegrees, metersAcross, width, height) {
        _centerLatRad = centerDegrees[0] * Math.PI / 180.0;
        _centerLonRad = centerDegrees[1] * Math.PI / 180.0;
        _cosLat = Math.cos(_centerLatRad);
        _pixelsPerMeter = width.toFloat() / metersAcross.toFloat();
        _centerX = width / 2;
        _centerY = height / 2;
    }

    function projectE5(point) {
        var lat = (point[0].toDouble() / 100000.0) * Math.PI / 180.0;
        var lon = (point[1].toDouble() / 100000.0) * Math.PI / 180.0;
        var east = (lon - _centerLonRad) * _cosLat * EARTH_RADIUS_M;
        var north = (lat - _centerLatRad) * EARTH_RADIUS_M;

        return [
            (_centerX + east * _pixelsPerMeter).toNumber(),
            (_centerY - north * _pixelsPerMeter).toNumber()
        ];
    }
}
