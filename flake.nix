{
  description = "Personal Clawdbot plugins monorepo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # Helper to create piper-speak for a given system
      mkPiperSpeak = system:
        let
          pkgs = import nixpkgs { inherit system; };
        in pkgs.writeShellScriptBin "piper-speak" ''
          set -euo pipefail

          VOICES_DIR="''${PIPER_VOICES_DIR:-$HOME/.local/share/piper-voices}"
          DEFAULT_VOICE="''${PIPER_DEFAULT_VOICE:-en_US-lessac-medium}"

          usage() {
            echo "Usage: piper-speak [OPTIONS] <text>"
            echo ""
            echo "Options:"
            echo "  -v, --voice NAME    Voice model name (default: $DEFAULT_VOICE)"
            echo "  -o, --output FILE   Output to WAV file instead of playing"
            echo "  -l, --list          List installed voices"
            echo "  --download NAME     Download a voice model"
            echo "  -h, --help          Show this help"
            echo ""
            echo "Examples:"
            echo "  piper-speak 'Hello world'"
            echo "  piper-speak -v en_GB-alba-medium 'Hello from Britain'"
            echo "  piper-speak -o greeting.wav 'This will be saved'"
            echo "  piper-speak --download en_US-amy-medium"
          }

          list_voices() {
            if [ -d "$VOICES_DIR" ]; then
              echo "Installed voices in $VOICES_DIR:"
              find "$VOICES_DIR" -name "*.onnx" -exec basename {} .onnx \; 2>/dev/null | sort
            else
              echo "No voices directory found at $VOICES_DIR"
              echo "Download a voice with: piper-speak --download <voice-name>"
            fi
          }

          download_voice() {
            local voice="$1"
            mkdir -p "$VOICES_DIR"
            local lang_prefix="''${voice%%-*}"
            local base_url="https://huggingface.co/rhasspy/piper-voices/resolve/main"

            echo "Downloading voice: $voice"
            ${pkgs.curl}/bin/curl -L -# \
              "$base_url/$lang_prefix/$voice/$voice.onnx" \
              -o "$VOICES_DIR/$voice.onnx"
            ${pkgs.curl}/bin/curl -L -# \
              "$base_url/$lang_prefix/$voice/$voice.onnx.json" \
              -o "$VOICES_DIR/$voice.onnx.json"
            echo "Downloaded: $voice"
          }

          VOICE="$DEFAULT_VOICE"
          OUTPUT=""
          TEXT=""

          while [[ $# -gt 0 ]]; do
            case "$1" in
              -v|--voice) VOICE="$2"; shift 2 ;;
              -o|--output) OUTPUT="$2"; shift 2 ;;
              -l|--list) list_voices; exit 0 ;;
              --download) download_voice "$2"; exit 0 ;;
              -h|--help) usage; exit 0 ;;
              *) TEXT="$1"; shift ;;
            esac
          done

          if [ -z "$TEXT" ]; then
            usage
            exit 1
          fi

          MODEL_PATH="$VOICES_DIR/$VOICE.onnx"
          if [ ! -f "$MODEL_PATH" ]; then
            echo "Voice '$VOICE' not found. Downloading..."
            download_voice "$VOICE"
          fi

          if [ -n "$OUTPUT" ]; then
            echo "$TEXT" | ${pkgs.piper-tts}/bin/piper --model "$MODEL_PATH" --output_file "$OUTPUT"
            echo "Saved to: $OUTPUT"
          else
            echo "$TEXT" | ${pkgs.piper-tts}/bin/piper --model "$MODEL_PATH" --output-raw | \
              ${pkgs.ffmpeg}/bin/ffplay -nodisp -autoexit -f s16le -ar 22050 -ac 1 -i - 2>/dev/null
          fi
        '';

    in
    # Per-system outputs (packages, devShells)
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        piper-speak = mkPiperSpeak system;
      in {
        packages = {
          piper-speak = piper-speak;
          default = piper-speak;
        };

        devShells.default = pkgs.mkShell {
          packages = [ piper-speak pkgs.piper-tts ];
        };
      }
    )
    //
    # Top-level clawdbotPlugins (not per-system)
    {
      clawdbotPlugins = {
        piper-tts = {
          name = "piper-tts";
          skills = [ ./plugins/piper-tts/skills/piper-tts ];
          # packages will be resolved per-system by the clawdbot module
          packages = [];
          needs = {
            stateDirs = [ ".local/share/piper-voices" ];
            requiredEnv = [];
          };
        };
      };
    };
}
