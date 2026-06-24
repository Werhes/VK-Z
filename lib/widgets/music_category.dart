import 'package:flutter/material.dart';

/// Виджет для [MusicCategory], отображающий анимированное число элементов в категории.

/// Виджет, отображающий отдельную категорию для раздела "музыки". У категории есть название, иногда количество элементов в категории.
class MusicCategory extends StatelessWidget {
  /// Название категории.
  final String title;

  /// Количество элементов в категории. К примеру, здесь может быть указано количество треков в разделе "ваша музыка", либо количество плейлистов.
  ///
  /// Если не указывать, то считается, что количество элементов неизвестно, и оно не будет отображаться.
  final int? count;

  /// Callback-метод, вызываемый при нажатии на X в категории. Если не указано, то X не будет отображаться.
  final VoidCallback? onDismiss;

  /// Содержимое этой категории.
  final List<Widget> children;

  const MusicCategory({
    super.key,
    required this.title,
    this.count,
    this.onDismiss,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium!;

    return MouseRegion(
      onEnter: onDismiss != null ? (_) => {} : null,
      onExit: onDismiss != null ? (_) => {} : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название с количеством, а так же кнопка для закрытия.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Название, количество.
              RichText(
                text: TextSpan(
                  children: [
                    // Название.
                    TextSpan(
                      text: title,
                      style: titleStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    // Количество, при наличии.
                    WidgetSpan(
                      baseline: TextBaseline.alphabetic,
                      alignment: PlaceholderAlignment.baseline,
                      child: Text(
                        count != null ? "  $count" : "",
                        style: titleStyle.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),

              // Кнопка для закрытия категории.
              if (onDismiss != null)
                Padding(
                  padding: const EdgeInsets.only(
                    right: 0,
                  ),
                  child: IconButton.filled(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    onPressed: onDismiss,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Содержимое категории.
          ...children,
        ],
      ),
    );
  }
}