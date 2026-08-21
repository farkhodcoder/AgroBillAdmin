import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/admin_dashboard_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/kpi_card.dart';
import '../widgets/metrics_chart.dart';

/// Dashboard — platforma ko'rsatkichlari (TTZ §6.1).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.analyticsRead,
      child: BlocProvider(
        create: (_) =>
            DashboardCubit(getIt<AdminDashboardRepository>())..load(),
        child: const _DashboardView(),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.failure != null) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AdminErrorBanner(
                failure: state.failure!,
                onRetry: () => context.read<DashboardCubit>().load(),
              ),
            ),
          );
        }

        if (state.kpi == null) return const AdminLoading();
        final kpi = state.kpi!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AgSpace.x7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPageHeader(
                title: 'admin.nav.dashboard'.tr(),
                subtitle: 'admin.dashboard.subtitle'.tr(),
                actions: [
                  for (final days in [7, 30, 90])
                    Padding(
                      padding: const EdgeInsets.only(left: AgSpace.x2),
                      child: AdminButton(
                        label: 'admin.dashboard.days'.tr(args: ['$days']),
                        kind: state.days == days
                            ? AdminButtonKind.primary
                            : AdminButtonKind.secondary,
                        onPressed: () =>
                            context.read<DashboardCubit>().load(days: days),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AgSpace.x6),

              // --- Diqqat talab qiladiganlar --------------------------------
              // Birinchi qatorda ataylab: admin ekranga qaraganda avval
              // NIMA KUTAYOTGANINI ko'rishi kerak.
              Wrap(
                spacing: AgSpace.x4,
                runSpacing: AgSpace.x4,
                children: [
                  KpiCard(
                    label: 'admin.dashboard.pending_listings'.tr(),
                    value: '${kpi.pendingListings}',
                    icon: Icons.pending_actions_outlined,
                    tone: kpi.pendingListings > 0 ? c.warningText : null,
                  ),
                  KpiCard(
                    label: 'admin.dashboard.orders_pending'.tr(),
                    value: '${kpi.ordersPending}',
                    icon: Icons.receipt_long_outlined,
                    tone: kpi.ordersPending > 0 ? c.warningText : null,
                  ),
                  KpiCard(
                    label: 'admin.dashboard.open_tickets'.tr(),
                    value: '${kpi.openTickets}',
                    icon: Icons.support_agent_outlined,
                    tone: kpi.openTickets > 0 ? c.warningText : null,
                  ),
                ],
              ),
              const SizedBox(height: AgSpace.x6),

              // --- O'sish ---------------------------------------------------
              Wrap(
                spacing: AgSpace.x4,
                runSpacing: AgSpace.x4,
                children: [
                  KpiCard(
                    label: 'admin.dashboard.total_users'.tr(),
                    value: Fmt.count(kpi.totalUsers),
                    hint: 'admin.dashboard.new_today'.tr(
                      args: ['${kpi.newUsersToday}'],
                    ),
                    icon: Icons.people_outline,
                  ),
                  KpiCard(
                    label: 'admin.dashboard.active_7d'.tr(),
                    value: Fmt.count(kpi.activeUsers7d),
                    icon: Icons.bolt_outlined,
                  ),
                  KpiCard(
                    label: 'admin.dashboard.total_farms'.tr(),
                    value: Fmt.count(kpi.totalFarms),
                    hint: 'admin.dashboard.hectares'.tr(
                      args: [Fmt.hectares(kpi.totalHectares)],
                    ),
                    icon: Icons.agriculture_outlined,
                  ),
                  KpiCard(
                    label: 'admin.dashboard.active_listings'.tr(),
                    value: Fmt.count(kpi.activeListings),
                    icon: Icons.storefront_outlined,
                  ),
                  KpiCard(
                    label: 'admin.dashboard.scans_today'.tr(),
                    value: Fmt.count(kpi.scansToday),
                    icon: Icons.center_focus_strong_outlined,
                  ),
                  KpiCard(
                    label: 'admin.dashboard.ai_today'.tr(),
                    value: Fmt.count(kpi.aiQuestionsToday),
                    icon: Icons.auto_awesome_outlined,
                  ),
                  KpiCard(
                    label: 'admin.dashboard.premium'.tr(),
                    value: Fmt.count(kpi.premiumUsers),
                    // Bu ko'rsatkich hozircha ishonchsiz — pastdagi izohga
                    // qarang.
                    hint: 'admin.dashboard.premium_hint'.tr(),
                    icon: Icons.workspace_premium_outlined,
                  ),
                ],
              ),

              const SizedBox(height: AgSpace.x7),
              _Charts(metrics: state.metrics),

              const SizedBox(height: AgSpace.x6),
              AdminNote(text: 'admin.dashboard.premium_note'.tr()),
            ],
          ),
        );
      },
    );
  }
}

class _Charts extends StatelessWidget {
  const _Charts({required this.metrics});

  final List metrics;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final data = metrics.cast<dynamic>();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ikki ustun faqat joy yetganda — aks holda grafik siqilib
        // o'qib bo'lmas holga keladi.
        final twoColumns = constraints.maxWidth > 900;
        final width = twoColumns
            ? (constraints.maxWidth - AgSpace.x4) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: AgSpace.x4,
          runSpacing: AgSpace.x4,
          children: [
            SizedBox(
              width: width,
              child: MetricsChart(
                title: 'admin.dashboard.chart_new_users'.tr(),
                metrics: data.cast(),
                value: (m) => m.newUsers.toDouble(),
              ),
            ),
            SizedBox(
              width: width,
              child: MetricsChart(
                title: 'admin.dashboard.chart_orders'.tr(),
                metrics: data.cast(),
                value: (m) => m.ordersCreated.toDouble(),
                tone: c.info,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricsChart(
                title: 'admin.dashboard.chart_gmv'.tr(),
                metrics: data.cast(),
                value: (m) => m.gmv,
                tone: c.accent,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricsChart(
                title: 'admin.dashboard.chart_ai'.tr(),
                metrics: data.cast(),
                value: (m) => m.aiQuestions.toDouble(),
                tone: c.success,
              ),
            ),
          ],
        );
      },
    );
  }
}
