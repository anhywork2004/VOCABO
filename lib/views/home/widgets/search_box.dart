import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── Enum chế độ dịch ────────────────────────────────────────────────────────

enum _LangMode { enToVi, viToEn }

// ─── SearchBox ────────────────────────────────────────────────────────────────

class SearchBox extends StatefulWidget {
  const SearchBox({super.key});

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final TextEditingController _ctrl  = TextEditingController();
  final FocusNode             _focus = FocusNode();

  String    _submittedQuery = '';
  bool      _showResults    = false;
  _LangMode _mode           = _LangMode.enToVi;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _submittedQuery = q;
      _showResults    = true;
    });
    _focus.unfocus();
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _submittedQuery = '';
      _showResults    = false;
    });
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == _LangMode.enToVi
          ? _LangMode.viToEn
          : _LangMode.enToVi;
      _submittedQuery = '';
      _showResults    = false;
      _ctrl.clear();
    });
  }

  String get _hintText => _mode == _LangMode.enToVi
      ? 'Nhập từ tiếng Anh...'
      : 'Nhập từ tiếng Việt...';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Input row ─────────────────────────────────────
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Nút chuyển ngôn ngữ ──────────────────
              GestureDetector(
                onTap: _toggleMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _mode == _LangMode.enToVi ? '🇬🇧' : '🇻🇳',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(Icons.swap_horiz_rounded,
                            size: 14, color: Color(0xFF667eea)),
                      ),
                      Text(
                        _mode == _LangMode.enToVi ? '🇻🇳' : '🇬🇧',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ── TextField ────────────────────────────
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: _hintText,
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: TextStyle(
                      color: cs.onSurface.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // ── Clear / Search ────────────────────────
              if (_showResults)
                GestureDetector(
                  onTap: _clear,
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: Colors.grey),
                )
              else
                GestureDetector(
                  onTap: _submit,
                  child: const Icon(Icons.search_rounded,
                      size: 20, color: Color(0xFF667eea)),
                ),
            ],
          ),
        ),

        // ── Results ───────────────────────────────────────
        if (_showResults && _submittedQuery.isNotEmpty)
          _LookupResult(query: _submittedQuery, mode: _mode),
      ],
    );
  }
}

// ─── Lookup Result ────────────────────────────────────────────────────────────

class _LookupResult extends StatefulWidget {
  final String    query;
  final _LangMode mode;
  const _LookupResult({required this.query, required this.mode});

  @override
  State<_LookupResult> createState() => _LookupResultState();
}

class _LookupResultState extends State<_LookupResult> {
  _ResultData? _data;
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  @override
  void didUpdateWidget(_LookupResult old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query || old.mode != widget.mode) {
      setState(() { _loading = true; _error = null; _data = null; });
      _lookup();
    }
  }

  Future<void> _lookup() async {
    try {
      if (widget.mode == _LangMode.enToVi) {
        await _lookupEnToVi(widget.query.trim().toLowerCase());
      } else {
        await _lookupViToEn(widget.query.trim());
      }
    } catch (_) {
      setState(() {
        _error   = 'Lỗi kết nối. Kiểm tra internet.';
        _loading = false;
      });
    }
  }

  // ── EN → VI: tra từ điển Oxford + dịch nghĩa ──────────

  Future<void> _lookupEnToVi(String word) async {
    final results = await Future.wait([
      _fetchDictionary(word),
      _translate(word, 'en', 'vi'),
    ]);

    final dict        = results[0] as Map<String, dynamic>?;
    final translation = results[1] as String;

    if (dict == null && translation.isEmpty) {
      setState(() {
        _error   = 'Không tìm thấy "$word"';
        _loading = false;
      });
      return;
    }

    setState(() {
      _data    = _ResultData.fromDict(word, dict, translation);
      _loading = false;
    });
  }

  // ── VI → EN: dịch sang tiếng Anh rồi tra từ điển ──────

  Future<void> _lookupViToEn(String text) async {
    // Bước 1: dịch VI → EN
    final enWord = await _translate(text, 'vi', 'en');
    if (enWord.isEmpty) {
      setState(() {
        _error   = 'Không thể dịch "$text"';
        _loading = false;
      });
      return;
    }

    // Lấy từ đầu tiên để tra từ điển
    final lookupWord = enWord.split(' ').first.toLowerCase();

    // Bước 2: tra từ điển Oxford
    final dict = await _fetchDictionary(lookupWord);

    // Bước 3: dịch lại EN → VI để lấy nghĩa chính xác
    final viMeaning = await _translate(lookupWord, 'en', 'vi');

    setState(() {
      _data = _ResultData(
        originalQuery: text,
        englishWord:   lookupWord,
        fullEnResult:  enWord,
        phonetic:      _extractPhonetic(dict),
        meanings:      _extractMeanings(dict),
        synonyms:      _extractSynonyms(dict),
        antonyms:      _extractAntonyms(dict),
        translation:   viMeaning,
        mode:          _LangMode.viToEn,
      );
      _loading = false;
    });
  }

  // ── API helpers ────────────────────────────────────────

  Future<Map<String, dynamic>?> _fetchDictionary(String word) async {
    try {
      final res = await http
          .get(Uri.parse(
              'https://api.dictionaryapi.dev/api/v2/entries/en/$word'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (list.isNotEmpty) return list[0] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<String> _translate(String text, String from, String to) async {
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}&langpair=$from|$to',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final t = json['responseData']?['translatedText'] as String? ?? '';
        if (t.isNotEmpty && !t.toUpperCase().startsWith('MYMEMORY')) {
          return t;
        }
      }
    } catch (_) {}
    return '';
  }

  String _extractPhonetic(Map<String, dynamic>? dict) {
    if (dict == null) return '';
    String p = dict['phonetic'] as String? ?? '';
    if (p.isEmpty) {
      for (final ph in (dict['phonetics'] as List? ?? [])) {
        final t = (ph as Map)['text'] as String? ?? '';
        if (t.isNotEmpty) { p = t; break; }
      }
    }
    return p;
  }

  List<_Meaning> _extractMeanings(Map<String, dynamic>? dict) {
    if (dict == null) return [];
    final list = <_Meaning>[];
    for (final m in (dict['meanings'] as List? ?? [])) {
      final pos  = (m as Map)['partOfSpeech'] as String? ?? '';
      final defs = <_Definition>[];
      for (final d in (m['definitions'] as List? ?? [])) {
        defs.add(_Definition(
          definition: (d as Map)['definition'] as String? ?? '',
          example:    d['example'] as String? ?? '',
        ));
      }
      if (defs.isNotEmpty) list.add(_Meaning(partOfSpeech: pos, definitions: defs));
    }
    return list;
  }

  List<String> _extractSynonyms(Map<String, dynamic>? dict) {
    if (dict == null) return [];
    final set = <String>{};
    for (final m in (dict['meanings'] as List? ?? [])) {
      set.addAll(((m as Map)['synonyms'] as List? ?? []).cast<String>().take(3));
      for (final d in (m['definitions'] as List? ?? [])) {
        set.addAll(((d as Map)['synonyms'] as List? ?? []).cast<String>().take(2));
      }
    }
    return set.take(6).toList();
  }

  List<String> _extractAntonyms(Map<String, dynamic>? dict) {
    if (dict == null) return [];
    final set = <String>{};
    for (final m in (dict['meanings'] as List? ?? [])) {
      set.addAll(((m as Map)['antonyms'] as List? ?? []).cast<String>().take(3));
    }
    return set.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF667eea)),
              ),
            )
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.search_off_rounded,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14)),
                      ),
                    ],
                  ),
                )
              : _data != null
                  ? _ResultCard(data: _data!)
                  : const SizedBox(),
    );
  }
}

// ─── Result Card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _ResultData data;
  const _ResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isViToEn = data.mode == _LangMode.viToEn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header gradient ───────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label nguồn khi VI→EN
              if (isViToEn) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🇻🇳 "${data.originalQuery}"',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Từ tiếng Anh + phiên âm
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isViToEn ? data.englishWord : data.englishWord,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (data.phonetic.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Text(
                      data.phonetic,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),

              // Nghĩa tiếng Việt
              if (data.translation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isViToEn
                        ? '🇻🇳  ${data.translation}'
                        : '🇻🇳  ${data.translation}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Row(
                children: [
                  _SourceBadge(label: 'Oxford Dictionary'),
                  const SizedBox(width: 6),
                  _SourceBadge(label: 'MyMemory'),
                ],
              ),
            ],
          ),
        ),

        // ── Definitions ───────────────────────────────────
        if (data.meanings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.meanings.take(3)
                  .map((m) => _MeaningBlock(meaning: m))
                  .toList(),
            ),
          ),

        // ── Synonyms ──────────────────────────────────────
        if (data.synonyms.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: _TagRow(
              label: 'Synonyms:',
              items: data.synonyms,
              color: Colors.green,
            ),
          ),

        // ── Antonyms ──────────────────────────────────────
        if (data.antonyms.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
            child: _TagRow(
              label: 'Antonyms:',
              items: data.antonyms,
              color: Colors.red,
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Meaning Block ────────────────────────────────────────────────────────────

class _MeaningBlock extends StatelessWidget {
  final _Meaning meaning;
  const _MeaningBlock({required this.meaning});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              meaning.partOfSpeech,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667eea),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...meaning.definitions.take(2).toList().asMap().entries.map((e) {
            final def = e.value;
            final num = e.key + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$num. ',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF667eea))),
                      Expanded(
                        child: Text(def.definition,
                            style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurface,
                                height: 1.4)),
                      ),
                    ],
                  ),
                  if (def.example.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote_rounded,
                              size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(def.example,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Tag Row (Synonyms / Antonyms) ───────────────────────────────────────────

class _TagRow extends StatelessWidget {
  final String       label;
  final List<String> items;
  final Color        color;
  const _TagRow({
    required this.label,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
        ...items.take(6).map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(s,
                  style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500)),
            )),
      ],
    );
  }
}

// ─── Source Badge ─────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final String label;
  const _SourceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────────────────────────

class _Definition {
  final String definition;
  final String example;
  const _Definition({required this.definition, required this.example});
}

class _Meaning {
  final String           partOfSpeech;
  final List<_Definition> definitions;
  const _Meaning({required this.partOfSpeech, required this.definitions});
}

class _ResultData {
  final String       originalQuery; // từ người dùng nhập
  final String       englishWord;   // từ tiếng Anh (sau khi dịch nếu cần)
  final String       fullEnResult;  // kết quả dịch đầy đủ
  final String       phonetic;
  final String       translation;   // nghĩa tiếng Việt
  final List<_Meaning> meanings;
  final List<String>   synonyms;
  final List<String>   antonyms;
  final _LangMode    mode;

  const _ResultData({
    required this.originalQuery,
    required this.englishWord,
    required this.fullEnResult,
    required this.phonetic,
    required this.translation,
    required this.meanings,
    required this.synonyms,
    required this.antonyms,
    required this.mode,
  });

  /// Factory cho chế độ EN→VI
  factory _ResultData.fromDict(
    String word,
    Map<String, dynamic>? dict,
    String translation,
  ) {
    String phonetic = '';
    final meanings  = <_Meaning>[];
    final synonyms  = <String>{};
    final antonyms  = <String>{};

    if (dict != null) {
      phonetic = dict['phonetic'] as String? ?? '';
      if (phonetic.isEmpty) {
        for (final p in (dict['phonetics'] as List? ?? [])) {
          final t = (p as Map)['text'] as String? ?? '';
          if (t.isNotEmpty) { phonetic = t; break; }
        }
      }
      for (final m in (dict['meanings'] as List? ?? [])) {
        final pos  = (m as Map)['partOfSpeech'] as String? ?? '';
        final defs = <_Definition>[];
        for (final d in (m['definitions'] as List? ?? [])) {
          defs.add(_Definition(
            definition: (d as Map)['definition'] as String? ?? '',
            example:    d['example'] as String? ?? '',
          ));
          synonyms.addAll(
              ((d['synonyms'] as List?) ?? []).cast<String>().take(2));
          antonyms.addAll(
              ((d['antonyms'] as List?) ?? []).cast<String>().take(2));
        }
        synonyms.addAll(
            ((m['synonyms'] as List?) ?? []).cast<String>().take(3));
        antonyms.addAll(
            ((m['antonyms'] as List?) ?? []).cast<String>().take(3));
        if (defs.isNotEmpty) {
          meanings.add(_Meaning(partOfSpeech: pos, definitions: defs));
        }
      }
    }

    return _ResultData(
      originalQuery: word,
      englishWord:   word,
      fullEnResult:  word,
      phonetic:      phonetic,
      translation:   translation,
      meanings:      meanings,
      synonyms:      synonyms.take(6).toList(),
      antonyms:      antonyms.take(6).toList(),
      mode:          _LangMode.enToVi,
    );
  }
}
