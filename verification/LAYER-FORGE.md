# Layer Forge source snapshot

This snapshot preserves the editable project for the regular Linux **Layer Forge** playtest. It uses the configured `res://single_body/main.tscn` entry point. Player profiles, generated Godot caches, local launchers and runtime binaries are not in the snapshot. The experimental pre-company world generator is not part of it.

The 4,815 authored game files are listed in [`layer-forge.authored.sha256`](layer-forge.authored.sha256). From the repository root, `sha256sum --strict --check verification/layer-forge.authored.sha256` checks the source and asset bytes.

Verified from a clean copy: cold Godot 4.4.1 import and configured game boot, both in an offline Linux environment with disposable game data. This is an import and startup smoke, not full campaign or platform-export testing. The test engine SHA-256 is `54215149d52efb1d653a3dec39d0993587bdf5daa2c56e787b5ee88417fb1339`.
