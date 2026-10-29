# Getting Started: Running, Compiling & Testing Reliq

A complete guide to starting the project, compiling the native Rust engine, running the mobile/desktop app, and executing the test suites.

---

## 1. Prerequisites & Environment Setup

Reliq is built as a hybrid architecture:
- **Frontend / Presentation:** Flutter 3.x (Dart 3.x)
- **Native Engine:** Rust (Cargo) embedding LDK Node (Lightning) & BDK (On-Chain)
- **Target Platforms:** Android (primary mobile), Linux desktop (WSL2 / native)

### Required Tools
Ensure these commands are available in your shell (`bash` on WSL / Linux):
```bash
flutter --version   # Flutter 3.27+ / 3.47+
cargo --version     # Rust 1.80+
adb --version       # Android Platform Tools (for Android devices)
```

Verify your Flutter environment is ready:
```bash
flutter doctor
```

---

## 2. Starting the Project (First-Time Setup)

### Step 1: Install Flutter Dependencies
From the project root (`reliq/`):
```bash
flutter pub get
```

### Step 2: Build the Native Rust Engine (`native/`)
The native crate contains the C-ABI exports for BIP39 mnemonic derivation, LDK Lightning node lifecycle, and BDK on-chain address generation.

Compile the native shared library and copy it to the local `native/lib/` folder:
```bash
# Navigate to native folder and build in release mode
cd native
CARGO_TARGET_DIR=/home/maheer-wsl/.cargo-target/reliq cargo build --release

# Copy the compiled shared library for Flutter FFI
mkdir -p lib
cp /home/maheer-wsl/.cargo-target/reliq/release/libreliq_native.so lib/
cd ..
```
*(Note: Compiling inside ext4 via `CARGO_TARGET_DIR` avoids Windows 9P filesystem locking).*

---

## 3. How to Run the Application

### Option A: Run on Desktop (WSLg / Linux) — Fast & Interactive
WSL2 supports native graphical windows via WSLg. You can run the app directly on your desktop:

```bash
flutter run -d linux
```

**Hot Reload / Controls in terminal:**
- Press `r` to hot-reload Dart code.
- Press `R` to restart the app.
- Press `q` to quit.

*(You can also run the precompiled binary directly without starting Flutter tools:)*
```bash
./build/linux/x64/debug/bundle/reliq
```

---

### Option B: Run on a Physical Android Device
1. Enable **Developer Options** and **USB Debugging** on your Android phone.
2. Connect your phone to your PC via USB cable.
3. Verify your device is detected:
   ```bash
   adb devices
   ```
4. Launch the app directly onto your phone:
   ```bash
   flutter run
   ```

---

## 4. How to Compile the Application

### 1. Build Android APK (Debug / Installable)
To compile a standalone APK that can be transferred and installed on any Android phone:
```bash
flutter build apk --debug
```
**Output APK location:**
- WSL path: `build/app/outputs/flutter-apk/app-debug.apk`
- Windows path: `c:\Users\HP-PC\Desktop\Bitcoin\Reliq\reliq\build\app\outputs\flutter-apk\app-debug.apk`

**To install the built APK onto a connected phone:**
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### 2. Build Linux Desktop Bundle
To compile a standalone Linux desktop executable bundle:
```bash
flutter build linux --debug
```
**Output bundle location:**
`build/linux/x64/debug/bundle/reliq`

---

## 5. How to Run the Test Suites

Reliq enforces strict automated testing across both the native Rust engine and the Flutter UI layer.

### 1. Run Flutter Test Suite (Unit & Widget Tests)
Runs all onboarding tests, payment flows, and Dart FFI bindings:
```bash
flutter test
```
*Expected output: `All tests passed! (12 tests)`*

To run a specific test file:
```bash
flutter test test/presentation/onboarding_test.dart
flutter test test/presentation/phase2_payment_flow_test.dart
flutter test test/data/ldk/ldk_node_service_test.dart
```

### 2. Run Native Rust Engine Tests
Verifies BIP39 mnemonic generation, C-ABI string memory safety, node lifecycle, and invoice decoding:
```bash
cd native
CARGO_TARGET_DIR=/home/maheer-wsl/.cargo-target/reliq cargo test
cd ..
```
*Expected output: `5 passed; 0 failed`*

---

## 6. Common Issues & Troubleshooting

### 1. `libsecret_error: Failed to unlock the keyring` (WSL / Linux Desktop)
- **What it is:** On Linux, `flutter_secure_storage` tries to access the desktop keyring daemon. In headless WSL2, this daemon is not unlocked by a graphical login session.
- **How Reliq handles it:** `SecureStorageService` automatically catches this error and falls back to persistent storage (`SharedPreferences`). Wallet creation, seed storage, and balance loading continue without interruption.
- **On Android:** Android uses hardware-backed KeyStore (`EncryptedSharedPreferences`) in silicon and is completely unaffected by this.

### 2. DevTools URL in Terminal Output
When running `flutter run`, Flutter prints:
```text
The Flutter DevTools debugger and profiler is available at:
http://127.0.0.1:xxxxx/xxxx=/devtools/?uri=ws://...
```
This is not an error. You can paste this URL into any browser to inspect the live widget tree, monitor Riverpod provider state, and profile memory performance.
