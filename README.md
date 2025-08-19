# QCuickBot - AI Chatbot Application

A cross-platform Flutter chatbot application powered by Google Gemini AI, with Firebase integration for notifications and Supabase for authentication and data storage.

## 🚀 Features

- **AI-Powered Chat**: Integrated with Google Gemini AI for intelligent conversations
- **Speech-to-Text**: Voice input capabilities for hands-free interaction
- **Cross-Platform**: Runs on Android, iOS, Windows, macOS, Linux, and Web
- **Real-time Notifications**: Firebase Cloud Messaging integration
- **User Authentication**: Secure login system via Supabase
- **Theme Support**: Light and dark theme modes
- **Deep Linking**: Custom URL scheme support (`qcuickbot://`)
- **Responsive UI**: Modern Material Design interface

## 📱 Screenshots

<!-- Add your app screenshots here -->

## 🛠️ Prerequisites

Before running this application, make sure you have:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.7.2 or higher)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- Android Studio / Xcode (for mobile development)
- A code editor (VS Code, Android Studio, etc.)

## ⚙️ Setup & Installation

### 1. Clone the Repository
```bash
git clone https://github.com/NoahOsmonth/qcuickbot3rdyear.git
cd qcuickbot3rdyear
```

### 2. Environment Configuration
Create a `.env` file in the root directory:
```env
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key_here
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Firebase Setup
- Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
- Add your Flutter app to the project
- Download and place configuration files:
  - `google-services.json` in `android/app/`
  - `GoogleService-Info.plist` in `ios/Runner/`
- Enable Firebase Cloud Messaging

### 5. Supabase Setup
- Create a Supabase project at [Supabase](https://supabase.com/)
- Configure authentication providers
- Update your environment variables with Supabase credentials

### 6. Google AI Setup
- Get your Google Gemini API key from [Google AI Studio](https://makersuite.google.com/)
- Configure the API key in your app

## 🚀 Running the App

### Mobile (Android/iOS)
```bash
# Run on connected device
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>
```

### Desktop
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Web
```bash
flutter run -d chrome
```

## 📂 Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # UI screens
│   └── notification_screen.dart
├── services/                 # Business logic
│   └── auth_service.dart
├── providers/                # State management
│   └── theme_provider.dart
└── theme/                    # App theming
    └── app_theme.dart

assets/
└── pictures/
    └── chatbotprofile.png    # App assets
```

## 🔧 Configuration

### Deep Linking
The app supports custom URL scheme `qcuickbot://` for deep linking:
- Login callback: `qcuickbot://login-callback`

### Permissions
The app requires the following permissions:
- **Microphone**: For speech-to-text functionality
- **Internet**: For AI API calls and data synchronization
- **Notifications**: For Firebase Cloud Messaging

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ Web

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Desktop
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Web
```bash
flutter build web --release
```

## 🔧 Dependencies

Key dependencies used in this project:

- `flutter_riverpod` - State management
- `google_generative_ai` - Google Gemini AI integration
- `flutter_gemini` - Additional Gemini features
- `supabase_flutter` - Backend services
- `firebase_core` & `firebase_messaging` - Push notifications
- `speech_to_text` - Voice input
- `flutter_markdown` - Markdown rendering
- `app_links` - Deep linking
- `flutter_local_notifications` - Local notifications

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:
- Create an issue on [GitHub Issues](https://github.com/NoahOsmonth/qcuickbot3rdyear/issues)
- Contact: [Your Email]

## 🙏 Acknowledgments

- Google Gemini AI for powering the chatbot
- Firebase for backend services
- Supabase for authentication and database
- Flutter team for the amazing framework

---

**Built with ❤️ using Flutter**
