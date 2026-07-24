using Toybox.Application as App;
using Toybox.WatchUi as WatchUi;

class GarminHeatmapApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new GarminHeatmapView()];
    }
}
