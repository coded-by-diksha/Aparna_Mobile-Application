import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/di/dependency_injection.dart';
import '../../main.dart';
import '../bloc/aama/aama_bloc.dart';
import '../bloc/aama/aama_event.dart';
import '../bloc/aama/aama_state.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/secure_session_service.dart';

class AamaScreen extends StatefulWidget {
  final String? userName;
  final int? userId;

  const AamaScreen({Key? key, this.userName, this.userId}) : super(key: key);

  @override
  State<AamaScreen> createState() => _AamaScreenState();
}

class _AamaScreenState extends State<AamaScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _token;
  int? _userId;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initializeScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLanguageChange();
  }

  Future<void> _checkLanguageChange() async {
    final newLang = await SecureSessionService.getLanguage() ?? 'en';
    if (newLang != _language) {
      _language = newLang;
      if (widget.userName != null && widget.userName!.isNotEmpty) {
        context.read<AamaBloc>().add(
          GetGreetingEvent(
            userName: widget.userName!,
            token: _token,
            language: _language,
          ),
        );
      }
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
      return;
    }

    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (!mounted) return;
        if (result.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone permission denied. Please enable it in Settings.'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required for voice input.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (!_speechEnabled) {
      _speechEnabled = await _speechToText.initialize();
    }

    if (_speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() => _isListening = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available on this device.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _messageController.text = result.recognizedWords;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  Future<void> _initializeScreen() async {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    _token = authRepo.getToken();
    _userId = widget.userId ?? authRepo.getUserId();

    _language = await SecureSessionService.getLanguage() ?? 'en';

    if (!mounted) return;

    context.read<AamaBloc>().add(
      InitializeAamaEvent(
        userName: widget.userName,
        userId: _userId,
        token: _token,
        language: _language,
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    context.read<AamaBloc>().add(
      SendMessageEvent(
        message: text,
        token: _token,
        userId: _userId,
        userName: widget.userName,
        language: _language,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask your query',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
            const Text(
              'Talk to Aama',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<AamaBloc, AamaState>(
        listener: (context, state) {
          if (state is AamaChatState) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          if (state is AamaInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E63)),
            );
          }

          final chatState = state is AamaChatState
              ? state
              : const AamaChatState();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      if (chatState.messages.isNotEmpty)
                        _buildMessageList(chatState),
                      if (chatState.messages.isEmpty)
                        _buildWelcomeSection(chatState),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              _buildInputSection(chatState.isLoading),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageList(AamaChatState chatState) {
    return BlocBuilder<AamaBloc, AamaState>(
      buildWhen: (prev, curr) {
        if (prev is AamaChatState && curr is AamaChatState) {
          return prev.messages != curr.messages || prev.isLoading != curr.isLoading;
        }
        return true;
      },
      builder: (context, state) {
        final cs = state is AamaChatState ? state : chatState;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: cs.messages.length,
          itemBuilder: (context, index) {
            final chatMessage = cs.messages[index];
            final isLastMessage = index == cs.messages.length - 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User message bubble
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        chatMessage.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Aama's response or loading indicator
                  if (chatMessage.response.isNotEmpty)
                    _buildAamaResponse(chatMessage.response)
                  else if (cs.isLoading && isLastMessage)
                    _buildThinkingIndicator(),
                  // Timestamp
                  if (chatMessage.response.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 48),
                      child: Text(
                        _formatTime(chatMessage.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeSection(AamaChatState chatState) {
    return BlocBuilder<AamaBloc, AamaState>(
      buildWhen: (prev, curr) {
        if (prev is AamaChatState && curr is AamaChatState) {
          return prev.greetingText != curr.greetingText || prev.isLoading != curr.isLoading;
        }
        return true;
      },
      builder: (context, state) {
        final cs = state is AamaChatState ? state : chatState;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAamaAvatar(24),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: cs.isLoading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Thinking...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              cs.greetingText.isEmpty
                                  ? 'Hello ${widget.userName ?? 'Nani'}...\nWhat can I do for you today?'
                                  : cs.greetingText,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAamaResponse(String response) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAamaAvatar(20),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              response,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAamaAvatar(20),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Thinking...',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAamaAvatar(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: Image.asset(
          'assets/aama.png',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: AppTheme.secondaryColor.withOpacity(0.3),
              child: Icon(
                Icons.person,
                size: radius * 1.2,
                color: AppTheme.primaryColor,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputSection(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      maxLines: 4,
                      minLines: 1,
                      textAlign: TextAlign.start,
                      textAlignVertical: TextAlignVertical.top,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        hintText: 'Ask aama...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),


                  //voice input button and on tap turn on the mic and actually listen to the user and when the user is done speaking, stop the mic and send the message to the server
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_off,
                      color: _isListening ? AppTheme.primaryColor : Colors.grey[700],
                    ),
                    onPressed: _toggleListening,
                    tooltip: 'Listen',
                  ),
                  // IconButton(
                  //   icon: Icon(
                  //     _isListening ? Icons.mic : Icons.mic_off,
                  //     color: _isListening ? AppTheme.primaryColor : Colors.grey[700],
                  //   ),
                  //   onPressed: _speechEnabled
                  //       ? (                    
                  //         _isListening ? _stopListening : _startListening)
                  //       : null,
                  //   tooltip: 'Listen',
                  // ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: isLoading ? Colors.grey : AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
              onPressed: isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _speechToText.stop();
    super.dispose();
  }
}
