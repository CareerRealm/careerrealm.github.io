# Career Realm — Development Roadmap

---

## ✅ v1.0 — Foundation (Completed)
*Core identity established*

- [x] Firebase Auth — Google Sign-In, email/password, guest mode
- [x] Real-time Firestore focus rooms with participant sync
- [x] Pomodoro timer (focus / short break / long break phases)
- [x] Room chat with system messages (join/leave events)
- [x] Basic XP and session counter
- [x] Ambient sound selector (rain, café, forest, etc.)
- [x] Cross-platform build: Android + Web + Windows

---

## ✅ v1.1 — Gamification Layer (Completed)
*The RPG core goes live*

- [x] 20-tier rank system (🌱 Seedling → ♾️ Infinity)
- [x] AXP (Academic XP) + PXP (Professional XP) separate tracks
- [x] Daily target progress bar and streak counter
- [x] Skill tree map with 7 domain nodes
- [x] 20 visual themes + animated backgrounds (stars, aurora, rain, fireflies...)
- [x] 10 timer face styles (Ring, Neon, Analog, Digital, Celestial...)
- [x] 5 UI looks (Classic, Glassmorphism, Brutalist, Cozy, Retro)
- [x] AI Resume Engine (basic — Gemini prompt for career summary)
- [x] Task management inside rooms (per-task time tracking)
- [x] Emoji reactions + read receipts in room chat

---

## ✅ v1.2 — AI & Responsive Fixes (Completed — Current)
*Bugs squashed, AI upgraded, skill tree expanded*

- [x] **HP logic corrected**: now starts at 100% and drains during focus
- [x] **Unlimited timer fixed**: UP mode no longer caps at room duration
- [x] **LayoutBuilder**: Focus Realm desktop layout shows HP bar, participants, Pomodoro card
- [x] **3 AI Companion modes**: Academic Mentor, Resume Architect, Open Source Mentor
- [x] **Skill tree rewrite**: expandable parent→child→grandchild hierarchy
- [x] **PXP-gated skills**: each skill locked behind a specific PXP threshold
- [x] **RAG tag injection**: unlocked skills feed keyword context into AI prompts
- [x] **Cybersecurity domain**: Red Teaming, Pen Testing, Blue Teaming, OSINT, Malware Analysis, Web Security, Cryptography
- [x] **API key security**: keys removed from source code, stored in SharedPreferences via Settings
- [x] Groq LLaMA-3 70B + Gemini 1.5/2.5 Flash support in AI chat
- [x] Markdown rendering with blockquotes, code blocks, checklists in AI responses

---

## 🔧 v1.3 — RAG & GitHub Integration (Next)
*Real retrieval-augmented generation — no billing required*

- [ ] `GitHubRepoService` — queries Firestore `github_repos` collection by RAG tags
- [ ] Admin script to populate Firestore with curated repos (README summaries, tags, stars)
- [ ] Open Source Mentor injects matched repos directly into LLM context
- [ ] "Save repo" feature — bookmarks a recommended repo to user profile
- [ ] Skill verification flow — user submits a project link; AI evaluates and grants PXP
- [ ] Scan-to-unlock: GitHub commit activity grants PXP automatically

---

## 🚀 v2.0 — Career Gateway (Planned)
*From study tool to career launcher*

- [ ] **AI Resume Export** — PDF generation from structured JSON schema (Header, Summary, Skills, Experience)
- [ ] **Public Profile Page** — shareable URL with rank, skills, and verified projects
- [ ] **Recruiter Mode** — companies can browse verified skill profiles
- [ ] **Vector RAG** — full Vertex AI embedding pipeline (requires Firebase Blaze)
  - Upload university syllabus PDFs → chunked + embedded → queryable by AI chat
  - GitHub repo READMEs embedded as vectors for precise semantic matching
- [ ] **Leaderboard** — global and room-based XP rankings
- [ ] **Push Notifications** — streak reminders, session invites, HP alerts via FCM
- [ ] **iOS support** (Firebase + Apple Sign-In configuration)
- [ ] **Offline mode** — local-only timer with sync on reconnect

---

## 💎 v3.0 — Premium Tier (Planned)
*Monetization without paywall-locking core features*

- [ ] Career Realm Pro subscription (£3.99/month)
- [ ] Pro features: unlimited AI queries, private rooms, custom domain profile page
- [ ] Team rooms (for companies / bootcamps)
- [ ] Integration with LinkedIn Learning and Coursera progress APIs
- [ ] AI Mock Interviewer — full technical interview simulation with scoring

---

## 📌 Known Issues / Backlog

| Priority | Issue |
|----------|-------|
| High | `skill_tree_map.dart` — `verifiedNodes` not yet written back to Firestore when user PXP crosses a threshold automatically |
| High | Task completion doesn't yet award PXP (only session time does) |
| Medium | Room heartbeat writes every 30s — should be batched to reduce Firestore writes |
| Medium | Settings avatars from local assets break on Web (asset path format) |
| Low | Timer face `Analog` style has a small regression on portrait phone screens |
| Low | Long display names overflow in the participant card |
