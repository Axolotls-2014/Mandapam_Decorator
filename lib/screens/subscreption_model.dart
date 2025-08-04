// To parse this JSON data, do
//
//     final subscriptionModel = subscriptionModelFromJson(jsonString);

import 'dart:convert';

SubscriptionModel subscriptionModelFromJson(String str) => SubscriptionModel.fromJson(json.decode(str));

String subscriptionModelToJson(SubscriptionModel data) => json.encode(data.toJson());

class SubscriptionModel {
    List<Package> packages;

    SubscriptionModel({
        required this.packages,
    });

    factory SubscriptionModel.fromJson(Map<String, dynamic> json) => SubscriptionModel(
        packages: List<Package>.from(json["packages"].map((x) => Package.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "packages": List<dynamic>.from(packages.map((x) => x.toJson())),
    };
}

class Package {
    int id;
    String packageName;
    int price;
    int validity;
    String maxOrder;
    String maxProduct;
    int pos;
    int mobileApp;
    int chat;
    int review;
    int selfDelivery;
    int status;
    int packageDefault;
    dynamic colour;
    dynamic text;
    DateTime createdAt;
    DateTime updatedAt;
    List<dynamic> translations;

    Package({
        required this.id,
        required this.packageName,
        required this.price,
        required this.validity,
        required this.maxOrder,
        required this.maxProduct,
        required this.pos,
        required this.mobileApp,
        required this.chat,
        required this.review,
        required this.selfDelivery,
        required this.status,
        required this.packageDefault,
        required this.colour,
        required this.text,
        required this.createdAt,
        required this.updatedAt,
        required this.translations,
    });

    factory Package.fromJson(Map<String, dynamic> json) => Package(
        id: json["id"],
        packageName: json["package_name"],
        price: json["price"],
        validity: json["validity"],
        maxOrder: json["max_order"],
        maxProduct: json["max_product"],
        pos: json["pos"],
        mobileApp: json["mobile_app"],
        chat: json["chat"],
        review: json["review"],
        selfDelivery: json["self_delivery"],
        status: json["status"],
        packageDefault: json["default"],
        colour: json["colour"],
        text: json["text"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        translations: List<dynamic>.from(json["translations"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "package_name": packageName,
        "price": price,
        "validity": validity,
        "max_order": maxOrder,
        "max_product": maxProduct,
        "pos": pos,
        "mobile_app": mobileApp,
        "chat": chat,
        "review": review,
        "self_delivery": selfDelivery,
        "status": status,
        "default": packageDefault,
        "colour": colour,
        "text": text,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "translations": List<dynamic>.from(translations.map((x) => x)),
    };
}
