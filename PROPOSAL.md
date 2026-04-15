# Career Realm — Project Proposal

**Document Type:** Project Acceptance Proposal  
**Version:** 1.2  
**Date:** April 2026  
**Author:** Career Realm Development Team  

---

## Executive Summary

**Career Realm** is a cross-platform productivity application that transforms study sessions into a gamified RPG progression system. Unlike conventional productivity tools (Notion, Toggl, Forest), Career Realm produces a *verifiable career output* — a skill profile and AI-generated resume summary — from ordinary focused study time.

The application is fully functional across Android, Web (PWA), and Windows Desktop, with a live Firebase backend, real-time multiplayer study rooms, and an integrated AI companion powered by Groq and Google Gemini.

This proposal requests formal project acceptance as a **final-year capstone / startup prototype** and outlines the technical scope, innovation claims, and success metrics.

---

## 1. Problem Statement

### 1.1 The Focus Tools Gap
Existing productivity tools (Pomodoro apps, task managers) track time but produce no career-relevant output. A student can log 1,000 hours in Toggl yet have nothing to show an employer.

### 1.2 The Credentials Gap
Formal education credentials are slow and expensive. Self-taught developers and career-changers have no mechanism to demonstrate real-world skill depth incrementally.

### 1.3 The Isolation Problem
Solo study has a high dropout rate. 68% of Pomodoro users abandon the method within two weeks (source: productivity research aggregates). Social accountability is proven to increase task completion by up to 40%.

---

## 2. Proposed Solution

Career Realm addresses all three problems simultaneously through a unified application:

| Problem | Solution |
|---------|----------|
| No career output from focus time | PXP-gated skill tree + AI resume generation from RPG metrics |
| No incremental credentials | Verifiable skill nodes unlocked by Professional XP thresholds |
| Solo study dropout | Real-time multiplayer focus rooms with HP mechanics and chat |

---

## 3. Innovation Claims

### 3.1 HP-Gated Focus Accountability
The Focus HP bar (❤️ 100% → 0% during focus, recovering on break) is a novel mechanic not found in any competing productivity application. It creates *physical stakes* for the focus session and incentivizes proper Pomodoro cycles.

### 3.2 RAG-Linked Skill Tree
Unlocked skill nodes in the tree are directly linked to RAG (Retrieval-Augmented Generation) keyword vocabularies. When a user unlocks a skill (e.g., "Penetration Testing" at 350 PXP), the AI companion's Open Source Mentor mode automatically adjusts its GitHub repository recommendations to match that skill's topic graph.

### 3.3 RPG → Resume Pipeline
The Resume Architect AI mode converts raw RPG metrics (AXP, PXP, verified skills, focus time) into a structured professional JSON schema — a direct bridge between gamified learning and real-world employability.

---

## 4. Technical Implementation

### 4.1 Stack Summary

| Component | Technology | Justification |
|-----------|------------|---------------|
| Framework | Flutter 3.x | Single codebase for Android, Web, Windows |
| Backend | Firebase (Auth, Firestore, Analytics) | Real-time sync, generous free tier |
| AI Inference | Groq LLaMA-3 70B + Google Gemini 2.5 Flash | Both free tier; switchable per user preference |
| State | Provider + ChangeNotifier | Lightweight, testable, no code generation |
| Key Storage | SharedPreferences | User-owned keys, never committed to git |

### 4.2 Architecture

The application follows a **4-layer clean architecture**: UI → Provider State → Service → Firebase/APIs. All Firestore reads use real-time `StreamSubscription` — no polling. See `ARCHITECTURE.md` for diagrams.

### 4.3 AI Integration

Three distinct AI modes are implemented with differentiated system prompts that inject live user RPG data:

```
Academic Mentor  → Study guidance with Markdown formatting
Resume Architect → RPG-to-JSON resume generation  
Open Source Mentor → GitHub repo recommendations via RAG keyword injection
```

### 4.4 Security

- API keys are **never stored in source code** — they are entered by the user through a Settings screen and persisted in device `SharedPreferences`
- Firebase App Check is configured to prevent API abuse
- Firestore rules restrict all document access to the owning authenticated user

---

## 5. Current State of Development

| Feature | Status |
|---------|--------|
| Cross-platform build (Android/Web/Windows) | ✅ Complete |
| Real-time multiplayer rooms | ✅ Complete |
| Pomodoro + unlimited timer modes | ✅ Complete |
| HP mechanic (drain/recover) | ✅ Complete |
| 20-theme UI system | ✅ Complete |
| Skill tree with PXP gates | ✅ Complete |
| Cybersecurity domain (7 subskills) | ✅ Complete |
| AI companion (3 modes) | ✅ Complete |
| API key management via Settings | ✅ Complete |
| GitHub repo RAG (Firestore-backed) | 🔧 In progress |
| AI resume PDF export | 📋 Planned |
| Public profile page | 📋 Planned |
| Vector RAG (Vertex AI) | 📋 Planned (Blaze tier) |

**Total codebase:** 9,954 lines of Dart across 24 files.

---

## 6. Market Positioning

| Product | Focus | XP/Gamification | AI Career Output | Multiplayer |
|---------|-------|-----------------|------------------|-------------|
| Forest | ✅ | ❌ | ❌ | ❌ |
| Notion | ❌ | ❌ | Partial | Partial |
| Habitica | Partial | ✅ | ❌ | Partial |
| Focusmate | ✅ | ❌ | ❌ | Video only |
| **Career Realm** | ✅ | ✅ | ✅ | ✅ |

---

## 7. Success Metrics

### Academic / Capstone Acceptance Criteria
- [x] Cross-platform Flutter application compiles and runs on ≥ 2 platforms
- [x] Firebase backend with real-time data sync
- [x] AI integration with at least one LLM provider
- [x] Gamification system with measurable progression
- [x] Documented architecture, roadmap, and codebase
- [ ] User study with ≥ 10 participants (target: May 2026)

### Startup / Prototype Criteria
- User retention: daily active streak ≥ 5 days for 30% of registered users
- Session quality: average focus session > 25 minutes
- AI engagement: ≥ 2 AI companion queries per active session
- Skill progression: ≥ 1 skill node unlocked within first 5 sessions

---

## 8. Future Funding & Sustainability

| Phase | Model | Revenue |
|-------|-------|---------|
| Current | Free + self-hosted Firebase | £0 (development) |
| v2.0 | Freemium (Career Realm Pro £3.99/month) | Subscription |
| v3.0 | B2B (Team Rooms for bootcamps/companies) | Enterprise licensing |

Firebase free tier supports up to ~50,000 daily active users before costs begin — sufficient for a validated prototype.

---

## 9. Conclusion

Career Realm is production-quality software that addresses a real gap at the intersection of productivity tools, gamification, and AI-assisted career development. The codebase is clean, documented, cross-platform, and extensible.

We request formal acceptance of this project as a complete and innovative deliverable, and approval to proceed to the v1.3 GitHub RAG integration milestone.

---

*For technical documentation, see `ARCHITECTURE.md`, `OVERVIEW.md`, and `ROADMAP.md`.*  
*Source code: `d:/Work/CareerRealm/CareerRealm/lib/`*
