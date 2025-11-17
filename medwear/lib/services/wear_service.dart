import 'dart:async';
import 'package:flutter/services.dart';

class WearService {
  static const _channel = MethodChannel('com.medwear/wear');

  static Future<List<Map<String, dynamic>>> getConnectedNodes() async {
    final res = await _channel.invokeMethod<List<dynamic>>('getConnectedNodes');
    final list = (res ?? []).cast<Map<dynamic, dynamic>>();
    return list
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);
  }

  static Future<bool> sendPing({String path = '/ping', String payload = 'ping'}) async {
    final ok = await _channel.invokeMethod<bool>('sendPing', {
      'path': path,
      'payload': payload,
    });
    return ok ?? false;
  }
}