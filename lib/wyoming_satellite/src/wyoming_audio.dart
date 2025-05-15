import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';

/// Cross-platform microphone audio capture for Wyoming Satellite
/// WyomingAudioRecorder captures microphone audio as 16-bit PCM, 16kHz, mono.
/// This format is REQUIRED for Wyoming protocol compatibility.
/// If the platform or record package does not support this, Wyoming integration will not work correctly.
class WyomingAudioRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSub;

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Start recording audio in 16-bit PCM, 16kHz, mono format.
  /// Throws if microphone permission is not granted.
  Future<void> start({required void Function(Uint8List data) onAudio}) async {
    if (!await hasPermission()) throw Exception('No microphone permission');
    // The RecordConfig below enforces the required format for Wyoming:
    // encoder: AudioEncoder.pcm16bits, numChannels: 1, sampleRate: 16000
    final config = const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      numChannels: 1,
      sampleRate: 16000,
      bitRate: 256000,
    );
    assert(config.encoder == AudioEncoder.pcm16bits && config.numChannels == 1 && config.sampleRate == 16000,
      'Audio format must be 16-bit PCM, 16kHz, mono for Wyoming Satellite');
    final stream = await _recorder.startStream(config);
    _audioSub = stream.listen(onAudio);
  }

  Future<void> stop() async {
    await _recorder.stop();
    await _audioSub?.cancel();
    _audioSub = null;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
