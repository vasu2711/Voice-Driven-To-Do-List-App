# Voice-Driven To-Do List App

A Flutter application that allows users to manage their tasks through voice commands, with offline support and real-time synchronization across devices.

## Features

- Voice input for adding tasks
- Text input fallback
- Offline storage with SQLite
- Real-time sync with Firebase
- Voice feedback for actions
- Swipe-to-delete functionality
- Checkbox to mark tasks as complete
- Manual sync button for offline changes

## Prerequisites

- Flutter SDK (latest version)
- Android Studio / Xcode
- Firebase account
- Physical device or emulator with microphone support

## Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd voice_todo
```

2. Install dependencies:
```bash
flutter pub get
```

3. Firebase Setup:
   - Create a new Firebase project
   - Add Android app to Firebase:
     - Download `google-services.json` and place it in `android/app/`
   - Add iOS app to Firebase:
     - Download `GoogleService-Info.plist` and place it in `ios/Runner/`
   - Enable Firestore Database in Firebase Console

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── models/
│   └── todo.dart
├── services/
│   ├── voice_service.dart
│   ├── database_service.dart
│   └── firebase_service.dart
├── providers/
│   └── todo_provider.dart
├── screens/
│   └── todo_list_screen.dart
└── main.dart
```

## Voice Commands

- To add a task: "Add [task description]"
- To complete a task: Tap the checkbox
- To delete a task: Swipe left and tap delete
- To sync offline changes: Tap the sync button

## Dependencies

- flutter_riverpod: State management
- sqflite: Local database
- speech_to_text: Voice recognition
- flutter_tts: Text-to-speech
- firebase_core & cloud_firestore: Cloud sync
- flutter_slidable: Swipe actions
- google_fonts: Typography

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
