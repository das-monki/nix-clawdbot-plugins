# nix-clawdbot-plugins

Personal Clawdbot plugins monorepo. A collection of plugins for [nix-clawdbot](https://github.com/clawdbot/nix-clawdbot) using the multi-plugin flake pattern.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| `piper-tts` | Local neural text-to-speech using [Piper](https://github.com/rhasspy/piper) |

## Usage

Add to your flake inputs:

```nix
{
  inputs = {
    nix-clawdbot.url = "github:clawdbot/nix-clawdbot";
    nix-clawdbot-plugins.url = "github:das-monki/nix-clawdbot-plugins";
    nix-clawdbot-plugins.inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Enable a plugin in your clawdbot configuration:

```nix
programs.clawdbot.instances.default = {
  plugins = [
    {
      input = inputs.nix-clawdbot-plugins;
      plugin = "piper-tts";
    }
  ];
};
```

## Plugin: piper-tts

Local neural text-to-speech using Piper. Provides the `piper-speak` CLI.

```bash
# Speak text aloud
piper-speak "Hello, world!"

# Save to file
piper-speak -o output.wav "This will be saved"

# Use a different voice
piper-speak -v en_GB-alba-medium "Hello from Britain"

# List installed voices
piper-speak --list

# Download a new voice
piper-speak --download en_US-amy-medium
```

Voice models are automatically downloaded on first use from [HuggingFace](https://huggingface.co/rhasspy/piper-voices).

## Adding New Plugins

See [CLAUDE.md](./CLAUDE.md) for development guidelines.
