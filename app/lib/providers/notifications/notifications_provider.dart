import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module/module_builder.dart';
import '../../main.mapper.g.dart';
import '../../modules/modules.dart';
import '../groups/logic_provider.dart';

final messageProvider = StateProvider<RemoteMessage?>((ref) => null);

final notificationsProvider = Provider((ref) => NotificationLogic(ref));

class NotificationLogic {
  final _firebaseMessaging = FirebaseMessaging.instance;

  bool _isSetup = false;

  final Ref ref;
  NotificationLogic(this.ref);

  Future<void> setup() async {
    if (_isSetup) return;

    var settings = await _firebaseMessaging.requestPermission();

    await AwesomeNotifications().initialize(
        'resource://drawable/app_icon',
        [
          NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'announcements',
            channelName: 'Announcements',
            channelDescription: 'Notification channel for announcements',
          ),
          NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'chat',
            channelName: 'Chat Notifications',
            channelDescription: 'Notification channel for chat messages',
            groupKey: 'chat',
            groupSort: GroupSort.Desc,
            groupAlertBehavior: GroupAlertBehavior.Children,
            importance: NotificationImportance.High,
          )
        ],
        // Channel groups are only visual and are not required
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group',
          ),
        ],
        debug: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _isSetup = true;
    }

    var isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    AwesomeNotifications().setListeners(onActionReceivedMethod: onActionReceived);

    if (!_firebaseMessaging.isAutoInitEnabled) {
      await _firebaseMessaging.setAutoInitEnabled(true);
    }

    var token = await _firebaseMessaging.getToken();
    await ref.read(groupsLogicProvider).setPushToken(token);

    FirebaseMessaging.onMessage.listen((message) async {
      print('Got foreground notification: ${message.data}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message opened App: ${message.data}');
      ref.read(messageProvider.state).state = message;
    });

    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
  }
}

class NotificationMessage extends ModuleMessage {
  final String key;
  final String input;
  final Map<String, dynamic> payload;
  final ProviderContainer container;

  NotificationMessage(String moduleId, this.key, this.input, this.payload, this.container) : super(moduleId);
}

class BackgroundMessage extends ModuleMessage {
  final ProviderContainer container;
  final String payload;

  BackgroundMessage({String? moduleId, required this.container, required this.payload}) : super(moduleId);
}

T decodePayload<T>(String payload) {
  return Mapper.fromJson(utf8.decode(base64Decode(payload)));
}

String encodePayload(dynamic value) {
  return base64Encode(utf8.encode(Mapper.toJson(value)));
}

Future<void> onActionReceived(ReceivedAction receivedAction) async {
  print('Action received $receivedAction');
  try {
    var buttonKey = receivedAction.buttonKeyPressed;
    var buttonKeyInput = receivedAction.buttonKeyInput;
    var payload = receivedAction.payload ?? {};
    await registry.handleMessage(
      NotificationMessage(payload['moduleId'] ?? '', buttonKey, buttonKeyInput, payload, ProviderContainer()),
    );
  } catch (e, st) {
    FirebaseCrashlytics.instance.recordError(e, st);
  }
}

Future<void> onBackgroundMessage(RemoteMessage message) async {
  print('Background message: ${message.data}');
  try {
    await AwesomeNotifications().setListeners(onActionReceivedMethod: onActionReceived);

    var msg = BackgroundMessage(
      moduleId: message.data['moduleId'] as String,
      container: ProviderContainer(),
      payload: message.data['payload'] as String,
    );
    await registry.handleMessage(msg);
  } catch (e, st) {
    FirebaseCrashlytics.instance.recordError(e, st);
  }
}
