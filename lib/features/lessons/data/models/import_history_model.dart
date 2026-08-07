import 'package:cloud_firestore/cloud_firestore.dart';

class ImportHistoryModel {
  final String id;
  final String fileName;
  final String fileType;
  final String importedBy;
  final DateTime? importedAt;
  final int totalRecords;
  final int createdRecords;
  final int updatedRecords;
  final int skippedRecords;
  final int failedRecords;
  final int durationMs;
  final String status;

  ImportHistoryModel({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.importedBy,
    this.importedAt,
    required this.totalRecords,
    required this.createdRecords,
    required this.updatedRecords,
    required this.skippedRecords,
    required this.failedRecords,
    required this.durationMs,
    required this.status,
  });

  factory ImportHistoryModel.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return ImportHistoryModel(
      id: documentId,
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      importedBy: json['importedBy'] ?? '',
      importedAt: json['importedAt'] != null
          ? (json['importedAt'] as Timestamp).toDate()
          : null,
      totalRecords: json['totalRecords'] ?? 0,
      createdRecords: json['createdRecords'] ?? 0,
      updatedRecords: json['updatedRecords'] ?? 0,
      skippedRecords: json['skippedRecords'] ?? 0,
      failedRecords: json['failedRecords'] ?? 0,
      durationMs: json['durationMs'] ?? 0,
      status: json['status'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileType': fileType,
      'importedBy': importedBy,
      'importedAt': importedAt != null
          ? Timestamp.fromDate(importedAt!)
          : FieldValue.serverTimestamp(),
      'totalRecords': totalRecords,
      'createdRecords': createdRecords,
      'updatedRecords': updatedRecords,
      'skippedRecords': skippedRecords,
      'failedRecords': failedRecords,
      'durationMs': durationMs,
      'status': status,
    };
  }
}
