import 'cart_item.dart';

class OrderModel {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime date;
  final String customerName;
  final String deliveryAddress;
  final String status; // 'Placed', 'Completed', 'Cancelled'

  const OrderModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
    required this.customerName,
    required this.deliveryAddress,
    this.status = 'Placed',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'customerName': customerName,
      'deliveryAddress': deliveryAddress,
      'status': status,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      customerName: json['customerName'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      status: json['status'] as String? ?? 'Placed',
    );
  }
}
