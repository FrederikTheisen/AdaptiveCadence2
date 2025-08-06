//! CircularBuffer.mc
//! Efficient circular buffer for timestamped cadence samples.
class CircularBuffer {
    var _buffer;
    var _maxSize;
    var _start;
    var _end;
    var _size;

    function initialize(maxSize) {
        _maxSize = maxSize;
        _buffer = new [maxSize];
        _start = 0;
        _end = 0;
        _size = 0;
    }

    function add(sample) {
        _buffer[_end] = sample;
        _end = (_end + 1) % _maxSize;
        if (_size < _maxSize) {
            _size += 1;
        } else {
            _start = (_start + 1) % _maxSize;
        }
    }

    function getSamples() {
        var samples = new [_size];
        for (var i = 0; i < _size; i++) {
            var idx = (_start + i) % _maxSize;
            samples[i] = _buffer[idx];
        }
        return samples;
    }

    function size() {
        return _size;
    }

    function clear() {
        _start = 0;
        _end = 0;
        _size = 0;
    }
}
