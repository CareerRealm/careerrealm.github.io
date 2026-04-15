# Career Realm — Project Overview

> **Gamified study sessions, real career progression.**

Career Realm turns your study time into a living RPG. Every minute of focused work earns XP, unlocks skills, and builds a verifiable professional profile — while you study in real-time focus rooms with others.

---

## 🎯 What Is It?

Career Realm is a cross-platform productivity application (Android, Web, Windows) built with Flutter and Firebase. It combines:

| Pillar | Description |
|--------|-------------|
| 🏰 **Focus Realm** | Real-time multiplayer study rooms with a synced Pomodoro timer, HP bar, ambient sounds, and live chat |
| 🌳 **Skill Tree** | A PXP-gated branching skill graph covering 7 domains (Computing, Algorithms, Architecture, AI/ML, Cybersecurity, Cloud, Mobile) |
| 🤖 **Career Companion** | An in-app AI assistant with three specialized modes: Academic Mentor, Resume Architect, and Open Source Mentor |
| 📊 **Stats Dashboard** | Rank system (20 tiers from 🌱 Seedling to ♾️ Infinity), daily streaks, and session history |
| 🎨 **Themes** | 20 visual themes, 10 timer face styles, 5 UI looks, and animated background effects |

---

## 👤 Who Is It For?

- **University students** who want to gamify their study sessions
- **Self-taught developers** building a skill portfolio without formal credentials
- **Professionals** who want a focus tool that also produces career-ready outputs
- **Study groups** that want shared accountability in real-time rooms

---

## ⚙️ Key Features

### Focus Realm (Timer Rooms)
- Countdown (`DOWN`) or stopwatch (`UP` / unlimited) modes
- Pomodoro system with configurable focus/break durations
- ❤️ HP bar: starts at 100%, drains during focus, recovers during breaks
- Live participant list with heartbeat presence detection
- Synced task list with per-task time tracking
- Ambient sounds (rain, forest, café, etc.) and alert SFX
- Room chat with emoji reactions and seen receipts

### Skill Tree
- 7 root domains, 35+ skills, with child/grandchild expansion
- Each skill requires a specific **PXP (Professional XP)** threshold
- Locked skills show their required PXP as a badge
- Verified skills inject **RAG keyword tags** into the AI mentor prompts

### Career Companion (AI Chat)
| Mode | Function |
|------|----------|
| 🎓 Academic Mentor | Study guidance with Markdown formatting, code blocks, checklists |
| 📄 Resume Architect | Converts RPG metrics (AXP/PXP/skills) into structured JSON resume |
| 🔧 Open Source Mentor | Recommends GitHub repos based on unlocked skill RAG tags |

- Supports Groq (LLaMA-3 70B) and Google Gemini (1.5 / 2.5 Flash)
- API keys entered once through Settings, stored locally (never hardcoded)

### Gamification System
```
XP  — General experience from all activity
AXP — Academic XP earned from study sessions  
PXP — Professional XP that gates skill unlocks
HP  — Focus stamina bar (100% → 0% during focus, recovers on break)
Rank — 20-tier system from Seedling 🌱 to Infinity ♾️
```

---

## 🛠️ Technology Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x (Dart) |
| Auth | Firebase Authentication (Google Sign-In + Email/Password) |
| Database | Cloud Firestore (real-time sync) |
| AI | Google Gemini API, Groq Cloud (LLaMA-3) |
| State | Provider + ChangeNotifier |
| Notifications | flutter_local_notifications |
| Markdown | flutter_markdown |
| Audio | audioplayers |
| Storage | shared_preferences |

---

## 📱 Platforms

- ✅ Android (primary)
- ✅ Web (PWA-capable)
- ✅ Windows Desktop

---

## 📊 Codebase Size

**9,641 lines of Dart** across 24 files. Largest modules:

| File | Lines | Purpose |
|------|-------|---------|
| `room_screen.dart` | 2,088 | Focus room UI + timer logic |
| `stats_screen.dart` | 891 | Dashboard, skill tree, AI resume |
| `home_screen.dart` | 699 | Navigation shell + room list |
| `timer_face_widget.dart` | 609 | 10 animated timer face styles |
| `app_theme.dart` | 598 | 20 themes, 5 looks, token system |
| `knowledge_architect_chat.dart` | 589 | AI companion with 3 modes |
| `models.dart` | 582 | All data models (Room, User, Task...) |
| `room_service.dart` | 527 | Firestore room CRUD + realtime |
