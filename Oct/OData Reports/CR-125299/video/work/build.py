import json, os, subprocess, sys, wave

D = sys.argv[1]
mode = sys.argv[2] if len(sys.argv) > 2 else "captions"  # captions | voice
out = sys.argv[3] if len(sys.argv) > 3 else os.path.join(D, f"demo_125299_{mode}.mp4")
m = json.load(open(os.path.join(D, "marks.json")))
caps = [l.strip() for l in open(os.path.join(D, "captions.txt"), encoding="utf-8") if l.strip()]
os.makedirs(os.path.join(D, "seg"), exist_ok=True)


def run(args):
    subprocess.run(args, check=True)


def wav_len(p):
    with wave.open(p) as w:
        return w.getnframes() / w.getframerate()


timeline, t = [], 0.0
parts = []
for i in range(1, len(caps) + 1):
    s = m["segs"][str(i)]
    clip = s["end"] - s["start"]
    voice = os.path.join(D, "voice", f"{i:02d}.wav")
    if mode == "voice":
        need = wav_len(voice) + 0.6
    else:
        need = max(4.0, len(caps[i - 1]) / 14 + 1.5)
    dur = max(clip, need)
    seg = os.path.join(D, "seg", f"{mode}_{i:02d}.mp4")
    vf = f"trim={s['start']}:{s['end']},setpts=PTS-STARTPTS,fps=30,scale=1366:768,tpad=stop_mode=clone:stop_duration={dur - clip + 0.05:.2f}"
    if mode == "voice":
        run(["ffmpeg", "-v", "error", "-y", "-i", m["video"], "-i", voice, "-filter_complex",
             f"[0:v]{vf}[v];[1:a]aresample=48000,apad[a]", "-map", "[v]", "-map", "[a]", "-t", f"{dur:.2f}",
             "-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "128k", seg])
    else:
        run(["ffmpeg", "-v", "error", "-y", "-i", m["video"], "-f", "lavfi", "-i", "anullsrc=r=48000:cl=mono",
             "-filter_complex", f"[0:v]{vf}[v]", "-map", "[v]", "-map", "1:a", "-t", f"{dur:.2f}",
             "-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "64k", seg])
    timeline.append((t, t + dur, caps[i - 1]))
    parts.append(seg)
    t += dur

lst = os.path.join(D, "seg", f"{mode}_list.txt")
with open(lst, "w", encoding="utf-8") as f:
    for p in parts:
        f.write(f"file '{p}'\n")


def ts(x):
    h, r = divmod(x, 3600); mi, se = divmod(r, 60)
    return f"{int(h)}:{int(mi):02d}:{se:05.2f}"


ass = os.path.join(D, "seg", "captions.ass")
with open(ass, "w", encoding="utf-8-sig") as f:
    f.write("[Script Info]\nScriptType: v4.00+\nPlayResX: 1366\nPlayResY: 768\n\n[V4+ Styles]\n"
            "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\n"
            "Style: Cap,Tahoma,34,&H00FFFFFF,&H00FFFFFF,&H00000000,&HB4302010,1,0,0,0,100,100,0,0,3,14,0,2,60,60,28,-1\n\n"
            "[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n")
    for a, b, c in timeline:
        f.write(f"Dialogue: 0,{ts(a)},{ts(b - 0.05)},Cap,,0,0,0,,\u200f{c}\u200f\n")

ass_arg = ass.replace("\\", "/").replace(":", "\\:")
run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", lst, "-vf", f"subtitles='{ass_arg}'",
     "-c:v", "libx264", "-preset", "medium", "-crf", "21", "-pix_fmt", "yuv420p", "-c:a", "copy", "-movflags", "+faststart", out])
print(json.dumps({"out": out, "total": round(t, 2), "segments": [[round(a, 2), round(b, 2)] for a, b, _ in timeline]}))
