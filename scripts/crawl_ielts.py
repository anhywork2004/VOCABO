"""
crawl_ielts.py
Crawl IELTS vocabulary từ các nguồn public:
  1. Free Dictionary API (dictionaryapi.dev) — phonetic + definition + example
  2. MyMemory API — dịch nghĩa sang tiếng Việt
  3. Danh sách từ IELTS Academic Word List (AWL) + IELTS common vocab

Output: scripts/ielts_words.json
"""

import json
import time
import random
import requests
from pathlib import Path

# ── IELTS word list (Academic Word List + common IELTS vocab) ─────────────────
IELTS_WORDS = [
    # Academic Word List - Sublist 1 (most frequent)
    "analyse","approach","area","assess","assume","authority","available",
    "benefit","concept","consist","context","contract","create","data",
    "define","derive","distribute","economy","environment","establish",
    "estimate","evidence","export","factor","finance","formula","function",
    "identify","income","indicate","individual","interpret","involve","issue",
    "labour","legal","legislate","major","method","occur","percent","period",
    "policy","principle","proceed","process","require","research","respond",
    "role","section","sector","significant","similar","source","specific",
    "structure","theory","vary",
    # Sublist 2
    "achieve","acquire","administrate","affect","appropriate","aspect",
    "assist","category","chapter","commission","community","complex",
    "compute","conclude","conduct","consequent","construct","consume",
    "credit","culture","design","distinct","element","equate","evaluate",
    "feature","final","focus","impact","injure","institute","invest",
    "item","journal","maintain","normal","obtain","participate","perceive",
    "positive","potential","previous","primary","purchase","range","region",
    "regulate","relevant","reside","resource","restrict","secure","seek",
    "select","site","strategy","survey","text","tradition","transfer",
    # Common IELTS vocabulary
    "abandon","abstract","accumulate","accurate","acknowledge","adapt",
    "adequate","adjacent","advocate","aggregate","allocate","alter",
    "ambiguous","anticipate","apparent","arbitrary","articulate","attribute",
    "bias","capacity","challenge","circumstance","clarify","collaborate",
    "compensate","complement","comprehensive","concentrate","confirm",
    "conflict","consequence","considerable","constitute","controversy",
    "conventional","coordinate","correspond","criteria","crucial","debate",
    "decline","deduce","demonstrate","depict","derive","detect","determine",
    "deviate","dimension","diminish","discriminate","display","diverse",
    "dominate","dynamic","eliminate","emerge","emphasise","enable","enhance",
    "enormous","ensure","equivalent","evolve","exceed","exclude","exhibit",
    "expand","explicit","exploit","expose","extensive","facilitate","flexible",
    "fluctuate","generate","global","guarantee","hypothesis","illustrate",
    "implement","imply","impose","incentive","incorporate","inevitable",
    "infrastructure","inherent","initiate","innovate","integrate","interact",
    "justify","maintain","manipulate","maximize","minimize","modify",
    "monitor","motivate","mutual","negate","objective","obtain","obvious",
    "offset","ongoing","overlap","participate","perceive","persist",
    "phenomenon","predict","predominant","preliminary","promote","proportion",
    "prospect","pursue","rational","reinforce","reject","rely","resolve",
    "retain","reveal","revise","simulate","specify","stabilize","substitute",
    "sufficient","summarize","supplement","sustain","terminate","transform",
    "transmit","undermine","utilize","validate","verify","widespread",
    # IELTS Reading/Writing common words
    "abstract","accumulate","accurate","acknowledge","adapt","adequate",
    "adjacent","advocate","aggregate","allocate","alter","ambiguous",
    "anticipate","apparent","arbitrary","articulate","attribute",
]

# Loại bỏ trùng lặp
IELTS_WORDS = list(dict.fromkeys(IELTS_WORDS))

OUTPUT_FILE = Path(__file__).parent / "ielts_words.json"


def fetch_dictionary(word: str) -> dict:
    """Lấy phonetic + definition + example từ dictionaryapi.dev"""
    try:
        r = requests.get(
            f"https://api.dictionaryapi.dev/api/v2/entries/en/{word}",
            timeout=8,
        )
        if r.status_code != 200:
            return {}
        data = r.json()
        if not data:
            return {}

        entry = data[0]

        # Phonetic
        phonetic = entry.get("phonetic", "")
        if not phonetic:
            for p in entry.get("phonetics", []):
                if p.get("text"):
                    phonetic = p["text"]
                    break

        # Definition + example + part of speech
        definition = ""
        example = ""
        part_of_speech = ""
        for meaning in entry.get("meanings", []):
            part_of_speech = meaning.get("partOfSpeech", "")
            for d in meaning.get("definitions", []):
                definition = d.get("definition", "")
                example = d.get("example", "")
                if definition:
                    break
            if definition:
                break

        return {
            "phonetic": phonetic,
            "definition_en": definition,
            "example": example,
            "part_of_speech": part_of_speech,
        }
    except Exception:
        return {}


def translate_vi(text: str) -> str:
    """Dịch sang tiếng Việt qua MyMemory API (free, no key)"""
    if not text:
        return ""
    try:
        r = requests.get(
            "https://api.mymemory.translated.net/get",
            params={"q": text[:400], "langpair": "en|vi"},
            timeout=8,
        )
        if r.status_code == 200:
            return r.json().get("responseData", {}).get("translatedText", "")
    except Exception:
        pass
    return ""


def crawl_all(words: list[str]) -> list[dict]:
    results = []
    total = len(words)

    for i, word in enumerate(words):
        print(f"[{i+1}/{total}] {word} ...", end=" ", flush=True)

        # 1. Dictionary API
        info = fetch_dictionary(word)
        time.sleep(0.3)  # rate limit

        # 2. Dịch nghĩa
        meaning_vi = translate_vi(word)
        time.sleep(0.3)

        example_vi = ""
        if info.get("example"):
            example_vi = translate_vi(info["example"])
            time.sleep(0.3)

        entry = {
            "word": word,
            "phonetic": info.get("phonetic", ""),
            "meaning": meaning_vi or word,
            "definition_en": info.get("definition_en", ""),
            "example": info.get("example", ""),
            "example_vi": example_vi,
            "part_of_speech": info.get("part_of_speech", ""),
            "category": "IELTS",
        }
        results.append(entry)
        print(f"✓ {meaning_vi[:20] if meaning_vi else '(no translation)'}")

        # Lưu tạm sau mỗi 20 từ
        if (i + 1) % 20 == 0:
            _save(results)
            print(f"  → Saved {len(results)} words so far")

    return results


def _save(data: list[dict]):
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def main():
    # Nếu đã có file, load và tiếp tục từ chỗ còn thiếu
    existing = []
    existing_words = set()
    if OUTPUT_FILE.exists():
        with open(OUTPUT_FILE, encoding="utf-8") as f:
            existing = json.load(f)
        existing_words = {e["word"] for e in existing}
        print(f"Loaded {len(existing)} existing words, continuing...")

    remaining = [w for w in IELTS_WORDS if w not in existing_words]
    print(f"Words to crawl: {len(remaining)}")

    if not remaining:
        print("All words already crawled!")
        return

    new_results = crawl_all(remaining)
    all_results = existing + new_results
    _save(all_results)
    print(f"\nDone! Total: {len(all_results)} words saved to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
