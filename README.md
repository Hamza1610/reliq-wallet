# Reliq

> **Self-Custodial Bitcoin & Lightning Mobile Platform for Informal Economies**

Reliq is a production-grade, self-custodial Bitcoin Lightning Network mobile wallet designed specifically for cash-heavy informal economies in emerging markets (Northern Nigeria and Sub-Saharan Africa). 

By uniting embedded **LDK Node (Layer-2 Lightning)**, **BDK (Layer-1 On-Chain)**, a high-contrast tactile UI with minimal text dependency, and 100% on-device offline voice synthesis (English & Hausa), Reliq enables daily micropayments and digital commerce without intermediaries or external custody.

---

## Architecture Overview

Reliq utilizes a hybrid architecture:

```
┌────────────────────────────────────────────────────────┐
│               Flutter Frontend (Dart 3.x)              │
│  - High-Contrast Tactile UI (Min 52dp Touch Targets)  │
│  - Riverpod State Architecture                         │
│  - Offline TTS Voice Prompts (English & Hausa)         │
└───────────────────────────┬────────────────────────────┘
                            │ Dart FFI (Pure C-ABI)
┌───────────────────────────▼────────────────────────────┐
│                  Native Engine (Rust)                  │
│  - LDK Node (Embedded Lightning Network Layer-2)       │
│  - BDK (Bitcoin Development Kit - On-Chain Layer-1)    │
│  - BIP39 Mnemonic & Seed Cryptographic Derivations     │
│  - Rapid Gossip Sync (RGS) & Esplora Network Client    │
└────────────────────────────────────────────────────────┘
```

- **Frontend:** Flutter 3.x / Dart 3.x with Riverpod state management.
- **Native Core:** Rust crate (`native/`) exporting memory-safe C-ABI functions for LDK and BDK.
- **Hardware Security:** Android KeyStore (`EncryptedSharedPreferences`) on Android; dual-tier fallback on Linux desktop/WSL.
- **Voice Engine:** On-device Sherpa-ONNX TTS with lightweight Piper models for offline Hausa & English balance/payment announcements.

---

## Key Features

- **Strict Self-Custody:** All entropy, seed words, and private keys are derived on-device and stored in hardware-backed storage. Keys never touch external servers.
- **Tactile UI (Low Literacy First):** Four large, color-coded tactile action blocks (**RECEIVE**, **SEND**, **ACTIVITY**, **VOICE**) with high outdoor sunlight contrast.
- **Dual-Layer Bitcoin Support:**
  - **Lightning (BOLT11):** Instant micropayments with dynamic QR generation and quick satoshi chips (`+500`, `+1,000`, `+2,500`, `+5,000`, `+10,000`, `+50,000` sats).
  - **On-Chain (BDK):** Native SegWit (`bc1q` / `tb1q`) address generation and balance management.
- **Seed Verification Gate:** Enforces mandatory interactive 3-word verification before wallet activation.
- **Payment Safety:** Payment confirmation modal with real-time fee ceiling estimation and spendable balance validation.
- **Local Activity Log:** Encrypted on-device transaction history with relative timestamps and detailed status sheets.

---

## Project Structure

```text
reliq/
├── android/                 # Android native project configuration & NDK bindings
├── linux/                   # Linux desktop runner (WSLg & Linux support)
├── native/                  # Rust C-ABI engine
│   ├── Cargo.toml           # Rust dependencies (ldk-node, bdk, bip39, serde)
│   ├── src/lib.rs           # C-ABI export functions & unit tests
│   └── lib/                 # Compiled shared library (libreliq_native.so)
├── lib/
│   ├── core/                # Themes, network constants, formatters
│   ├── data/
│   │   ├── ldk/             # Dart FFI bindings & LDK/BDK models
│   │   └── storage/         # Secure storage service & payment history
│   └── presentation/
│       ├── providers/       # Riverpod wallet state notifiers
│       └── screens/
│           ├── onboarding/  # Welcome, Seed Generation, 3-Word Verification, Restore
│           ├── home/        # 4-block tactile home screen & satoshi balance cards
│           ├── receive/     # BOLT11 Lightning QR & BDK On-Chain SegWit tabs
│           ├── send/        # Camera reticle scanner & payment confirmation modal
│           └── activity/    # Chronological payment history & detail modal
├── test/                    # Unit, FFI integration, and widget tests
├── docs/                    # In-depth technical guides
│   └── getting_started.md   # Complete step-by-step run & test manual
└── README.md                # Project documentation
```

---

## Quick Start: How to Run & Test

For detailed instructions and troubleshooting, see **[`docs/getting_started.md`](docs/getting_started.md)**.

### 1. Build the Native Rust Engine
```bash
cd native
CARGO_TARGET_DIR=/home/maheer-wsl/.cargo-target/reliq cargo build --release
mkdir -p lib && cp /home/maheer-wsl/.cargo-target/reliq/release/libreliq_native.so lib/
cd ..
```

### 2. Run the Application

- **On Desktop (WSLg / Linux):**
  ```bash
  flutter run -d linux
  ```
  *(Or execute the built bundle directly: `./build/linux/x64/debug/bundle/reliq`)*

- **On an Android Phone (USB Debugging enabled):**
  ```bash
  flutter run
  ```

### 3. Compile Standalone Builds

- **Build Android APK:**
  ```bash
  flutter build apk --debug
  ```
  *Output: `build/app/outputs/flutter-apk/app-debug.apk`*

- **Build Linux Desktop Bundle:**
  ```bash
  flutter build linux --debug
  ```
  *Output: `build/linux/x64/debug/bundle/reliq`*

### 4. Run Automated Test Suites

- **Flutter Tests (12/12 passing):**
  ```bash
  flutter test
  ```
- **Rust Native Engine Tests (5/5 passing):**
  ```bash
  cd native && CARGO_TARGET_DIR=/home/maheer-wsl/.cargo-target/reliq cargo test
  ```

---

## Implementation Roadmap

| Phase | Description | Status |
| :--- | :--- | :---: |
| **Phase 1** | Foundation & Wallet Lifecycle (LDK/BDK FFI, Storage, Onboarding, Home) | **100% Completed** |
| **Phase 2** | Receive & Basic Send (BOLT11 Invoices, QR Code, Payment Modal, Activity) | **100% Completed** |
| **Phase 3** | Intermittent Connectivity & Push Wake-Up (LSP Client, FCM, Background Claim) | **Ready to Start** |
| **Phase 4** | Offline Voice Layer & UX Polish (Sherpa-ONNX, Hausa/English TTS, Audit) | **Not Started** |

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.
