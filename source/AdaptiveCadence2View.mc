import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class AdaptiveCadence2View extends WatchUi.DataField {
    // --- Configurable parameters ---
    const MAX_WINDOW_SEC = 1200; // 20 min
    const MIN_WINDOW_SEC = 10;   // 10 sec
    const SLOPE_STABLE_THRESHOLD = 0.05; // rpm/sec
    const SLOPE_CHANGE_THRESHOLD = 0.5;  // rpm/sec
    const WINDOW_GROWTH_RATE = 5; // sec per tick
    const WINDOW_SHRINK_RATE = 30; // sec per tick
    const ZERO_CADENCE_IGNORE = true;
    const CADENCE_THRESHOLD = 10; // Ignore if cadence is below this value

    hidden var mCadence as Numeric;
    hidden var mTrend as Numeric;
    hidden var mWindowSec as Number;
    hidden var mBuffer;
    hidden var mLastTimestamp as Number;
    hidden var mProfileInfo;

    function initialize() {
        DataField.initialize();
        mCadence = 0.0f;
        mTrend = 0.0f;
        mWindowSec = MIN_WINDOW_SEC; // Start with 1 min
        mBuffer = new CircularBuffer(MAX_WINDOW_SEC); // Max buffer size
        mLastTimestamp = 0;
        mProfileInfo = Activity.getProfileInfo();
    }

    function onLayout(dc as Dc) as Void {
        View.setLayout(Rez.Layouts.MainLayout(dc));

        (View.findDrawableById("label") as Text).setText(Lang.format("adaptive_cadence", [mCadence]));
    }

    function compute(info as Activity.Info) as Void {
        var cadence = info.currentCadence;
        var time = info.elapsedTime / 1000.0;
        if (cadence == null || ZERO_CADENCE_IGNORE && cadence <= CADENCE_THRESHOLD) { return; }
        if (mProfileInfo.sport == Activity.SPORT_CYCLING) { cadence /= 2; }
        if (time <= mLastTimestamp) { time = mLastTimestamp + 1; }

        mBuffer.add([time, cadence]);

        // Remove samples outside window
        var samples = mBuffer.getSamples();
        var cutoff = time - mWindowSec;
        var filtered = [];
        for (var i = 0; i < samples.size(); ++i) {
            var sample = samples[i];
            if (sample[0] >= cutoff) {
                filtered.add(sample);
            }
        }

        // Regression
        var reg = RegressionUtils.computeRegression(filtered);
        mCadence = reg["latest"];
        mTrend = reg["slope"];

        // Window adaptation
        if ((mTrend < 0 ? -mTrend : mTrend) < SLOPE_STABLE_THRESHOLD) {
            mWindowSec = (mWindowSec + WINDOW_GROWTH_RATE < MAX_WINDOW_SEC) ? mWindowSec + WINDOW_GROWTH_RATE : MAX_WINDOW_SEC;
        } else if ((mTrend < 0 ? -mTrend : mTrend) > SLOPE_CHANGE_THRESHOLD) {
            mWindowSec = (mWindowSec - WINDOW_SHRINK_RATE > MIN_WINDOW_SEC) ? mWindowSec - WINDOW_SHRINK_RATE : MIN_WINDOW_SEC;
        }

        System.println(time + "," + cadence + "," + mCadence + "," + mTrend + "," + mWindowSec);

        mLastTimestamp = time;
    }

    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());
        // Set the foreground color and value
        var value = View.findDrawableById("value") as Text;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
        }
        value.setText(mCadence.format("%.1f") + " rpm\n" + Lang.format("cadence_trend", [mTrend]));
        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }
}
