{
  description = "Personal Clawdbot plugins monorepo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ellie-cli = {
      url = "github:das-monki/ellie-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    clank = {
      url = "github:das-monki/clank";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ellie-cli,
      clank,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems f;

      # Voice model registry with pre-computed hashes
      voiceRegistry = {
        # "en_US-lessac-medium" = {
        #   onnx = {
        #     url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx";
        #     hash = "sha256:17q1mzm6xd5i2rxx2xwqkxvfx796kmp1lvk4mwkph602k7k0kzjy";
        #   };
        #   json = {
        #     url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json";
        #     hash = "sha256:184hnvd8389xpdm0x2w6phss23v5pb34i0lhd4nmy1gdgd0rrqgg";
        #   };
        # };
        "en_US-libritts_r-medium" = {
          onnx = {
            url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/libritts_r/medium/en_US-libritts_r-medium.onnx";
            hash = "sha256:159iq7x4idczq4p5ap9wmf918jfhk4brydhz0zsgq5nnf7h8bfqh";
          };
          json = {
            url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/libritts_r/medium/en_US-libritts_r-medium.onnx.json";
            hash = "sha256:1cxgr5dm0y4q4rxjal80yhbjhydzdxnijg9rkj0mwcyqs9hdqwdl";
          };
          # Multi-speaker model - default to speaker 3922
          defaultSpeaker = "3922";
        };
      };

      # Create a derivation containing bundled voice models
      mkPiperVoices =
        { pkgs, voices }:
        if voices == [ ] then
          null
        else
          pkgs.runCommand "piper-voices-1.0.0" { } ''
            mkdir -p $out
            ${builtins.concatStringsSep "\n" (
              map (
                voice:
                let
                  v = voiceRegistry.${voice};
                in
                ''
                  cp ${
                    pkgs.fetchurl {
                      url = v.onnx.url;
                      hash = v.onnx.hash;
                    }
                  } $out/${voice}.onnx
                  cp ${
                    pkgs.fetchurl {
                      url = v.json.url;
                      hash = v.json.hash;
                    }
                  } $out/${voice}.onnx.json
                ''
              ) voices
            )}
          '';

      # Create speak wrapper with optional bundled voices
      mkPiperSpeak =
        {
          system,
          voices ? [ ],
        }:
        let
          pkgs = import nixpkgs { inherit system; };
          bundledVoices = mkPiperVoices { inherit pkgs voices; };
          bundledDir = if bundledVoices != null then "${bundledVoices}" else "";
        in
        pkgs.writeShellScriptBin "speak" ''
          set -euo pipefail

          BUNDLED_DIR="${bundledDir}"
          VOICES_DIR="''${PIPER_VOICES_DIR:-$HOME/.local/share/piper-voices}"

          usage() {
            echo "Usage: speak [OPTIONS] <text>"
            echo ""
            echo "Options:"
            echo "  -v, --voice NAME    Voice model name (auto-detected if only one installed)"
            echo "  -s, --speaker ID    Speaker ID for multi-speaker models"
            echo "  -o, --output FILE   Output to WAV file instead of playing"
            echo "  -l, --list          List installed voices"
            echo "  --download NAME     Download a voice model"
            echo "  -h, --help          Show this help"
            ${
              if bundledDir != "" then
                ''
                  echo ""
                  echo "Bundled voices: ${builtins.concatStringsSep ", " voices}"
                ''
              else
                ""
            }
          }

          # Get all installed voices (bundled + downloaded)
          get_installed_voices() {
            local voices=()
            ${
              if bundledDir != "" then
                ''
                  while IFS= read -r v; do
                    [ -n "$v" ] && voices+=("$v")
                  done < <(find "$BUNDLED_DIR" -name "*.onnx" -exec basename {} .onnx \; 2>/dev/null | sort)
                ''
              else
                ""
            }
            if [ -d "$VOICES_DIR" ]; then
              while IFS= read -r v; do
                [ -n "$v" ] && voices+=("$v")
              done < <(find "$VOICES_DIR" -name "*.onnx" -exec basename {} .onnx \; 2>/dev/null | sort)
            fi
            printf '%s\n' "''${voices[@]}" | sort -u
          }

          list_voices() {
            echo "Installed voices:"
            ${
              if bundledDir != "" then
                ''
                  echo "  Bundled:"
                  find "$BUNDLED_DIR" -name "*.onnx" -exec basename {} .onnx \; 2>/dev/null | sed 's/^/    /' | sort
                ''
              else
                ""
            }
            if [ -d "$VOICES_DIR" ]; then
              echo "  Downloaded ($VOICES_DIR):"
              find "$VOICES_DIR" -name "*.onnx" -exec basename {} .onnx \; 2>/dev/null | sed 's/^/    /' | sort
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

          VOICE=""
          SPEAKER=""
          OUTPUT=""
          TEXT=""

          while [[ $# -gt 0 ]]; do
            case "$1" in
              -v|--voice) VOICE="$2"; shift 2 ;;
              -s|--speaker) SPEAKER="$2"; shift 2 ;;
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

          # Auto-detect voice if not specified
          if [ -z "$VOICE" ]; then
            mapfile -t installed < <(get_installed_voices)
            if [ "''${#installed[@]}" -eq 0 ]; then
              echo "Error: No voices installed. Use --download to get a voice first." >&2
              exit 1
            elif [ "''${#installed[@]}" -eq 1 ]; then
              VOICE="''${installed[0]}"
            else
              echo "Error: Multiple voices installed. Please specify one with -v:" >&2
              printf '  %s\n' "''${installed[@]}" >&2
              exit 1
            fi
          fi

          # Find voice path: bundled > user-downloaded > download on demand
          MODEL_PATH=""
          if [ -n "$BUNDLED_DIR" ] && [ -f "$BUNDLED_DIR/$VOICE.onnx" ]; then
            MODEL_PATH="$BUNDLED_DIR/$VOICE.onnx"
          elif [ -f "$VOICES_DIR/$VOICE.onnx" ]; then
            MODEL_PATH="$VOICES_DIR/$VOICE.onnx"
          else
            echo "Voice '$VOICE' not found. Downloading..."
            download_voice "$VOICE"
            MODEL_PATH="$VOICES_DIR/$VOICE.onnx"
          fi

          # Build piper arguments
          PIPER_ARGS=(--model "$MODEL_PATH")
          if [ -n "$SPEAKER" ]; then
            PIPER_ARGS+=(--speaker "$SPEAKER")
          fi

          if [ -n "$OUTPUT" ]; then
            echo "$TEXT" | ${pkgs.piper-tts}/bin/piper "''${PIPER_ARGS[@]}" --output_file "$OUTPUT"
            echo "Saved to: $OUTPUT"
          else
            # Use temp file to avoid broken pipe issues on macOS
            TMPFILE=$(mktemp --suffix=.wav)
            trap "rm -f '$TMPFILE'" EXIT
            echo "$TEXT" | ${pkgs.piper-tts}/bin/piper "''${PIPER_ARGS[@]}" --output_file "$TMPFILE"
            ${pkgs.ffmpeg}/bin/ffplay -nodisp -autoexit "$TMPFILE" 2>/dev/null
          fi
        '';

    in
    {
      packages = forAllSystems (system: {
        # Bundled voice (~75MB), can download additional voices at runtime
        speak = mkPiperSpeak {
          inherit system;
          voices = [ "en_US-libritts_r-medium" ];
        };

        # ELLIE Daily Planner CLI
        ellie =
          let
            pkgs = import nixpkgs { inherit system; };
          in
          pkgs.runCommand "ellie" { } ''
            mkdir -p $out/bin
            ln -s ${ellie-cli.packages.${system}.default}/bin/elli $out/bin/ellie
          '';

        # Clank task management CLI
        clank = clank.packages.${system}.default;

        default = self.packages.${system}.speak;
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              self.packages.${system}.speak
              pkgs.piper-tts
            ];
          };
        }
      );

      clawdbotPlugins = {
        piper-tts = {
          name = "piper-tts";
          skills = [ ./plugins/piper-tts/skills/piper-tts ];
          packages = [ ]; # Uses flake.packages (speak-with-voices by default)
          needs = {
            stateDirs = [ ".local/share/piper-voices" ];
            requiredEnv = [ ];
          };
        };

        ellie-cli = {
          name = "ellie-cli";
          skills = [ ./plugins/ellie-cli/skills/ellie-cli ];
          packages = [ ]; # Uses flake.packages.ellie
          needs = {
            stateDirs = [ ".config/ellie" ];
            requiredEnv = [ "ELLIE_API_KEY_FILE" ]; # Path to file containing API key (agenix-friendly)
          };
        };

        clank = {
          name = "clank";
          skills = [ ./plugins/clank/skills/clank ];
          packages = [ ]; # Uses flake.packages.clank
          needs = {
            stateDirs = [ ];
            requiredEnv = [ "CLANK_API" ]; # API URL (e.g., http://localhost:8080)
          };
        };
      };
    };
}
