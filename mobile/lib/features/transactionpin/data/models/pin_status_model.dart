/// Mirrors PinStatusResponse from GET /api/transaction-pin/status.
class PinStatusModel {
  final bool pinConfigured;
  final String message;

  const PinStatusModel({required this.pinConfigured, required this.message});

  factory PinStatusModel.fromJson(Map<String, dynamic> json) {
    return PinStatusModel(
      pinConfigured: json['pinConfigured'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
