import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/currency/currency_service.dart';

enum DisplayMode {
  everydayNgn, // OPay-style Everyday Fintech mode (₦)
  proSats,     // Pro Bitcoin mode (⚡ sats)
}

class CurrencyState {
  final DisplayMode mode;
  final double? ngnRatePerSat;
  final bool isFetching;

  const CurrencyState({
    required this.mode,
    this.ngnRatePerSat,
    this.isFetching = false,
  });

  bool get isNgn => mode == DisplayMode.everydayNgn;

  CurrencyState copyWith({
    DisplayMode? mode,
    double? ngnRatePerSat,
    bool? isFetching,
  }) {
    return CurrencyState(
      mode: mode ?? this.mode,
      ngnRatePerSat: ngnRatePerSat ?? this.ngnRatePerSat,
      isFetching: isFetching ?? this.isFetching,
    );
  }
}

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  final CurrencyService _service;

  CurrencyNotifier(this._service)
      : super(const CurrencyState(mode: DisplayMode.everydayNgn)) {
    _init();
  }

  Future<void> _init() async {
    final modeStr = await _service.getCurrencyMode();
    final mode = modeStr == 'sats' ? DisplayMode.proSats : DisplayMode.everydayNgn;
    final customRate = await _service.getCustomRate();

    state = state.copyWith(
      mode: mode,
      ngnRatePerSat: customRate,
    );

    // Fetch live rate in background
    fetchLiveRate();
  }

  Future<void> fetchLiveRate() async {
    state = state.copyWith(isFetching: true);
    final rate = await _service.fetchLiveNgnRate();
    state = state.copyWith(
      ngnRatePerSat: rate ?? state.ngnRatePerSat,
      isFetching: false,
    );
  }

  Future<void> toggleMode() async {
    final next = state.mode == DisplayMode.everydayNgn
        ? DisplayMode.proSats
        : DisplayMode.everydayNgn;
    state = state.copyWith(mode: next);
    await _service.setCurrencyMode(next == DisplayMode.proSats ? 'sats' : 'ngn');
  }

  Future<void> setCustomRate(double rate) async {
    await _service.setCustomRate(rate);
    state = state.copyWith(ngnRatePerSat: rate);
  }
}

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  final service = ref.watch(currencyServiceProvider);
  return CurrencyNotifier(service);
});

