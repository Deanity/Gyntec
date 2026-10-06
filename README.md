<p align="center">
  <img src="assets/showcase/image.png" alt="Gyntec Apps" width="100%" />
</p>

<h1 align="center">Gyntec</h1>

<p align="center">
  A teaching companion app for interactive classroom learning sessions.<br />
  Materials, group discussions, and quizzes in one unified flow.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41.6-02569B?style=flat-square" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.11.4-0175C2?style=flat-square" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/Version-1.0.0-111111?style=flat-square" alt="Version" />
</p>

## About Gyntec

Gyntec is a Flutter-based mobile application designed to facilitate interactive learning in educational settings. Teachers act as the main operators who run the sessions, while students follow a learning flow guided directly through the screen.

The app is built with a mobile-first and offline-friendly approach. Module data is stored locally so sessions can still run in environments with limited connectivity, while the network status is always displayed so teachers know the device's condition at all times.

## Key Features

### Module Management
Teachers can browse the list of learning modules along with their detailed content, ranging from text and image materials and group discussion questions to quiz question previews.

### Participant Management
Student data can be added, viewed, and managed through a dedicated page. Before a session starts, the teacher selects the students who are present, and the system automatically divides them into groups.

### Three-Stage Learning Session

| Stage | Description |
|:--|:--|
| 1. Material | The teacher presents the module content to the students. |
| 2. Discussion | Students discuss in groups with a full-screen countdown timer. Once time runs out, the session automatically moves on to the quiz stage. |
| 3. Quiz | Questions are displayed one by one. The teacher marks the groups that answered correctly, then completes the quiz through a confirmation modal. |

### Session Recap and History
After a session ends, a recap is displayed containing the module information, the points earned by each group, and the list of members in each group. All completed sessions are saved in the history page and can be reopened in detail.

### Module Sharing
Modules can be sent to and received from nearby teachers' devices through the sharing feature, complete with a device scanning view and a module preview before sending.

### Network Status Detection
An offline banner appears automatically when the device is not connected to the internet. The status is updated in real time through a combination of event streams and polling every 4 seconds, and can also be refreshed manually with pull-to-refresh.

## Technology

| Component | Description |
|:--|:--|
| Framework | Flutter 3.41.6 |
| Language | Dart 3.11.4 |
| State Management | StatefulWidget (local, no external library) |
| Icons | lucide_icons_flutter 3.1.20 |
| SVG | flutter_svg 2.3.0 |
| Connectivity | connectivity_plus 7.3.1 |
| Data Source | Local JSON via rootBundle (`assets/data/mock_data.json`) |

## Project Structure

The project uses a feature-first architecture. Each feature has its own `models`, `screens`, and `widgets` folders, while shared components are placed in `core`.

```
gyntec/
  assets/
    data/                  Module, student, and quiz question data (mock_data.json)
    MateriImage/           Supporting images for the material content
    showcase/              App showcase images
  lib/
    main.dart              Application entry point
    core/
      constants/           App color palette
      services/            Network status detection service
      utils/               General utilities (keyboard, etc.)
      widgets/             Shared components (button, input, top bar, nav bar, offline banner)
    features/
      auth/                Login and user model
      home/                Home page, latest sessions, and module list
      module/              Module list and module detail (Material, Discussion, Quiz)
      student/             Student list, detail, and add student
      session/             Participant selection, learning session, discussion timer, recap, and history
      sharing/             Sharing hub, module selection, and sending to other devices
    utils/
      models.dart          Common data model definitions
```

## Navigation Flow

```
LoginScreen
  HomeScreen
    ModuleListScreen
      ModuleDetailScreen
        ParticipantSelectionScreen
          LearningSessionScreen
            DiscussionTimerScreen     (push / pop)
            QuizFinishModal           (dialog)
            PostQuizSummaryScreen
              HomeScreen              (pop until first)
    StudentScreen
      StudentDetailScreen
      AddStudentScreen
    SessionHistoryScreen
      SessionHistoryDetailScreen
    SharingHubScreen
      SelectModuleToSendScreen
        SendModuleScreen
```

## Getting Started

### Prerequisites

Make sure Flutter SDK version 3.41 or later is installed. Verify with the following command.

```bash
flutter doctor
```

### Installation and Running

```bash
git clone https://github.com/Deanity/Gyntec.git
cd Gyntec
flutter pub get
flutter run
```

### Testing

```bash
flutter test
```

### Build Release APK

```bash
flutter build apk --release
```

The APK file will be available at `build/app/outputs/flutter-apk/app-release.apk`.

## Testing on a Physical Device

1. Enable **USB Debugging** from the Developer Options menu on the Android device.
2. Connect the device to your computer using a USB cable.
3. Run `flutter run`. Flutter will detect the device and install the app automatically.

To test the offline banner, turn on airplane mode on the device. The banner will appear within 4 seconds at most. Pull the screen down to refresh the connection status instantly.

## About the Project

Gyntec was developed as an entry for a competition. The project was born from a real classroom need: how teachers can manage interactive learning sessions in a structured way, keep them running under limited connectivity, and encourage active student engagement through group discussions and quizzes.

All data used in this application is sample (mock) data for demonstration purposes.

## Development Team

| Name | Role |
|:--|:--|
| I Gede Dhiyo Lawe Wikantara | UI/UX & Project Manager |
| Dendra De Tama  | Flutter Developer |


## License

Copyright belongs to the development team. This project was created for competition purposes and is not intended for commercial use without permission.
