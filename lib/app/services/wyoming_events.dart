// SPDX-License-Identifier: MIT

// -----------------------------------------------------------------------------
// 1. Event Model --------------------------------------------------------------
// -----------------------------------------------------------------------------

abstract class WyoEvent {}

class Describe extends WyoEvent {}

class Info extends WyoEvent {}

class ErrorEvt extends WyoEvent {}

class Ping extends WyoEvent {}

class Pong extends WyoEvent {}

class AudioStart extends WyoEvent {}

class AudioChunk extends WyoEvent {}

class AudioStop extends WyoEvent {}

class Played extends WyoEvent {}

class Detect extends WyoEvent {}

class Detection extends WyoEvent {}

class VoiceStarted extends WyoEvent {}

class VoiceStopped extends WyoEvent {}

class Transcript extends WyoEvent {}

class Synthesize extends WyoEvent {}

class RunPipeline extends WyoEvent {}

class RunSatellite extends WyoEvent {}

class PauseSatellite extends WyoEvent {}

class StreamingStarted extends WyoEvent {}

class StreamingStopped extends WyoEvent {}

class SatelliteConnected extends WyoEvent {}

class SatelliteDisconnected extends WyoEvent {}

class TimerStarted extends WyoEvent {}

class TimerUpdated extends WyoEvent {}

class TimerCancelled extends WyoEvent {}

class TimerFinished extends WyoEvent {}

class WyomingSocket {}

class SatelliteSettings {}

class SatelliteBase {}

class AlwaysStreamingSatellite {}

class SatelliteEventHandler {}
