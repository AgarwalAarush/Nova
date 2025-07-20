# RMS Silence Detection Implementation in Jarvis Voice Assistant

## Overview

This document describes how the RMS-based silence detection system is implemented and integrated within the Jarvis voice assistant (`jarvis.py`). The system uses adaptive audio level monitoring to determine when a user has finished speaking.

## Architecture Integration

### Class Structure
```python
class VoiceAssistant:
    def __init__(self):
        # Silence detection state variables
        self.silence_threshold = SILENCE_THRESHOLD  # Fixed threshold (0.005)
        self.audio_levels_buffer = []               # Rolling window of audio levels
        self.adaptive_threshold = SILENCE_THRESHOLD # Dynamic threshold
        self.silence_counter = 0                    # Consecutive silence chunks
        self.silence_debug_enabled = False          # Debug mode flag
```

## State Management Integration

### Three-State System
1. **Listening** (`is_listening=True`) - Waiting for wake word "Jarvis"
2. **Recording** (`is_recording=True`) - Capturing user speech
3. **Processing** (`is_processing=True`) - Transcribing and responding

### State Transitions
```
Listening → Recording: Wake word detected (confidence ≥ 0.95)
Recording → Processing: Silence detected for 25 consecutive chunks (~2s)
Processing → Listening: Response completed
```

## Audio Processing Pipeline

### 1. Audio Stream Setup
```python
# jarvis.py:396-404
self.audio_stream = sd.InputStream(
    samplerate=16000,      # 16kHz sampling
    blocksize=1280,        # 80ms chunks
    channels=1,            # Mono audio
    dtype='int16',         # 16-bit PCM
    callback=self.audio_callback
)
```

### 2. Continuous Audio Capture
```python
# jarvis.py:115-121
def audio_callback(self, indata, frames, time_info, status):
    if not self.stop_event.is_set():
        self.audio_queue.put(indata.copy())
```

### 3. Main Processing Loop
Located in `process_wake_word_detection()` (jarvis.py:164-217):

#### Wake Word Detection Phase
```python
# jarvis.py:174-196
if self.is_listening and not self.is_recording and not self.is_processing:
    # Check for wake word with fixed threshold
    prediction = self.wake_word_model.predict(audio_chunk_flat)
    if jarvis_score >= WAKE_WORD_CONFIDENCE_THRESHOLD:
        self._start_recording()
```

#### Recording Phase with Silence Detection
```python
# jarvis.py:198-210
elif self.is_recording and not self.is_processing:
    self.recording_buffer.append(audio_chunk_flat)

    if self.detect_silence(audio_chunk_flat):
        self.silence_counter += 1
        if self.silence_counter >= SILENCE_DURATION_BLOCKS:
            self._stop_recording()
    else:
        self.silence_counter = 0  # Reset on speech detection
```

## RMS Implementation Details

### Core RMS Calculation
```python
# jarvis.py:123-127
def calculate_rms(self, audio_data):
    audio_float = audio_data.astype(np.float32) / 32768.0
    return np.sqrt(np.mean(audio_float ** 2))
```

### Adaptive Threshold System
```python
# jarvis.py:129-144
def update_adaptive_threshold(self, current_rms):
    self.audio_levels_buffer.append(current_rms)

    # Maintain rolling window of 10 samples
    if len(self.audio_levels_buffer) > SILENCE_BUFFER_SIZE:
        self.audio_levels_buffer.pop(0)

    # Calculate new threshold after 5+ samples
    if len(self.audio_levels_buffer) >= 5:
        avg_level = np.mean(self.audio_levels_buffer)
        self.adaptive_threshold = max(
            MIN_SILENCE_THRESHOLD,    # 0.002
            min(MAX_SILENCE_THRESHOLD, avg_level * 1.5)  # 0.02 max
        )
```

### Silence Detection Logic
```python
# jarvis.py:146-162
def detect_silence(self, audio_chunk):
    rms = self.calculate_rms(audio_chunk)

    # Update adaptive threshold only during recording
    if self.is_recording:
        self.update_adaptive_threshold(rms)

    # Choose threshold based on current state
    threshold = self.adaptive_threshold if self.is_recording else self.silence_threshold

    # Optional debug output every 10th chunk
    if self.silence_debug_enabled and self.is_recording and self.silence_counter % 10 == 0:
        self.console.print(f"RMS: {rms:.4f}, Threshold: {threshold:.4f}")

    return rms < threshold
```

## Session Management

### Recording Session Start
```python
# jarvis.py:219-238
def _start_recording(self):
    self.is_recording = True
    self.is_listening = False
    self.recording_buffer = []
    self.silence_counter = 0

    # Reset adaptive threshold system
    self.audio_levels_buffer = []
    self.adaptive_threshold = SILENCE_THRESHOLD

    # Reset wake word model buffers
    self.wake_word_model.reset()
```

### Recording Session End
```python
# jarvis.py:240-247
def _stop_recording(self):
    self.is_recording = False
    self.is_processing = True

    # Process in separate thread to avoid blocking audio
    processing_thread = threading.Thread(target=self._process_recording)
    processing_thread.start()
```

### Complete State Reset
```python
# jarvis.py:355-379
def _reset_state(self):
    self.is_listening = True
    self.is_recording = False
    self.is_processing = False

    # Clear buffers
    self.recording_buffer = []
    self.silence_counter = 0
    self.keyword_buffer = np.array([], dtype=np.float32)

    # Reset adaptive threshold
    self.audio_levels_buffer = []
    self.adaptive_threshold = SILENCE_THRESHOLD

    # Clear audio queue and reset wake word model
    self._clear_audio_buffer()
    self.wake_word_model.reset()
```

## Configuration Parameters

### Timing Configuration
```python
# jarvis.py:34-43
SILENCE_THRESHOLD = 0.005           # Base RMS threshold
SILENCE_DURATION_BLOCKS = 25        # ~2 seconds (25 × 80ms)
SILENCE_BUFFER_SIZE = 10            # Rolling window size
ADAPTIVE_THRESHOLD_MULTIPLIER = 1.5 # Scaling factor
MIN_SILENCE_THRESHOLD = 0.002       # Lower bound
MAX_SILENCE_THRESHOLD = 0.02        # Upper bound
```

### Audio Configuration
```python
# jarvis.py:27-31
SAMPLE_RATE = 16000    # 16kHz sampling
CHUNK_SIZE = 1280      # 80ms chunks (1280 samples)
CHANNELS = 1           # Mono audio
DTYPE = np.int16       # 16-bit PCM
```

## Debug Features

### Debug Mode Activation
```python
# jarvis.py:381-387
def enable_silence_debug(self, enabled=True):
    self.silence_debug_enabled = enabled
```

### Debug Output Format
When enabled, outputs every 10th chunk during recording:
```
RMS: 0.0124, Threshold: 0.0087, Counter: 15
```

## Processing Flow Summary

1. **Continuous Audio Stream**: 80ms chunks at 16kHz
2. **Wake Word Detection**: Uses fixed threshold (0.005)
3. **Recording Activation**: Switches to adaptive threshold
4. **Adaptive Learning**: Builds threshold from speech levels
5. **Silence Counting**: Accumulates consecutive silent chunks
6. **Recording Termination**: Stops after 25 silent chunks (~2s)
7. **Speech Processing**: Transcription → LLM → TTS response
8. **State Reset**: Returns to wake word listening mode

## Integration Benefits

- **Seamless Transitions**: Smooth state changes between listening/recording/processing
- **Adaptive Performance**: Automatically adjusts to speaker volume and environment
- **Thread Safety**: Non-blocking audio processing with separate threads
- **Robust Error Handling**: Graceful recovery from audio or processing errors
- **Real-time Feedback**: Rich console output with colored status messages
