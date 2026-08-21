import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/result.dart';
import '../../../data/models/admin_metrics.dart';
import '../../../data/repositories/admin_dashboard_repository.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.kpi,
    this.metrics = const [],
    this.loading = true,
    this.failure,
    this.days = 30,
  });

  final DashboardKpi? kpi;
  final List<DailyMetric> metrics;
  final bool loading;
  final AppFailure? failure;
  final int days;

  DashboardState copyWith({
    DashboardKpi? kpi,
    List<DailyMetric>? metrics,
    bool? loading,
    AppFailure? failure,
    int? days,
    bool clearFailure = false,
  }) => DashboardState(
    kpi: kpi ?? this.kpi,
    metrics: metrics ?? this.metrics,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
    days: days ?? this.days,
  );

  @override
  List<Object?> get props => [
    kpi?.totalUsers,
    kpi?.newUsersToday,
    metrics.length,
    metrics.isEmpty ? null : metrics.last.day,
    loading,
    failure?.messageKey,
    days,
  ];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repo) : super(const DashboardState());

  final AdminDashboardRepository _repo;

  Future<void> load({int? days}) async {
    emit(
      state.copyWith(
        loading: true,
        clearFailure: true,
        days: days ?? state.days,
      ),
    );

    // KPI va grafik alohida so'rovlar, lekin birga kutiladi — ikkitasi
    // ketma-ket bo'lsa panel ikki marta sakrardi.
    final results = await Future.wait([
      _repo.loadKpi(),
      _repo.loadMetrics(days: days ?? state.days),
    ]);

    final kpiRes = results[0] as Result<DashboardKpi>;
    final metricsRes = results[1] as Result<List<DailyMetric>>;

    // KPI muhimroq: u yiqilsa sahifada ko'rsatadigan narsa qolmaydi.
    if (kpiRes case Fail(:final failure)) {
      emit(state.copyWith(loading: false, failure: failure));
      return;
    }

    emit(
      state.copyWith(
        loading: false,
        kpi: kpiRes.valueOrNull,
        // Grafik yiqilsa KPI kartalar baribir ko'rsatiladi — yarim
        // ma'lumot hech narsadan yaxshi.
        metrics: metricsRes.valueOrNull ?? const [],
        clearFailure: true,
      ),
    );
  }
}
