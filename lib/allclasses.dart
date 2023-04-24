class Employee {
  final String id;
  final String firstName;
  final String lastName;

  Employee(this.id, this.firstName, this.lastName);

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      json['id'],
      json['first_name'],
      json['last_name'],
    );
  }
}

class UserSettings {
  final String customer_id;
  final String camera_level;
  final String active_days;
  final String start_time;
  final String end_time;

  UserSettings(this.customer_id, this.camera_level, this.active_days,
      this.start_time, this.end_time);

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(json['customer_id'], json['camera_level'],
        json['active_day'], json['start_time'], json['end_time']);
  }
}

class Alert {
  final String alert_id;
  final String customer_id;
  final String type;
  final String date;
  final String image;
  final String location_id;

  Alert(this.alert_id, this.customer_id, this.type, this.date, this.image,
      this.location_id);
  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(json['alert_id'], json['customer_id'], json['type'],
        json['date'], json['image'], json['location_id']);
  }
}

class Location {
  final int location_id;
  final String region_name;
  final String district_name;
  final String area_name;
  final String street_name;
  final String house_info;

  Location(this.location_id, this.region_name, this.district_name,
      this.area_name, this.street_name, this.house_info);
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
        json['location_id'],
        json['region_name'],
        json['district_name'],
        json['area_name'],
        json['street_name'],
        json['house_info']);
  }
}

class DefaultPlace {
  final String location_id;
  final String region_name;
  final String district_name;
  final String area_name;

  DefaultPlace(
      this.location_id, this.region_name, this.district_name, this.area_name);
  factory DefaultPlace.fromJson(Map<String, dynamic> json) {
    return DefaultPlace(
      json['location_id'],
      json['region_name'],
      json['district_name'],
      json['area_name'],
    );
  }
}

class User {
  final String email;
  final String pass;
  User(this.email, this.pass);
}

class stationStaff extends User {
  stationStaff(String email, String pass) : super(email, pass);
}

class Customer {
  final String customer_id;
  final String customer_name;
  final String customer_phone;
  final String customer_email;
  final String customer_pass;
  final String location_id;
  Customer(this.customer_id, this.customer_name, this.customer_phone,
      this.customer_email, this.customer_pass, this.location_id);
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      json['customer_id'],
      json['customer_name'],
      json['customer_phone'],
      json['customer_email'],
      json['customer_pass'],
      json['location_id'],
    );
  }
}

class Object {
  final String name;
  final String image;
  final String danger_level;
  Object(this.name, this.image, this.danger_level);
  factory Object.fromJson(Map<String, dynamic> json) {
    return Object(
      json['name'],
      json['image'],
      json['danger_level'],
    );
  }
}

class Success {
  final String condition;

  Success(this.condition);
  factory Success.fromJson(Map<String, dynamic> json) {
    return Success(
      json['condition'],
    );
  }
}

class Suspect {
  final String name;
  final String image;
  Suspect(this.name, this.image);
  factory Suspect.fromJson(Map<String, dynamic> json) {
    return Suspect(
      json['name'],
      json['image'],
    );
  }
}

class CameraMessages {
  static const String automatic = 'automatic';
  static const String motion = 'motion';
  static const String object = 'object';
  static const String criminal = 'criminal';
  static const String object_criminal = 'object_criminal';
  static const String criminal_motion = 'criminal_motion';
  static const String object_motion = 'object_motion';
  static const String start = 'start';
  static const String stop = 'stop';
  static const String remote = 'manual';
}
