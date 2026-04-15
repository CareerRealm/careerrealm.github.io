import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'skill_tree_map.dart'; // Injects unlocked skill RAG tags into mentor prompts

// ─────────────────────────────────────────────────────────────────────────────
// Enum: AI Backend
// ─────────────────────────────────────────────────────────────────────────────
enum AIBackend {
  groqLlama3,
  gemini15Flash,
  gemini25Flash,
}

extension AIBackendExt on AIBackend {
  String get label {
    switch (this) {
      case AIBackend.groqLlama3:
        return 'Groq (LLaMA-3 70B)';
      case AIBackend.gemini15Flash:
        return 'Gemini 1.5 Flash';
      case AIBackend.gemini25Flash:
        return 'Gemini 2.5 Flash';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enum: AI Companion Mode (the 3 specialized personas)
// ─────────────────────────────────────────────────────────────────────────────
enum AICompanionMode {
  academicMentor,
  resumeArchitect,
  openSourceMentor,
}

extension AICompanionModeExt on AICompanionMode {
  String get label {
    switch (this) {
      case AICompanionMode.academicMentor:    return '🎓 Academic Mentor';
      case AICompanionMode.resumeArchitect:   return '📄 Resume Architect';
      case AICompanionMode.openSourceMentor:  return '🔧 Open Source Mentor';
    }
  }

  String get description {
    switch (this) {
      case AICompanionMode.academicMentor:
        return 'Guides your studies with structured tasks, code snippets, and deep work tips.';
      case AICompanionMode.resumeArchitect:
        return 'Converts your RPG metrics into a professional JSON resume summary.';
      case AICompanionMode.openSourceMentor:
        return 'Recommends relevant repositories and explains why they match your learning path.';
    }
  }

  /// Build the system prompt for this mode, injecting real user RPG data.
  String buildSystemPrompt(AppUser? user) {
    final name        = user?.displayName ?? 'Scholar';
    final rank        = user?.rank        ?? '🌱 Seedling';
    final axp         = user?.axp         ?? 0;
    final pxp         = user?.pxp         ?? 0;
    final focusTime   = user?.formattedFocusTime ?? '0m';
    final skills      = user?.verifiedNodes.isNotEmpty == true
        ? user!.verifiedNodes.join(', ')
        : 'None verified yet';
    final sessions    = user?.sessionsCompleted ?? 0;

    switch (this) {

      // ── 1. Academic Mentor ─────────────────────────────────────────────────
      case AICompanionMode.academicMentor:
        return '''You are the Career Realm Academic Assistant for $name.
You must always format your responses using high-fidelity Markdown.
 * Use # for section titles.
 * Use > for 'Deep Work' tips or motivational quotes.
 * Use triple backtick code blocks with a language tag for any code snippets.
 * Use - [ ] for academic task checklists.

User Profile:
- Rank: $rank
- Academic XP (AXP): $axp
- Total Focus Time Logged: $focusTime
- Completed Study Sessions: $sessions
- Verified Skills: $skills

Constraint: Be encouraging but direct. If the user's logic is wrong, correct them immediately as an honest mentor. Always tailor your answer to their current AXP level — simpler explanations for low AXP, advanced depth for high AXP.''';

      // ── 2. Resume Architect ────────────────────────────────────────────────
      case AICompanionMode.resumeArchitect:
        return '''You are the Career Realm Professional Architect.
Your goal is to convert the provided user study logs and RPG metrics (AXP/PXP) into a structured professional summary.

STRICT RULE: Always respond in valid, well-formatted Markdown. When the user asks to generate a resume JSON, output ONLY a valid JSON object — no markdown code fences, no explanations.

User RPG Metrics:
- Name: $name
- Rank: $rank
- Academic XP (AXP): $axp
- Professional XP (PXP): $pxp
- Total Focus Time: $focusTime
- Completed Sessions: $sessions
- Verified Skills: $skills

Required JSON Schema when user requests resume generation:
{
  "header": {"name": "$name", "contact": "user@example.com", "title": "string"},
  "summary": "Professional summary based on verified skills",
  "skills": ["list of strings — only skills with sufficient PXP"],
  "experience": [{"project_name": "string", "verified_achievement": "string"}]
}

If the user has low PXP in a certain area, do not list it as a core skill. Be honest and precise. For every other question, respond in rich Markdown with professional career advice.''';

      // ── 3. Open Source Mentor ──────────────────────────────────────────────
      case AICompanionMode.openSourceMentor:
        // Derive the user's active RAG vocabulary from their unlocked skill nodes
        final ragTags = getUnlockedRagTags(user?.verifiedNodes ?? []);
        final ragContext = ragTags.isNotEmpty
            ? ragTags.join(', ')
            : 'general computer science, software development';
        return '''You are a Senior Open Source Mentor inside Career Realm for $name.

Your task: When the user describes what they are studying or asks for repository recommendations, provide detailed, structured guidance based on their **verified skill profile**.

Formatting rules:
 1. Use ## headers for repository or topic names.
 2. Use **bold** for specific libraries, files, or concepts they should focus on.
 3. Always provide a "Level of Difficulty" badge based on their AXP: 
    - AXP < 500  → 🟢 Beginner
    - AXP < 2000 → 🟡 Intermediate  
    - AXP >= 2000 → 🔴 Advanced
 4. Use > blockquotes for "Why this matters to your learning path" explanations.
 5. Use - [ ] checklists for concrete next steps.

User Context:
- Name: $name
- Current Rank: $rank
- Academic XP (AXP): $axp  → Difficulty: ${axp < 500 ? '🟢 Beginner' : axp < 2000 ? '🟡 Intermediate' : '🔴 Advanced'}
- Professional XP (PXP): $pxp
- Verified Skills: $skills
- Focus Time Logged: $focusTime

RAG Skill Vocabulary (topics from their unlocked skills — use these to match repos):
[$ragContext]

Always connect recommendations to the above skill vocabulary. When suggesting a GitHub repository, explain how it relates to their verified tags. Never recommend content that assumes skills more than two levels above their current AXP.''';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────
class KnowledgeArchitectChat extends StatefulWidget {
  const KnowledgeArchitectChat({super.key});

  @override
  State<KnowledgeArchitectChat> createState() => _KnowledgeArchitectChatState();
}

class _KnowledgeArchitectChatState extends State<KnowledgeArchitectChat> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = false;
  String? _error;

  // Active backend selector
  AIBackend _activeBackend = AIBackend.groqLlama3;

  // Active companion mode — controls the system prompt injected into the API
  AICompanionMode _activeMode = AICompanionMode.academicMentor;

  // Chat context: ordered list of {role, content} sent to the API on every request
  final List<Map<String, String>> _chatContext = [];

  // Displayed chat bubbles
  final List<MessageBubble> _messages = [];

  // All AI calls route through the Cloudflare Worker proxy at this base URL.
  // Keys (Gemini + Groq) are stored securely in Cloudflare env vars — never in this app.
  static const String _proxyBase = 'https://career-realm.marwan-wahid.workers.dev';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.isEmpty) _initializeChat();
  }

  void _initializeChat() {
    final user = context.read<AppProvider>().user;
    _rebuildSystemPrompt(user);

    final name = (user != null && user.displayName.isNotEmpty) ? user.displayName : 'Scholar';
    _messages.add(MessageBubble(
      text: 'Hello $name! 🚀 I am your **Career Companion** — currently in **${_activeMode.label}** mode.\n\n'
            '${_activeMode.description}\n\n'
            'How can I assist your professional journey today?',
      isUser: false,
    ));
  }

  /// Rebuilds the system prompt when the mode changes.
  void _rebuildSystemPrompt(AppUser? user) {
    _chatContext.clear();
    _chatContext.add({
      'role': 'system',
      'content': _activeMode.buildSystemPrompt(user),
    });
  }

  void _onBackendChanged(AIBackend? newBackend) {
    if (newBackend == null || newBackend == _activeBackend) return;
    setState(() {
      _activeBackend = newBackend;
      _messages.add(MessageBubble(
        text: '🔄 Switched cognitive engine to **${newBackend.label}**.',
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  void _onModeChanged(AICompanionMode? newMode) {
    if (newMode == null || newMode == _activeMode) return;
    final user = context.read<AppProvider>().user;
    setState(() {
      _activeMode = newMode;
      _rebuildSystemPrompt(user);
      _messages.add(MessageBubble(
        text: '🔄 Switched to **${newMode.label}** mode.\n\n${newMode.description}',
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(MessageBubble(text: text, isUser: true));
      _chatContext.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _scrollToBottom();

    try {
      String responseText;

      if (_activeBackend == AIBackend.groqLlama3) {
        responseText = await _callGroqAPI(_chatContext);
      } else {
        final modelId = _activeBackend == AIBackend.gemini25Flash
            ? 'gemini-2.5-flash'
            : 'gemini-1.5-flash';
        responseText = await _callFreeGeminiAPI(modelId);
      }

      _chatContext.add({'role': 'assistant', 'content': responseText});

      setState(() {
        _messages.add(MessageBubble(text: responseText, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(MessageBubble(
          text: '⚠ Connection Error: Failed to reach the **${_activeBackend.label}** provider.\n\n`$e`',
          isUser: false,
          isError: true,
        ));
        _chatContext.removeLast();
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  /// Gemini call — routed through Cloudflare Worker proxy (keys stored server-side)
  Future<String> _callFreeGeminiAPI(String model) async {
    final url = Uri.parse('$_proxyBase/gemini?model=$model');

    // Convert chat context to Gemini's {role, parts} format (skip system msg)
    final List<Map<String, dynamic>> contents = [];
    for (var msg in _chatContext) {
      if (msg['role'] == 'system') continue;
      contents.add({
        'role': msg['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': msg['content']}],
      });
    }

    final systemInstruction = _chatContext
        .firstWhere((e) => e['role'] == 'system', orElse: () => {'content': ''})['content']!;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-career-realm-app': 'true',
      },
      body: jsonEncode({
        'systemInstruction': {'parts': [{'text': systemInstruction}]},
        'contents': contents,
        'generationConfig': {'temperature': 0.7},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } else {
      throw Exception('Google API Error: ${response.statusCode} — ${response.body}');
    }
  }

  /// Groq call — routed through Cloudflare Worker proxy (keys stored server-side)
  Future<String> _callGroqAPI(List<Map<String, String>> messages) async {
    final url = Uri.parse('$_proxyBase/groq');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-career-realm-app': 'true',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': messages,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('Groq API Error: ${response.statusCode} — ${response.body}');
    }
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
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    }

    return Column(
      children: [
        // ── Top Toolbar: Mode selector + Backend selector ──────────────────
        _buildToolbar(),
        const SizedBox(height: 8),

        // ── Chat Window ────────────────────────────────────────────────────
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Input Box ──────────────────────────────────────────────────────
        _buildInputBar(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          // Mode selector chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AICompanionMode.values.map((mode) {
                  final sel = mode == _activeMode;
                  return GestureDetector(
                    onTap: () => _onModeChanged(mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.stroke,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? AppColors.primaryLight : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Backend dropdown
          DropdownButton<AIBackend>(
            value: _activeBackend,
            dropdownColor: AppColors.card,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 18),
            items: AIBackend.values
                .map((b) => DropdownMenuItem(value: b, child: Text(b.label)))
                .toList(),
            onChanged: _onBackendChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Ask your ${_activeMode.label} anything...',
                hintStyle: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                  child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MessageBubble widget
// ─────────────────────────────────────────────────────────────────────────────
class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isError;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary.withValues(alpha: 0.8)
              : isError
                  ? Colors.red.withValues(alpha: 0.3)
                  : AppColors.card,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft:
                isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: Border.all(
            color: isUser
                ? Colors.transparent
                : (isError ? Colors.redAccent : AppColors.stroke),
          ),
        ),
        child: MarkdownBody(
          data: text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            strong: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            em: const TextStyle(
                color: Colors.white, fontStyle: FontStyle.italic),
            listBullet:
                const TextStyle(color: Colors.white, fontSize: 14),
            blockquotePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            blockquoteDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3)),
              borderRadius: BorderRadius.circular(4),
            ),
            code: TextStyle(
              color: AppColors.primaryLight,
              backgroundColor: AppColors.surfaceLight,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            codeblockDecoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.stroke),
            ),
          ),
        ),
      ),
    );
  }
}
