# OpenMW for New 3DS setup app

The setup app prepares the folder players copy to their New 3DS's SD card, from their own Morrowind installation. It
writes the configuration with Morrowind.ini's values, packs the sounds into one archive, copies the game's files and
cooks the textures for the 3DS's GPU, next to the port's own files and its CIA. The game's files are only read, never
modified or shared.

Preparing a folder that already has an install updates it. The sounds, the game's files and the textures are kept
when nothing they're made from has changed, so an update mostly copies the port's new files. The app remembers the
last folder it prepared and offers it next time.

It's written in Rust, with a Tauri window, under the GPL-3.0 like the port.

## What's here

- `core/` is the preparation, without an interface. It checks the Morrowind folder and tells its edition, finds it
  (Steam, GOG, the original installer), writes `openmw.cfg`, packs `sound3ds.bsa`, cooks the textures, works out the
  space an install takes, checks a copy on the SD card and keeps a log. The cooker gives the same bytes as the port's
  `tools/cook_textures.py`, and its ETC1 encoder is rg_etc1, ported to Rust.
- `app/` and `ui/` are the window. `app/` is the Rust side and `ui/` the page, in plain HTML, CSS and JavaScript with
  no build step. It's light or dark as the system is.
- `cli/` is the command-line tool, with developer commands (`cook`, `dump`, `space`, `check`).
- `python/openmw3ds_setup.py` is a backup in Python (Pillow and NumPy), without a window, for when the app doesn't
  run. It makes the same folder, except for the ETC1 blocks, which its own encoder packs a little differently.
- `data/` holds lists taken from OpenMW's source, refreshed by `tools/update_*.py`.
- `packaging/` holds the READMEs that go in the release downloads.

## Building

You need [Rust](https://rustup.rs) and Node.js, which fetches Tauri's command-line tool with `npx`. On Windows, use
the MSVC toolchain (`rustup toolchain install stable-x86_64-pc-windows-msvc`, with Visual Studio's Build Tools), so
the program is a single file. On Linux, install Tauri's libraries first (`libwebkit2gtk-4.1-dev` and the rest of
[its list](https://v2.tauri.app/start/prerequisites/)).

    cd app
    npx @tauri-apps/cli@2.12.4 build --no-bundle

The program is `target/release/openmw3ds-setup`. It looks for the port's files, laid out as on the SD card, in a
`port` folder next to it. In the macOS and Linux releases they're inside the app instead, which
`tauri.release.conf.json` sets up from `app/port`.

Build the command-line tool alone with `cargo build --release -p openmw3ds-setup-cli`, and run the tests with
`cargo test`.

## Using it

Run `openmw3ds-setup` for the window. The command line works the same way.

    openmw3ds-setup-cli --morrowind "<Morrowind folder>" --output <folder> --port <the release's port files>

The Python backup takes the same options.

    python python/openmw3ds_setup.py --morrowind "<Morrowind folder>" --output <folder> --port <port files>

To check the texture cooker against a reference pack, cook one with
`openmw3ds-setup-cli cook ... --out new.o3tp --keys new.keys`, then compare them with
`python tools/compare_packs.py reference.o3tp new.o3tp --keys new.keys`.
