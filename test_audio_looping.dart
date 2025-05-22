import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'lib/app/services/audio_service.dart';

void main() {
  // Initialize MediaKit
  MediaKit.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Audio Looping Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AudioLoopingTest(),
    );
  }
}

class AudioLoopingTest extends StatefulWidget {
  const AudioLoopingTest({super.key});

  @override
  _AudioLoopingTestState createState() => _AudioLoopingTestState();
}

class _AudioLoopingTestState extends State<AudioLoopingTest> {
  late AudioService audioService;
  final testAudioUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
  bool isLooping = false;
  
  @override
  void initState() {
    super.initState();
    initializeAudioService();
  }
  
  Future<void> initializeAudioService() async {
    audioService = AudioService();
    await audioService.init();
    Get.put(audioService);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Looping Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Text(
              'Current Audio: ${audioService.currentRemoteAudio.value ?? "None"}',
              textAlign: TextAlign.center,
            )),
            Obx(() => Text(
              'Status: ${audioService.isRemotePlaying.value ? "Playing" : "Stopped"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    audioService.playRemoteAudio(testAudioUrl, looping: false);
                    isLooping = false;
                  },
                  child: const Text('Play Once'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    audioService.playRemoteAudio(testAudioUrl, looping: true);
                    isLooping = true;
                  },
                  child: const Text('Play Looping'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => audioService.stopRemoteAudio(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Stop Audio'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Instructions:\n'
              '1. Press "Play Once" to play audio once\n'
              '2. Press "Play Looping" to play audio in a loop\n'
              '3. Verify that looping continues after track completion\n'
              '4. Press "Stop Audio" to stop playback',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    audioService.stopRemoteAudio();
    super.dispose();
  }
}
