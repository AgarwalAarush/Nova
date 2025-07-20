# RMS-Based Silence Detection System

## Overview

The Jarvis voice assistant implements an RMS (Root Mean Square) based silence detection system to determine when a user has finished speaking. This system dynamically adapts to ambient noise levels and provides reliable speech boundary detection for voice interactions.

## Core Algorithm

### RMS Calculation
```python
def calculate_rms(self, audio_data):
    audio_float = audio_data.astype(np.float32) / 32768.0
    return np.sqrt(np.mean(audio_float ** 2))
```

The RMS calculation:
1. Converts 16-bit integer audio to normalized float32 (-1.0 to 1.0 range)
2. Squares each sample to eliminate negative values
3. Calculates the mean of squared values
4. Takes the square root to get the RMS value

### Adaptive Threshold System

#### Static Configuration
- `SILENCE_THRESHOLD = 0.005` - Base threshold for silence detection
- `MIN_SILENCE_THRESHOLD = 0.002` - Minimum allowed threshold
- `MAX_SILENCE_THRESHOLD = 0.02` - Maximum allowed threshold
- `ADAPTIVE_THRESHOLD_MULTIPLIER = 1.5` - Scaling factor for adaptation
- `SILENCE_BUFFER_SIZE = 10` - Number of chunks used for threshold calculation

#### Dynamic Adaptation
```python
def update_adaptive_threshold(self, current_rms):
    self.audio_levels_buffer.append(current_rms)

    if len(self.audio_levels_buffer) >= 5:
        avg_level = np.mean(self.audio_levels_buffer)
        self.adaptive_threshold = max(
            MIN_SILENCE_THRESHOLD,
            min(MAX_SILENCE_THRESHOLD, avg_level * ADAPTIVE_THRESHOLD_MULTIPLIER)
        )
```

The system continuously adjusts the silence threshold based on:
- Recent audio level history (rolling window)
- Environmental noise floor
- Clamped to predefined minimum/maximum bounds

## Recording Workflow

### 1. Wake Word Detection Phase
- Uses fixed `SILENCE_THRESHOLD` (0.005)
- Listens for "Jarvis" wake word
- No adaptive threshold during this phase

### 2. Recording Phase
- Switches to adaptive threshold system
- Continuously updates threshold based on speech levels
- Resets adaptive parameters for each new recording session

### 3. Silence Detection Logic
```python
def detect_silence(self, audio_chunk):
    rms = self.calculate_rms(audio_chunk)

    if self.is_recording:
        self.update_adaptive_threshold(rms)

    threshold = self.adaptive_threshold if self.is_recording else self.silence_threshold
    return rms < threshold
```

### 4. Recording Termination
- Silence counter increments when RMS < threshold
- Recording stops after `SILENCE_DURATION_BLOCKS = 25` consecutive silent chunks
- Approximately 2 seconds of silence (25 × 80ms chunks)

## Audio Processing Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Sample Rate | 16,000 Hz | Audio sampling frequency |
| Chunk Size | 1,280 samples | 80ms audio chunks |
| Channels | 1 (Mono) | Single channel audio |
| Data Type | 16-bit PCM | Audio format |
| Silence Duration | ~2 seconds | Time before stopping recording |

## Advantages

1. **Adaptive Nature**: Automatically adjusts to different acoustic environments
2. **Low Latency**: Real-time processing with 80ms chunks
3. **Noise Resilience**: Adapts to background noise levels
4. **Computational Efficiency**: Simple mathematical operations
5. **Tunable Parameters**: Easily adjustable thresholds and timing

## Limitations

1. **Amplitude-Based Only**: Cannot distinguish speech from other sounds of similar volume
2. **Breathing/Mouth Sounds**: May not detect quiet speech artifacts
3. **Sudden Noise**: Brief loud sounds can affect adaptive threshold
4. **No Spectral Analysis**: Lacks frequency-domain speech characteristics

## Debug Features

```python
def enable_silence_debug(self, enabled=True):
    self.silence_debug_enabled = enabled
```

When enabled, outputs:
- Current RMS values
- Active threshold levels
- Silence counter status
- Logged every 10th chunk during recording

## Integration Points

The silence detection system integrates with:
- **Wake Word Detection**: Transitions from listening to recording mode
- **Audio Buffer Management**: Controls when to stop collecting audio
- **Speech Processing Pipeline**: Triggers transcription when silence detected
- **State Management**: Resets thresholds between recording sessions

## Performance Characteristics

- **Response Time**: ~2 seconds after speech ends
- **Sensitivity**: Automatically adapts to speaker volume
- **Reliability**: Consistent performance across different environments
- **Resource Usage**: Minimal CPU overhead for real-time processing
