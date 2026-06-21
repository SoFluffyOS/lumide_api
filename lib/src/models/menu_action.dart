/// Plugin-contributed context menu actions.
library;

/// Menus that plugins can contribute actions to.
enum LumideMenuLocation {
  addPane('addPane'),
  fileTreeItem('fileTreeItem'),
  tabBarItem('tabBarItem'),
  editor('editor');

  const LumideMenuLocation(this.value);

  final String value;
}

/// A menu action contributed by a plugin.
class LumideMenuAction {
  const LumideMenuAction({
    required this.id,
    required this.title,
    required this.command,
    required this.location,
    this.group,
    this.when,
    this.priority = 0,
  });

  /// Unique action id within the plugin.
  final String id;

  /// User-facing label shown in the menu.
  final String title;

  /// Command to execute when selected.
  final String command;

  /// Menu location where this action appears.
  final LumideMenuLocation location;

  /// Optional section key used to place dividers between related actions.
  ///
  /// Actions with the same [group] stay together. When adjacent actions have
  /// different non-null group values, the host inserts a visual separator.
  final String? group;

  /// Optional context expression reserved for future filtering.
  final String? when;

  /// Larger priorities appear before lower priorities within plugin actions.
  final int priority;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'command': command,
      'location': location.value,
      if (group != null) 'group': group,
      if (when != null) 'when': when,
      'priority': priority,
    };
  }
}
