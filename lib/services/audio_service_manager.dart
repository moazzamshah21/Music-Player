import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:umarplayer/services/player_service.dart';
import 'package:umarplayer/services/audio_handler_service.dart';

class AudioServiceManager {
  // Static flag to prevent multiple AudioService.init() calls globally
  static bool _isAudioServiceInitializing = false;
  static bool _isAudioServiceInitialized = false;
  
  bool _isInitialized = false;
  bool _isInitializing = false;
  AudioHandlerService? _audioHandler;
  PlayerService? _playerService;

  /// Must be called with the app's PlayerService before first playback.
  /// This ensures notification bar controls interact with the same player instance.
  void setPlayerService(PlayerService playerService) {
    _playerService = playerService;
  }

  OnTrackChangedCallback? _onTrackChanged;

  /// Called when notification bar controls change the track (next/previous).
  /// Keeps the app UI in sync when user interacts with the background mini player.
  void setOnTrackChanged(OnTrackChangedCallback? callback) {
    _onTrackChanged = callback;
  }


  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  AudioHandlerService? get audioHandler => _audioHandler;

  Future<void> _initializeAudioService({int retryCount = 0}) async {
    // CRITICAL: Check and set static flags SYNCHRONOUSLY before any async operations
    // This prevents multiple concurrent initialization attempts
    
    // Check if already initialized
    if (_isAudioServiceInitialized) {
      if (globalAudioHandler != null && _audioHandler == null) {
        _audioHandler = globalAudioHandler;
        _isInitialized = true;
      }
      return;
    }
    
    // Check if AudioService is already initialized via global handler
    if (globalAudioHandler != null) {
      print('✅ [AudioServiceManager] AudioService already initialized, using existing handler');
      _isInitialized = true;
      _isAudioServiceInitialized = true;
      _audioHandler = globalAudioHandler;
      return;
    }
    
    // Check if another instance is initializing - wait for it
    if (_isAudioServiceInitializing) {
      print('⏳ [AudioServiceManager] AudioService initialization already in progress, waiting...');
      int waitAttempts = 0;
      while (_isAudioServiceInitializing && waitAttempts < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitAttempts++;
        // Check if it succeeded while waiting
        if (globalAudioHandler != null) {
          _isInitialized = true;
          _isAudioServiceInitialized = true;
          _audioHandler = globalAudioHandler;
          print('✅ [AudioServiceManager] AudioService initialized by another instance');
          return;
        }
      }
      // If still initializing after timeout, check one more time
      if (globalAudioHandler != null) {
        _isInitialized = true;
        _isAudioServiceInitialized = true;
        _audioHandler = globalAudioHandler;
        return;
      }
      return;
    }
    
    // Set flags IMMEDIATELY and SYNCHRONOUSLY to prevent concurrent calls
    // This must happen before any await
    _isAudioServiceInitializing = true;
    _isInitializing = true;

    try {
      // CRITICAL: Wait for FlutterEngine to be fully ready before initializing AudioService
      // This prevents the "FlutterEngine not provided" error
      if (retryCount == 0) {
        print('⏳ [AudioServiceManager] Waiting for FlutterEngine to be ready...');
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      print('🔧 [AudioServiceManager] Initializing AudioService... (attempt ${retryCount + 1})');
      
      // Use the app's PlayerService (set via setPlayerService) so notification
      // bar controls interact with the same player. Fallback only for edge cases.
      _playerService ??= PlayerService();
      
      // Check one more time if AudioService was initialized by another thread
      // This prevents the _cacheManager assertion error
      if (globalAudioHandler != null) {
        print('✅ [AudioServiceManager] AudioService initialized by another thread, using existing handler');
        _audioHandler = globalAudioHandler;
        _isInitialized = true;
        _isAudioServiceInitialized = true;
        return;
      }
      
      await audio_service.AudioService.init(
        builder: () {
          _audioHandler = AudioHandlerService(
            _playerService!,
            onTrackChanged: _onTrackChanged,
          );
          return _audioHandler!;
        },
        config: audio_service.AudioServiceConfig(
          androidNotificationChannelId: 'com.umarplayer.channel.audio',
          androidNotificationChannelName: 'Umar Player',
          androidNotificationChannelDescription: 'Audio playback controls',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: false,
          androidNotificationClickStartsActivity: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidShowNotificationBadge: true,
          notificationColor: const Color(0xFF1a1a1a), // Dark background like modern media players
          artDownscaleWidth: 512,
          artDownscaleHeight: 512,
          preloadArtwork: true,
          fastForwardInterval: const Duration(seconds: 10),
          rewindInterval: const Duration(seconds: 10),
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ [AudioServiceManager] Initialization timeout');
          throw TimeoutException('AudioService init timeout');
        },
      );
      
      _isInitialized = true;
      _isAudioServiceInitialized = true;
      print('✅ [AudioServiceManager] AudioService initialized successfully');
    } catch (e) {
      print('❌ [AudioServiceManager] Error initializing AudioService: $e');
      
      // If _cacheManager error, it means AudioService is already initialized
      // This can happen if init() was called multiple times
      if (e.toString().contains('_cacheManager') || 
          e.toString().contains('is not true')) {
        print('ℹ️ [AudioServiceManager] AudioService appears to be already initialized');
        
        // Wait a moment for the handler to be set (in case it's being set asynchronously)
        for (int i = 0; i < 10; i++) {
          if (globalAudioHandler != null) {
            _audioHandler = globalAudioHandler;
            _isInitialized = true;
            _isAudioServiceInitialized = true;
            print('✅ [AudioServiceManager] Using existing AudioService instance from global handler');
            return; // Success - don't retry
          }
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // If global handler is still null after waiting, AudioService is initialized
        // but handler wasn't created. This is a problematic state.
        // Try one more time to access it after a longer delay
        print('⚠️ [AudioServiceManager] AudioService initialized but handler not accessible, waiting longer...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (globalAudioHandler != null) {
          _audioHandler = globalAudioHandler;
          _isInitialized = true;
          _isAudioServiceInitialized = true;
          print('✅ [AudioServiceManager] Handler found after longer wait');
          return;
        }
        
        // Last resort: try to create handler anyway (it will set globalAudioHandler)
        // This might work if AudioService is initialized but handler wasn't set
        print('⚠️ [AudioServiceManager] Attempting to create handler for existing AudioService...');
        try {
          if (_playerService == null) {
            _playerService = PlayerService();
          }
          _audioHandler = AudioHandlerService(
            _playerService!,
            onTrackChanged: _onTrackChanged,
          );
          // The handler constructor sets globalAudioHandler = this
          _isInitialized = true;
          _isAudioServiceInitialized = true;
          print('✅ [AudioServiceManager] Created handler for existing AudioService');
          return;
        } catch (handlerError) {
          print('❌ [AudioServiceManager] Failed to create handler: $handlerError');
          // Mark as initialized anyway to prevent infinite retries
          _isInitialized = true;
          _isAudioServiceInitialized = true;
          return;
        }
      }
      
      // Check if it was actually initialized despite the error
      if (globalAudioHandler != null) {
        print('✅ [AudioServiceManager] AudioService initialized despite error, using handler');
        _audioHandler = globalAudioHandler;
        _isInitialized = true;
        _isAudioServiceInitialized = true;
      } else {
        // Only retry for FlutterEngine errors, not _cacheManager errors
        if (e.toString().contains('FlutterEngine') || 
            e.toString().contains('Activity class') ||
            e.toString().contains('AndroidManifest')) {
          if (retryCount < 2) {
            print('🔄 [AudioServiceManager] Retrying initialization in ${3 + retryCount} seconds...');
            _isInitializing = false;
            _isAudioServiceInitializing = false;
            await Future.delayed(Duration(seconds: 3 + retryCount));
            await _initializeAudioService(retryCount: retryCount + 1);
            return;
          } else {
            print('❌ [AudioServiceManager] Max retries reached for FlutterEngine error');
          }
        }
        
        _isInitialized = false;
        _isAudioServiceInitialized = false;
        _audioHandler = null;
      }
    } finally {
      _isInitializing = false;
      _isAudioServiceInitializing = false;
    }
  }

  Future<void> ensureInitialized() async {
    // Quick check - if already initialized, return immediately
    if (_isAudioServiceInitialized && globalAudioHandler != null) {
      if (_audioHandler == null) {
        _audioHandler = globalAudioHandler;
      }
      _isInitialized = true;
      return;
    }
    
    if (_isInitialized && _audioHandler != null) {
      return;
    }
    
    // Check if another instance is initializing
    if (_isAudioServiceInitializing) {
      int attempts = 0;
      while (_isAudioServiceInitializing && attempts < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
        // Check if it succeeded while waiting
        if (globalAudioHandler != null) {
          _audioHandler = globalAudioHandler;
          _isInitialized = true;
          _isAudioServiceInitialized = true;
          return;
        }
      }
      // Final check after waiting
      if (globalAudioHandler != null) {
        _audioHandler = globalAudioHandler;
        _isInitialized = true;
        _isAudioServiceInitialized = true;
        return;
      }
    }
    
    await _initializeAudioService();
    
    // Wait for initialization to complete if it's still in progress
    int attempts = 0;
    while (_isInitializing && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
      // Check if it succeeded while waiting
      if (globalAudioHandler != null && _audioHandler == null) {
        _audioHandler = globalAudioHandler;
        _isInitialized = true;
        _isAudioServiceInitialized = true;
        return;
      }
    }
    
    // Final check - use global handler if available
    if (globalAudioHandler != null && _audioHandler == null) {
      _audioHandler = globalAudioHandler;
      _isInitialized = true;
      _isAudioServiceInitialized = true;
    }
  }
}
