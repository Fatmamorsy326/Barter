// ============================================
// FILE: lib/model/exchange_model.dart
// ============================================

import 'package:flutter/material.dart';

enum ExchangeStatus {
  pending,    // Waiting for acceptance
  accepted,   // Both agreed, arranging meetup
  completed,  // Both confirmed exchange happened
  cancelled,  // Either user cancelled
}

class ExchangeModel {
  final String id;
  final ExchangeStatus status;
  final String proposedBy;      // User who proposed
  final String proposedTo;      // User who receives proposal
  final ExchangeItem itemOffered;   // What proposer offers
  final ExchangeItem itemRequested; // What proposer wants
  final DateTime proposedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final List<String> confirmedBy;  // User IDs who confirmed
  final String? meetingLocation;
  final DateTime? meetingDate;
  final String? notes;
  final String chatId;
  final double? ratingByProposer;  // 1-5 stars
  final double? ratingByAccepter;  // 1-5 stars
  final String? reviewByProposer;
  final String? reviewByAccepter;

  ExchangeModel({
    required this.id,
    required this.status,
    required this.proposedBy,
    required this.proposedTo,
    required this.itemOffered,
    required this.itemRequested,
    required this.proposedAt,
    this.acceptedAt,
    this.completedAt,
    this.confirmedBy = const [],
    this.meetingLocation,
    this.meetingDate,
    this.notes,
    required this.chatId,
    this.ratingByProposer,
    this.ratingByAccepter,
    this.reviewByProposer,
    this.reviewByAccepter,
  });

  factory ExchangeModel.fromJson(Map<String, dynamic> json) {
    return ExchangeModel(
      id: json['id'] ?? '',
      status: ExchangeStatus.values[json['status'] ?? 0],
      proposedBy: json['proposedBy'] ?? '',
      proposedTo: json['proposedTo'] ?? '',
      itemOffered: ExchangeItem.fromJson(json['itemOffered'] ?? {}),
      itemRequested: ExchangeItem.fromJson(json['itemRequested'] ?? {}),
      proposedAt: DateTime.parse(json['proposedAt']),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      confirmedBy: List<String>.from(json['confirmedBy'] ?? []),
      meetingLocation: json['meetingLocation'],
      meetingDate: json['meetingDate'] != null
          ? DateTime.parse(json['meetingDate'])
          : null,
      notes: json['notes'],
      chatId: json['chatId'] ?? '',
      ratingByProposer: json['ratingByProposer']?.toDouble(),
      ratingByAccepter: json['ratingByAccepter']?.toDouble(),
      reviewByProposer: json['reviewByProposer'],
      reviewByAccepter: json['reviewByAccepter'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.index,
      'proposedBy': proposedBy,
      'proposedTo': proposedTo,
      'itemOffered': itemOffered.toJson(),
      'itemRequested': itemRequested.toJson(),
      'proposedAt': proposedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'confirmedBy': confirmedBy,
      'meetingLocation': meetingLocation,
      'meetingDate': meetingDate?.toIso8601String(),
      'notes': notes,
      'chatId': chatId,
      'ratingByProposer': ratingByProposer,
      'ratingByAccepter': ratingByAccepter,
      'reviewByProposer': reviewByProposer,
      'reviewByAccepter': reviewByAccepter,
    };
  }

  ExchangeModel copyWith({
    String? id,
    ExchangeStatus? status,
    DateTime? acceptedAt,
    DateTime? completedAt,
    List<String>? confirmedBy,
    String? meetingLocation,
    DateTime? meetingDate,
    String? notes,
    double? ratingByProposer,
    double? ratingByAccepter,
    String? reviewByProposer,
    String? reviewByAccepter,
  }) {
    return ExchangeModel(
      id: id ?? this.id,
      status: status ?? this.status,
      proposedBy: proposedBy,
      proposedTo: proposedTo,
      itemOffered: itemOffered,
      itemRequested: itemRequested,
      proposedAt: proposedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      meetingLocation: meetingLocation ?? this.meetingLocation,
      meetingDate: meetingDate ?? this.meetingDate,
      notes: notes ?? this.notes,
      chatId: chatId,
      ratingByProposer: ratingByProposer ?? this.ratingByProposer,
      ratingByAccepter: ratingByAccepter ?? this.ratingByAccepter,
      reviewByProposer: reviewByProposer ?? this.reviewByProposer,
      reviewByAccepter: reviewByAccepter ?? this.reviewByAccepter,
    );
  }
}

class ExchangeItem {
  final String itemId;
  final String title;
  final String imageUrl;

  ExchangeItem({
    required this.itemId,
    required this.title,
    required this.imageUrl,
  });

  factory ExchangeItem.fromJson(Map<String, dynamic> json) {
    return ExchangeItem(
      itemId: json['itemId'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'title': title,
      'imageUrl': imageUrl,
    };
  }
}

// Extension for display
extension ExchangeStatusExtension on ExchangeStatus {
  String get displayName {
    switch (this) {
      case ExchangeStatus.pending:
        return 'Pending';
      case ExchangeStatus.accepted:
        return 'Accepted';
      case ExchangeStatus.completed:
        return 'Completed';
      case ExchangeStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ExchangeStatus.pending:
        return Colors.orange;
      case ExchangeStatus.accepted:
        return Colors.blue;
      case ExchangeStatus.completed:
        return Colors.green;
      case ExchangeStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ExchangeStatus.pending:
        return Icons.hourglass_empty;
      case ExchangeStatus.accepted:
        return Icons.handshake;
      case ExchangeStatus.completed:
        return Icons.check_circle;
      case ExchangeStatus.cancelled:
        return Icons.cancel;
    }
  }
}