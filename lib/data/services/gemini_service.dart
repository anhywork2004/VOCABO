import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyAppK6SvkUIzXrxDxwVDE4Xr7oJ0gwCQeU'; // 👈 key
  // gemini-2.0-flash-lite has a higher free-tier quota than gemini-2.0-flash
  static const String _model = 'gemini-2.0-flash-lite';
  static const String _historyKey = 'meow_chat_history';

  /// Maximum number of retry attempts on 429 rate-limit errors.
  static const int _maxRetries = 3;

  static Future<String> askMeow(String userMessage) async {
    try {
      final history = await loadHistory();

      // Build contents array from history + new message
      final contents = [
        ...history.map((m) => {
          "role": m['role'] == 'ai' ? 'model' : 'user',
          "parts": [{"text": m['content']}]
        }),
        {
          "role": "user",
          "parts": [{"text": userMessage}]
        }
      ];

      final body = jsonEncode({
        "system_instruction": {
          "parts": [{"text": "Bạn là Meow 😺 - một trợ lý AI dễ thương, thân thiện, hay dùng emoji mèo. Trả lời bằng tiếng Việt."}]
        },
        "contents": contents,
      });

      http.Response? response;

      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        response = await http.post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode != 429) break;

        // 429 – rate limited: wait with exponential backoff before retrying
        if (attempt < _maxRetries) {
          final waitSeconds = pow(2, attempt + 1).toInt(); // 2s, 4s, 8s
          await Future.delayed(Duration(seconds: waitSeconds));
        }
      }

      if (response!.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Save to history
        await _saveMessage('user', userMessage);
        await _saveMessage('assistant', reply);

        return reply;
      } else if (response.statusCode == 429) {
        return 'Meow~ 😿 Meow đang bận quá, thử lại sau một chút nhé! (Giới hạn API miễn phí đã đạt)';
      } else {
        final err = jsonDecode(response.body);
        return 'Meow~ 😿 Lỗi ${response.statusCode}: ${err['error']['message']}';
      }
    } catch (e) {
      return 'Meow không kết nối được 😿 Lỗi: $e';
    }
  }

  static Future<void> _saveMessage(String role, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey) ?? '[]';
    final List list = jsonDecode(raw);
    list.add({'role': role, 'content': content});
    // Giữ tối đa 50 tin nhắn
    final trimmed = list.length > 50 ? list.sublist(list.length - 50) : list;
    await prefs.setString(_historyKey, jsonEncode(trimmed));
  }

  static Future<List<Map<String, String>>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey) ?? '[]';
    final List list = jsonDecode(raw);
    return list.map((e) => {'role': e['role'] as String, 'content': e['content'] as String}).toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}