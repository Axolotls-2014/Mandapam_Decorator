class ResponseModel {
  final bool _isSuccess;
  final String? _message;
  final String? token;
  final bool isPhoneVerified;
  final int? userId;
  List<int>? zoneIds;

  ResponseModel(
    this._isSuccess,
    this._message, {
    this.token,
    this.isPhoneVerified = false,
    this.userId,
    this.zoneIds,
  });

  String? get message => _message;
  bool get isSuccess => _isSuccess;
}
