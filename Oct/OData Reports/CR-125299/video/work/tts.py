import os, sys, wave, time, json
from google import genai
from google.genai import types
d = sys.argv[1]
style = "اقرا الكلام ده بصوت راجل مصري، باللهجة المصرية القاهرية البسيطة، بهدوء ووضوح كأنك بتشرح لزميلك. خلي مخارج الحروف واضحة وفرّق بين الحروف المتشابهة. انطق الكلمات الإنجليزي بالإنجليزي الصح"
only = set(int(x) for x in sys.argv[2:]) if len(sys.argv) > 2 else None
client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
lines = [l.strip() for l in open(os.path.join(d, "lines.txt"), encoding="utf-8") if l.strip()]
for i, line in enumerate(lines, 1):
    if only and i not in only: continue
    out = os.path.join(d, "voice", f"{i:02d}.wav")
    for attempt in range(2):
        try:
            r = client.models.generate_content(
                model="gemini-2.5-flash-preview-tts",
                contents=f"{style}:\n{line}",
                config=types.GenerateContentConfig(
                    response_modalities=["AUDIO"],
                    speech_config=types.SpeechConfig(voice_config=types.VoiceConfig(
                        prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name="Iapetus")))))
            pcm = r.candidates[0].content.parts[0].inline_data.data
            with wave.open(out, "wb") as w:
                w.setnchannels(1); w.setsampwidth(2); w.setframerate(24000); w.writeframes(pcm)
            print(json.dumps({"line": i, "sec": round(len(pcm)/48000, 2), "chars": len(line)}), flush=True)
            time.sleep(65)
            break
        except Exception as e:
            print(json.dumps({"line": i, "error": str(e)[:300]}), flush=True)
            if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e): sys.exit(2)
            time.sleep(5)
print(json.dumps({"voice": "gemini-Iapetus"}))
