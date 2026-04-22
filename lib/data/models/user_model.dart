class UserModel {

  String uid;
  String name;
  String email;
  String phone;
  String address;
  String avatar;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.avatar,
  });

  Map<String,dynamic> toJson(){
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "phone": phone,
      "address": address,
      "avatar": avatar
    };
  }

}