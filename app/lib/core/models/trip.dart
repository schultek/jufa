import 'package:dart_mappable/dart_mappable.dart';

import '../../main.mapper.g.dart';
import '../templates/templates.dart';
import '../themes/themes.dart';

@MappableClass()
class Trip with Mappable {
  final String name;
  final String id;
  final String? pictureUrl;
  final TemplateModel template;
  final ThemeModel theme;
  final Map<String, TripUser> users;
  final Map<String, List<String>> modules;
  final List<String> moduleBlacklist;

  Trip({
    required this.id,
    required this.name,
    this.pictureUrl,
    required this.template,
    required this.theme,
    this.users = const {},
    this.modules = const {},
    this.moduleBlacklist = const [],
  });
}

@MappableClass()
class TripUser with Mappable {
  String role;
  String? nickname;
  String? profileUrl;

  TripUser({this.role = UserRoles.participant, this.nickname, this.profileUrl});

  bool get isOrganizer => role == UserRoles.organizer;
}

class UserRoles {
  static const organizer = 'organizer';
  static const leader = 'leader';
  static const participant = 'participant';
}
