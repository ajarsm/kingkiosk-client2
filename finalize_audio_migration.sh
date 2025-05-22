#!/bin/bash
# Script to finalize the migration from just_audio to media_kit

echo "Finalizing just_audio to media_kit migration..."

# Add a note to FIXES_SUMMARY.md
if [ -f "FIXES_SUMMARY.md" ]; then
  echo -e "\n## Audio Migration\nMigrated audio playback from just_audio to media_kit for cross-platform support, including Windows.\n" >> FIXES_SUMMARY.md
  echo "✅ Added note to FIXES_SUMMARY.md"
else
  echo "⚠️ Could not find FIXES_SUMMARY.md"
fi

# Update README.md if it exists
if [ -f "README.md" ]; then
  echo -e "\n## Audio System\nThe app uses media_kit for audio playback, which supports all platforms including Windows, macOS, Linux, Android, iOS, and web.\n" >> README.md
  echo "✅ Added note to README.md"
else
  echo "⚠️ Could not find README.md"
fi

# Verify that no just_audio imports remain
echo "Checking for remaining just_audio imports..."
JUST_AUDIO_FILES=$(grep -r "just_audio" --include="*.dart" . | grep -v "audio_service_backup" | wc -l)

if [ "$JUST_AUDIO_FILES" -eq "0" ]; then
  echo "✅ No remaining just_audio imports found"
else
  echo "⚠️ Found $JUST_AUDIO_FILES files that may still reference just_audio"
  grep -r "just_audio" --include="*.dart" . | grep -v "audio_service_backup"
fi

echo "Migration finalized!"

# Create a test file to verify audio playback
cat > test_mediakit_audio.dart << 'EOF'
// A simple Flutter app to test MediaKit audio playback

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  // Initialize MediaKit
  MediaKit.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaKit Audio Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AudioTestPage(),
    );
  }
}

class AudioTestPage extends StatefulWidget {
  const AudioTestPage({super.key});

  @override
  State<AudioTestPage> createState() => _AudioTestPageState();
}

class _AudioTestPageState extends State<AudioTestPage> {
  late final Player player;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    player = Player();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> playAsset(String path) async {
    try {
      await player.open(Media('asset:///$path'));
      setState(() {
        isPlaying = true;
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaKit Audio Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Test MediaKit Audio Playback',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => playAsset('assets/sounds/notification.wav'),
              child: const Text('Play Notification Sound'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => playAsset('assets/sounds/correct.wav'),
              child: const Text('Play Success Sound'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => playAsset('assets/sounds/wrong.wav'),
              child: const Text('Play Error Sound'),
            ),
            const SizedBox(height: 20),
            if (isPlaying)
              ElevatedButton(
                onPressed: () {
                  player.pause();
                  setState(() {
                    isPlaying = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Stop Audio'),
              ),
          ],
        ),
      ),
    );
  }
}
EOF

echo "Created test_mediakit_audio.dart for testing audio playback"
echo "To test, run: flutter run -t test_mediakit_audio.dart"
