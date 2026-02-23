import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:schedule_generator_ai/models/task.dart';

class GeminiService {
  static const String _baseUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent";
  final String apiKey;

  GeminiService() : apiKey = dotenv.env["GEMINI_API_KEY"] ?? "Please input your API KEY" {
    if (apiKey.isEmpty) { // kalo kosong
      throw ArgumentError("API KEY is missing");
    }
  }

   Future<String> generateSchedule(List<Task> tasks) async {
    _validateTasks(tasks);
    final prompt = _buildPromt(tasks);
    try {
      // akan muncul di debug console
      print("Prompt: \n$prompt");
      // menambahkan request timeout message untuk menghindari kalau API nya tidak merespon.
      // timeout => supaya proses tidak terlalu lama
      final response = await http
          .post(Uri.parse("$_baseUrl?key=$apiKey"), 
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "contents": [
              {
                "role": "user",
                "parts": [
                  {"text": prompt}
                ]
              }
            ]
          })
          ).timeout(Duration(seconds: 20));
          return _handleResponse(response);
      // sebuah code yg letak nya setelah await itu hasil yg akan di generate setelah proses asinkronus selesai.
    } catch (e) {
      throw ArgumentError("Failed to generate schedule: $e");
    }
  }

  String _handleResponse(http.Response responses) {
    final data = jsonDecode(responses.body);
    if (responses.statusCode == 401) {
      throw ArgumentError("Invalid API Key or Unauthorized Access");
    } else if (responses.statusCode == 429) {
      throw ArgumentError("Rate limit exceded");
    } else if (responses.statusCode == 500) {
      throw ArgumentError("Internal Server Error");
    } else if (responses.statusCode == 503) {
      throw ArgumentError("Service Unavailable");
    } else if (responses.statusCode == 200) {
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      throw ArgumentError("Unknown Error");
    }
  }

  String _buildPromt(List<Task> tasks) {
    final tasksList = tasks.map((tasks) => "${tasks.name} (Priority: ${tasks.priority}, Duration: ${tasks.duration} minute, Deadline: ${tasks.deadline})").join("\n");
    return "Buatkan jadwal harian yang optimal berdasarkan task berikut:\n$tasksList";
  }

  // kadang yang bikin error itu adalah perubahan versi library
  void _validateTasks(List<Task> tasks) {
    if (tasks.isEmpty) throw ArgumentError("Task cannot be empty. Please insert your promt");
  }
}

// sebuah kode yang letaknya setelah keyword await itu hasilnya akan di generate setelah proses async selesai