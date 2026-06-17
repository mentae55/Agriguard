import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ClassificationResult {
  final String prediction;
  final double confidence;
  final Map<String, dynamic> allScores;
  final String? error;

  ClassificationResult({
    required this.prediction,
    required this.confidence,
    required this.allScores,
    this.error,
  });

  factory ClassificationResult.withError(String message) {
    return ClassificationResult(
      prediction: '',
      confidence: 0.0,
      allScores: {},
      error: message,
    );
  }
}

class ClassificationService {
  final String baseUrl;
  final Duration timeoutDuration;
  final int maxRetries;
  final Duration initialBackoff;

  http.Client? _activeClient;

  ClassificationService({
    this.baseUrl = 'https://robot-api-production.up.railway.app',
    this.timeoutDuration = const Duration(seconds: 90), // production-safe timeout
    this.maxRetries = 3,
    this.initialBackoff = const Duration(seconds: 2),
  });

  /// Send image to classification API based on crop type
  /// cropType: 'wheat', 'tomato', or 'both'
  Future<ClassificationResult> classifyImage({
    required File imageFile,
    required String cropType,
  }) async {
    // Cancel previous active request client to abort duplicate requests
    _activeClient?.close();

    final client = http.Client();
    _activeClient = client;

    try {
      String endpoint;
      if (cropType.toLowerCase() == 'wheat') {
        endpoint = '/classify/task1';
      } else if (cropType.toLowerCase() == 'tomato') {
        endpoint = '/classify/task2';
      } else {
        endpoint = '/classify/both';
      }

      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('[ClassificationService] Sending POST request to: $uri');

      // Check if file exists and has size
      if (!await imageFile.exists()) {
        return ClassificationResult.withError('The selected image file does not exist.');
      }
      final int size = await imageFile.length();
      if (size == 0) {
        return ClassificationResult.withError('The selected image file is empty.');
      }

      int attempt = 0;
      http.Response? response;
      String? lastErrorMessage;

      while (attempt < maxRetries) {
        attempt++;
        try {
          debugPrint('[ClassificationService] Attempt $attempt of $maxRetries...');

          // Re-create MultipartRequest for each attempt
          final request = http.MultipartRequest('POST', uri);
          
          // Determine content type
          String extension = imageFile.path.split('.').last.toLowerCase();
          String mimeType = 'image/jpeg';
          if (extension == 'png') {
            mimeType = 'image/png';
          } else if (extension == 'webp') {
            mimeType = 'image/webp';
          }

          // Add image file to request
          final stream = http.ByteStream(imageFile.openRead());
          final multipartFile = http.MultipartFile(
            'file',
            stream,
            size,
            filename: imageFile.path.split(Platform.pathSeparator).last,
            contentType: MediaType.parse(mimeType),
          );
          request.files.add(multipartFile);

          // Send request with configured timeout duration
          final streamedResponse = await client.send(request).timeout(timeoutDuration);
          response = await http.Response.fromStream(streamedResponse);
          
          // Request succeeded, break from retry loop
          break;
        } on SocketException catch (e) {
          debugPrint('[ClassificationService] SocketException on attempt $attempt: $e');
          lastErrorMessage = 'No internet connection. Please verify your network.';
        } on TimeoutException catch (e) {
          debugPrint('[ClassificationService] TimeoutException on attempt $attempt: $e');
          lastErrorMessage = 'Classification request timed out. Please try again.';
        } on http.ClientException catch (e) {
          debugPrint('[ClassificationService] ClientException on attempt $attempt: $e');
          lastErrorMessage = 'Connection aborted or closed.';
          // If the client was closed manually (cancelled), don't retry!
          if (e.message.toLowerCase().contains('closed') || e.message.toLowerCase().contains('abort')) {
            return ClassificationResult.withError('Classification request cancelled.');
          }
        } catch (e) {
          debugPrint('[ClassificationService] Unexpected error on attempt $attempt: $e');
          lastErrorMessage = 'Network error: $e';
        }

        // Wait with exponential backoff delay before retrying
        if (attempt < maxRetries) {
          final backoffDelay = initialBackoff * (1 << (attempt - 1));
          debugPrint('[ClassificationService] Waiting ${backoffDelay.inSeconds}s before next retry...');
          await Future.delayed(backoffDelay);
        }
      }

      if (response == null) {
        return ClassificationResult.withError(lastErrorMessage ?? 'Request failed after $maxRetries attempts.');
      }

      debugPrint('[ClassificationService] Status code: ${response.statusCode}');
      debugPrint('[ClassificationService] Response body: ${response.body}');

      if (response.statusCode != 200) {
        // Handle validation errors from API (e.g. status code 422)
        try {
          final errBody = jsonDecode(response.body);
          if (errBody is Map && errBody.containsKey('detail')) {
            final details = errBody['detail'];
            if (details is List && details.isNotEmpty) {
              return ClassificationResult.withError(details[0]['msg']?.toString() ?? 'Validation error.');
            }
            return ClassificationResult.withError(errBody['detail']?.toString() ?? 'Server validation failed.');
          }
        } catch (_) {}
        return ClassificationResult.withError('Server returned error code: ${response.statusCode}');
      }

      final parsed = jsonDecode(response.body);
      if (parsed == null || parsed is! Map) {
        return ClassificationResult.withError('Invalid JSON response format.');
      }

      // If we called classify both, the response structure is a map of results:
      // e.g. {"task1": {"prediction": "...", "confidence": ...}, "task2": {"prediction": "...", "confidence": ...}}
      if (cropType.toLowerCase() == 'both') {
        if (parsed.containsKey('task1') || parsed.containsKey('task2')) {
          final t1 = parsed['task1'] as Map?;
          final t2 = parsed['task2'] as Map?;
          
          final double c1 = double.tryParse(t1?['confidence']?.toString() ?? '0.0') ?? 0.0;
          final double c2 = double.tryParse(t2?['confidence']?.toString() ?? '0.0') ?? 0.0;

          if (c1 >= c2 && t1 != null) {
            return ClassificationResult(
              prediction: t1['prediction']?.toString() ?? 'Healthy',
              confidence: c1,
              allScores: Map<String, dynamic>.from(t1['all_scores'] ?? t1['scores'] ?? {}),
            );
          } else if (t2 != null) {
            return ClassificationResult(
              prediction: t2['prediction']?.toString() ?? 'Healthy',
              confidence: c2,
              allScores: Map<String, dynamic>.from(t2['all_scores'] ?? t2['scores'] ?? {}),
            );
          }
        }
      }

      // Default single task parsing
      final prediction = parsed['prediction']?.toString() ?? '';
      final confidence = double.tryParse(parsed['confidence']?.toString() ?? '0.0') ?? 0.0;
      final allScores = Map<String, dynamic>.from(parsed['all_scores'] ?? parsed['scores'] ?? {});

      if (prediction.isEmpty) {
        return ClassificationResult.withError('Prediction is missing in server response.');
      }

      return ClassificationResult(
        prediction: prediction,
        confidence: confidence,
        allScores: allScores,
      );

    } finally {
      client.close();
      if (_activeClient == client) {
        _activeClient = null;
      }
    }
  }
}
