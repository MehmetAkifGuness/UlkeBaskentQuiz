class AuthModel {
  final String? token;
  final String? username;
  final String? message;

  AuthModel({this.token, this.username, this.message});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token: json['token'],
      username: json['username'],
      message: json['message'],
    );
  }
}
