import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SkillNode — a single node in the Career Realm skill tree.
// Each node has a required PXP to unlock, an optional parent, and
// RAG keyword tags that feed the Open Source Mentor's repo recommendations.
// ─────────────────────────────────────────────────────────────────────────────
class SkillNode {
  final String id;
  final String label;
  final String emoji;
  final String? parentId;     // null = root domain node
  final int pxpRequired;      // PXP needed to unlock this node
  final List<String> ragTags; // keywords fed to RAG / Open Source Mentor

  const SkillNode({
    required this.id,
    required this.label,
    required this.emoji,
    this.parentId,
    required this.pxpRequired,
    this.ragTags = const [],
  });

  bool isUnlocked(int userPxp) => userPxp >= pxpRequired;
}

// ─────────────────────────────────────────────────────────────────────────────
// Full skill catalogue — roots + children.
// PXP thresholds: roots are cheap; deep specialisations cost more.
// ─────────────────────────────────────────────────────────────────────────────
const List<SkillNode> kSkillTree = [

  // ── Computing Core (root) ─────────────────────────────────────────────────
  SkillNode(id: 'comp_core', label: 'Computing Core', emoji: '💻',
      pxpRequired: 0,
      ragTags: ['computer science', 'programming basics', 'CS fundamentals']),

  SkillNode(id: 'os',           label: 'Operating Systems', emoji: '🖥️',  parentId: 'comp_core', pxpRequired: 50,
      ragTags: ['linux kernel', 'process scheduling', 'memory management']),
  SkillNode(id: 'networking',   label: 'Networking',        emoji: '🌐',  parentId: 'comp_core', pxpRequired: 80,
      ragTags: ['TCP/IP', 'networking protocols', 'socket programming']),
  SkillNode(id: 'hardware',     label: 'Hardware & SoC',    emoji: '🔌',  parentId: 'comp_core', pxpRequired: 60,
      ragTags: ['embedded systems', 'microcontrollers', 'FPGA']),
  SkillNode(id: 'comp_arch',    label: 'Computer Arch.',    emoji: '⚙️',  parentId: 'comp_core', pxpRequired: 100,
      ragTags: ['CPU architecture', 'RISC-V', 'instruction set']),

  // ── Algorithms (root) ─────────────────────────────────────────────────────
  SkillNode(id: 'algorithms', label: 'Algorithms', emoji: '🧮',
      pxpRequired: 0,
      ragTags: ['data structures', 'algorithms', 'competitive programming']),

  SkillNode(id: 'sorting',    label: 'Sorting & Search', emoji: '📊', parentId: 'algorithms', pxpRequired: 30,
      ragTags: ['sorting algorithms', 'binary search', 'complexity']),
  SkillNode(id: 'graphs',     label: 'Graph Theory',     emoji: '🕸️', parentId: 'algorithms', pxpRequired: 120,
      ragTags: ['graph algorithms', 'BFS DFS', 'shortest path', 'Dijkstra']),
  SkillNode(id: 'dp',         label: 'Dynamic Prog.',    emoji: '🧩', parentId: 'algorithms', pxpRequired: 180,
      ragTags: ['dynamic programming', 'memoization', 'optimization']),
  SkillNode(id: 'cp',         label: 'Competitive Prog.', emoji: '🏆', parentId: 'algorithms', pxpRequired: 300,
      ragTags: ['competitive programming', 'LeetCode', 'Codeforces']),

  // ── Software Architecture (root) ──────────────────────────────────────────
  SkillNode(id: 'architecture', label: 'Architecture', emoji: '🏗️',
      pxpRequired: 0,
      ragTags: ['software architecture', 'design patterns', 'clean code']),

  SkillNode(id: 'oop',        label: 'OOP & SOLID',     emoji: '🔷', parentId: 'architecture', pxpRequired: 40,
      ragTags: ['object oriented programming', 'SOLID principles', 'design patterns']),
  SkillNode(id: 'clean_arch', label: 'Clean Arch.',     emoji: '🧼', parentId: 'architecture', pxpRequired: 200,
      ragTags: ['clean architecture', 'hexagonal architecture', 'DDD']),
  SkillNode(id: 'microsvcs',  label: 'Microservices',   emoji: '🔬', parentId: 'architecture', pxpRequired: 350,
      ragTags: ['microservices', 'API gateway', 'service mesh', 'gRPC']),
  SkillNode(id: 'system_design', label: 'System Design', emoji: '📐', parentId: 'architecture', pxpRequired: 500,
      ragTags: ['system design', 'scalability', 'load balancing', 'CAP theorem']),

  // ── Mobile/UI (root) ──────────────────────────────────────────────────────
  SkillNode(id: 'mobile_ui', label: 'Mobile & UI', emoji: '📱',
      pxpRequired: 0,
      ragTags: ['mobile development', 'UI design', 'cross-platform']),

  SkillNode(id: 'flutter',    label: 'Flutter / Dart',  emoji: '🐦', parentId: 'mobile_ui', pxpRequired: 100,
      ragTags: ['Flutter', 'Dart', 'widget tree', 'state management']),
  SkillNode(id: 'react_native', label: 'React Native',  emoji: '⚛️', parentId: 'mobile_ui', pxpRequired: 150,
      ragTags: ['React Native', 'Expo', 'JavaScript mobile']),
  SkillNode(id: 'ux_design',  label: 'UX/UI Design',    emoji: '🎨', parentId: 'mobile_ui', pxpRequired: 80,
      ragTags: ['UX design', 'Figma', 'design systems', 'accessibility']),

  // ── Databases (root) ──────────────────────────────────────────────────────
  SkillNode(id: 'databases', label: 'Databases', emoji: '🗄️',
      pxpRequired: 0,
      ragTags: ['database design', 'SQL', 'NoSQL']),

  SkillNode(id: 'sql',        label: 'Relational SQL',   emoji: '🔡', parentId: 'databases', pxpRequired: 70,
      ragTags: ['SQL', 'PostgreSQL', 'MySQL', 'database normalization']),
  SkillNode(id: 'nosql',      label: 'NoSQL / Document', emoji: '📄', parentId: 'databases', pxpRequired: 90,
      ragTags: ['MongoDB', 'Firestore', 'document database', 'NoSQL']),
  SkillNode(id: 'vector_db',  label: 'Vector Search',    emoji: '🔢', parentId: 'databases', pxpRequired: 400,
      ragTags: ['vector database', 'Pinecone', 'embeddings', 'semantic search']),

  // ── Cloud Backend (root) ──────────────────────────────────────────────────
  SkillNode(id: 'cloud', label: 'Cloud Backend', emoji: '🌥️',
      pxpRequired: 0,
      ragTags: ['cloud computing', 'backend development', 'serverless']),

  SkillNode(id: 'firebase',   label: 'Firebase',         emoji: '🔥', parentId: 'cloud', pxpRequired: 150,
      ragTags: ['Firebase', 'Firestore', 'Firebase Auth', 'Cloud Functions']),
  SkillNode(id: 'gcp',        label: 'Google Cloud',     emoji: '☁️', parentId: 'cloud', pxpRequired: 300,
      ragTags: ['GCP', 'Cloud Run', 'BigQuery', 'Vertex AI']),
  SkillNode(id: 'aws',        label: 'AWS',              emoji: '🟠', parentId: 'cloud', pxpRequired: 300,
      ragTags: ['AWS', 'Lambda', 'EC2', 'S3', 'DynamoDB']),
  SkillNode(id: 'devops',     label: 'DevOps / CI/CD',   emoji: '🔄', parentId: 'cloud', pxpRequired: 250,
      ragTags: ['DevOps', 'Docker', 'Kubernetes', 'GitHub Actions', 'CI/CD']),
  SkillNode(id: 'containers', label: 'Containers',       emoji: '🐳', parentId: 'devops', pxpRequired: 280,
      ragTags: ['Docker', 'Kubernetes', 'container orchestration']),

  // ── AI / LLM (root) ───────────────────────────────────────────────────────
  SkillNode(id: 'ai_ml', label: 'AI & Machine Learning', emoji: '🧠',
      pxpRequired: 0,
      ragTags: ['machine learning', 'AI', 'deep learning']),

  SkillNode(id: 'ml_basics',  label: 'ML Fundamentals',  emoji: '📈', parentId: 'ai_ml', pxpRequired: 200,
      ragTags: ['scikit-learn', 'supervised learning', 'regression', 'classification']),
  SkillNode(id: 'deep_learn', label: 'Deep Learning',    emoji: '🤖', parentId: 'ai_ml', pxpRequired: 400,
      ragTags: ['PyTorch', 'TensorFlow', 'neural networks', 'CNNs', 'transformers']),
  SkillNode(id: 'llm_agents', label: 'LLM Agents',       emoji: '🦾', parentId: 'ai_ml', pxpRequired: 600,
      ragTags: ['LangChain', 'LlamaIndex', 'RAG', 'LLM', 'prompt engineering', 'agents']),
  SkillNode(id: 'rag',        label: 'RAG Systems',      emoji: '📚', parentId: 'llm_agents', pxpRequired: 700,
      ragTags: ['retrieval augmented generation', 'vector search', 'embeddings', 'knowledge base']),
  SkillNode(id: 'cv',         label: 'Computer Vision',  emoji: '👁️', parentId: 'ai_ml', pxpRequired: 500,
      ragTags: ['OpenCV', 'YOLO', 'image classification', 'object detection']),

  // ── Cybersecurity (root) — NEW ────────────────────────────────────────────
  SkillNode(id: 'cybersec', label: 'Cybersecurity', emoji: '🛡️',
      pxpRequired: 0,
      ragTags: ['cybersecurity', 'information security', 'CTF']),

  SkillNode(id: 'red_team',   label: 'Red Teaming',        emoji: '🔴', parentId: 'cybersec', pxpRequired: 400,
      ragTags: ['red team', 'offensive security', 'adversarial simulation', 'attack simulation']),
  SkillNode(id: 'pentest',    label: 'Penetration Testing', emoji: '💉', parentId: 'cybersec', pxpRequired: 350,
      ragTags: ['penetration testing', 'ethical hacking', 'Metasploit', 'Burp Suite', 'Kali Linux']),
  SkillNode(id: 'blue_team',  label: 'Blue Teaming',        emoji: '🔵', parentId: 'cybersec', pxpRequired: 300,
      ragTags: ['blue team', 'SOC', 'SIEM', 'incident response', 'threat hunting']),
  SkillNode(id: 'osint',      label: 'OSINT',               emoji: '🔍', parentId: 'cybersec', pxpRequired: 200,
      ragTags: ['OSINT', 'open source intelligence', 'reconnaissance', 'Shodan', 'Maltego']),
  SkillNode(id: 'malware',    label: 'Malware Analysis',    emoji: '🦠', parentId: 'cybersec', pxpRequired: 500,
      ragTags: ['malware analysis', 'reverse engineering', 'IDA Pro', 'Ghidra', 'binary analysis']),
  SkillNode(id: 'crypto_sec', label: 'Cryptography',        emoji: '🔐', parentId: 'cybersec', pxpRequired: 280,
      ragTags: ['cryptography', 'encryption', 'PKI', 'TLS', 'hashing algorithms']),
  SkillNode(id: 'web_sec',    label: 'Web Security',        emoji: '🌐', parentId: 'cybersec', pxpRequired: 250,
      ragTags: ['OWASP Top 10', 'XSS', 'SQL injection', 'web vulnerabilities', 'CSRF']),

  // ── pen-testing children ──────────────────────────────────────────────────
  SkillNode(id: 'webapp_pentest', label: 'Web App Pentesting', emoji: '🕷️', parentId: 'pentest', pxpRequired: 420,
      ragTags: ['web application security', 'DAST', 'OWASP', 'Burp Suite Pro']),
  SkillNode(id: 'network_pentest', label: 'Network Pentesting', emoji: '📡', parentId: 'pentest', pxpRequired: 450,
      ragTags: ['nmap', 'network scanning', 'pivot', 'lateral movement']),
  SkillNode(id: 'social_eng', label: 'Social Engineering', emoji: '🎭', parentId: 'pentest', pxpRequired: 500,
      ragTags: ['social engineering', 'phishing', 'pretexting', 'SET toolkit']),
];

// ─────────────────────────────────────────────────────────────────────────────
// SkillTreeMap — the interactive expandable skill tree widget.
// Roots are shown in a horizontal scrollable row. Tapping a root expands
// its children in a vertical sheet-style panel below.
// ─────────────────────────────────────────────────────────────────────────────
class SkillTreeMap extends StatefulWidget {
  final AppUser user;
  const SkillTreeMap({super.key, required this.user});

  @override
  State<SkillTreeMap> createState() => _SkillTreeMapState();
}

class _SkillTreeMapState extends State<SkillTreeMap> with SingleTickerProviderStateMixin {
  // Currently expanded root node id (null = none expanded)
  String? _expandedRoot;
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  // Returns all root-level nodes (no parent)
  List<SkillNode> get _roots => kSkillTree.where((n) => n.parentId == null).toList();

  // Returns direct children of a given parent id
  List<SkillNode> _childrenOf(String parentId) =>
      kSkillTree.where((n) => n.parentId == parentId).toList();

  void _toggleRoot(String id) {
    setState(() {
      if (_expandedRoot == id) {
        _expandedRoot = null;
        _expandCtrl.reverse();
      } else {
        _expandedRoot = id;
        _expandCtrl.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pxp = widget.user.pxp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Domain roots row ─────────────────────────────────────────────────
        Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.stroke),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: _roots.map((node) {
                final unlocked = node.isUnlocked(pxp);
                final isExpanded = _expandedRoot == node.id;
                return _RootChip(
                  node: node,
                  unlocked: unlocked,
                  isExpanded: isExpanded,
                  onTap: () => _toggleRoot(node.id),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Expanded children panel ───────────────────────────────────────────
        if (_expandedRoot != null) ...[
          const SizedBox(height: 8),
          SizeTransition(
            sizeFactor: _expandAnim,
            child: _ChildrenPanel(
              parentId: _expandedRoot!,
              children: _childrenOf(_expandedRoot!),
              deepChildren: (id) => _childrenOf(id),
              userPxp: pxp,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RootChip — a single tappable domain node in the top row
// ─────────────────────────────────────────────────────────────────────────────
class _RootChip extends StatelessWidget {
  final SkillNode node;
  final bool unlocked;
  final bool isExpanded;
  final VoidCallback onTap;

  const _RootChip({
    required this.node,
    required this.unlocked,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = isExpanded
        ? AppColors.primaryLight
        : unlocked
            ? AppColors.primary
            : AppColors.stroke;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.18)
              : unlocked
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ringColor, width: isExpanded ? 2 : 1.5),
          boxShadow: isExpanded
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12)]
              : [],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            node.emoji,
            style: TextStyle(
              fontSize: 26,
              color: unlocked ? Colors.white : Colors.white24,
              shadows: !unlocked ? [const Shadow(color: Colors.black, blurRadius: 10)] : [],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            node.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w500,
              color: unlocked ? AppColors.primaryLight : AppColors.textMuted,
            ),
          ),
          if (!unlocked)
            Text(
              '${node.pxpRequired} PXP',
              style: TextStyle(fontSize: 8, color: AppColors.textMuted),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChildrenPanel — animated expanded panel showing a domain's skill children.
// Each child can itself be tapped to reveal its own grandchildren.
// ─────────────────────────────────────────────────────────────────────────────
class _ChildrenPanel extends StatefulWidget {
  final String parentId;
  final List<SkillNode> children;
  final List<SkillNode> Function(String id) deepChildren;
  final int userPxp;

  const _ChildrenPanel({
    required this.parentId,
    required this.children,
    required this.deepChildren,
    required this.userPxp,
  });

  @override
  State<_ChildrenPanel> createState() => _ChildrenPanelState();
}

class _ChildrenPanelState extends State<_ChildrenPanel> {
  // Which child is expanded to show its own grandchildren
  String? _expandedChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(Icons.account_tree_rounded, color: AppColors.primaryLight, size: 14),
              const SizedBox(width: 6),
              Text('Skill Branches', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ]),
          ),

          // Child skill chips in a wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.children.map((child) {
              final unlocked = child.isUnlocked(widget.userPxp);
              final grandchildren = widget.deepChildren(child.id);
              final hasGrandchildren = grandchildren.isNotEmpty;
              final isExpanded = _expandedChild == child.id;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Child chip
                  GestureDetector(
                    onTap: hasGrandchildren
                        ? () => setState(() =>
                            _expandedChild = isExpanded ? null : child.id)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : unlocked
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isExpanded
                              ? AppColors.primaryLight
                              : unlocked
                                  ? AppColors.primary.withValues(alpha: 0.6)
                                  : AppColors.stroke,
                          width: isExpanded ? 1.5 : 1,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(child.emoji, style: TextStyle(fontSize: 14, color: unlocked ? Colors.white : Colors.white30)),
                        const SizedBox(width: 5),
                        Text(
                          child.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: unlocked ? FontWeight.w600 : FontWeight.w400,
                            color: unlocked ? AppColors.primaryLight : AppColors.textMuted,
                          ),
                        ),
                        // PXP lock badge
                        if (!unlocked) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${child.pxpRequired} PXP',
                              style: TextStyle(fontSize: 8, color: AppColors.amber, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        // Expand indicator
                        if (hasGrandchildren) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 14,
                            color: unlocked ? AppColors.primaryLight : AppColors.textMuted,
                          ),
                        ],
                      ]),
                    ),
                  ),

                  // Grandchildren (nested row)
                  if (hasGrandchildren && isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: grandchildren.map((gc) {
                          final gcUnlocked = gc.isUnlocked(widget.userPxp);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: gcUnlocked
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: gcUnlocked
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : AppColors.stroke.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(gc.emoji, style: TextStyle(fontSize: 12, color: gcUnlocked ? Colors.white : Colors.white24)),
                              const SizedBox(width: 4),
                              Text(
                                gc.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: gcUnlocked ? AppColors.textSecondary : AppColors.textMuted,
                                  fontWeight: gcUnlocked ? FontWeight.w500 : FontWeight.w400,
                                ),
                              ),
                              if (!gcUnlocked) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${gc.pxpRequired}p',
                                  style: TextStyle(fontSize: 8, color: AppColors.amber),
                                ),
                              ],
                            ]),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility: given a user's verifiedNodes list, return all RAG tags for
// unlocked skills — these are injected into the Open Source Mentor prompt.
// ─────────────────────────────────────────────────────────────────────────────
List<String> getUnlockedRagTags(List<String> verifiedNodeIds) {
  final tags = <String>{};
  for (final node in kSkillTree) {
    if (verifiedNodeIds.contains(node.id)) {
      tags.addAll(node.ragTags);
    }
  }
  return tags.toList();
}
