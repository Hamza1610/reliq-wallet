# Reliq Implementation Status Tracker

> **Tracking progress against `Reliq_Technical_Implementation.md` specifications.**

| Phase | Description | Status | Test Coverage | Deliverables |
|---|---|:---:|:---:|---|
| **Phase 1** | Foundation & Wallet Lifecycle | ✅ **100% Complete** | 6 Unit / FFI Tests | Rust C-ABI engine, BIP39 entropy, Android KeyStore + fallback storage, Welcome/Create/Backup/Restore flow, 4-action HomeScreen. |
| **Phase 2** | Receive & Basic Send | ✅ **100% Complete** | 9 Flow / Widget Tests | BOLT11 dynamic invoice generation & decoding, on-chain SegWit address generation, camera scanner reticle, PaymentConfirmationModal, encrypted local payment history. |
| **Phase 3** | Intermittent Connectivity & Push Wake-Up | ✅ **100% Complete** | 10 LSP & Push Tests | LSPS2 dynamic inbound liquidity provisioning, C-ABI bindings (`lsp_create_inbound_invoice`, `lsp_claim_inbound_htlc`), FCM silent push receiver, headless background claim execution, real-time sync UI. |
| **Phase 4** | Offline Voice Layer & Accessibility Polish | ✅ **100% Complete** | 18 Voice & TTS Tests | On-device TTS (`TtsService`), culturally localized English & Hausa voice prompts (`VoicePrompts`), marketplace satoshi number converter (`numberToHausaWords`), voice balance/send/receive feedback, Android TTS queries. |

---

## Complete Test Suite Status

- **Flutter Tests:** 40 / 40 Passing (`flutter test`)
- **Native Rust Tests:** 6 / 6 Passing (`cargo test`)
- **Total Automated Tests:** 46 / 46 Passing

---

## Phase 4 Verification Summary

1. **`lib/data/tts/voice_prompts.dart`:**
   - Hausa marketplace denominations converter (`numberToHausaWords`) handles 0 to 1,000,000,000 with exact grammatical conjunctions (*ashirin da biyar*, *dubu goma sha biyu da dari hudu da hamsin*).
   - Prompts for Balance, Payment Received, Payment Sent, Language Changed, Voice Toggled, and Invoice Created.
2. **`lib/data/tts/tts_service.dart`:**
   - On-device speech synthesis wrapper around `flutter_tts` / Piper & Sherpa-ONNX.
   - Configures 0.85 speech rate for loud marketplace environments.
   - Handles muting, locale switching (`en-US` and `ha-NG`/`ha`), and graceful headless platform fallbacks.
3. **UI & Riverpod Integration:**
   - `WalletNotifier` wires `speakCurrentBalance()`, `speakPaymentReceived()`, and `speakPaymentSent()`.
   - `HomeScreen` balance card tap triggers voice balance announcement + visual snackbar.
   - `HomeScreen` VOICE block toggles voice status and speaks status.
   - `ReceiveScreen` invoice QR tap announces invoice amount.
   - `SendScreen` confirms payment dispatch audibly.
   - `SettingsScreen` switches between English and Hausa with immediate audio confirmation.
4. **Hardware Permissions & Visibility:**
   - `android.intent.action.TTS_SERVICE` declared under `<queries>` in `AndroidManifest.xml` for Android 11+ package visibility.
   - `INTERNET`, `ACCESS_NETWORK_STATE`, `VIBRATE`, and `CAMERA` permissions registered.

