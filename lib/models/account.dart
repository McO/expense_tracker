import 'currency.dart';

class Account {
  final String id;
  final String name;
  final Currency currency;
  final String icon;
  final String color;
  final bool isDefault;

  Account({
    required this.id,
    required this.name,
    required this.currency,
    this.icon = '💳',
    this.color = 'FF2196F3', // Blue
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currency': currency.toJson(),
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      currency: Currency.fromJson(json['currency'] as Map<String, dynamic>),
      icon: json['icon'] as String? ?? '💳',
      color: json['color'] as String? ?? 'FF2196F3',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Account copyWith({
    String? id,
    String? name,
    Currency? currency,
    String? icon,
    String? color,
    bool? isDefault,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}
