import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/voice_controller.dart';

/// 🎤 Voice Control Button Widget
///
/// Nút điều khiển bằng giọng nói với UI đẹp
class VoiceControlButton extends StatefulWidget {
  final VoidCallback? onCommandExecuted;

  const VoiceControlButton({Key? key, this.onCommandExecuted})
    : super(key: key);

  @override
  State<VoiceControlButton> createState() => _VoiceControlButtonState();
}

class _VoiceControlButtonState extends State<VoiceControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceController>(
      builder: (context, voiceController, child) {
        // Nếu chưa initialized, hiện loading
        if (!voiceController.isInitialized) {
          return Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
              ),
            ),
          );
        }

        final isListening = voiceController.isListening;
        final isProcessing = voiceController.isProcessing;
        final isBusy = voiceController.isBusy;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Text
            if (voiceController.statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _getStatusColor(voiceController).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(voiceController).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(voiceController),
                      size: 16,
                      color: _getStatusColor(voiceController),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        voiceController.statusMessage,
                        style: TextStyle(
                          color: _getStatusColor(voiceController),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

            // Voice Button
            GestureDetector(
              onTap: isProcessing
                  ? null
                  : () => _handleTap(
                      voiceController,
                    ), // ✅ Cho phép bấm dừng khi đang nghe
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse effect khi đang nghe
                      if (isListening)
                        Container(
                          width: 80 * _pulseAnimation.value,
                          height: 80 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),

                      // Main button
                      Transform.scale(
                        scale: isListening ? _scaleAnimation.value : 1.0,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _getButtonColors(
                                isListening,
                                isProcessing,
                              ),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getButtonColors(
                                  isListening,
                                  isProcessing,
                                )[0].withOpacity(0.4),
                                blurRadius: isListening ? 20 : 10,
                                spreadRadius: isListening ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getButtonIcon(isListening, isProcessing),
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Last Command
            if (voiceController.lastCommand.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"${voiceController.lastCommand}"',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }

  void _handleTap(VoiceController voiceController) async {
    if (voiceController.isListening) {
      await voiceController.stopListening();
    } else {
      await voiceController.startListening();
    }
  }

  List<Color> _getButtonColors(bool isListening, bool isProcessing) {
    if (isProcessing) {
      return [Colors.orange.shade400, Colors.orange.shade600];
    } else if (isListening) {
      return [Colors.red.shade400, Colors.red.shade600];
    } else {
      return [Colors.blue.shade400, Colors.blue.shade600];
    }
  }

  IconData _getButtonIcon(bool isListening, bool isProcessing) {
    if (isProcessing) {
      return Icons.psychology; // AI processing
    } else if (isListening) {
      return Icons.mic;
    } else {
      return Icons.mic_none;
    }
  }

  Color _getStatusColor(VoiceController voiceController) {
    if (voiceController.statusMessage.contains('❌')) {
      return Colors.red;
    } else if (voiceController.statusMessage.contains('✅')) {
      return Colors.green;
    } else if (voiceController.statusMessage.contains('🤖')) {
      return Colors.orange;
    } else if (voiceController.statusMessage.contains('🎤')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  IconData _getStatusIcon(VoiceController voiceController) {
    if (voiceController.statusMessage.contains('❌')) {
      return Icons.error_outline;
    } else if (voiceController.statusMessage.contains('✅')) {
      return Icons.check_circle_outline;
    } else if (voiceController.statusMessage.contains('🤖')) {
      return Icons.psychology;
    } else if (voiceController.statusMessage.contains('🎤')) {
      return Icons.mic;
    } else {
      return Icons.info_outline;
    }
  }
}
