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

print("🔊 Opening persistent CoreAudio stream...")
audio_stream = sd.OutputStream(
    samplerate=SAMPLE_RATE, channels=1, dtype="float32"
)
audio_stream.start()


async def playback_worker():
  """Reads from the queue and feeds the speaker hardware without blocking."""
  global cancel_flag
  while True:
    samples = await audio_queue.get()
    # Only play the audio if we haven't hit the abort switch
    if not cancel_flag:
      await asyncio.to_thread(audio_stream.write, samples)
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

    # Remove http:// and https://
    text = text.replace("http://", "").replace("https://", "")

    # Remove leading dashes used as list items
    text = re.sub(r"(?m)^[-]\s+", "", text)
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
