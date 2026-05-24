import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object> get props => [];
}

class FetchUnreadCount extends NotificationEvent {}

class NotificationMarkAsRead extends NotificationEvent {}

class NotificationMarkAllAsRead extends NotificationEvent {}
