// ── Flashcard logic ───────────────────────────────────────────────────────────
import { db } from "./firebase-config.js";
import {
  collection, query, where, getDocs, addDoc, doc,
  updateDoc, increment, serverTimestamp, getDoc, setDoc
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";
import { showToast, showLoading, hideLoading } from "./utils.js";

export const PRESET_TOPICS = [
  { name:"Animals",    nameVi:"Động vật",   emoji:"🐾", color:"#FF6B6B",
    words:["elephant","lion","tiger","dolphin","eagle","rabbit","wolf","giraffe","penguin","crocodile","butterfly","octopus","kangaroo","cheetah","gorilla","flamingo","panda","koala","jaguar","hawk"] },
  { name:"Food",       nameVi:"Đồ ăn",      emoji:"🍎", color:"#FF9F1C",
    words:["apple","banana","mango","strawberry","avocado","broccoli","salmon","noodle","rice","cheese","chocolate","mushroom","pineapple","coconut","almond","blueberry","cucumber","tomato","watermelon","lemon"] },
  { name:"Travel",     nameVi:"Du lịch",    emoji:"✈️", color:"#3A86FF",
    words:["passport","luggage","airport","hotel","tourism","adventure","destination","journey","ticket","reservation","landmark","souvenir","itinerary","explore","culture","museum","beach","mountain","cruise","backpack"] },
  { name:"Technology", nameVi:"Công nghệ",  emoji:"💻", color:"#8338EC",
    words:["algorithm","database","network","software","hardware","cybersecurity","artificial","interface","bandwidth","processor","wireless","browser","download","encryption","firewall","server","protocol","digital","innovation","automation"] },
  { name:"Business",   nameVi:"Kinh doanh", emoji:"💼", color:"#06D6A0",
    words:["investment","revenue","profit","strategy","marketing","entrepreneur","contract","negotiation","dividend","budget","shareholder","merger","bankruptcy","franchise","commodity","inflation","interest","assets","liability","capital"] },
  { name:"Health",     nameVi:"Sức khoẻ",   emoji:"❤️", color:"#FF006E",
    words:["medicine","symptom","diagnosis","therapy","nutrition","exercise","vitamin","antibody","immune","vaccine","surgeon","pharmacy","mental","anxiety","depression","recovery","prevention","hygiene","cardiovascular","metabolism"] },
  { name:"Nature",     nameVi:"Thiên nhiên", emoji:"🌿", color:"#2EC4B6",
    words:["forest","ocean","desert","volcano","glacier","ecosystem","biodiversity","atmosphere","hurricane","earthquake","waterfall","coral","drought","erosion","habitat","fossil","mineral","rainfall","climate","lightning"] },
  { name:"Education",  nameVi:"Giáo dục",   emoji:"🎓", color:"#FFBE0B",
    words:["knowledge","scholarship","curriculum","academic","research","examination","diploma","graduate","lecture","laboratory","thesis","semester","tuition","discipline","textbook","assignment","concept","theory","skill","certificate"] },
];

// Fetch word data from Dictionary API + MyMemory
export async function fetchWordData(word) {
  let phonetic = "", example = "", exampleVi = "", meaning = word;
  try {
    const res  = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${word}`);
    const data = await res.json();
    if (Array.isArray(data) && data[0]) {
      phonetic = data[0].phonetic || "";
      if (!phonetic && data[0].phonetics) {
        phonetic = data[0].phonetics.find(p => p.text)?.text || "";
      }
      const defs = data[0].meanings?.[0]?.definitions || [];
      example = defs[0]?.example || "";
    }
  } catch (_) {}

  try {
    const r = await fetch(`https://api.mymemory.translated.net/get?q=${encodeURIComponent(word)}&langpair=en|vi`);
    const j = await r.json();
    const t = j.responseData?.translatedText || "";
    if (t && !t.toUpperCase().startsWith("MYMEMORY")) meaning = t;
  } catch (_) {}

  if (example) {
    try {
      const r = await fetch(`https://api.mymemory.translated.net/get?q=${encodeURIComponent(example)}&langpair=en|vi`);
      const j = await r.json();
      const t = j.responseData?.translatedText || "";
      if (t && !t.toUpperCase().startsWith("MYMEMORY")) exampleVi = t;
    } catch (_) {}
  }

  return { word, meaning, phonetic, example, exampleVi, imageUrl: "" };
}

// Seed words into Firestore topic
export async function seedWords(topicId, wordList) {
  const ref    = collection(db, "topics", topicId, "words");
  const result = [];
  for (let i = 0; i < wordList.length; i += 3) {
    const batch = wordList.slice(i, i + 3);
    const items = await Promise.all(batch.map(w => fetchWordData(w)));
    for (const item of items) {
      const docRef = await addDoc(ref, { ...item, createdAt: serverTimestamp() });
      result.push({ id: docRef.id, ...item });
    }
  }
  return result;
}

// Mark word as learned
export async function markWordLearned(uid, word, topicId, topicName, topicNameVi, topicEmoji, topicColor) {
  const docId = `${topicId}_${word.id}`;
  await setDoc(doc(db, "users", uid, "learned_words", docId), {
    uid, wordId: word.id, word: word.word, meaning: word.meaning,
    phonetic: word.phonetic || "", example: word.example || "",
    exampleVi: word.exampleVi || "", topicId, topicName, topicNameVi,
    topicEmoji, topicColor, learnedAt: serverTimestamp()
  }, { merge: true });

  // Update study_sessions
  const today   = new Date();
  const dateKey = `${today.getFullYear()}-${String(today.getMonth()+1).padStart(2,"0")}-${String(today.getDate()).padStart(2,"0")}`;
  const sessRef = doc(db, "study_sessions", `${uid}_${dateKey}`);
  const sessSnap = await getDoc(sessRef);
  if (sessSnap.exists()) {
    await updateDoc(sessRef, { wordsLearned: increment(1) });
  } else {
    await setDoc(sessRef, { uid, date: serverTimestamp(), wordsLearned: 1 });
  }

  // Update user stats
  await updateDoc(doc(db, "users", uid), { wordsLearned: increment(1) });
}
