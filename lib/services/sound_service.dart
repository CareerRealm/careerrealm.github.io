import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _alertPlayer = AudioPlayer();
  final AudioPlayer _notificationPlayer = AudioPlayer();

  String? _currentAmbient;

  SoundService._internal() {
    // Configure global audio context for Android volume control (media session)
    final audioContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );
    AudioPlayer.global.setAudioContext(audioContext);
  }

  // ── Ambient sounds (loop while focusing) ─────────────────────────────────
  static const Map<String, Map<String, String>> ambientSounds = {
    'rain': {'emoji': '🌧️', 'label': 'Rain', 'file': 'sounds/rain.mp3'},
    'lightrain': {'emoji': '🌦️', 'label': 'Light Rain', 'file': 'sounds/lightrain.mp3'},
    'rain2': {'emoji': '⛈️', 'label': 'Heavy Rain', 'file': 'sounds/rain2.mp3'},
    'rain3': {'emoji': '🌊', 'label': 'Ocean Rain', 'file': 'sounds/rain3.mp3'},
    'forest': {'emoji': '🌲', 'label': 'Forest', 'file': 'sounds/forest.mp3'},
    'nature': {'emoji': '🌿', 'label': 'Nature', 'file': 'sounds/nature.mp3'},
    'campfire': {'emoji': '🔥', 'label': 'Campfire', 'file': 'sounds/campfire.mp3'},
    'brownnoise': {'emoji': '🟤', 'label': 'Brown Noise', 'file': 'sounds/brownnoise.mp3'},
    'tick1': {'emoji': '🕐', 'label': 'Clock Tick', 'file': 'sounds/tick1.mp3'},
    'tick2': {'emoji': '🕑', 'label': 'Tick Tock', 'file': 'sounds/tick2.mp3'},
    'tick3': {'emoji': '⏰', 'label': 'Soft Tick', 'file': 'sounds/tick3.mp3'},
    'tick4': {'emoji': '⏱️', 'label': 'Fast Tick', 'file': 'sounds/tick4.mp3'},
    'tick5': {'emoji': '🕰️', 'label': 'Grand Clock', 'file': 'sounds/tick5.mp3'},
    'tick6': {'emoji': '⌚', 'label': 'Watch Tick', 'file': 'sounds/tick6.mp3'},
    'tick7': {'emoji': '🔔', 'label': 'Tick Bell', 'file': 'sounds/tick7.mp3'},
    'tick8': {'emoji': '⏲️', 'label': 'Timer Tick', 'file': 'sounds/tick8.mp3'},
  };

  // ── Alert sounds (played once on timer events) ────────────────────────────
  static const Map<String, Map<String, String>> alertSounds = {
    // "Focus time!" alerts (played when break ends → back to focus)
    'bell': {'emoji': '🔔', 'label': 'Bell', 'file': 'sounds/bell.mp3'},
    'bell2': {'emoji': '🎵', 'label': 'Bell Chime', 'file': 'sounds/bell2.mp3'},
    'bell3': {'emoji': '🔕', 'label': 'Bell Soft', 'file': 'sounds/bell3.mp3'},
    'horn': {'emoji': '📣', 'label': 'Horn', 'file': 'sounds/horn.mp3'},
    'horn2': {'emoji': '🎺', 'label': 'Horn Short', 'file': 'sounds/horn2.mp3'},
    // "Break time!" alerts (played when focus session ends → break starts)
    'airhorn': {'emoji': '📢', 'label': 'Air Horn', 'file': 'sounds/airhorn.mp3'},
    'airhorn2': {'emoji': '🔊', 'label': 'Air Horn 2', 'file': 'sounds/airhorn2.mp3'},
    'partyhorn': {'emoji': '🎉', 'label': 'Party Horn', 'file': 'sounds/partyhorn.mp3'},
    'oldcarhorn': {'emoji': '🚗', 'label': 'Retro Horn', 'file': 'sounds/oldcarhorn.mp3'},
    'vintagecarhorn': {'emoji': '🏎️', 'label': 'Vintage Car', 'file': 'sounds/vintagecarhorn.mp3'},
  };

  String? get currentAmbient => _currentAmbient;
  bool get isPlayingAmbient => _currentAmbient != null;

  // ── Ambient ────────────────────────────────────────────────────────────────
  Future<void> playAmbient(String key) async {
    if (_currentAmbient == key) return;
    await _ambientPlayer.stop();
    final info = ambientSounds[key];
    if (info == null) return;
    _currentAmbient = key;
    await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
    await _ambientPlayer.play(AssetSource(info['file']!));
  }

  Future<void> stopAmbient() async {
    _currentAmbient = null;
    await _ambientPlayer.stop();
  }

  Future<void> setAmbientVolume(double volume) async {
    await _ambientPlayer.setVolume(volume);
  }

  // ── Alert ──────────────────────────────────────────────────────────────────
  Future<void> playAlert(String key) async {
    final info = alertSounds[key];
    if (info == null) return;
    await _alertPlayer.stop();
    await _alertPlayer.setReleaseMode(ReleaseMode.release);
    await _alertPlayer.play(AssetSource(info['file']!));
  }

  // ── Notification (chat message received) ──────────────────────────────────
  Future<void> playNotification() async {
    await _notificationPlayer.stop();
    await _notificationPlayer.setReleaseMode(ReleaseMode.release);
    // Use a short bell for notification
    await _notificationPlayer.setVolume(0.5);
    await _notificationPlayer.play(AssetSource('sounds/bell.mp3'));
  }

  Future<void> dispose() async {
    await _ambientPlayer.dispose();
    await _alertPlayer.dispose();
    await _notificationPlayer.dispose();
  }
}
