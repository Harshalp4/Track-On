class BaseUrl {
  static const String baseUrl = "https://cims-trackon-api.azurewebsites.net";

  static const String login = "$baseUrl/api/TokenAuth/Authenticate";
  static const String logout = "$baseUrl/api/TokenAuth/Logout";

  static const String getTimeLog =
      "$baseUrl/api/services/app/Timelogs/GetTimeLog";
  static const String getDeviceTracking =
      "$baseUrl/api/services/app/DeviceTrackings/GetDeviceTracking";

  static const String getNewFaceForDevice =
      "$baseUrl/api/services/app/User/GetNewFaceForDevice?deviceKey=";
  static const String registeredFaceForDevice =
      "$baseUrl/api/services/app/User/RegisteredFaceForDevice";
  static const String getDeviceIdFromKey =
      "$baseUrl/api/services/app/User/GetDeviceIdByKey";
  static const String getPersonIdByIdCardNum =
      "$baseUrl/api/services/app/Persons/GetPersonIdByIdCardNum";
  static const String getDeviceLookup =
      "$baseUrl/api/services/app/Devices/GetDeviceLookup";
}
