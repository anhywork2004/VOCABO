"""
upload_ielts_to_firestore.py
Upload ielts_words.json lên Firestore collection: ielts_questions

Yêu cầu:
  pip install firebase-admin

Cách dùng:
  1. Vào Firebase Console → Project Settings → Service accounts → Generate new private key
  2. Lưu file JSON vào scripts/serviceAccountKey.json
  3. Chạy: python scripts/upload_ielts_to_firestore.py
"""

import json
import sys
from pathlib import Path

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("Installing firebase-admin...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "firebase-admin"])
    import firebase_admin
    from firebase_admin import credentials, firestore

WORDS_FILE      = Path(__file__).parent / "ielts_words.json"
SERVICE_KEY     = Path(__file__).parent / "serviceAccountKey.json"
COLLECTION_NAME = "ielts_questions"
BATCH_SIZE      = 400  # Firestore batch limit = 500


def main():
    if not WORDS_FILE.exists():
        print(f"ERROR: {WORDS_FILE} not found. Run crawl_ielts.py first.")
        return

    if not SERVICE_KEY.exists():
        print(f"ERROR: {SERVICE_KEY} not found.")
        print("Download from Firebase Console → Project Settings → Service accounts")
        return

    # Load words
    with open(WORDS_FILE, encoding="utf-8") as f:
        words = json.load(f)

    # Filter valid entries
    valid = [w for w in words if w.get("word") and w.get("meaning")]
    print(f"Uploading {len(valid)} words to Firestore collection '{COLLECTION_NAME}'...")

    # Init Firebase
    cred = credentials.Certificate(str(SERVICE_KEY))
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    # Upload in batches
    uploaded = 0
    for i in range(0, len(valid), BATCH_SIZE):
        batch = db.batch()
        chunk = valid[i : i + BATCH_SIZE]

        for word_data in chunk:
            doc_ref = db.collection(COLLECTION_NAME).document(word_data["word"])
            batch.set(doc_ref, {
                "word":           word_data["word"],
                "phonetic":       word_data.get("phonetic", ""),
                "meaning":        word_data.get("meaning", ""),
                "definition_en":  word_data.get("definition_en", ""),
                "example":        word_data.get("example", ""),
                "example_vi":     word_data.get("example_vi", ""),
                "part_of_speech": word_data.get("part_of_speech", ""),
                "category":       word_data.get("category", "IELTS"),
            })

        batch.commit()
        uploaded += len(chunk)
        print(f"  Uploaded {uploaded}/{len(valid)}")

    print(f"\nDone! {uploaded} words uploaded to '{COLLECTION_NAME}'")


if __name__ == "__main__":
    main()
