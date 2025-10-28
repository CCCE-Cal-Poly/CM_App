# Cal Poly Construction Management App

A comprehensive mobile application for Cal Poly's Construction Management department that facilitates communication and resource sharing between students, faculty, and industry members.

## Features

### 🏠 Home Screen
- Interactive calendar with event management
- Announcements and important notifications
- Real-time updates for department activities

### 👥 Member Directory
- Comprehensive listing of department members
- Search and filter capabilities
- Detailed member profiles with contact information

### 🏛️ Club Directory
- List of all CM-related clubs and organizations
- Club events and activities
- Membership information and contact details

### 👨‍🏫 Faculty Directory
- Complete faculty listing with contact information
- Office hours and availability
- Areas of expertise and research interests

### 💼 Info Sessions
- Upcoming company information sessions
- Registration for events
- Session details and locations

### 💻 Job Board
- Industry job postings
- Internship opportunities
- Easy application process

### 👤 Profile Management
- Personal profile customization
- Academic and professional information
- Contact preferences

### 🔐 Admin Control Panel
- Event management
- User management
- Content moderation

## Technology Stack

- **Frontend**: Flutter
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Notifications**: Firebase Cloud Messaging
- **Cloud Functions**: Firebase Cloud Functions

## Getting Started

### Prerequisites

1. Flutter SDK
2. Firebase CLI
3. Android Studio / Xcode
4. VS Code (recommended)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/CCCE-Cal-Poly/CM_App.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Create a new Firebase project
   - Add Android/iOS apps to the project
   - Download and add configuration files
   - Enable required Firebase services

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── common/
│   ├── collections/    # Data models
│   ├── features/       # Feature implementations
│   ├── providers/      # State management
│   ├── theme/         # UI theme definitions
│   ├── utils/         # Utility functions
│   └── widgets/       # Reusable UI components
├── services/          # Firebase service implementations
└── main.dart         # Application entry point
```

## Key Features

### Authentication
- Email/password sign-in
- Account creation
- Password recovery
- Terms of Service acceptance

### Real-time Updates
- Live event updates
- Push notifications
- Calendar synchronization

### Data Management
- Cloud storage for files
- Real-time database updates
- Offline data persistence

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is proprietary and owned by Cal Poly's Construction Management department.

## Contact

Cal Poly Construction Management Department - [Department Website](https://construction.calpoly.edu/)
