import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// NLP Engine: Generates academic/professional AI resumes using Generative LLMs.
class AiResumeEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // FREE TIER GEMINI API KEY (Replace with user's key)
  static const String _geminiApiKey = 'AIzaSyAw7K254jUonKNBbLBSWcRdM9nOo-yDxkA'; 

  /// Synthesizes the user's progression data via NLP into a formal professional JSON structure.
  Future<AiResume> generateProofOfSkillSummary(AppUser user) async {
    final prompt = '''
    Analyze the following User Data and act as an elite technical recruiter.
    User Name: ${user.displayName}
    Current Rank: ${user.rank}
    Global XP: ${user.xp} | Academic XP: ${user.axp} | Professional XP: ${user.pxp}
    Verified Skills: ${user.verifiedNodes.join(", ")}
    Focus Time Logged: ${user.formattedFocusTime}

    Task: Write a strictly professional, extremely high-quality 3-sentence summary of this user's profile highlighting their verified nodes and dedication to deep work (focus time).
    Return ONLY a raw JSON mapping with:
    {
      "title": "A strong technical title based on their skills",
      "summary": "The 3 sentence NLP summary"
    }
    ''';

    // Invoke Gemini NLP Endpoint
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.4}
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawText = data['candidates'][0]['content']['parts'][0]['text'] as String;
      
      // Clean up markdown code blocks if LLM adds them
      final cleanJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final decodedMap = jsonDecode(cleanJson);

      final newResume = AiResume(
        id: _db.collection('resumes').doc().id,
        userId: user.uid,
        title: decodedMap['title'] ?? 'Verified Engineer',
        summary: decodedMap['summary'] ?? '',
        verifiedSkills: user.verifiedNodes,
        generatedAt: DateTime.now(),
        isPublic: false,
      );

      // Persist to Cloud Database
      await _db.collection('resumes').doc(newResume.id).set(newResume.toMap());
      return newResume;
    } else {
      throw Exception('NLP Engine Failed: \${response.body}');
    }
  }

  /* =========================================================================
     [PRESERVED NLP/MACHINE LEARNING: PAID VERTEX AI & FIREBASE EXTENSIONS]
     (Leave commented until migrating to Blaze Plan)
     
     Future<AiResume> generatePremiumResumeVertex(AppUser user) async {
       final model = FirebaseVertexAI.instance.generativeModel(
           model: 'gemini-1.5-pro-preview',
           generationConfig: GenerationConfig(responseMimeType: 'application/json')
       );
       final content = [Content.text("...prompt...")];
       final response = await model.generateContent(content);
       // Structured JSON guaranteed via Schema enforcement on paid tier.
       ...
     }
  ========================================================================= */
}
