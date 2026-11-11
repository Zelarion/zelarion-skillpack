---
name: agentview
description: Use when the user points at a folder of site-visit or meeting media (videos, photos, screen recordings) and wants it actually understood, not just listed. Acts like a person who sits down, watches every video, listens to the audio, reads every screen in the photos, and writes up what was learned. Transcribes speech (Taglish/Filipino/English) via Groq Whisper, extracts frames, reads screenshots, and fills inaudible gaps from surrounding context, always marking what was inferred. Trigger with /agentview or "watch these videos and tell me what they said".
---

# agentview

Turn a folder of raw site-visit media into a written understanding of what happened.

The point is not to produce a transcript file. The point is to answer questions like
"what does their process actually look like" and "what must we build" from
recordings and screenshots, the way a person who was in the room would.

## Usage

```
/agentview <folder>                     # full pass: transcribe + view + write up
/agentview <folder> --audio-only        # skip frame extraction, transcripts only
/agentview <folder> --topic "payroll"   # focus the write-up on one subject
/agentview <folder> --out <path.md>     # where the findings go
```

## Hard rules

1. **Work off the real media.** Never summarise from filenames or guesses. If a
   video was not transcribed or a photo was not opened, say so explicitly.
2. **Keep heavy artifacts off the system drive.** Write extracted audio, frames and
   transcripts into `<source folder>/_agentview/` on the same volume as the source.
   Site-visit media is routinely 5 to 15 GB.
3. **Mark inference.** When audio is unclear, you may fill the gap from context, but
   the write-up must tag it: `[inferred]`, `[unclear]`, or `[not captured]`. Never
   present a guess as something the client said.
4. **Adopt the client's vocabulary.** If a screen says "Item Component", write
   "Item Component", not "BOM". Extract their terms from the screenshots and use those.
5. **Quote with timestamps.** Every factual claim in the write-up cites `file [mm:ss]`
   or a photo filename, so anything can be re-checked.

## Procedure

### 1. Inventory

```bash
D="<folder>"
ls -la "$D"
find "$D" -maxdepth 2 -type f | sed 's/.*\.//' | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn
for f in "$D"/*.mp4; do
  dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$f" | cut -d. -f1)
  printf "  %-26s %3d min %02d sec\n" "$(basename "$f")" $((dur/60)) $((dur%60))
done
```

Report totals before doing the work: how many videos, total minutes, how many photos.

### 2. Extract audio (cheap, small, fast)

```bash
OUT="$D/_agentview"; mkdir -p "$OUT/audio" "$OUT/frames" "$OUT/transcripts"
for f in "$D"/*.mp4; do
  b=$(basename "$f" .mp4)
  [ -f "$OUT/audio/$b.mp3" ] && continue
  ffmpeg -v error -y -i "$f" -vn -ac 1 -ar 16000 -b:a 32k "$OUT/audio/$b.mp3"
done
```

16 kHz mono at 32 kbps is plenty for speech and keeps every file under the API limit
(roughly 1 MB per 4 minutes). Split anything over 24 MB with
`ffmpeg -i in.mp3 -f segment -segment_time 900 -c copy out_%02d.mp3`.

### 3. Transcribe

Groq hosts `whisper-large-v3` and auto-detects language, which matters because site
visits are usually Taglish. The key lives in `~/.config/watch/.env` as `GROQ_API_KEY`.

```bash
K=$(grep GROQ_API_KEY ~/.config/watch/.env | cut -d= -f2- | tr -d '\r\n ')
curl -s -m 1800 -X POST https://api.groq.com/openai/v1/audio/transcriptions \
  -H "Authorization: Bearer $K" \
  -F "file=@$a" -F "model=whisper-large-v3" \
  -F "response_format=verbose_json" \
  -F "prompt=<domain terms so whisper spells them right>" > "$OUT/transcripts/$b.json"
```

**Use curl, not a hand-rolled Python multipart** — a malformed body returns a
confusing `403 Forbidden` that looks like an auth failure but is not.

The `prompt` field is the single biggest accuracy lever. Seed it with the jargon you
expect (module names, local terms, acronyms) so they are not transcribed phonetically.

Render each `verbose_json` to a timestamped `.txt` (`[mm:ss] text`) for citation.

### 4. Look at the screens

Photos of monitors are usually the highest-value evidence in the whole folder: they
show the actual software, its menus, its table names and its field labels.

Read them with the Read tool (it accepts images). Prioritise:
- anything showing an application window, especially the **title bar and menu bar**
- database or table listings
- forms with visible field labels
- printed reports and paper forms
- whiteboards and handwritten notes

For long screen recordings, pull frames instead of watching blind:

```bash
ffmpeg -v error -i "$f" -vf fps=1/15 -q:v 3 "$OUT/frames/${b}_%03d.jpg"   # 1 frame / 15s
```

Then read the frames where the transcript says something visual is happening
("ito yung system", "click ko lang ito"). Use the transcript timestamps to pick frames
rather than opening all of them.

### 5. Cross-check audio against screen

This is where the real understanding comes from. The speaker says what they do; the
screen shows the system they do it in. Reconcile them:
- speaker says "upload ko sa system" and the screen shows Microsoft Access
  → the "system" is an Access database, write that down
- a menu bar item nobody mentioned is still scope, note it
- table names in a database listing tell you the data model for free

### 6. Write it up

Produce one markdown findings file containing:

1. **What was examined** — file counts, total runtime, what was transcribed vs skipped
2. **What the process actually is** — step by step, in the client's own words, cited
3. **The systems and screens observed** — application names, menus, tables, field labels
4. **Pain points they stated out loud** — quote them; these justify features
5. **Decisions this evidence settles** — and what it does not
6. **Open questions** — what the media could not answer
7. **Confidence and gaps** — anything inaudible or inferred, flagged

Keep every claim traceable to `file [mm:ss]` or a photo filename.

## Failure modes

- **403 from Groq** — malformed multipart, not auth. Use curl as shown.
- **`ffprobe` prints 0 duration** — pipe through `cut -d. -f1`; shell arithmetic cannot
  handle the float.
- **Transcript is phonetic nonsense for domain words** — enrich the `prompt` and re-run
  that file only.
- **Nothing but filenames in the write-up** — the pass failed. Go back and open the media.
