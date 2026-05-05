<p align="center">
  <img src="assets/upasthiti.png" alt="Upasthiti Logo" width="180"/>
</p>

<h1 align="center">उपस्थिति — Upasthiti</h1>

<p align="center">
  <strong>AI-Powered Attendance Management System with Face Verification & Geofencing</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Appwrite-Cloud-F02E65?style=for-the-badge&logo=appwrite&logoColor=white" alt="Appwrite"/>
  <img src="https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20Windows%20|%20Web-green?style=for-the-badge" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License"/>
</p>

<p align="center">
  <em>Upasthiti (उपस्थिति — Sanskrit for "presence") is a full-featured, multi-role attendance management system built with Flutter and Appwrite. It combines <strong>AI-powered face recognition</strong>, <strong>GPS geofencing</strong>, and <strong>real-time data sync</strong> to deliver a tamper-proof, modern attendance experience for educational institutions.</em>
</p>

---

## 📖 Table of Contents

- [✨ Features](#-features)
- [🛠 Tech Stack](#-tech-stack)
- [🏗 Architecture Overview](#-architecture-overview)
- [🚀 Installation & Setup](#-installation--setup)
- [📱 Usage](#-usage)
- [📸 Screenshots](#-screenshots)
- [📂 Folder Structure](#-folder-structure)
- [🔌 API & Backend Details](#-api--backend-details)
- [🔒 Security Notes](#-security-notes)
- [🗺 Future Improvements](#-future-improvements)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## ✨ Features

### 🔐 Authentication & Role-Based Access

- **Multi-role login system** — Student, Admin, and Dean (Super Admin) portals
- **CAPTCHA-protected** admin login to prevent brute-force attacks
- **Hidden Dean portal** — accessible via a secret 5-tap easter egg on the login screen
- **Role-Based Access Control (RBAC)** — prevents cross-role portal access
- **Account status management** — Admins can be suspended/reactivated by the Dean
- **Admin level hierarchy** (Level 1–3) — controls feature access and approval chains

### 📋 Attendance Management

- **AI-powered face verification** — students must pass face recognition before logging attendance
- **GPS geofencing** — attendance is only accepted within the class boundary radius
- **Period-based scheduling** — admins define time windows; students report within active sessions
- **Entry status tracking** — records whether entry was Early, Within Window, or Late
- **Photo upload & storage** — captured selfies are stored in Appwrite Storage
- **Admin verification workflow** — attendance marked as Present, Late, Absent, or Pending
- **Attendance history** — students can view their full history per class with status indicators

### 🗺 Geofencing & Boundary Management

- **Interactive map boundary picker** — powered by OpenStreetMap via `flutter_map`
- **Configurable radius** (30m – 500m) — adjustable per class
- **Real-time location verification** — checks GPS coordinates against boundary on report
- **Visual boundary indicators** — "In Zone" / "Out of Zone" chips on attendance logs

### 💬 Community & Messaging

- **Class channel** — public broadcast chat per class with real-time updates
- **Direct Messages** — private 1:1 messaging between admins and students
- **File attachments** — share PDFs, spreadsheets, images, and documents
- **Admin badges** — admin messages are visually distinguished in the chat
- **Real-time sync** — powered by Appwrite Realtime subscriptions

### 📊 Analytics & Log Management

- **Global attendance logs** — filterable by class and date range
- **Log selection & batch operations** — select, delete, or soft-delete logs
- **Delete by day** — granular cleanup of attendance records
- **CSV export** — export all attendance data as CSV for external analysis
- **Student count & boundary status** — visible per class on the admin dashboard

### 📝 Leave Management

- **Leave request system** — Medical, Casual, Paid Leave, and LTC categories
- **Hierarchical approval chain** — Level N requests go to Level N+1 for approval
- **Approve / Deny workflow** — approvers can action requests with status tracking
- **Request history** — users can view their own leave requests and statuses

### 🎓 Dean (Super Admin) Dashboard

- **Personnel management** — onboard new admins with department, level, and credentials
- **Supervision mode** — enter any admin's dashboard to inspect their classes and logs
- **Account controls** — override passwords, suspend/reactivate, or delete admin accounts
- **Data migration tool** — link unowned legacy classes and logs to the master account

### 🎨 UI/UX Design

- **Animated splash screen** — logo appear/disappear with scale and opacity transitions
- **Rising sheet pattern** — signature bottom-to-top slide + fade entrance across all screens
- **Poppins typography** — consistent Google Fonts throughout the app
- **Custom theme system** — centralized `AppTheme` with brand colors, input styles, and decorations
- **Hero animations** — smooth transitions between class list and detail views
- **Micro-animations** — tab switching, selection indicators, and status chip transitions

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.10+ (Dart 3.x) |
| **Backend** | [Appwrite Cloud](https://appwrite.io) (Singapore region) |
| **Database** | Appwrite Databases (NoSQL documents) |
| **File Storage** | Appwrite Storage (attendance photos, community files) |
| **Real-time** | Appwrite Realtime (WebSocket subscriptions) |
| **Face Recognition** | Custom Python backend hosted on [Hugging Face Spaces](https://huggingface.co/spaces) |
| **Maps** | OpenStreetMap tiles via [`flutter_map`](https://pub.dev/packages/flutter_map) + [`latlong2`](https://pub.dev/packages/latlong2) |
| **Geolocation** | [`geolocator`](https://pub.dev/packages/geolocator) |
| **Typography** | [`google_fonts`](https://pub.dev/packages/google_fonts) (Poppins) |
| **Camera** | [`image_picker`](https://pub.dev/packages/image_picker) / [`camera`](https://pub.dev/packages/camera) |
| **CSV Export** | [`csv`](https://pub.dev/packages/csv) |
| **Date/Time** | [`intl`](https://pub.dev/packages/intl) |
| **File Sharing** | [`file_picker`](https://pub.dev/packages/file_picker) |
| **URL Handling** | [`url_launcher`](https://pub.dev/packages/url_launcher) |
| **Permissions** | [`permission_handler`](https://pub.dev/packages/permission_handler) |

---

## 🏗 Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                     Flutter Client                       │
│  ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌───────────┐  │
│  │ Student  │  │  Admin  │  │   Dean   │  │  Shared   │  │
│  │  Pages   │  │  Pages  │  │  Pages   │  │ Services  │  │
│  └────┬─────┘  └────┬────┘  └────┬─────┘  └─────┬─────┘  │
│       │             │            │              │         │
│       └─────────────┴────────────┴──────────────┘         │
│                          │                                │
│                   AppwriteService                         │
│              (Databases / Storage / Realtime)              │
└──────────────────────────┬───────────────────────────────┘
                           │ HTTPS / WSS
              ┌────────────┴────────────┐
              │    Appwrite Cloud       │
              │  ┌──────────────────┐   │
              │  │  users           │   │
              │  │  classes         │   │
              │  │  attendance_logs │   │
              │  │  periods         │   │
              │  │  community_msgs  │   │
              │  │  leave_requests  │   │
              │  └──────────────────┘   │
              │  ┌──────────────────┐   │
              │  │  Storage Buckets │   │
              │  │  • attendance_   │   │
              │  │    photos        │   │
              │  │  • community_    │   │
              │  │    files         │   │
              │  └──────────────────┘   │
              └────────────┬────────────┘
                           │
              ┌────────────┴────────────┐
              │  Face Recognition API   │
              │  (Hugging Face Spaces)  │
              │  • POST /register-face  │
              │  • POST /login-face     │
              └─────────────────────────┘
```

### Data Flow

1. **Registration** → Student captures photo + location → Face registered on ML backend → Profile saved in Appwrite
2. **Attendance** → Student opens active class → GPS check against geofence → Camera capture → Face verification via API → Attendance log created in Appwrite
3. **Admin Review** → Realtime subscription updates admin dashboard → Admin verifies/marks each log → Status reflected to student in real-time
4. **Community** → Messages stored in `community_messages` collection → Realtime delivers to all subscribers instantly

---

## 🚀 Installation & Setup

### Prerequisites

- **Flutter SDK** `>=3.10.4` ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK** `>=3.x` (bundled with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for cloning the repository

### 1. Clone the Repository

```bash
git clone https://github.com/yawansharma/Navikarana.git
cd Navikarana
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Appwrite (Backend)

The app connects to **Appwrite Cloud**. To use your own instance:

1. Open `lib/services/appwrite_service.dart`
2. Replace the endpoint and project ID:

```dart
class AppwriteService {
  static const String endpoint = 'https://your-appwrite-instance/v1';
  static const String projectId = 'your-project-id';
  // ...
}
```

3. Create the required database collections (see [API & Backend Details](#-api--backend-details))

### 4. Configure Face Recognition Backend

The face verification API is hosted on Hugging Face Spaces. To use your own:

1. Open `lib/class_detail_page.dart` and `lib/register_page.dart`
2. Update the backend URL:

```dart
static const String _backendBaseUrl = "https://your-backend-url";
```

### 5. Run the App

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows Desktop
flutter run -d windows

# Web
flutter run -d chrome
```

### 6. Build for Production

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release
```

---

## 📱 Usage

### Student Workflow

1. **Register** → Create account with photo, location, school selection, and face registration
2. **Login** → Enter unique code and password
3. **Join Class** → Use the class code provided by your admin
4. **View Schedule** → See today's active/upcoming sessions on the dashboard
5. **Report Attendance** → Open active class → GPS verification → Face scan → Done!
6. **Chat** → Access the Community page to message classmates or your admin
7. **Track History** → View attendance history with Present/Late/Absent/Pending status

### Admin Workflow

1. **Login** → Use admin credentials with CAPTCHA verification
2. **Create Classes** → Set class name, join code, and GPS boundary
3. **Manage Periods** → Schedule attendance windows with start/end times
4. **Review Logs** → Verify attendance, mark students as Present/Late/Absent
5. **Analytics** → Filter logs by class, date range; export to CSV
6. **Community** → Broadcast messages and DM individual students
7. **Leave Management** → Review and approve/deny leave requests

### Dean Workflow

1. **Access** → Hidden portal via 5-tap easter egg on login screen
2. **Manage Admins** → Onboard, suspend, override passwords, or delete admins
3. **Supervise** → Enter any admin's dashboard in supervision mode
4. **System Maintenance** → Run data migration for legacy records

---

## 📸 Screenshots

> Screenshots of the app in action. Replace placeholders with actual images.

| Login | Student Dashboard | Class Detail |
|:---:|:---:|:---:|
| ![Login](screenshots/login.png) | ![Dashboard](screenshots/dashboard.png) | ![Class](screenshots/class_detail.png) |

| Admin Panel | Attendance Logs | Community Chat |
|:---:|:---:|:---:|
| ![Admin](screenshots/admin.png) | ![Logs](screenshots/logs.png) | ![Chat](screenshots/community.png) |

| Geofence Picker | Dean Portal | Leave System |
|:---:|:---:|:---:|
| ![Geofence](screenshots/geofence.png) | ![Dean](screenshots/dean.png) | ![Leave](screenshots/leave.png) |

---

## 📂 Folder Structure

```
lib/
├── main.dart                   # App entry, splash screen, student login page
├── app_theme.dart              # Centralized theme, colors, text styles, RisingSheet widget
│
├── register_page.dart          # Student registration with photo + location + face enrollment
├── admin_login.dart            # Admin login with CAPTCHA verification
├── dean_login.dart             # Dean/Super Admin login portal
│
├── home_page.dart              # Student dashboard — joined classes, today's sessions
├── class_detail_page.dart      # Class view — attendance reporting, history, geofence check
├── profile_page.dart           # Student profile — password change
│
├── admin_home_page.dart        # Admin dashboard — classes, analytics, settings, class management
├── dean_home_page.dart         # Dean dashboard — admin personnel management, system settings
│
├── community_page.dart         # Class channel + DM messaging with file attachments
├── camera_page.dart            # Camera integration for Windows desktop
├── eye_test_dialog.dart        # WebView-based eye test dialog (Windows)
│
├── leave_management_page.dart  # Leave request list + approval workflow
├── leave_request_page.dart     # Submit new leave request form
│
├── services/
│   ├── appwrite_service.dart   # Appwrite client configuration (endpoint, project, databases)
│   └── leave_service.dart      # Leave request CRUD operations
│
├── backend/                    # (Reserved for future backend logic)
└── registered_faces/           # (Local face registration data)

assets/
├── appLogo.png                 # App launcher icon
└── upasthiti.png               # Brand logo used in splash screen and footers
```

---

## 🔌 API & Backend Details

### Appwrite Collections

| Collection | Description | Key Fields |
|---|---|---|
| `users` | All user accounts (students, admins, dean) | `username`, `name`, `password`, `role`, `department`, `level`, `status`, `lastLogin` |
| `classes` | Class/course records | `className`, `classCode`, `createdBy`, `adminName`, `studentIds[]`, `boundary` (JSON) |
| `attendance_logs` | Individual attendance entries | `userId`, `classId`, `adminId`, `periodId`, `timestamp`, `photoUrl`, `isWithinGeofence`, `isVerified`, `adminVerifiedStatus`, `entryStatus` |
| `periods` | Scheduled attendance windows | `classId`, `date`, `startTime`, `endTime` |
| `community_messages` | Chat messages (channel & DM) | `classId`, `channel`, `senderId`, `text`, `fileUrl`, `fileType`, `fileName`, `timestamp`, `isAdmin` |
| `leave_requests` | Leave request records | `userId`, `userName`, `leaveType`, `startDate`, `endDate`, `reason`, `status`, `approverLevel`, `actionBy` |

### Storage Buckets

| Bucket | Purpose |
|---|---|
| `attendance_photos` | Selfie photos captured during attendance reporting |
| `community_files` | File attachments shared in community channels and DMs |

### Face Recognition API

| Endpoint | Method | Description |
|---|---|---|
| `/register-face` | `POST` | Register a new face with `username` + `image` (multipart) |
| `/login-face` | `POST` | Verify a face against registered data with `username` + `image` (multipart) |

> Hosted on Hugging Face Spaces — returns `{ "verified": true }` on success or `{ "error": "..." }` on failure.

---

## 🔒 Security Notes

> ⚠️ **Important:** This project is under active development. The following security considerations should be addressed before production deployment.

- **Password Storage** — Passwords are currently stored as plaintext in Appwrite documents. Migrate to Appwrite's native session-based authentication for production use.
- **Dean Credentials** — The Dean login uses hardcoded credentials. This should be replaced with secure, server-side authentication.
- **Database IDs** — Appwrite database and collection IDs are embedded in the client code. Consider using environment variables or a configuration file.
- **Client-Side RBAC** — Role checks are performed on the client side. Implement Appwrite ACLs and server-side permissions for robust security.
- **API Endpoints** — The face recognition backend URL is hardcoded. Use environment configuration for different deployment environments.

---

## 🗺 Future Improvements

- [ ] **Migrate to Appwrite native auth** — Replace plaintext credential storage with session-based authentication
- [ ] **Server-side RBAC** — Enforce role-based access via Appwrite permissions and ACLs
- [ ] **Push notifications** — Notify students of upcoming classes and admins of new attendance logs
- [ ] **Offline support** — Cache attendance data locally and sync when connectivity is restored
- [ ] **Timetable integration** — Auto-generate periods from uploaded timetable data
- [ ] **Attendance analytics dashboard** — Charts and graphs for attendance trends, student performance
- [ ] **Face liveness detection** — Prevent photo spoofing with blink/motion detection
- [ ] **Multi-language support** — Hindi, English, and regional language localization
- [ ] **Dark mode** — Full dark theme support for the student and admin interfaces
- [ ] **QR code attendance** — Alternative quick check-in method alongside face verification
- [ ] **Automated absence alerts** — Email/SMS notifications when students miss classes
- [ ] **Environment config** — Move all API URLs, project IDs, and secrets to env files

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit** your changes with descriptive messages
   ```bash
   git commit -m "feat: add QR code attendance scanning"
   ```
4. **Push** to your branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open** a Pull Request

### Guidelines

- Follow the existing code style and architecture patterns
- Use the centralized `AppTheme` for all UI styling
- Add comments for complex logic
- Test on at least Android and Windows before submitting
- Use `AppwriteService` for all backend interactions
- Keep commit messages descriptive and follow [Conventional Commits](https://www.conventionalcommits.org/)


<p align="center">
  <sub>Built with ❤️ using Flutter & Appwrite</sub><br/>
  <sub><strong>उपस्थिति</strong> — Making Attendance Intelligent</sub>
</p>
