/// Base class for all SDUI widgets.
library;

/// Base class for serializable UI widgets.
///
/// All SDUI widgets extend this class and can be serialized to JSON
/// for transmission to the host IDE.
sealed class LumideWidget {
  const LumideWidget({this.key});

  /// Optional unique key for widget identification.
  final String? key;

  /// Serializes this widget to JSON.
  Map<String, dynamic> toJson();

  /// Deserializes a widget from JSON.
  static LumideWidget fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'box' => LumideBox.fromJson(json),
      'label' => LumideLabel.fromJson(json),
      'button' => LumideButton.fromJson(json),
      'textField' => LumideTextField.fromJson(json),
      'row' => LumideRow.fromJson(json),
      'column' => LumideColumn.fromJson(json),
      _ => throw ArgumentError('Unknown widget type: $type'),
    };
  }
}

/// Forward declarations for fromJson
class LumideBox extends LumideWidget {
  const LumideBox({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.child,
  });

  factory LumideBox.fromJson(Map<String, dynamic> json) {
    return LumideBox(
      key: json['key'] as String?,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      padding: json['padding'] as double?,
      margin: json['margin'] as double?,
      color: json['color'] as String?,
      borderRadius: json['borderRadius'] as double?,
      child: json['child'] != null
          ? LumideWidget.fromJson(json['child'] as Map<String, dynamic>)
          : null,
    );
  }

  final double? width;
  final double? height;
  final double? padding;
  final double? margin;
  final String? color; // Hex color string
  final double? borderRadius;
  final LumideWidget? child;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'box',
        if (key != null) 'key': key,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (padding != null) 'padding': padding,
        if (margin != null) 'margin': margin,
        if (color != null) 'color': color,
        if (borderRadius != null) 'borderRadius': borderRadius,
        if (child != null) 'child': child!.toJson(),
      };
}

class LumideLabel extends LumideWidget {
  const LumideLabel({
    required this.text,
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
  });

  factory LumideLabel.fromJson(Map<String, dynamic> json) {
    return LumideLabel(
      key: json['key'] as String?,
      text: json['text'] as String,
      fontSize: json['fontSize'] as double?,
      fontWeight: json['fontWeight'] as String?,
      color: json['color'] as String?,
      maxLines: json['maxLines'] as int?,
    );
  }

  final String text;
  final double? fontSize;
  final String? fontWeight; // 'normal', 'bold', 'w500', etc.
  final String? color;
  final int? maxLines;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'label',
        'text': text,
        if (key != null) 'key': key,
        if (fontSize != null) 'fontSize': fontSize,
        if (fontWeight != null) 'fontWeight': fontWeight,
        if (color != null) 'color': color,
        if (maxLines != null) 'maxLines': maxLines,
      };
}

class LumideButton extends LumideWidget {
  const LumideButton({
    required this.label,
    required this.onClickAction,
    super.key,
    this.variant = 'primary',
    this.disabled = false,
  });

  factory LumideButton.fromJson(Map<String, dynamic> json) {
    return LumideButton(
      key: json['key'] as String?,
      label: json['label'] as String,
      onClickAction: json['onClickAction'] as String,
      variant: json['variant'] as String? ?? 'primary',
      disabled: json['disabled'] as bool? ?? false,
    );
  }

  final String label;
  final String onClickAction; // Action ID sent back to plugin
  final String variant; // 'primary', 'secondary', 'text'
  final bool disabled;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'button',
        'label': label,
        'onClickAction': onClickAction,
        if (key != null) 'key': key,
        'variant': variant,
        'disabled': disabled,
      };
}

class LumideTextField extends LumideWidget {
  const LumideTextField({
    required this.id,
    super.key,
    this.placeholder,
    this.initialValue,
    this.onChangeAction,
    this.obscureText = false,
  });

  factory LumideTextField.fromJson(Map<String, dynamic> json) {
    return LumideTextField(
      key: json['key'] as String?,
      id: json['id'] as String,
      placeholder: json['placeholder'] as String?,
      initialValue: json['initialValue'] as String?,
      onChangeAction: json['onChangeAction'] as String?,
      obscureText: json['obscureText'] as bool? ?? false,
    );
  }

  final String id; // Field ID for value retrieval
  final String? placeholder;
  final String? initialValue;
  final String? onChangeAction; // Action ID for change events
  final bool obscureText;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'textField',
        'id': id,
        if (key != null) 'key': key,
        if (placeholder != null) 'placeholder': placeholder,
        if (initialValue != null) 'initialValue': initialValue,
        if (onChangeAction != null) 'onChangeAction': onChangeAction,
        'obscureText': obscureText,
      };
}

class LumideRow extends LumideWidget {
  const LumideRow({
    super.key,
    this.children = const [],
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.spacing,
  });

  factory LumideRow.fromJson(Map<String, dynamic> json) {
    return LumideRow(
      key: json['key'] as String?,
      children: (json['children'] as List? ?? [])
          .map((e) => LumideWidget.fromJson(e as Map<String, dynamic>))
          .toList(),
      mainAxisAlignment: json['mainAxisAlignment'] as String?,
      crossAxisAlignment: json['crossAxisAlignment'] as String?,
      spacing: json['spacing'] as double?,
    );
  }

  final List<LumideWidget> children;
  final String? mainAxisAlignment; // 'start', 'center', 'end', 'spaceBetween'
  final String? crossAxisAlignment; // 'start', 'center', 'end', 'stretch'
  final double? spacing;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'row',
        if (key != null) 'key': key,
        'children': children.map((c) => c.toJson()).toList(),
        if (mainAxisAlignment != null) 'mainAxisAlignment': mainAxisAlignment,
        if (crossAxisAlignment != null)
          'crossAxisAlignment': crossAxisAlignment,
        if (spacing != null) 'spacing': spacing,
      };
}

class LumideColumn extends LumideWidget {
  const LumideColumn({
    super.key,
    this.children = const [],
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.spacing,
  });

  factory LumideColumn.fromJson(Map<String, dynamic> json) {
    return LumideColumn(
      key: json['key'] as String?,
      children: (json['children'] as List? ?? [])
          .map((e) => LumideWidget.fromJson(e as Map<String, dynamic>))
          .toList(),
      mainAxisAlignment: json['mainAxisAlignment'] as String?,
      crossAxisAlignment: json['crossAxisAlignment'] as String?,
      spacing: json['spacing'] as double?,
    );
  }

  final List<LumideWidget> children;
  final String? mainAxisAlignment;
  final String? crossAxisAlignment;
  final double? spacing;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'column',
        if (key != null) 'key': key,
        'children': children.map((c) => c.toJson()).toList(),
        if (mainAxisAlignment != null) 'mainAxisAlignment': mainAxisAlignment,
        if (crossAxisAlignment != null)
          'crossAxisAlignment': crossAxisAlignment,
        if (spacing != null) 'spacing': spacing,
      };
}
