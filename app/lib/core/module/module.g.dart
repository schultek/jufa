import 'module.super.dart';
import 'module.dart';

final registry = ModuleRegistry({
  'thebutto': ModuleInstance<TheButtonModule>(TheButtonModule(),
      {'thebutton': ModuleFactory<TheButtonModule, ContentSegment>((c, m, id) => m.getButtonCard())}),
  'profile': ModuleInstance<ProfileModule>(
      ProfileModule(), {'profile': ModuleFactory<ProfileModule, ContentSegment>((c, m, id) => m.getProfileCard())}),
  'chat': ModuleInstance<ChatModule>(
      ChatModule(), {'chat': ModuleFactory<ChatModule, PageSegment>((c, m, id) => m.getChatPage())}),
  'camera': ModuleInstance<CameraModule>(
      CameraModule(), {'camera': ModuleFactory<CameraModule, PageSegment>((c, m, id) => m.getCameraPage())}),
  'elimination': ModuleInstance<EliminationModule>(
      EliminationModule(), {'game': ModuleFactory<EliminationModule, ContentSegment>((c, m, id) => m.getGame(c, id))}),
  'poll': ModuleInstance<PollsModule>(
      PollsModule(), {'poll': ModuleFactory<PollsModule, ContentSegment>((c, m, id) => m.getPoll(c, id))}),
  'welcome': ModuleInstance<WelcomeModule>(WelcomeModule(), {
    'action1': ModuleFactory<WelcomeModule, QuickAction>((c, m, id) => m.getAction1()),
    'welcome': ModuleFactory<WelcomeModule, ContentSegment>((c, m, id) => m.getWelcomeBanner(id))
  }),
  'announcement': ModuleInstance<AnnouncementModule>(AnnouncementModule(),
      {'announcement': ModuleFactory<AnnouncementModule, ContentSegment>((c, m, id) => m.getAnnouncement(c, id))}),
  'users': ModuleInstance<UsersModule>(
      UsersModule(), {'users': ModuleFactory<UsersModule, ContentSegment>((c, m, id) => m.getUsers())}),
  'music': ModuleInstance<MusicModule>(
      MusicModule(), {'player': ModuleFactory<MusicModule, ContentSegment>((c, m, id) => m.getPlayer(c, id))}),
  'notes': ModuleInstance<NotesModule>(NotesModule(), {
    'notes': ModuleFactory<NotesModule, ContentSegment>((c, m, id) => m.getNotes()),
    'note': ModuleFactory<NotesModule, ContentSegment>((c, m, id) => m.getNote(c, id))
  })
});
