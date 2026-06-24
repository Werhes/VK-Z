/// Root response from audio.getStreamMixSettings
class MixSettingsRoot {
  final MixSettings settings;

  MixSettingsRoot({required this.settings});

  factory MixSettingsRoot.fromJson(Map<String, dynamic> json) {
    return MixSettingsRoot(
      settings: MixSettings.fromJson(
        json['settings'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// Settings containing title, subtitle and categories
class MixSettings {
  final String title;
  final String subtitle;
  final List<MixCategory> categories;

  MixSettings({
    required this.title,
    this.subtitle = '',
    this.categories = const [],
  });

  factory MixSettings.fromJson(Map<String, dynamic> json) {
    final categoriesList = <MixCategory>[];
    if (json['mix_categories'] is List) {
      for (final item in json['mix_categories'] as List) {
        if (item is Map<String, dynamic>) {
          categoriesList.add(MixCategory.fromJson(item));
        }
      }
    }
    return MixSettings(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      categories: categoriesList,
    );
  }
}

/// A category in mix settings (e.g. "Настроение", "Жанры")
class MixCategory {
  final String id;
  final String title;
  final String type;
  final List<MixOption> options;

  MixCategory({
    required this.id,
    required this.title,
    this.type = 'simple_button',
    this.options = const [],
  });

  factory MixCategory.fromJson(Map<String, dynamic> json) {
    final optionsList = <MixOption>[];
    if (json['options'] is List) {
      for (final item in json['options'] as List) {
        if (item is Map<String, dynamic>) {
          optionsList.add(MixOption.fromJson(item));
        }
      }
    }
    return MixCategory(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'simple_button',
      options: optionsList,
    );
  }
}

/// An individual option/toggle within a category
class MixOption {
  final String id;
  final String title;
  final String? iconUrl;
  bool selected;

  MixOption({
    required this.id,
    required this.title,
    this.iconUrl,
    this.selected = false,
  });

  factory MixOption.fromJson(Map<String, dynamic> json) {
    return MixOption(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      iconUrl: json['icon'] as String?,
      selected: json['selected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (iconUrl != null) 'icon': iconUrl,
      'selected': selected,
    };
  }
}