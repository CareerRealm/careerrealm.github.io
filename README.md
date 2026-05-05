🏰 Career Realm

Career Realm is a cross-platform productivity ecosystem that transforms focused study sessions into a gamified RPG progression system. Unlike standard timers, Career Realm produces a verifiable career output by bridging the gap between deep-work discipline and professional employability.
 Key Innovation Pillars
 AI-Driven Career Companion

The app features a sophisticated AI Wrapper service that operates in three specialized modes:

    Academic Mentor: Provides real-time study guidance and technical explanations via high-fidelity Markdown.

    Resume Architect: Synthesizes RPG metrics (XP/Skills) into a structured JSON Resume Schema for professional export.

    Open Source Mentor: Implements a Semantic RAG Pipeline to recommend GitHub repositories from a database of 20,000+ projects based on the user's unlocked skill nodes.

🎮 RPG Progression System

    Focus HP Bar: A novel accountability mechanic. HP drains during focus sessions to enforce discipline and recovers during breaks.

    Dual XP Tracks: * AXP (Academic XP): Earned through consistent study sessions.

        PXP (Professional XP): Earned by reaching milestones, used to unlock nodes in the Skill Tree.

    PXP-Gated Skill Tree: A branching graph covering 7 domains (Cybersecurity, AI/ML, Backend, etc.).

🌐 Multiplayer Focus Realm

    Real-time synchronized Pomodoro rooms powered by Firestore StreamSubscriptions.

    Live participant presence, room-wide task lists, and interactive chat.

🛠️ Technical Stack
Layer	Technology
Frontend	Flutter 3.x (Dart)
State Management	Provider + ChangeNotifier (Layered Clean Architecture)
Backend	Cloud Firestore, Firebase Auth, App Check
AI Orchestration	Google Gemini 2.5 Flash & Groq (Llama-3 70B)
UI Components	flutter_markdown, audioplayers, shared_preferences
Discovery Logic	Keyword-based Semantic Vector Search
📦 Project Structure
Bash

lib/
├── models/      # Data models for User, Room, Task, and Rank System
├── providers/   # Global State Management (Auth, Theme, Room sync)
├── screens/     # Multi-platform UI (Focus Realm, Stats, Skill Tree)
├── services/    # AI Wrapper, GitHub RAG Processor, Resume Engine
├── widgets/     # Custom UI (Markdown Chat, Animated Timer Faces)
└── theme/       # 20+ Dynamic Themes and UI Token system

⚙️ Setup & Installation

    Clone the Repository:
    Bash

    git clone https://github.com/Maro/CareerRealm.git
    cd CareerRealm

    Install Dependencies:
    Bash

    flutter pub get

    Firebase Configuration:

        Create a Firebase project and add your google-services.json (Android) or firebase_options.dart.

        Enable Firestore, Authentication (Google/Email), and App Check.

    Run the App:
    Bash

    flutter run

    Note: API keys for Gemini/Groq are entered within the app settings and stored securely on-device via SharedPreferences.

📈 Roadmap

    [x] v1.2: HP Logic, Multi-mode AI Companion, and Markdown UI.

    [ ] v1.3: Integration of 20k Repository Firestore database for Open Source RAG.

    [ ] v2.0: PDF Resume Export from AI-generated JSON and Public Profile Pages.

📄 License

Distributed under the MIT License. See LICENSE for more information.

Author: [Maro]