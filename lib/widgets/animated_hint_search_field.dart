import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/app_theme.dart';

/// A search text field that shows a rotating "ticker" carousel of placeholder
/// phrases when empty and not focused (e.g. "Find Flats...", "Find Plots..."),
/// switching to a normal blinking cursor the moment the user taps in or types.
/// Includes a filter button and a mic (voice search) button inside the same box.
class AnimatedHintSearchField extends StatefulWidget {
  final TextEditingController controller;
  final List<String> hints;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;
  final ValueChanged<bool>? onFocusChanged; // notifies parent when field gains/loses focus
  final double iconSize; // change this to resize the search/filter/mic icons
  final double fontSize; // change this to resize the typed/hint text
  final Duration rotateInterval; // change this to speed up/slow down the ticker

  const AnimatedHintSearchField({
    super.key,
    required this.controller,
    required this.hints,
    this.onSubmitted,
    this.onFilterTap,
    this.hasActiveFilters = false,
    this.onFocusChanged,
    this.iconSize = 22,
    this.fontSize = 16,
    this.rotateInterval = const Duration(seconds: 2),
  });

  @override
  State<AnimatedHintSearchField> createState() => _AnimatedHintSearchFieldState();
}

class _AnimatedHintSearchFieldState extends State<AnimatedHintSearchField>
    with SingleTickerProviderStateMixin {
  int _currentHintIndex = 0;
  Timer? _rotateTimer;
  bool _hasFocus = false;
  late final FocusNode _focusNode;
  late final AnimationController _tickerController;

  // Voice search
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _recognitionLocale = 'en_IN'; // long-press the mic to switch to hi_IN

  double get _tickerHeight => widget.fontSize + 8;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
      widget.onFocusChanged?.call(_focusNode.hasFocus);
    });

    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _tickerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % widget.hints.length;
        });
        _tickerController.value = 0; // reset instantly, ready for the next cycle
      }
    });
    _rotateTimer = Timer.periodic(widget.rotateInterval, (_) {
      if (!mounted || widget.hints.length < 2) return;
      _tickerController.forward(from: 0);
    });

    widget.controller.addListener(_onTextChanged);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _onTextChanged() => setState(() {});

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice search is not available on this device.')),
      );
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      localeId: _recognitionLocale,
      onResult: (result) {
        widget.controller.text = result.recognizedWords;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
        if (result.finalResult) {
          setState(() => _isListening = false);
          widget.onSubmitted?.call(result.recognizedWords);
        }
      },
    );
  }

  void _switchRecognitionLanguage() {
    setState(() {
      _recognitionLocale = _recognitionLocale == 'en_IN' ? 'hi_IN' : 'en_IN';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _recognitionLocale == 'hi_IN'
              ? 'Voice search set to Hindi'
              : 'Voice search set to English',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _tickerController.dispose();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  Widget _hintText(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: widget.fontSize, color: AppColors.textMuted),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final showRotatingHint = widget.controller.text.isEmpty && !_hasFocus;
    final nextHintIndex = (_currentHintIndex + 1) % widget.hints.length;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white, // change this to recolor the search box itself
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.search, size: widget.iconSize, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (showRotatingHint)
                  ClipRect(
                    child: SizedBox(
                      height: _tickerHeight,
                      child: AnimatedBuilder(
                        animation: _tickerController,
                        builder: (context, _) {
                          final progress = _tickerController.value;
                          return Stack(
                            children: [
                              // Current phrase slides UP and fades out
                              Transform.translate(
                                offset: Offset(0, -progress * _tickerHeight),
                                child: Opacity(
                                  opacity: 1 - progress,
                                  child: _hintText(widget.hints[_currentHintIndex]),
                                ),
                              ),
                              // Next phrase slides UP from below and fades in
                              Transform.translate(
                                offset: Offset(0, (1 - progress) * _tickerHeight),
                                child: Opacity(
                                  opacity: progress,
                                  child: _hintText(widget.hints[nextHintIndex]),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  style: TextStyle(fontSize: widget.fontSize, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: widget.onSubmitted,
                ),
              ],
            ),
          ),
          // Mic button - long-press to switch between English and Hindi recognition
          GestureDetector(
            onLongPress: _switchRecognitionLanguage,
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: widget.iconSize,
                color: _isListening ? AppColors.primary : AppColors.textMuted,
              ),
              onPressed: _toggleListening,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Voice search (long-press to switch language)',
            ),
          ),
          if (widget.onFilterTap != null) ...[
            const SizedBox(width: 4),
            Container(width: 1, height: 24, color: AppColors.cardBorder), // simple divider
            const SizedBox(width: 4),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(Icons.filter_list, size: widget.iconSize + 2, color: AppColors.accent),
                  onPressed: widget.onFilterTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                if (widget.hasActiveFilters)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}