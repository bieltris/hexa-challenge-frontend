import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DuelSocketService {
  static final DuelSocketService instance = DuelSocketService._();
  DuelSocketService._();

  IO.Socket? _socket;
  String _mySocketId = '';
  String get mySocketId => _mySocketId;

  final _onlineCtrl    = StreamController<List<Map<String,dynamic>>>.broadcast();
  final _searchCtrl    = StreamController<List<Map<String,dynamic>>>.broadcast();
  final _inviteCtrl    = StreamController<Map<String,dynamic>>.broadcast();
  final _startCtrl     = StreamController<Map<String,dynamic>>.broadcast();
  final _roundStCtrl   = StreamController<Map<String,dynamic>>.broadcast();
  final _roundResCtrl  = StreamController<Map<String,dynamic>>.broadcast();
  final _endCtrl       = StreamController<Map<String,dynamic>>.broadcast();
  final _discCtrl      = StreamController<Map<String,dynamic>>.broadcast();
  final _reconCtrl     = StreamController<Map<String,dynamic>>.broadcast();
  final _queuedCtrl    = StreamController<bool>.broadcast();
  final _lockCtrl      = StreamController<String>.broadcast();
  final _declinedCtrl  = StreamController<Map<String,dynamic>>.broadcast();

  Stream<List<Map<String,dynamic>>> get onlineUsers    => _onlineCtrl.stream;
  Stream<List<Map<String,dynamic>>> get searchResults  => _searchCtrl.stream;
  Stream<Map<String,dynamic>>       get inviteReceived => _inviteCtrl.stream;
  Stream<Map<String,dynamic>>       get duelStart      => _startCtrl.stream;
  Stream<Map<String,dynamic>>       get roundStart     => _roundStCtrl.stream;
  Stream<Map<String,dynamic>>       get roundResult    => _roundResCtrl.stream;
  Stream<Map<String,dynamic>>       get duelEnd        => _endCtrl.stream;
  Stream<Map<String,dynamic>>       get oppDisconnected => _discCtrl.stream;
  Stream<Map<String,dynamic>>       get oppReconnected  => _reconCtrl.stream;
  Stream<bool>                      get queued          => _queuedCtrl.stream;
  Stream<String>                    get choiceLocked    => _lockCtrl.stream;
  Stream<Map<String,dynamic>>       get inviteDeclined  => _declinedCtrl.stream;

  void connect(String name, String sala) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('user_join', {'name': name, 'sala': sala});
      return;
    }
    _socket = IO.io(
      'https://hexa-challenge-api.onrender.com',
      IO.OptionBuilder().setTransports(['websocket']).enableReconnection().build(),
    );
    _socket!.onConnect((_) {
      _mySocketId = _socket!.id ?? '';
      _socket!.emit('user_join', {'name': name, 'sala': sala});
    });
    _socket!.on('duel_online_users',   (d) => _onlineCtrl.add(_toList(d)));
    _socket!.on('duel_search_results', (d) => _searchCtrl.add(_toList(d)));
    _socket!.on('duel_invite_received',(d) => _inviteCtrl.add(_toMap(d)));
    _socket!.on('duel_start',          (d) => _startCtrl.add(_toMap(d)));
    _socket!.on('duel_round_start',    (d) => _roundStCtrl.add(_toMap(d)));
    _socket!.on('duel_round_result',   (d) => _roundResCtrl.add(_toMap(d)));
    _socket!.on('duel_end',            (d) => _endCtrl.add(_toMap(d)));
    _socket!.on('duel_opponent_disconnected', (d) => _discCtrl.add(_toMap(d)));
    _socket!.on('duel_opponent_reconnected',  (d) => _reconCtrl.add(_toMap(d)));
    _socket!.on('duel_queued',         (_) => _queuedCtrl.add(true));
    _socket!.on('duel_queue_left',     (_) => _queuedCtrl.add(false));
    _socket!.on('duel_choice_locked',  (d) => _lockCtrl.add(_toMap(d)['choice'] as String? ?? ''));
    _socket!.on('duel_invite_declined',(d) => _declinedCtrl.add(_toMap(d)));
  }

  void searchUsers(String q)              => _socket?.emit('duel_search_users',  {'query': q});
  void inviteUser(String targetSid)       => _socket?.emit('duel_invite',        {'targetSocketId': targetSid});
  void respondInvite(String duelId, String fromSid, bool accepted) =>
      _socket?.emit('duel_invite_response', {'duelId': duelId, 'fromSocketId': fromSid, 'accepted': accepted});
  void joinQueue()                        => _socket?.emit('duel_queue_join');
  void leaveQueue()                       => _socket?.emit('duel_queue_leave');
  void sendChoice(String duelId, String choice) =>
      _socket?.emit('duel_choice', {'duelId': duelId, 'choice': choice});

  void disconnect() { _socket?.disconnect(); _socket = null; _mySocketId = ''; }

  List<Map<String,dynamic>> _toList(dynamic d) =>
      (d as List).map((e) => Map<String,dynamic>.from(e as Map)).toList();
  Map<String,dynamic> _toMap(dynamic d) => Map<String,dynamic>.from(d as Map);
}
