# JM Mini Mart ProPOS 🛒

A high-speed, mobile-first Point of Sale (POS) and Inventory Management System built with Flutter, Riverpod, and SQFlite. This system is designed for fast-paced retail environments with offline-first reliability and a robust clean architecture.

## 🚀 Features

- **Inventory Management:** Full CRUD for products with image support and low-stock alerts.
- **Dynamic Point of Sale (POS):** Fast cart management and barcode scanning integration.
- **Offline-First:** SQFlite local relational storage ensures the app works perfectly without internet.
- **Reporting & Printing:** Generate PDF receipts and view daily/weekly sales analytics.
- **Cloud Sync Ready:** Includes a `Syncable` interface and base Firebase service for background sync (Phase 5).

## 🛠 Tech Stack

- **Framework:** Flutter (3.41.5 Stable)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Local Database:** SQFlite & path_provider
- **Features:**
  - Barcode Scanning: `mobile_scanner`
  - PDF Receipts: `pdf` & `printing`
  - Analytics: `fl_chart`
  - Cloud Sync: `firebase_core` & `cloud_firestore`

---

## 💻 Setup & Installation

### Prerequisites

1.  **Flutter SDK:** Make sure you have Flutter installed (version 3.41.5 or newer).
    *   [Install Flutter](https://docs.flutter.dev/get-started/install)
2.  **IDE:** Visual Studio Code or Android Studio with the Flutter and Dart plugins installed.
3.  **Firebase (Optional for Phase 1-4):** If you intend to use the Cloud Sync features, you will need to set up a Firebase project and add the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files to the appropriate directories.

### Steps

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd jm-mini-mart
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run Code Generation (if applicable in future updates):**
    Currently, the app uses standard Riverpod Notifiers, but if `build_runner` is added later for Freezed or Riverpod Generator:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

## 🐛 Debugging & Development

### Running the App

To run the application in debug mode on an emulator or connected device:

```bash
flutter run
```

### Architecture Overview

This project strictly adheres to a **Feature-First Clean Architecture**.

*   `lib/core/`: Contains shared logic, database helpers (`database_helper.dart`), themes, and network services.
*   `lib/features/`: Contains the core modules of the app.
    *   `inventory/`: Product and Category CRUD, entities (`product.dart`, `category.dart`), and Riverpod providers.
    *   `pos/`: Shopping cart logic (`cart_provider.dart`), sales entities, and POS UI state.
    *   `reporting/`: Sales data aggregation and PDF receipt generation (`receipt_provider.dart`).

### Local Database (SQLite)

The database schema is defined in `lib/core/db/database_helper.dart`. It includes tables for `categories`, `products`, `sales`, and `sale_items`.
To inspect the database while debugging, you can use tools like **DB Browser for SQLite**. You will need to pull the `.db` file from the device/emulator:

```bash
# Android Example (replace package name if different)
adb exec-out run-as com.jmminimart cat databases/pos_system.db > pos_system.db
```

### Firebase Sync (Phase 5)

The `SyncService` in `lib/features/core/network/sync_service.dart` looks for entities implementing the `Syncable` interface (which includes an `is_synced` boolean).
*Note: You must configure Firebase via the FlutterFire CLI (`flutterfire configure`) before using this feature in production.*

---

## 📦 Building for Production

When you are ready to deploy the application, build the release versions.

### Android

To build an App Bundle (recommended for Google Play):
```bash
flutter build appbundle --release
```

To build an APK:
```bash
flutter build apk --release
```

### iOS

*Note: Requires macOS and Xcode.*

1.  Update the bundle identifier and provisioning profiles in Xcode (`ios/Runner.xcworkspace`).
2.  Run the build command:
    ```bash
    flutter build ipa --release
    ```

## 🧪 Testing

To run the unit and widget tests:

```bash
flutter test
```
