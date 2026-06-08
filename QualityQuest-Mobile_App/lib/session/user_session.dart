class UserSession {
  static int? userId;
  static String? fname;
  static String? lname;
  static String? email;
  static bool isDiabetic = false;
  static String? profilePicture;
  static String? password;


  static String get fullName {
    if (fname == null || fname!.isEmpty) return "Guest";
    return "$fname ${lname ?? ''}".trim();
  }

  static void clear() {
    userId = null;
    fname = null;
    lname = null;
    email = null;
    isDiabetic = false;
  }
}
