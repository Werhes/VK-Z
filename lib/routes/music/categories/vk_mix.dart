import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../consts.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../provider/playlists.dart";
import "../../../provider/preferences.dart";
import "../../../provider/user.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/music_category.dart";
import "../playlist.dart";
import "realtime_playlists.dart";

/// Виджет, показывающий раздел "VK Mix".
class VKMixBlock extends HookConsumerWidget {
  static final AppLogger logger = getLogger("VKMixBlock");

  const VKMixBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final mixPlaylists = ref.watch(mixPlaylistsProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerIsLoadedProvider);

    final bool mobileLayout = isMobileLayout(context);

    return MusicCategory(
      title: l18n.vk_mix_chip,
      onDismiss: () {
        final preferences = ref.read(preferencesProvider.notifier);

        HapticFeedback.selectionClick();
        preferences.setVkMixChipEnabled(false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l18n.category_closed(
                category: l18n.vk_mix_chip,
              ),
            ),
            duration: const Duration(
              seconds: 5,
            ),
            action: SnackBarAction(
              label: l18n.general_restore,
              onPressed: () => preferences.setVkMixChipEnabled(true),
            ),
          ),
        );
      },
      children: [
        // Skeleton loader.
        if (mixPlaylists == null) ...[
          Skeletonizer(
            child: LivePlaylistWidget(
              title: "VK Mix",
              description: "Mix that plays tracks adapting to your mood",
              bigLayout: !mobileLayout,
            ),
          ),
          const Gap(8),
        ],

        // Настоящие данные.
        if (mixPlaylists != null)
          for (ExtendedPlaylist playlist in mixPlaylists) ...[
            LivePlaylistWidget(
              title: playlist.title!,
              description: playlist.description,
              lottieUrl: playlist.backgroundAnimationUrl!,
              lottieCacheKey: "${playlist.mediaKey}animation",
              bigLayout: !mobileLayout,
              selected: player.playlist?.mediaKey == playlist.mediaKey,
              currentlyPlaying: player.isPlaying,
              onPlayToggle: () async {
                HapticFeedback.mediumImpact();

                onMixPlayToggle(ref, playlist);
              },
            ),
            const Gap(8),
          ],
      ],
    );
  }
}