

Map<String, List<String>> getInviteMatches({
  required List<String> people,
  required List<Map<String, dynamic>> friends,
}) {
  final List<String> inviteNames = [];
  final List<String> invitedUserIds = [];
  print("🔍 getInviteMatches called with:");
  print("People: $people");
  print("Friends: ${friends.map((f) => f['nickname']).toList()}");

  for (final name in people) {
    for (final friend in friends) {
      final String nickname = friend['nickname'] ?? '';
      final String firstName = friend['firstName'] ?? '';
      final String lastName = friend['lastName'] ?? '';
      final String fullName = '$firstName $lastName';
      final String uid = friend['uid'];

      // Check if the name matches nickname, first name, or full name
      if (name.toLowerCase() == nickname.toLowerCase() ||
          name.toLowerCase() == firstName.toLowerCase() ||
          name.toLowerCase() == fullName.toLowerCase() ||
          name.toLowerCase() == lastName.toLowerCase()) {
        inviteNames.add(name);
        print("Friend found: $name");
        invitedUserIds.add(uid);
        break; // Stop checking other friends for this name
      }
    }
  }

  return {
    'inviteNames': inviteNames,
    'invitedUserIds': invitedUserIds,
  };
}
