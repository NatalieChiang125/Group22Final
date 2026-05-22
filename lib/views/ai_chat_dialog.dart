import 'package:flutter/material.dart';
import 'dart:async';

// --- 模擬從 ../types 與 ../services 引入的資料結構 ---
class RecommendationRequirement {
  // 根據專案結構自訂欄位
}

// 模擬 AI 串接服務
class AIService {
  static Future<Map<String, dynamic>> processRecommendationChat(
      List<Map<String, dynamic>> history, String userMsg) async {
    // 模擬網路延遲
    await Future.delayed(const Duration(seconds: 1));
    return {
      'reply': 'I have updated your meal preferences based on "$userMsg". Let me know if you need anything else!',
      'requirement': RecommendationRequirement(), // 模擬回傳更新的需求
    };
  }
}

class ChatMessage {
  final String role; // 'user' | 'model'
  final String content;

  ChatMessage({required this.role, required this.content});
}
// --------------------------------------------------

class AIChatDialog extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<RecommendationRequirement> onUpdateRequirement;

  const AIChatDialog({
    Key? key,
    required this.onClose,
    required this.onUpdateRequirement,
  }) : super(key: key);

  @override
  State<AIChatDialog> createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<AIChatDialog> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [
    ChatMessage(
      role: 'model',
      content: "Hello! I'm Wise AI. How can I help you refine your meal recommendations today? You can tell me things like 'I'm looking for something light' or 'I need more protein'.",
    )
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _isSyncing = false;

  final List<String> _suggestions = [
    "High protein options",
    "Under \$15 lunch",
    "Italian vibes",
    "Healthy & quick"
  ];

  // 用於右上角綠色在線圓點的呼吸動畫
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
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

  Future<void> _handleSubmit(String text) async {
    final userMsg = text.trim();
    if (userMsg.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: userMsg));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // 轉換歷史紀錄格式
      final history = _messages.map((m) => {
        'role': m.role,
        'parts': [{'text': m.content}]
      }).toList();

      final result = await AIService.processRecommendationChat(history, userMsg);
      
      setState(() {
        _messages.add(ChatMessage(role: 'model', content: result['reply']));
        
        if (result['requirement'] != null) {
          _isSyncing = true;
          widget.onUpdateRequirement(result['requirement']);
          // 模擬 React 的 setTimeout(() => setIsSyncing(false), 2000)
          Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _isSyncing = false);
          });
        }
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(role: 'model', content: "Sorry, I encountered an error. Please try again."));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 響應式佈局：如果是寬螢幕，靠右側顯示固定寬度
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 640;

    return Scaffold(
      backgroundColor: Colors.transparent, // 讓背景可以透出毛玻璃與遮罩
      body: Stack(
        children: [
          // 1. Backdrop Overlay (遮罩)
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: const Color(0xFF0F172A).withOpacity(0.6), // bg-slate-900/60
            ),
          ),
          
          // 2. Main Chat Panel (右側滑入面板)
          Align(
            alignment: isDesktop ? Alignment.centerRight : Alignment.bottomCenter,
            child: Container(
              width: isDesktop ? 450 : double.infinity,
              height: isDesktop ? 800 : double.infinity,
              margin: isDesktop ? const EdgeInsets.all(24) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: isDesktop ? BorderRadius.circular(40) : const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 4)),
                ],
              ),
              child: SafeArea(
                bottom: !isDesktop,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildSyncIndicator(),
                    Expanded(child: _buildChatArea()),
                    _buildInputArea(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA5B4FC)]), // wise-gradient
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.2).animate(
                        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wise AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ALWAYS LEARNING',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 24),
            splashRadius: 20,
          )
        ],
      ),
    );
  }

  Widget _buildSyncIndicator() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: _isSyncing
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              //  統一收進 BoxDecoration
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5), // 注意：設定了 decoration，color 就必須移進來，否則會報錯！
                border: Border(
                  bottom: BorderSide(color: Color(0xFFD1FAE5)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'OPTIMIZING RECOMMENDATIONS...',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669), letterSpacing: 1.2),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildChatArea() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(32),
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length) {
            return _buildLoadingBubble(); // 顯示打字中動畫
          }
          final msg = _messages[index];
          final bool isModel = msg.role == 'model';

          return Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: isModel ? TextDirection.ltr : TextDirection.rtl,
              children: [
                // 頭像
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isModel ? null : const Color(0xFF0F172A),
                    gradient: isModel ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA5B4FC)]) : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(isModel ? Icons.smart_toy : Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                // 訊息內文
                Container(
                  width: MediaQuery.of(context).size.width * 0.65,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isModel ? Colors.white : const Color(0xFF6366F1), // 改用品牌藍代表 User
                    border: isModel ? Border.all(color: const Color(0xFFF1F5F9)) : null,
                    borderRadius: BorderRadius.only(
                      topLeft: isModel ? Radius.zero : const Radius.circular(24),
                      topRight: isModel ? const Radius.circular(24) : Radius.zero,
                      bottomLeft: const Radius.circular(24),
                      bottomRight: const Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: isModel ? const Color(0xFF334155) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA5B4FC)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF1F5F9)),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: const TypingIndicator(),
          )
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          // 快速建議選單
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                return InkWell(
                  onTap: () => _inputController.text = _suggestions[idx],
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      _suggestions[idx],
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // 輸入表單
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: TextField(
                    controller: _inputController,
                    onSubmitted: _handleSubmit,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _handleSubmit(_inputController.text),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

// 仿三點跳動/閃爍的打字中指示器
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double delay = index * 0.2;
            double progress = _controller.value - delay;
            if (progress < 0) progress += 1.0;
            if (progress > 1.0) progress -= 1.0;
            
            final double opacity = progress < 0.5 ? (progress * 2) : (1.0 - (progress - 0.5) * 2);

            return Opacity(
              opacity: opacity.clamp(0.2, 1.0),
              child: Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
              ),
            );
          },
        );
      }),
    );
  }
}