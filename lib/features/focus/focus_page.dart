import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/models.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/settings_button.dart';
import 'widgets/decorative_timer.dart';
import 'widgets/break_options.dart';
import 'widgets/study_together_dialog.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  int _duration = 25 * 60;
  int _timeRemaining = 25 * 60;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isBreak = false;
  int _breakDuration = 0;
  int _breakTimeRemaining = 0;
  int _breaksTaken = 0;
  String _subject = 'Mathematics';
  String _focusMode = 'normal';
  bool _isEditingSubject = false;
  Timer? _timer;
  final _subjectController = TextEditingController(text: 'Mathematics');
  
  // Store final state before last 10 seconds
  String _savedSubject = 'Mathematics';
  String _savedFocusMode = 'normal';
  int _savedBreaksTaken = 0;
  bool _isInFinalTenSeconds = false;

  @override
  void initState() {
    super.initState();
    _subjectController.addListener(() {
      setState(() {
        _subject = _subjectController.text;
      });
    });
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subjectController.dispose();
    // Stop focusing status when leaving page
    Provider.of<AppProvider>(context, listen: false).stopFocusing();
    super.dispose();
  }

  void _startTimer() {
    // Cancel existing timer if any
    _timer?.cancel();
    
    // Update presence to focusing
    Provider.of<AppProvider>(context, listen: false).startFocusing(
      subject: _subject,
      durationMinutes: (_duration / 60).round(),
    );
    
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _isInFinalTenSeconds = false;
      // Save initial state
      _savedSubject = _subject;
      _savedFocusMode = _focusMode;
      _savedBreaksTaken = _breaksTaken;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isBreak) {
        if (_breakTimeRemaining > 0 && !_isPaused) {
          setState(() => _breakTimeRemaining--);
        } else if (_breakTimeRemaining == 0) {
          _endBreak();
        }
      } else {
        if (_timeRemaining > 0 && !_isPaused) {
          // Check if entering final 10 seconds
          if (_timeRemaining == 11 && !_isInFinalTenSeconds) {
            setState(() {
              _isInFinalTenSeconds = true;
              // Save final state before locking
              _savedSubject = _subject;
              _savedFocusMode = _focusMode;
              _savedBreaksTaken = _breaksTaken;
            });
          }
          setState(() => _timeRemaining--);
        } else if (_timeRemaining == 0) {
          _completeSession();
        }
      }
    });
  }

  void _endBreak() {
    setState(() {
      _isBreak = false;
      _isPaused = true; // Keep study timer paused after break
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('☕ Break over! Ready to focus?'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _endBreakManually() {
    setState(() {
      _isBreak = false;
      _isPaused = true;
      _breakTimeRemaining = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Break ended. Ready to focus!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
      // Update saved state when pausing (if not in final 10 seconds)
      if (!_isInFinalTenSeconds) {
        _savedSubject = _subject;
        _savedFocusMode = _focusMode;
        _savedBreaksTaken = _breaksTaken;
      }
    });
  }
  
  void _resumeTimer() {
    setState(() => _isPaused = false);
  }

  void _resetTimer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            const Text('Reset Session?'),
          ],
        ),
        content: const Text('This will reset your current session progress. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _timer?.cancel();
              // Update presence - no longer focusing
              Provider.of<AppProvider>(context, listen: false).stopFocusing();
              setState(() {
                _isRunning = false;
                _isPaused = false;
                _timeRemaining = _duration;
                _breaksTaken = 0;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _completeSession() async {
    _timer?.cancel();
    
    // Play completion sound
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print('Error playing sound: $e');
    }
    
    final provider = context.read<AppProvider>();
    
    // Update presence - no longer focusing
    await provider.stopFocusing();
    
    final actualDuration = (_duration - _timeRemaining) ~/ 60; // Actual time focused
    print('⏱️ Completing focus session: $actualDuration minutes');
    print('📝 Subject: $_savedSubject');
    print('🎯 Mode: $_savedFocusMode');
    print('☕ Breaks: $_savedBreaksTaken');
    
    // Use saved state (from before last 10 seconds)
    final newSession = FocusSession(
      id: const Uuid().v4(),
      durationMinutes: actualDuration > 0 ? actualDuration : 1,
      subjectTags: [_savedSubject],
      sessionDate: DateTime.now(),
      completed: true,
      breakCount: _savedBreaksTaken,
      focusMode: _savedFocusMode,
    );
    
    await provider.addFocusSession(newSession);
    
    print('✅ Focus session added to provider');
    print('📊 Total sessions now: ${provider.focusSessions.length}');
    
    // Reset everything to default state
    if (mounted) {
      setState(() {
        _isRunning = false;
        _isPaused = false;
        _isInFinalTenSeconds = false;
        _timeRemaining = _duration; // Reset to initial duration
        _breaksTaken = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 $_savedSubject session completed! Data saved.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTimerPicker() {
    if (_isRunning) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _TimerPickerSheet(
        initialMinutes: _duration ~/ 60,
        onSet: (minutes) {
          setState(() {
            _duration = minutes * 60;
            _timeRemaining = minutes * 60;
          });
        },
      ),
    );
  }

  void _showBreakOptions() {
    if (_focusMode == 'high') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔥 No breaks allowed in High Focus mode!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (_isInFinalTenSeconds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Cannot take break in final 10 seconds!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: BreakOptions(
            onSelect: (duration) {
              Navigator.pop(context);
              if (duration == -1) {
                // End session
                _timer?.cancel();
                setState(() {
                  _isRunning = false;
                  _isPaused = false;
                  _isBreak = false;
                  _timeRemaining = _duration;
                });
                _completeSession();
              } else {
                // Start break immediately
                setState(() {
                  _isBreak = true;
                  _isPaused = false;
                  _breakDuration = duration * 60;
                  _breakTimeRemaining = duration * 60;
                  _breaksTaken++;
                  // Update saved state when taking break
                  if (!_isInFinalTenSeconds) {
                    _savedBreaksTaken = _breaksTaken;
                    _savedSubject = _subject;
                    _savedFocusMode = _focusMode;
                  }
                });
                
                // Always start new timer for break
                _startTimer();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('☕ $duration min break started!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _showStudyTogetherDialog() {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (context) => StudyTogetherDialog(
        friends: provider.friends,
        onAction: (friendId, action) async {
          if (action.startsWith('invite')) {
            // Handle invite logic - send study together notification
            try {
              final friend = provider.friends.firstWhere((f) => f.id == friendId);
              final userName = provider.user?.fullName ?? 'Someone';
              final supabaseService = SupabaseService();
              await supabaseService.sendNotification(
                receiverId: friendId,
                message: '📚 $userName invited you to study together! Let\'s focus!',
              );
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invite sent to ${friend.name}! 🎉'),
                    backgroundColor: const Color(0xFF14B8A6),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send invite: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          } else if (action.startsWith('message:')) {
            // Handle message logic - send custom message notification
            try {
              final message = action.substring('message:'.length);
              final friend = provider.friends.firstWhere((f) => f.id == friendId);
              final supabaseService = SupabaseService();
              await supabaseService.sendNotification(
                receiverId: friendId,
                message: message,
              );
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message sent to ${friend.name}! 📬'),
                    backgroundColor: const Color(0xFF14B8A6),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send message: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  void _showFocusingFriends() {
    final provider = context.read<AppProvider>();
    final focusingFriends = provider.friends.where((f) => f.status == 'focusing').toList();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '${focusingFriends.length} Friends Focusing',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (focusingFriends.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No friends are focusing right now',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...focusingFriends.map((friend) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.orange,
                          child: Text(
                            friend.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.check, size: 8, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            friend.currentActivity ?? 'Focusing...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (friend.focusMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${friend.focusMinutes} min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Color get _modeColor {
    switch (_focusMode) {
      case 'mid':
        return const Color(0xFFF97316);
      case 'high':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFF14B8A6);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final currentMinutes = _isBreak ? _breakTimeRemaining : _timeRemaining;
    final currentDuration = _isBreak ? _breakDuration : _duration;
    
    final minutes = currentMinutes ~/ 60;
    final seconds = currentMinutes % 60;
    final progress = currentDuration == 0 ? 0.0 : ((currentDuration - currentMinutes) / currentDuration) * 100;
    
    final provider = context.watch<AppProvider>();
    final focusingFriends = provider.friends.where((f) => f.status == 'focusing').toList();

    final padding = Responsive.getPadding(context);
    final spacing = Responsive.getSpacing(context, 16);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Focus Mode',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(DateTime.now()),
                        style: TextStyle(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stay focused, stay productive',
                        style: TextStyle(fontSize: 14, color: AppColors.foreground.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                  const SettingsButton(),
                ],
              ),
              const SizedBox(height: 24),

              // Focus Mode Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeButton('normal', '😌 Normal', const Color(0xFF14B8A6)),
                  const SizedBox(width: 12),
                  _buildModeButton('mid', '🎯 Mid Focus', const Color(0xFFF97316)),
                  const SizedBox(width: 12),
                  _buildModeButton('high', '🔥 High Focus', const Color(0xFFFBBF24)),
                ],
              ),
              const SizedBox(height: 32),

              // Subject Name
              GestureDetector(
                onTap: (_isRunning && _isInFinalTenSeconds) 
                    ? null 
                    : () => setState(() => _isEditingSubject = true),
                child: _isEditingSubject
                    ? SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _subjectController,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          enabled: !(_isRunning && _isInFinalTenSeconds),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onSubmitted: (value) {
                            setState(() {
                              _subject = value.isEmpty ? 'Mathematics' : value;
                              _isEditingSubject = false;
                              // Update saved state if not in final 10 seconds
                              if (!_isInFinalTenSeconds) {
                                _savedSubject = _subject;
                              }
                            });
                          },
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _subject,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          if (!(_isRunning && _isInFinalTenSeconds))
                            const SizedBox(width: 8),
                          if (!(_isRunning && _isInFinalTenSeconds))
                            Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // Timer
              GestureDetector(
                onTap: _showTimerPicker,
                child: DecorativeTimer(
                  progress: progress,
                  mode: _focusMode,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: _modeColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isBreak && _isRunning && !_isPaused 
                            ? '☕ Break Time' 
                            : _isBreak && _isPaused 
                                ? '⏸ Break Paused'
                                : _isInFinalTenSeconds && _isRunning
                                    ? '🔒 Settings Locked'
                                    : _isRunning && !_isPaused 
                                        ? '✨ Focusing' 
                                        : _isPaused 
                                            ? '⏸ Paused' 
                                            : '🎯 Ready',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _isInFinalTenSeconds && _isRunning
                              ? Colors.orange
                              : AppColors.foreground.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(Icons.refresh, _resetTimer),
                  const SizedBox(width: 16),
                  _buildMainButton(),
                  const SizedBox(width: 16),
                  _focusMode == 'high'
                      ? Opacity(
                          opacity: 0.3,
                          child: _buildControlButton(
                            Icons.coffee,
                            () {}, // Disabled in high focus mode
                          ),
                        )
                      : _buildControlButton(
                          _isBreak ? Icons.stop_circle_outlined : Icons.coffee,
                          _isBreak ? _endBreakManually : _showBreakOptions,
                        ),
                ],
              ),
              const SizedBox(height: 24),

              // Study Together Button
              GestureDetector(
                onTap: _showStudyTogetherDialog,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Study Together',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // See Focusing Friends Button
              GestureDetector(
                onTap: _showFocusingFriends,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF14B8A6)),
                      const SizedBox(width: 8),
                      Text(
                        '${focusingFriends.length} Friends Focusing',
                        style: const TextStyle(
                          color: Color(0xFF14B8A6),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Today's Focus History
              _buildTodayHistory(provider),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String mode, String label, Color color) {
    final isSelected = _focusMode == mode;
    final isDisabled = _isRunning && _isInFinalTenSeconds;
    return GestureDetector(
      onTap: isDisabled ? null : () {
        setState(() {
          _focusMode = mode;
          // Update saved state if not in final 10 seconds
          if (!_isInFinalTenSeconds) {
            _savedFocusMode = mode;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)]) : null,
          color: isSelected ? null : (isDisabled ? Colors.grey.shade300 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDisabled 
                ? Colors.grey.shade500
                : (isSelected ? Colors.white : AppColors.foreground.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: _isRunning && !_isPaused 
          ? _pauseTimer 
          : (_isRunning && _isPaused ? _resumeTimer : _startTimer),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _focusMode == 'normal'
                ? [const Color(0xFF14B8A6), const Color(0xFF06B6D4)]
                : _focusMode == 'mid'
                    ? [const Color(0xFFF472B6), const Color(0xFFFB923C)]
                    : [const Color(0xFFFBBF24), const Color(0xFFF97316)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _modeColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          _isRunning && !_isPaused ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildTodayHistory(AppProvider provider) {
    final today = DateTime.now();
    final todaySessions = provider.focusSessions.where((s) {
      return s.sessionDate.year == today.year &&
             s.sessionDate.month == today.month &&
             s.sessionDate.day == today.day;
    }).toList();

    if (todaySessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No focus sessions today',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start your first session!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    final totalMinutes = todaySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accentBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accentBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Today's Focus History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              // Clear All Button
              GestureDetector(
                onTap: () => _showClearAllDialog(provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Focus Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${todaySessions.length} session${todaySessions.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...todaySessions.map((session) {
            final timeStr = DateFormat('h:mm a').format(session.sessionDate);
            final durationStr = session.durationMinutes >= 60
                ? '${session.durationMinutes ~/ 60}h ${session.durationMinutes % 60}m'
                : '${session.durationMinutes}m';
            
            return Dismissible(
              key: Key(session.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Delete Session?'),
                    content: const Text('This will permanently delete this focus session.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                provider.deleteFocusSession(session.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session deleted')),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accentBlue],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.subjectTags.isNotEmpty 
                                ? session.subjectTags.first 
                                : 'Focus Session',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getModeColor(session.focusMode).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  session.focusMode.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: _getModeColor(session.focusMode),
                                  ),
                                ),
                              ),
                              if (session.breakCount > 0) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.coffee, size: 10, color: Colors.grey.shade400),
                                const SizedBox(width: 2),
                                Text(
                                  '${session.breakCount}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      durationStr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  Color _getModeColor(String mode) {
    switch (mode) {
      case 'mid':
        return const Color(0xFFF472B6);
      case 'high':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF14B8A6);
    }
  }

  void _showClearAllDialog(AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            const Text('Clear All Sessions?'),
          ],
        ),
        content: const Text(
          'This will permanently delete ALL your focus sessions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.clearAllFocusSessions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All sessions cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TimerPickerSheet extends StatefulWidget {
  final int initialMinutes;
  final Function(int) onSet;

  const _TimerPickerSheet({required this.initialMinutes, required this.onSet});

  @override
  State<_TimerPickerSheet> createState() => _TimerPickerSheetState();
}

class _TimerPickerSheetState extends State<_TimerPickerSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMinutes.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Set Timer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 8),
          Text('minutes', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final mins = int.tryParse(_controller.text) ?? 25;
                    widget.onSet(mins);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Set Timer', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
