# fabric-verify

The slice's verification smokes as a systemd podman quadlet queue, per the
[quadlet queue decision](https://v-sekai-multiplayer-fabric.github.io/manuals/decisions/20260612-systemd-quadlet-verification-queue.html):
oneshot `.container` units serialized with `After=` under `fabric-verify.target`.
Every smoke asserts against Lean-emitted golden vectors pinned by Plausible
properties in the cores (loot, combat, progression repos).

| Unit | Asserts |
| --- | --- |
| `fabric-smoke-monado` | headless OpenXR `xrCreateInstance` (Monado null compositor) |
| `fabric-smoke-loot` | loot wire parity vs the Lean golden vectors |
| `fabric-smoke-combat` | combat wire parity vs the Lean effect trace |
| `fabric-smoke-fourplayer` | four-player contention vs the Lean golden winners |

```sh
podman build -t fabric-smoke -f Containerfile .
cp quadlets/*.container ~/.config/containers/systemd/
cp quadlets/fabric-verify.target ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user start fabric-verify.target
systemctl --user is-active 'fabric-smoke-*'   # -> active x4
```

The merged double-precision Godot binary bind-mounts read-only from the host
(`/godot/bin`); the image stays generic (fedora + fontconfig + diffutils).
