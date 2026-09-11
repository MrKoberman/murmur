# Murmur

Murmur is a minimalist system tray application for recording audio and transcribing it to text using local `whisper.cpp` models.

## Features
- **Local Transcribing:** Uses `whisper.cpp` for privacy and speed.
- **System Tray:** Minimalist menu in your system tray.
- **Hotkey Support:** Start/Stop recording with controls.
- **Nix-Powered:** Fully reproducible environment with managed dependencies.
- **Model Management:** Models are managed automatically via Nix Store.

## Prerequisites
- Nix with Flakes enabled.

## Build & Run
1. **Build:**
   ```bash
   nix build
   ```
   *If a hash mismatch occurs, copy the "got" hash from the error and update `flake.nix`.*

2. **Run:**
   ```bash
   ./result/bin/murmur
   ```

## Integration (Home Manager)
Add to your `home.nix`:
```nix
{ inputs, ... }: {
  # Add the flake to your flake inputs first:
  # inputs.murmur.url = "github:MrKoberma/murmur";

  home.packages = [ inputs.murmur.packages.${pkgs.system}.default ];
  
  systemd.user.services.murmur = {
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      ExecStart = "${inputs.murmur.packages.${pkgs.system}.default}/bin/murmur";
      Restart = "always";
    };
  };
}
```

## Dependencies
- `arecord` (ALSA)
- `whisper-cli` (whisper.cpp)
- `xclip`
