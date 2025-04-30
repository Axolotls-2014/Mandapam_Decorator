class SignUpBodyModel {
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? password;
  String? refCode;
  // String? deviceToken;
  String? UserType;
  String? zoneId;
  String? moduleId;
  String? latitude;
  String? longitude;
  String? address;

  SignUpBodyModel({
    this.phone,
    this.fName,
    this.lName,
    this.email = '',
    this.UserType,
    this.refCode = '',
    // this.deviceToken,
    this.password,
    this.latitude,
    this.longitude,
    this.zoneId,
    this.moduleId,
    this.address,
  });

  SignUpBodyModel.fromJson(Map<String, dynamic> json) {
    phone = json['phone'];
    fName = json['f_name'];
    lName = json['l_name'];
    email = json['email'];
    UserType = json['usertype'];
    refCode = json['ref_by'];
    password = json['password'];
    // deviceToken = json['cm_firebase_token'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    zoneId = json['zone_id'];
    moduleId = json['module_id'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['phone'] = phone;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['email'] = email;
    data['usertype'] = UserType;
    data['ref_by'] = refCode;
    data['password'] = password;
    // data['cm_firebase_token'] = deviceToken;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['zone_id'] = zoneId;
    data['module_id'] = moduleId;
    data['address'] = address;
    return data;
  }
}
