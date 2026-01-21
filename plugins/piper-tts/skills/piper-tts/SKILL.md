---
name: piper-tts
description: Local neural text-to-speech using Piper
metadata: {"clawdbot":{"always":true,"requires":{"bins":["piper-speak"]}}}
---

Use `piper-speak` to convert text to speech locally using the Piper TTS engine.

## Commands

```bash
# Speak text aloud (plays through speakers)
piper-speak "Hello, how are you today?"

# Save to a WAV file
piper-speak -o output.wav "This will be saved to a file"

# Use a different voice
piper-speak -v en_US-libritts_r-medium "Hello world"

# Use a multi-speaker model with specific speaker
piper-speak -v en_US-libritts_r-medium -s 3922 "Hello world"

# List installed voices
piper-speak --list

# Download a new voice
piper-speak --download en_US-amy-medium
```

## Bundled Voice

The bundled voice `en_US-libritts_r-medium` (American English, multi-speaker) is used automatically. Use `-s` to select a speaker ID.

## Multi-Speaker Models

Some models like `en_US-libritts_r-medium` support multiple speakers. Use `-s <ID>` to select:
```bash
piper-speak -v en_US-libritts_r-medium -s 3922 "This is speaker 3922"
```

## Additional Voices

More voices can be downloaded on first use. Browse all voices at:
https://huggingface.co/rhasspy/piper-voices

Listen to samples at:
https://rhasspy.github.io/piper-samples/

## When to Use

- When the user asks you to speak or say something aloud
- When the user wants audio output of text
- For accessibility purposes
- When creating audio files from text
