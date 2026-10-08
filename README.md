# Smart Assistant

A Flutter voice-and-chat assistant app. You can talk to an AI chatbot by typing or speaking (in English or Bangla), record audio and get it transcribed, upload files, and look back at everything you've done in a history view. Each user gets their own account, activity stats and history, all stored locally on the device.

AI features run on the [Groq API](https://groq.com/): **Llama 3.1 8B Instant** for chat replies and **Whisper Large v3** for audio transcription.

---

## Features

- **Login / sign-up / guest mode** – local accounts with username, password and optional email and phone. A guest option skips sign-in.
- **AI chatbot** – ask anything by typing or by voice; answers come from Groq's Llama 3.1 model. Every message is saved to history.
- **English ⇄ Bangla voice input** – a flag button in the chatbot switches speech recognition between `en_US` and `bn_BD` and translates the chatbot's interface text.
- **Audio recording + transcription** – the green mic button on the home screen records audio (`.m4a`), sends it to Groq Whisper, shows the transcript, and offers to open it in the chatbot.
- **Live speech-to-text** – a mic in the home screen's message bar converts speech to text on the fly.
- **File upload** – pick any file from the device; it's copied into the app's documents folder and logged in history.
- **History** – three tabs (Chats, Files, Recordings) with timestamps and sizes, playback for recordings, and a "clear all" button.
- **Calendar** – a month view with today highlighted, month navigation and date selection; Bangla and English month and weekday names are built in.
- **Profile** – shows and edits name, email and phone, and displays activity stats (messages, files uploaded, recordings).

---

## Tech stack

| Area | Package / service |
|---|---|
| Framework | Flutter (Dart SDK `>=3.2.0 <4.0.0`) |
| AI chat | Groq API – `llama-3.1-8b-instant` via `http` |
| Transcription | Groq API – `whisper-large-v3` |
| Live speech recognition | `speech_to_text` |
| Audio recording / playback | `record`, `audioplayers` |
| File handling | `file_picker`, `path_provider`, `path` |
| Local database | `sqflite` |
| Accounts & session | `shared_preferences` |
| Permissions | `permission_handler` |
| Config | `flutter_dotenv` (reads `GROQ_API_KEY` from `.env`) |
| UI | `chat_bubbles`, `avatar_glow`, Material widgets |

---

## Project structure (`lib/`)

```
lib/
├── main.dart             # App entry: loads .env, reads GROQ_API_KEY, opens LoggingScreen
├── LoggingScreen.dart    # Login / sign-up / guest login (animated gradient UI)
├── HomeScreen.dart       # Main hub: recorder, Whisper transcription, quick-action buttons, upload sheet
├── ChatbotScreen.dart    # Voice + text AI chat with English/Bangla toggle
├── HistoryScreen.dart    # Tabs for chats, files and recordings; playback; clear all
├── CalendarScreen.dart   # Custom month calendar with Bangla month/weekday names
├── ProfileScreen.dart    # Profile details, edit mode, activity stats, options
├── groq_service.dart     # GroqService – sends a prompt to Groq chat completions
├── database_helper.dart  # SQLite helper (Record model, per-user queries)
└── user_service.dart     # User model + sign-up/login/logout/stats in SharedPreferences
```

### How the screens connect

```
LoggingScreen ──login / sign-up / guest──▶ HomeScreen
                                              │
          ┌──────────────┬────────────────────┼──────────────┬──────────────┐
          ▼              ▼                    ▼              ▼              ▼
   ChatbotScreen   CalendarScreen      HistoryScreen   Upload sheet   ProfileScreen
          ▲                                                              (menu)
          └── "Use in Chatbot?" after a recording is transcribed
```

---

## How it works

### AI chat (`groq_service.dart`, `ChatbotScreen.dart`)
`GroqService.getResponse()` posts the user's message to `https://api.groq.com/openai/v1/chat/completions` with `temperature: 0.7` and `max_tokens: 150`, and a 20-second timeout. Each request sends only the current message, so the bot doesn't remember earlier turns. Both the user's message and the reply are saved to SQLite as `chat` records.

### Recording → transcription (`HomeScreen.dart`)
1. Tap the green mic to start recording to `recording_<timestamp>.m4a` in the documents directory.
2. Tap again to stop. The file is logged as a `recording` record and the user's `recordings` stat goes up.
3. The audio is uploaded to `https://api.groq.com/openai/v1/audio/transcriptions` (`whisper-large-v3`, plain-text response, 60-second timeout).
4. The transcript is shown in the chat, and a dialog asks whether to send it to the chatbot. Choosing **Yes** opens `ChatbotScreen` with the text pre-filled.

### Data storage
**SQLite** – database file `smart_assistant_records.db`, table `records` (schema version 2):

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER | primary key, autoincrement |
| `user_id` | TEXT | owner; defaults to `guest` |
| `type` | TEXT | `chat`, `file` or `recording` |
| `content` | TEXT | message text or file name |
| `timestamp` | TEXT | ISO 8601 |
| `metadata` | TEXT | JSON – `{sender, source}` for chats, `{path, size, is_recording}` for files/recordings |

Every query is filtered by the current user ID from SharedPreferences (`current_user_id`), so each account sees only its own history. The version 1 → 2 migration added the `user_id` column.

**SharedPreferences**
- `app_users` – JSON list of all users (username, password, display name, email, phone, created date, usage stats)
- `current_user` – logged-in username (used by `UserService`)
- `current_user_id` – user ID used to scope database records

---

## Getting started

### Prerequisites
- Flutter SDK with Dart 3.2 or newer
- An Android/iOS device or emulator (the mic, file picker and speech features are built for mobile)
- A Groq API key from [console.groq.com](https://console.groq.com/)

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/zero00147/smartassistant.git
   cd smartassistant
   ```

2. **Create a `.env` file** in the project root (it's git-ignored but listed as an asset in `pubspec.yaml`, so the app won't build without it):
   ```env
   GROQ_API_KEY=your_groq_api_key_here
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Add microphone permissions** (needed for recording and speech-to-text)
   - Android – `android/app/src/main/AndroidManifest.xml` currently declares only `INTERNET`. Add:
     ```xml
     <uses-permission android:name="android.permission.RECORD_AUDIO"/>
     ```
   - iOS – add `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` to `ios/Runner/Info.plist`.

5. **Run**
   ```bash
   flutter run
   ```

6. **(Optional) Regenerate app icons** from `assets/icon/app_icon.png`:
   ```bash
   dart run flutter_launcher_icons
   ```

### Assets
- `assets/flags/us.png`, `assets/flags/bd.png` – language toggle icons in the chatbot
- `assets/icon/app_icon.png` – launcher icon source

---

## Known limitations and to-dos

These are things the current code doesn't do yet, useful to know before picking the project back up:

- **The home-screen chat isn't AI.** Messages typed in the home screen's bottom bar get canned replies from `_getAIResponse()` (keyword matches for "hello" and "time"). The real AI chat is in the **Chatbot** screen.
- **Chatbot has no memory.** Only the latest message is sent to Groq, and `max_tokens: 150` keeps replies short.
- **Passwords are stored in plain text** in SharedPreferences. Fine for a local demo, not for real users.
- **The Groq key ships inside the app**, because `.env` is bundled as a Flutter asset. A backend proxy would keep it private.
- **Logout doesn't fully sign out.** The Logout menu items only navigate back to the login screen, and Guest Login doesn't reset `current_user_id`, so a guest can see the previous user's history.
- **Profile edits can fail silently.** `updateUser()` is called with the edited display name as the username, so changing your name means no matching user is found and nothing is saved.
- **Stats aren't complete.** The home screen adds 2 to `totalMessages` per exchange, but Chatbot screen messages don't update stats.
- **Placeholders:** the dark-theme switch, Settings and Delete Account show snackbars only. The calendar has no events, and its Bangla labels depend on the device locale, which the app doesn't configure.
- **Housekeeping:** there's an older copy of `database_helper.dart` in the project root (the app uses `lib/database_helper.dart`), and a stray `avatar_glow:` line sits outside the `dependencies:` block in `pubspec.yaml`.

---

## Author

Ahammed Jumma
