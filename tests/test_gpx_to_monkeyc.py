from pathlib import Path

from tools.gpx_to_monkeyc import Point, parse_gpx, quantize, render_monkey_c, simplify


def test_parse_gpx_with_namespace(tmp_path: Path) -> None:
    path = tmp_path / "sample.gpx"
    path.write_text(
        """<?xml version="1.0"?>
<gpx xmlns="http://www.topografix.com/GPX/1/1">
  <trk><trkseg>
    <trkpt lat="55.6761" lon="12.5681" />
    <trkpt lat="55.6762" lon="12.5682" />
  </trkseg></trk>
</gpx>""",
        encoding="utf-8",
    )
    assert parse_gpx(path) == [[Point(55.6761, 12.5681), Point(55.6762, 12.5682)]]


def test_simplify_removes_nearly_collinear_point() -> None:
    points = [Point(55.0, 12.0), Point(55.00001, 12.00001), Point(55.00002, 12.00002)]
    assert simplify(points, tolerance_m=2.0) == [points[0], points[-1]]


def test_quantize_and_render() -> None:
    track = quantize([Point(55.67612, 12.56834), Point(55.67622, 12.56844)])
    output = render_monkey_c([track])
    assert "[5567612, 1256834]" in output
    assert "class HeatmapData" in output
