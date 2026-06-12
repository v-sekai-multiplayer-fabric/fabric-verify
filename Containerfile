# fabric-smoke: runs the headless verification smokes against the merged
# double-precision Godot build (bind-mounted read-only by the quadlets).
FROM fedora:44
RUN dnf -y install fontconfig procps-ng diffutils gawk && dnf clean all
ENV GODOT=/godot/bin/godot.linuxbsd.editor.double.x86_64
WORKDIR /work
