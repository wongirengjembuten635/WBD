enum UserRole { driver, client }

String getUserRoleString(UserRole role) {
  switch (role) {
    case UserRole.driver:
      return 'driver';
    case UserRole.client:
      return 'client';
  }
}

UserRole? userRoleFromString(String? roleStr) {
  if (roleStr == 'driver') return UserRole.driver;
  if (roleStr == 'client') return UserRole.client;
  return null;
}
