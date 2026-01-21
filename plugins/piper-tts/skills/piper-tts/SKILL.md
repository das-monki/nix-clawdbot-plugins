---
name: piper-tts
description: Local neural text-to-speech using Piper
---

Use `piper-speak` to convert text to speech locally using the Piper TTS engine.

## Commands

```bash
# Speak text aloud (plays through speakers)
piper-speak "Hello, how are you today?"

# Save to a WAV file
piper-speak -o output.wav "This will be saved to a file"

# Use a different voice
piper-speak -v en_GB-alba-medium "Hello from Britain"

# List installed voices
piper-speak --list

# Download a new voice
piper-speak --download en_US-amy-medium
```

## Available Voices

Popular English voices:
- `en_US-lessac-medium` (default) - American English, neutral
- `en_US-amy-medium` - American English, female
- `en_US-ryan-medium` - American English, male
- `en_GB-alba-medium` - British English, female
- `en_GB-aru-medium` - British English, male

Voices are downloaded automatically on first use. Browse all voices at:
https://huggingface.co/rhasspy/piper-voices

## When to Use

- When the user asks you to speak or say something aloud
- When the user wants audio output of text
- For accessibility purposes
- When creating audio files from text
