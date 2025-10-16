// lib/chat_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

import 'app_theme.dart';
import 'camera_settings.dart';
import 'apiservice.dart';
import 'youtubeplayer.dart';
import 'login.dart';

class ChatScreen extends StatefulWidget {
  final Function(CameraSettings) onSettingsReceived;

  const ChatScreen({Key? key, required this.onSettingsReceived}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isTyping = false;
  String? _pendingImagePath;
  bool _showRestorePrompt = true;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  // ====== 메시지 흐름 ======

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: "안녕하세요! 👋\n카메라 어시스턴트 CAMgent 입니다.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendMessage({required String text, String? imagePath}) {
    if (text.trim().isEmpty && imagePath == null) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      ));
    });
    _scrollToBottom();

    _processUserInput(text: text, imagePath: imagePath);
  }

  Future<void> _processUserInput({required String text, String? imagePath}) async {
    setState(() => _isTyping = true);
    try {
      await _sendToAgentica(text: text, imagePath: imagePath);
    } catch (e) {
      _addBotMessage(text: "처리 중 오류가 발생했습니다. 다시 시도해 주세요.");
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  Future<void> _sendToAgentica({required String text, String? imagePath}) async {
    try {
      final res = await ApiService.sendToAgentica(text, imagePath);

      // UX: 약간의 텀
      await Future.delayed(const Duration(milliseconds: 600));

      if (res.cameraSettings != null) {
        _addBotMessage(
          text: '카메라 설정을 적용했어요. 촬영을 시작해보세요! ✅',
          cameraSettings: res.cameraSettings,
        );
      } else if (res.url != null && res.url!.isNotEmpty) {
        _addBotMessage(
          text: "이런 숏츠 영상을 추천드려요!",
          youtubeUrl: res.url,
        );
      } else if (res.b64 != null && res.b64!.isNotEmpty) {
        try {
          final processedImageBytes = base64Decode(res.b64!);
          _addBotMessage(text: "보정 완료", image: processedImageBytes);
        } catch (_) {
          _addBotMessage(text: "이미지 처리 중 오류가 발생했습니다.");
        }
      } else {
        _addBotMessage(text: res.text.isNotEmpty ? res.text : "응답을 받지 못했습니다.");
      }
    } catch (e) {
      _addBotMessage(text: "죄송합니다. 서버 통신 오류가 발생했습니다. 다시 시도해 주세요.");
    }
  }

  void _addBotMessage({
    required String text,
    CameraSettings? cameraSettings,
    String? youtubeUrl,
    Uint8List? image,
  }) {
    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          cameraSettings: cameraSettings,
          youtubeUrl: youtubeUrl,
          image: image,
        ),
      );
    });
    _scrollToBottom();
  }

  // ====== 유틸 ======

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ====== 이미지 선택/촬영 ======

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) _sendImageMessage(image);
    } catch (e) {
      _showErrorSnackBar('이미지를 선택하는 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) _sendImageMessage(image);
    } catch (e) {
      _showErrorSnackBar('사진을 촬영하는 중 오류가 발생했습니다: $e');
    }
  }

  void _sendImageMessage(XFile image) {
    setState(() {
      _pendingImagePath = image.path;
    });
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            decoration: AppTheme.glass(radius: 16),
            margin: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('갤러리에서 선택'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('카메라로 촬영'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('취소'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ====== 이전 대화 불러오기 ======

  Future<void> _loadPreviousChats() async {
    setState(() => _isTyping = true);
    try {
      final List<dynamic> rawList = await ApiService.getConversation();


      final List<ChatMessage> prev = rawList.map<ChatMessage>((e) {
        if (e is Map) {
          final role = (e['role'] as String? ?? '').toLowerCase();
          if(role != 'user') print(e);

          String text = (e['text'] as String? ?? '');
          final String? youtubeUrl = e['youtubeUrl'] as String?;

          CameraSettings? cs;
          final csRaw = e['cameraSettings'];
          if (csRaw is Map<String, dynamic>) {
            cs = CameraSettings.fromJson(csRaw);
            if (text.trim().isEmpty) {
              text = '카메라 설정을 적용했어요. 촬영을 시작해보세요! ✅';
            }
          }

          Uint8List? imageBytes;
          final img64 = e['image'] as String?;
          if (img64 != null && img64.isNotEmpty) {
            try {
              print("??: => " + e['role']);
              if(e['role'] == 'user'){
                final aaa = img64.split(',')[1];
                imageBytes = base64Decode(aaa);
              }else{
                imageBytes = base64Decode(img64);
              }
              text = text.trim().isEmpty ? '보정 완료' : text;
            } catch (_) {}
          }

          return ChatMessage(
            text: text,
            isUser: role == 'user',
            timestamp: DateTime.now(),
            cameraSettings: cs,
            youtubeUrl: youtubeUrl,
            image: imageBytes,
          );
        }

        return ChatMessage(
          text: e.toString(),
          isUser: true,
          timestamp: DateTime.now(),
        );
      }).toList();

      setState(() {
        _messages.addAll(prev);
        _showRestorePrompt = false;
      });

      _scrollToBottom();
    } catch (err) {
      _showErrorSnackBar('이전 대화 불러오기 실패: $err');
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  // ====== UI ======

  @override
  Widget build(BuildContext context) {
    final disabled = _isTyping;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CAMgent Assistant'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_showRestorePrompt ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_showRestorePrompt && index == 1) { //
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 40.0, bottom: 8.0),
                              child: (islogin) ? _RestoreHistoryChip(
                                enabled: !_isTyping,
                                onLoad: () async {
                                  await _loadPreviousChats();
                                  _scrollToBottom();
                                },
                                onDismiss: () {
                                  setState(() => _showRestorePrompt = false);
                                },
                              ) : null,
                            ),
                          );
                        }

                        final shift = (_showRestorePrompt && index > 1) ? 1 : 0;
                        final msg = _messages[index - shift];
                        return _buildMessageBubble(msg);
                      },
                    ),
                  ],
                ),
              ),
              _buildInputArea(disabled: disabled),
            ],
          ),

          // 로딩 모달
          if (_isTyping) ...[
            ModalBarrier(color: Colors.black.withOpacity(0.25), dismissible: false),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glass(radius: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('서버 응답을 기다리는 중…'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 1) 아바타 + 말풍선
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: message.isUser
                            ? null
                            : Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 사용자가 보낸 이미지 (파일 경로)
                          if (message.imagePath != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(message.imagePath!),
                                width: 220,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // 봇이 보낸 이미지 (메모리)
                          if (message.image != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                message.image!,
                                width: 220,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final tmpDir = await getTemporaryDirectory();
                                    final tmpPath =
                                        '${tmpDir.path}/ai_${DateTime.now().millisecondsSinceEpoch}.png';
                                    final tmpFile = File(tmpPath);
                                    await tmpFile.writeAsBytes(message.image!);

                                    await Gal.putImage(tmpFile.path);

                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('갤러리에 저장되었습니다')),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('저장 중 오류: $e')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: const Text('갤러리에 저장'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                                  ),
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                  minimumSize: const Size(150, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.white.withOpacity(0.02),
                                ),
                              ),
                            ),
                          ],

                          // 텍스트
                          if (message.text.isNotEmpty) ...[
                            Text(
                              message.text,
                              style: TextStyle(
                                color: message.isUser ? Colors.black : Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 카메라 설정 버튼
                    if (message.cameraSettings != null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _applyCameraSettings(message.cameraSettings!),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('설정 적용하고 촬영하기'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white70, size: 16),
                ),
              ],
            ],
          ),

          // 2) YouTube 카드
          if (message.youtubeUrl != null) ...[
            const SizedBox(height: 8),
            YouTubePreviewTile(youtubeUrl: message.youtubeUrl!),
          ],
        ],
      ),
    );
  }

  // ====== 입력 영역 ======

  Widget _buildInputArea({required bool disabled}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_pendingImagePath != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_pendingImagePath!),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _pendingImagePath = null),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo),
                onPressed: disabled ? null : _showImagePickerDialog,
                tooltip: '사진 첨부',
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: !disabled,
                  decoration: InputDecoration(
                    hintText: disabled ? '처리 중…' : '원하는 촬영/보정/추천을 말씀해 주세요',
                    fillColor: Colors.white.withOpacity(0.04),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (t) => _handleSubmitted(t),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                width: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: disabled ? null : () => _handleSubmitted(_textController.text),
                  child: const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _applyCameraSettings(CameraSettings settings) {
    try {
      widget.onSettingsReceived(settings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라 설정이 적용되었습니다')),
      );
    } catch (e) {
      _showErrorSnackBar('설정 적용 중 오류가 발생했습니다: $e');
    }
  }

  void _handleSubmitted(String text) {
    if (_isTyping) return;
    final trimmed = text.trim();
    final hasImage = _pendingImagePath != null;
    if (trimmed.isEmpty && !hasImage) return;

    _sendMessage(text: trimmed, imagePath: _pendingImagePath);
    _textController.clear();
    setState(() => _pendingImagePath = null);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ====== 모델 ======

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final CameraSettings? cameraSettings;
  final String? imagePath;     // 사용자가 보낸 원본 이미지 경로
  final String? youtubeUrl;    // 추천 동영상 URL
  final Uint8List? image;      // 봇이 보낸 가공 이미지 (메모리)

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.cameraSettings,
    this.imagePath,
    this.youtubeUrl,
    this.image,
  });
}

// ====== 복원 칩 ======

class _RestoreHistoryChip extends StatelessWidget {
  final VoidCallback onLoad;
  final VoidCallback onDismiss;
  final bool enabled;

  const _RestoreHistoryChip({
    required this.onLoad,
    required this.onDismiss,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondary.withOpacity(0.18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onLoad : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history, size: 18),
              const SizedBox(width: 8),
              Text(enabled ? '이전 대화 불러오기' : '로딩 중…'),
              const SizedBox(width: 6),
              // TextButton(
              //   onPressed: enabled ? onDismiss : null,
              //   child: const Text('숨기기'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
