# Claude Development Guide

This is a personal Clawdbot plugins monorepo using the multi-plugin flake pattern.

## Repository Structure

```
nix-clawdbot-plugins/
├── flake.nix                 # Single flake exposing all plugins
├── plugins/
│   └── <plugin-name>/
│       └── skills/
│           └── <plugin-name>/
│               └── SKILL.md  # Agent instructions for using the plugin
```

## Architecture

This repo uses a single `flake.nix` that exposes:
- `packages.<system>.<name>` - Per-system packages for each plugin
- `clawdbotPlugins.<name>` - Top-level plugin definitions (not per-system)
- `devShells.<system>.default` - Development shell with all tools

The `clawdbotPlugins` output is consumed by nix-clawdbot's module system to:
1. Install packages to the gateway's PATH
2. Copy skills to the workspace
3. Create required state directories

## Adding a New Plugin

1. Create the plugin directory structure:
   ```
   plugins/<name>/skills/<name>/SKILL.md
   ```

2. Add the plugin definition to `flake.nix`:
   ```nix
   clawdbotPlugins.<name> = {
     name = "<name>";
     skills = [ ./plugins/<name>/skills/<name> ];
     packages = [];  # Uses flake.packages.<system> automatically
     needs = {
       stateDirs = [];      # Directories to create under $HOME
       requiredEnv = [];    # Required environment variables
     };
   };
   ```

3. If the plugin needs a CLI tool, add it to the `packages` output:
   ```nix
   packages = forAllSystems (system: {
     <name> = <derivation>;
     default = self.packages.${system}.<name>;
   });
   ```

## SKILL.md Format

Skills teach the agent how to use the plugin:

```markdown
---
name: <plugin-name>
description: Short description
---

Instructions for the agent on when and how to use this plugin.

## Commands

\`\`\`bash
example-command --help
\`\`\`

## When to Use

- Bullet points describing use cases
```

## Development Workflow

```bash
# Enter dev shell
nix develop

# Test a package builds
nix build .#piper-speak

# Test the full flake
nix flake check
```

## Testing with nix-clawdbot

Use a local path during development:

```nix
# In your test flake
inputs.nix-clawdbot-plugins.url = "path:/path/to/nix-clawdbot-plugins";
```

## Conventions

- Plugin names should be lowercase with hyphens
- Each plugin gets its own directory under `plugins/`
- Skills directory name must match plugin name
- Wrapper scripts should have clear `--help` output
- Prefer downloading resources at runtime over bundling large files

## Adding Piper Voice Models

Voice models are bundled at build time using `voiceRegistry` in `flake.nix`. To add a new voice:

1. Browse available voices at https://huggingface.co/rhasspy/piper-voices
2. Listen to samples at https://rhasspy.github.io/piper-samples/
3. Find the voice path (e.g., `en/en_US/amy/medium/`)
4. Get the SRI hashes for the `.onnx` and `.onnx.json` files:

```bash
# Get hash for the onnx model
nix hash convert --to sri --hash-algo sha256 $(nix-prefetch-url --type sha256 \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx")

# Get hash for the json config
nix hash convert --to sri --hash-algo sha256 $(nix-prefetch-url --type sha256 \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx.json")
```

5. Add the voice to `voiceRegistry` in `flake.nix`:

```nix
voiceRegistry = {
  # ... existing voices ...
  "en_US-amy-medium" = {
    onnx = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx";
      hash = "sha256:...";  # from step 4
    };
    json = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx.json";
      hash = "sha256:...";  # from step 4
    };
    # For multi-speaker models, add:
    # defaultSpeaker = "1234";
  };
};
```

6. Add the voice to the bundled list in `piper-speak-with-voices`:

```nix
piper-speak-with-voices = mkPiperSpeak {
  inherit system;
  voices = [ "en_US-libritts_r-medium" "en_US-amy-medium" ];
};
```

7. Update `plugins/piper-tts/skills/piper-tts/SKILL.md` with the new voice
