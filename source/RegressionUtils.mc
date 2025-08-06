//! RegressionUtils.mc
//! Utility for incremental linear regression (least squares) on timestamped cadence samples.
import Toybox.Lang;

class RegressionUtils {
    //! Computes linear regression slope and intercept for (time, value) pairs.
    //! Returns {slope, intercept}.
    static function computeRegression(samples) as Dictionary {
        var n = samples.size();
        if (n == 0) { return { "slope" => 0.0, "intercept" => 0.0, "latest" => 0.0 }; }
        if (n < 2) { return { "slope" => 0.0, "intercept" => samples[n-1][1], "latest" => samples[n-1][1] }; }
        var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumXX = 0.0;
        for (var i = 0; i < n; ++i) {
            var x = samples[i][0] as Float;
            var y = samples[i][1] as Float;
            sumX += x;
            sumY += y;
            sumXY += x * y;
            sumXX += x * x;
        }
        var denom = n * sumXX - sumX * sumX;
        if (denom == 0) {
            var avg = sumY / n;
            return {"slope" => 0.0, "intercept" => avg, "latest" => avg};
        }
        var slope = (n * sumXY - sumX * sumY) / denom;
        var intercept = (sumY - slope * sumX) / n;
        var latestX = samples[n-1][0] as Float;
        var latestY = slope * latestX + intercept;
        return {"slope" => slope, "intercept" => intercept, "latest" => latestY};
    }
}
