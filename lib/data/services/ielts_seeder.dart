import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Danh sách 200 từ IELTS Academic Word List (AWL) phổ biến nhất
const _kIeltsWords = [
  // Group 1 — Most frequent
  "analyse","approach","area","assess","assume","authority","available",
  "benefit","concept","consist","context","contract","create","data",
  "define","derive","distribute","economy","environment","establish",
  "estimate","evidence","export","factor","finance","formula","function",
  "identify","income","indicate","individual","interpret","involve",
  "issue","labour","legal","legislate","major","method","occur",
  "percent","period","policy","principle","proceed","process","require",
  "research","respond","role","section","sector","significant","similar",
  "source","specific","structure","theory","vary",
  // Group 2
  "achieve","acquire","administrate","affect","appropriate","aspect",
  "assist","category","chapter","commission","community","complex",
  "compute","conclude","conduct","consequent","construct","consume",
  "credit","culture","design","distinct","element","equate","evaluate",
  "feature","final","focus","impact","injure","institute","invest",
  "item","journal","maintain","normal","obtain","participate","perceive",
  "positive","potential","previous","primary","purchase","range","region",
  "regulate","relevant","reside","resource","restrict","secure","seek",
  "select","site","strategy","survey","text","tradition","transfer",
  // Group 3
  "alternative","circumstance","comment","compensate","component",
  "consent","considerable","constant","constrain","contribute","convene",
  "coordinate","core","corporate","correspond","criteria","deduce",
  "demonstrate","document","dominate","emphasis","ensure","exclude",
  "framework","fund","illustrate","immigrate","imply","initial","instance",
  "interact","justify","layer","link","locate","maximize","minor",
  "negate","outcome","partner","philosophy","physical","proportion",
  "publish","react","register","rely","remove","scheme","sequence",
  "shift","specify","sufficient","task","technical","technique","valid",
  // Group 4
  "access","adequate","annual","apparent","approximate","attitude",
  "attribute","civil","code","commit","communicate","concentrate",
  "confer","contrast","cycle","debate","despite","dimension","domestic",
  "emerge","error","ethnic","goal","grant","hence","hypothesis",
  "implement","implicate","impose","integrate","internal","investigate",
  "job","label","mechanism","obvious","occupy","option","output",
  "overall","parallel","parameter","phase","predict","principal",
  "prior","professional","project","promote","proportion","pursue",
  "statistic","status","stress","subsequent","sum","summary","undertake",
  // Group 5
  "academic","adjust","alter","amend","aware","capacity","challenge",
  "clause","compound","conflict","consult","contact","decline","discrete",
  "draft","enable","energy","enforce","entity","equivalent","evolve",
  "expand","expose","external","facilitate","fundamental","generate",
  "image","liberal","licence","logic","marginal","medical","mental",
  "modify","monitor","network","notion","objective","orient","perspective",
  "precise","prime","psychology","pursue","ratio","reject","revenue",
  "stable","style","substitute","sustain","symbol","target","transition",
  "trend","ultimate","visible","voluntary",
];

class IeltsSeeder {
  static final _db = FirebaseFirestore.instance;

  /// Gọi hàm này 1 lần để seed dữ liệu IELTS vào Firestore
  static Future<void> seed({
    void Function(String)? onProgress,
  }) async {
    // Kiểm tra đã có dữ liệu chưa
    final existing = await _db
        .collection('ielts_questions')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      onProgress?.call('✅ Dữ liệu IELTS đã tồn tại (${existing.docs.length}+ docs)');
      return;
    }

    onProgress?.call('🚀 Bắt đầu seed ${_kIeltsWords.length} từ IELTS...');

    int success = 0;
    int failed  = 0;

    // Xử lý theo batch 5 từ để tránh rate limit API
    for (int i = 0; i < _kIeltsWords.length; i += 5) {
      final batch = _kIeltsWords.sublist(
          i, (i + 5).clamp(0, _kIeltsWords.length));

      await Future.wait(batch.map((word) async {
        try {
          final data = await _fetchWordData(word);
          if (data != null) {
            await _db.collection('ielts_questions').add(data);
            success++;
            onProgress?.call('✅ $word ($success/${_kIeltsWords.length})');
          } else {
            // Lưu từ tối thiểu nếu API không trả về
            await _db.collection('ielts_questions').add({
              'word':      word,
              'meaning':   word,
              'phonetic':  '',
              'example':   '',
              'source':    'ielts_awl',
              'createdAt': FieldValue.serverTimestamp(),
            });
            success++;
          }
        } catch (e) {
          failed++;
          onProgress?.call('❌ $word: $e');
        }
      }));

      // Delay nhỏ giữa các batch để tránh rate limit
      await Future.delayed(const Duration(milliseconds: 500));
    }

    onProgress?.call(
        '🎉 Hoàn thành! $success thành công, $failed thất bại');
  }

  static Future<Map<String, dynamic>?> _fetchWordData(String word) async {
    try {
      // 1. Dictionary API — lấy phonetic + example + definition
      final dictRes = await http
          .get(Uri.parse(
              'https://api.dictionaryapi.dev/api/v2/entries/en/$word'))
          .timeout(const Duration(seconds: 8));

      String phonetic  = '';
      String example   = '';
      String defEn     = '';

      if (dictRes.statusCode == 200) {
        final list = jsonDecode(dictRes.body) as List;
        if (list.isNotEmpty) {
          final entry = list[0] as Map<String, dynamic>;

          // Phonetic
          phonetic = entry['phonetic'] as String? ?? '';
          if (phonetic.isEmpty) {
            for (final p in (entry['phonetics'] as List? ?? [])) {
              final t = (p as Map)['text'] as String? ?? '';
              if (t.isNotEmpty) { phonetic = t; break; }
            }
          }

          // Definition + Example
          for (final m in (entry['meanings'] as List? ?? [])) {
            for (final d in ((m as Map)['definitions'] as List? ?? [])) {
              defEn   = (d as Map)['definition'] as String? ?? '';
              example = d['example'] as String? ?? '';
              if (defEn.isNotEmpty) break;
            }
            if (defEn.isNotEmpty) break;
          }
        }
      }

      // 2. MyMemory — dịch sang tiếng Việt
      String meaningVi = '';
      if (defEn.isNotEmpty) {
        meaningVi = await _translate(word);
      } else {
        meaningVi = await _translate(word);
      }

      return {
        'word':      word,
        'meaning':   meaningVi.isNotEmpty ? meaningVi : defEn.isNotEmpty ? defEn : word,
        'phonetic':  phonetic,
        'example':   example,
        'source':    'ielts_awl',
        'createdAt': FieldValue.serverTimestamp(),
      };
    } catch (_) {
      return null;
    }
  }

  static Future<String> _translate(String text) async {
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}&langpair=en|vi',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['responseData']?['translatedText'] as String? ?? '';
      }
    } catch (_) {}
    return '';
  }
}
