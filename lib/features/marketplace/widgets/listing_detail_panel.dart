import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/admin_listing.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../cubit/listings_cubit.dart';
import '../pages/marketplace_page.dart' show listingPrice, listingTone;

/// E'lon tafsiloti va moderatsiya qarorlari.
class ListingDetailPanel extends StatelessWidget {
  const ListingDetailPanel({
    super.key,
    required this.listing,
    required this.imageUrls,
    required this.history,
    required this.loading,
    required this.onClose,
    this.acting = false,
  });

  final AdminListingRow listing;
  final List<String> imageUrls;
  final List<ModerationEntry> history;
  final bool loading;
  final VoidCallback onClose;

  /// Qaror so'rovi ketmoqda — tugmalar bloklanadi.
  final bool acting;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final description = listing.description?.trim() ?? '';

    // Esc — panelni yopadi. Moderator navbatni klaviaturada ko'rib chiqadi,
    // har safar sichqoncha bilan "×" ni izlash sekinlashtirardi.
    return Positioned.fill(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (!acting) onClose();
          },
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              GestureDetector(
                onTap: onClose,
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: c.surface,
                  child: SizedBox(
                    width: 560,
                    height: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(listing: listing, colors: c, onClose: onClose),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AgSpace.x6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Images(
                                  urls: imageUrls,
                                  count: listing.imagePaths.length,
                                  loading: loading,
                                  colors: c,
                                ),
                                const SizedBox(height: AgSpace.x5),
                                _Facts(listing: listing, colors: c),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: AgSpace.x5),
                                  Text(
                                    description,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AgSpace.x6),
                                _Actions(listing: listing, acting: acting),
                                if (history.isNotEmpty) ...[
                                  const SizedBox(height: AgSpace.x6),
                                  _History(entries: history, colors: c),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.listing,
    required this.colors,
    required this.onClose,
  });

  final AdminListingRow listing;
  final AppColors colors;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AgSpace.x6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: AppTypography.h3.copyWith(color: colors.text),
                ),
                const SizedBox(height: AgSpace.x2),
                Row(
                  children: [
                    StatusBadge(
                      label: 'admin.listing_status.${listing.status}'.tr(),
                      tone: listingTone(listing.status),
                    ),
                    const SizedBox(width: AgSpace.x2),
                    Flexible(
                      child: Text(
                        listing.sellerEmail ?? '—',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, size: 18, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Images extends StatelessWidget {
  const _Images({
    required this.urls,
    required this.count,
    required this.loading,
    required this.colors,
  });

  final List<String> urls;
  final int count;
  final bool loading;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(height: 140, child: AdminLoading());
    }

    if (count == 0) {
      return _placeholder('admin.market.no_images'.tr());
    }

    // Buket private va admin unga `listings.moderate` bilan kiradi (0009).
    // Ruxsat yo'q bo'lsa signed URL olinmaydi — bu xato emas, shuning uchun
    // sabab tushuntiriladi.
    if (urls.isEmpty) {
      return _placeholder('admin.market.images_no_access'.tr());
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: AgSpace.x2),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: AgRadius.rMd,
          child: CachedNetworkImage(
            imageUrl: urls[i],
            width: 180,
            height: 140,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: colors.skeletonBase),
            errorWidget: (_, _, _) => Container(
              width: 180,
              color: colors.surfaceSunken,
              child: Icon(
                Icons.broken_image_outlined,
                color: colors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(String text) => Container(
    height: 140,
    decoration: BoxDecoration(
      color: colors.surfaceSunken,
      borderRadius: AgRadius.rMd,
    ),
    child: Center(
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: colors.textTertiary),
      ),
    ),
  );
}

class _Facts extends StatelessWidget {
  const _Facts({required this.listing, required this.colors});

  final AdminListingRow listing;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('admin.market.col_price', listingPrice(listing)),
      // Sotuv/ijara farqi narxni butunlay boshqacha o'qitadi: ijarada u
      // oylik to'lov. Moderator buni ko'rmasa narxni noto'g'ri baholaydi.
      (
        'admin.market.col_kind',
        (listing.kind == ListingKind.rent
                ? 'admin.market.kind_rent'
                : 'admin.market.kind_sale')
            .tr(),
      ),
      (
        'admin.market.quantity',
        '${Fmt.decimal(listing.quantity)} ${listing.unit}',
      ),
      ('admin.market.col_crop', listing.cropName ?? listing.category),
      ('admin.users.col_region', listing.regionName ?? '—'),
      ('admin.market.views', '${listing.viewCount}'),
      ('admin.market.col_created', Fmt.dateTime(listing.createdAt)),
      ('admin.market.expires', Fmt.date(listing.expiresAt)),
      if (listing.rejectReason != null)
        ('admin.market.last_reason', listing.rejectReason!),
    ];

    return Column(
      children: [
        for (final (labelKey, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AgSpace.x1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    labelKey.tr(),
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: AppTypography.bodySmall.copyWith(color: colors.text),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.listing, required this.acting});

  final AdminListingRow listing;
  final bool acting;

  /// E'lon allaqachon shu holatda bo'lsa tugma ko'rsatilmaydi: faol e'lonni
  /// qayta "tasdiqlash" sotuvchiga ortiqcha bildirishnoma va tarixga
  /// ma'nosiz `active -> active` yozuvini qo'shardi.
  bool _offers(String status) => listing.status != status;

  @override
  Widget build(BuildContext context) {
    final canRequestChanges = _offers(ListingStatus.changesRequested);
    final canReject = _offers(ListingStatus.rejected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PermissionGuard(
          permission: AdminPermission.listingsModerate,
          fallback: const SizedBox.shrink(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_offers(ListingStatus.active)) ...[
                AdminButton(
                  label: 'admin.market.approve'.tr(),
                  icon: Icons.check,
                  size: AdminButtonSize.large,
                  expand: true,
                  busy: acting,
                  onPressed: () => _decide(context, ListingStatus.active),
                ),
                const SizedBox(height: AgSpace.x2),
              ],
              if (canRequestChanges || canReject) ...[
                Row(
                  children: [
                    if (canRequestChanges)
                      Expanded(
                        child: AdminButton(
                          label: 'admin.market.request_changes'.tr(),
                          kind: AdminButtonKind.secondary,
                          expand: true,
                          busy: acting,
                          onPressed: () =>
                              _decide(context, ListingStatus.changesRequested),
                        ),
                      ),
                    if (canRequestChanges && canReject)
                      const SizedBox(width: AgSpace.x2),
                    if (canReject)
                      Expanded(
                        child: AdminButton(
                          label: 'admin.market.reject'.tr(),
                          kind: AdminButtonKind.danger,
                          expand: true,
                          busy: acting,
                          onPressed: () =>
                              _decide(context, ListingStatus.rejected),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AgSpace.x2),
              ],
              if (_offers(ListingStatus.suspended))
                AdminButton(
                  label: 'admin.market.suspend'.tr(),
                  kind: AdminButtonKind.secondary,
                  expand: true,
                  icon: Icons.pause_circle_outline,
                  busy: acting,
                  onPressed: () => _decide(context, ListingStatus.suspended),
                ),
            ],
          ),
        ),

        // O'chirish alohida ruxsat (`listings.delete`) va yumshoq o'chirish:
        // buyurtma va yozishma tarixi uzilib qolmasin.
        PermissionGuard(
          permission: AdminPermission.listingsDelete,
          fallback: const SizedBox.shrink(),
          child: Padding(
            padding: const EdgeInsets.only(top: AgSpace.x4),
            child: AdminButton(
              label: 'admin.market.delete'.tr(),
              kind: AdminButtonKind.ghost,
              expand: true,
              icon: Icons.delete_outline,
              busy: acting,
              onPressed: () async {
                final cubit = context.read<ListingsCubit>();
                final messenger = ScaffoldMessenger.of(context);
                final result = await showReasonDialog(
                  context,
                  title: 'admin.market.delete'.tr(),
                  message: 'admin.market.delete_confirm'.tr(
                    args: [listing.title],
                  ),
                  confirmLabel: 'admin.market.delete'.tr(),
                );
                if (!result.confirmed || result.reason == null) return;
                if (await cubit.delete(listing.id, result.reason!)) {
                  _notifyDone(messenger);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _decide(BuildContext context, String status) async {
    final cubit = context.read<ListingsCubit>();
    // Muvaffaqiyatdan keyin panel yopiladi va bu `context` yo'qoladi —
    // xabar uchun messenger oldindan olinadi.
    final messenger = ScaffoldMessenger.of(context);
    final needsReason = ListingStatus.needsReason(status);

    final result = await showReasonDialog(
      context,
      title: 'admin.listing_status.$status'.tr(),
      message: 'admin.market.decide_confirm'.tr(
        args: [listing.title, 'admin.listing_status.$status'.tr()],
      ),
      confirmLabel: 'admin.common.confirm'.tr(),
      reasonRequired: needsReason,
      danger: needsReason,
    );

    if (!result.confirmed) return;
    if (await cubit.moderate(listing.id, status, result.reason)) {
      _notifyDone(messenger);
    }
  }

  /// Qaror saqlangani haqida qisqa xabar. Ilgari muvaffaqiyatda panel
  /// jimgina yopilardi — moderator qaror o'tdimi yoki panel shunchaki
  /// yopildimi, bilmasdi.
  void _notifyDone(ScaffoldMessengerState messenger) {
    messenger.showSnackBar(
      SnackBar(content: Text('admin.market.action_done'.tr())),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.entries, required this.colors});

  final List<ModerationEntry> entries;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.market.history'.tr(),
          style: AppTypography.label.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AgSpace.x3),
        for (final e in entries)
          Container(
            margin: const EdgeInsets.only(bottom: AgSpace.x2),
            padding: const EdgeInsets.all(AgSpace.x3),
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              borderRadius: AgRadius.rSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (e.oldStatus != null) ...[
                      Text(
                        'admin.listing_status.${e.oldStatus}'.tr(),
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      Icon(
                        Icons.arrow_right_alt,
                        size: 14,
                        color: colors.textTertiary,
                      ),
                    ],
                    Text(
                      'admin.listing_status.${e.newStatus}'.tr(),
                      style: AppTypography.caption.copyWith(color: colors.text),
                    ),
                    const Spacer(),
                    Text(
                      Fmt.dateTime(e.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
                if (e.reason != null) ...[
                  const SizedBox(height: AgSpace.x1),
                  Text(
                    e.reason!,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                if (e.moderatorName != null)
                  Text(
                    e.moderatorName!,
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
