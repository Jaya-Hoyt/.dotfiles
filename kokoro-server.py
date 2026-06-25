import asyncio
import os
import re
import textwrap
import time
from kokoro_onnx import Kokoro
import numpy as np
import sounddevice as sd

base_dir = os.path.expanduser("~/kokoro-tts")
model_path = os.path.join(base_dir, "kokoro-v1.0.onnx")
voices_path = os.path.join(base_dir, "voices-v1.0.bin")

print("🧠 Loading Kokoro model...")
kokoro = Kokoro(model_path, voices_path)

SAMPLE_RATE = 24000
audio_queue = asyncio.Queue()

# Global flag to abort playback instantly
cancel_flag = False

# Persistent stream removed - managed dynamically in playback_worker



async def playback_worker():
  """Reads from the queue and feeds the speaker hardware without blocking."""
  global cancel_flag
  stream = None
  while True:
    try:
      item = await audio_queue.get()
    except asyncio.CancelledError:
      break

    if item is None or cancel_flag:
      if stream is not None:
        await asyncio.to_thread(stream.stop)
        await asyncio.to_thread(stream.close)
        stream = None
      audio_queue.task_done()
      continue

    samples = item
    if not cancel_flag:
      try:
        if stream is None:
          print("🔊 Opening CoreAudio stream...")
          try:
            sd._terminate()
            sd._initialize()
          except Exception as init_err:
            print(f"Warning: Failed to re-initialize sounddevice: {init_err}")
          stream = sd.OutputStream(
              samplerate=SAMPLE_RATE, channels=1, dtype="float32"
          )
          await asyncio.to_thread(stream.start)
        await asyncio.to_thread(stream.write, samples)
      except Exception as e:
        print(f"Error playing audio: {e}")
        if stream is not None:
          try:
            stream.close()
          except:
            pass
          stream = None
    audio_queue.task_done()


async def handle_client(reader, writer):
  global cancel_flag
  data = await reader.read()
  text = data.decode("utf-8", errors="ignore").strip()

  # Ignore HTTP requests (e.g., from browser probes or port scanners)
  # to prevent the TTS from reading out localhost headers.
  if (
      text.startswith((
          "GET ",
          "POST ",
          "OPTIONS ",
          "HEAD ",
          "PUT ",
          "DELETE ",
          "CONNECT ",
          "TRACE ",
      ))
      and "HTTP/" in text
  ):
    writer.close()
    return

  # INTERCEPT THE STOP COMMAND
  if text == "!!!STOP!!!":
    print("\n🛑 [Interrupt] Stop command received. Halting audio...")
    cancel_flag = True
    # Instantly delete everything waiting in the queue
    while not audio_queue.empty():
      audio_queue.get_nowait()
      audio_queue.task_done()
    await audio_queue.put(None)
    writer.close()
    return

  if text:
    cancel_flag = False  # Reset the flag for the new text

    print(f"\n[Client Connected] Received text ({len(text)} characters)")

    # Wake up the audio hardware by sending a brief moment of silence
    # This prevents the OS/Bluetooth device from clipping the first syllable
    wakeup_silence = np.zeros(int(SAMPLE_RATE * 0.25), dtype=np.float32)
    await audio_queue.put(wakeup_silence)

    # Sanitize text: remove backticks, asterisks, and bullet points
    text = text.replace("`", "").replace("*", "").replace("•", "")

    # Remove leading dashes used as list items
    text = re.sub(r"(?m)^[-]\s+", "", text)

    # 1. Handle URLs and CL notations pointing to CLs specifically (case-insensitive):
    def cl_repl(match):
      cl_num = match.group(1)
      short_num = cl_num[-2:] if len(cl_num) >= 2 else cl_num
      return f"cl {short_num}"

    # Match critique URL formats first
    text = re.sub(
        r'\b(?:https?://)?critique\.corp\.google\.com/(?:cl|c)/?(\d+)\b',
        cl_repl,
        text,
    )
    # Match raw cl prefix formats
    text = re.sub(
        r'\b(?:cl|CL)(?:/|:|#|\s)+(\d+)\b',
        cl_repl,
        text,
    )

    # 2. Bug IDs (e.g. b/123456789, bug 123456789)
    def bug_repl(match):
      bug_num = match.group(1)
      short_num = bug_num[-2:] if len(bug_num) >= 2 else bug_num
      return f"bug {short_num}"

    text = re.sub(
        r'\bb/(\d+)\b',
        bug_repl,
        text,
    )
    text = re.sub(
        r'\b(?:bug|BUG)(?:/|:|#|\s)+(\d+)\b',
        bug_repl,
        text,
    )

    # 3. General links cleanup (for URLs that are NOT CLs/Bugs):
    def url_repl(match):
      domain = match.group(1)
      if domain.startswith("www."):
        domain = domain[4:]
      return domain

    text = re.sub(r'https?://([a-zA-Z0-9.-]+)(?:/[^\s]*)?', url_repl, text)
    text = re.sub(r'\bwww\.([a-zA-Z0-9.-]+)(?:/[^\s]*)?', r'\1', text)

    # 4. Clean up hex hashes (e.g. Git commit hashes, UUIDs) and long IDs/numbers.
    def uuid_repl(match):
      uuid_str = match.group(0)
      start_idx = match.start()
      preceding_text = text[max(0, start_idx - 10):start_idx].strip().lower()
      if preceding_text.endswith("uuid") or preceding_text.endswith("id"):
        return uuid_str[:4]
      return f"hash {uuid_str[:4]}"

    text = re.sub(
        r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
        uuid_repl,
        text,
    )

    # Git/hex hashes (length 7 to 40)
    def hash_repl(match):
      hash_str = match.group(0)
      chars = " ".join(list(hash_str[:4]))
      start_idx = match.start()
      preceding_text = text[max(0, start_idx - 10):start_idx].strip().lower()
      if preceding_text.endswith("hash"):
        return chars
      return f"hash {chars}"

    text = re.sub(
        r'\b(?=[0-9a-fA-F]{7,40}\b)(?=[a-zA-Z]*[0-9])(?=[0-9]*[a-zA-Z])[0-9a-fA-F]{7,40}\b',
        hash_repl,
        text,
    )

    # Long pure numbers of length 8 to 15.
    def long_num_repl(match):
      num_str = match.group(0)
      if num_str.endswith("0000"):
        return num_str
      start_idx = match.start()
      preceding_text = text[max(0, start_idx - 10):start_idx].strip().lower()
      if (
          preceding_text.endswith("id")
          or preceding_text.endswith("number")
          or preceding_text.endswith("num")
      ):
        return f"ending in {num_str[-2:]}"
      return f"number ending in {num_str[-2:]}"

    text = re.sub(r'\b\d{8,15}\b', long_num_repl, text)

    # Prevent splitting on filenames/decimals by replacing internal periods with " dot "
    text = re.sub(r"(?<=\S)\.(?=\S)", " dot ", text)

    # 1. Split by paragraph (two or more newlines) to preserve maximum natural flow
    paragraphs = re.split(r"\n{2,}", text)

    safe_chunks = []
    for para in paragraphs:
      para = para.replace("\n", " ").strip()
      para = re.sub(r"\s+", " ", para)
      if not para:
        continue

      # If the paragraph is short enough, keep it whole
      if len(para) <= 250:
        safe_chunks.append(para)
      else:
        # If the paragraph exceeds Kokoro's safe limit, fall back to splitting by sentences
        sentences = re.split(r"(?<=[.!?])\s+", para)
        for sentence in sentences:
          if sentence:
            # As an absolute last resort, if a single sentence is > 250 chars, wrap it
            safe_chunks.extend(
                textwrap.wrap(sentence, width=250, break_long_words=False)
            )

    print(
        f"   [Chunker] Sliced into {len(safe_chunks)} micro-chunks for instant"
        " playback."
    )

    for i, sentence in enumerate(safe_chunks):
      # Abort the math computation if the stop flag was thrown
      if cancel_flag:
        print("   🛑 Generation aborted.")
        break

      # Prepend a comma to give the phonemizer a natural pause token.
      # This forces the ONNX model to generate a brief moment of room tone before
      # speaking the first syllable, preventing the word from being swallowed.
      # We only do this for chunks after the very first one to maintain instant start.
      if i > 0:
        padded_sentence = ", " + sentence.strip()
      else:
        padded_sentence = sentence.strip()

      stream = kokoro.create_stream(
          padded_sentence, voice="af_heart", speed=1.5, lang="en-us"
      )

      async for samples, sample_rate in stream:
        if cancel_flag:
          break
        await audio_queue.put(samples)

    await audio_queue.put(None)

  writer.close()


async def main():
  asyncio.create_task(playback_worker())

  print("🔥 Warming up Neural Engine...")
  dummy_text = (
      "This is a significantly longer warmup sentence designed specifically to"
      " force the neural engine to allocate a large enough tensor graph to"
      " accommodate typical clipboard copy and paste operations."
  )
  dummy_stream = kokoro.create_stream(
      dummy_text, voice="af_heart", speed=1.5, lang="en-us"
  )
  async for samples, _ in dummy_stream:
    pass
  print("   └─ Warmup completed!")

  print(
      "✅ Server is HOT and listening on port 5050! You can now use speak.fish"
      " instantly."
  )
  server = await asyncio.start_server(handle_client, "127.0.0.1", 5050)
  async with server:
    await server.serve_forever()


if __name__ == "__main__":
  os.environ["PYTHONWARNINGS"] = "ignore"
  asyncio.run(main())
