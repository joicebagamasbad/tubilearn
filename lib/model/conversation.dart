import 'message.dart';

class Conversation {
  final String id;
  final String userName;
  final String initials;
  final String city;
  final String skillWanted;
  final String skillOffered;
  final String status;

  final List<Message> messages;

  Conversation({
    required this.id,
    required this.userName,
    required this.initials,
    required this.city,
    required this.skillWanted,
    required this.skillOffered,
    required this.status,
    required this.messages,
  });
}