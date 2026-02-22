# butterfly-ublue

Custom Universal Blue images for my personal machines, built on Bazzite (Fedora Atomic/OSTree).

## Images

### Desktop (`butterfly-ublue`)

Based on `bazzite-nvidia-open:stable`. Targets my desktop with NVIDIA GPUs. Includes DKMS-built
NVIDIA modules, Hyprland, Ceph client, observability tools, and more.

```
ghcr.io/butterflysky/butterfly-ublue:latest
```

### Laptop (`butterfly-ublue-laptop`)

Based on `bazzite:stable` (no NVIDIA drivers). Targets the **Lenovo Yoga 9 2-in-1 14ILL10**:

- Intel Core Ultra 7 258V (Lunar Lake)
- Intel Xe/Arc 140V integrated graphics
- 2-in-1 convertible with touchscreen and stylus support

Includes Intel VA-API acceleration (`intel-media-driver`), ISH/audio firmware from the Windows
extraction, power management (`power-profiles-daemon`, `thermald`), and sensor support
(`iio-sensor-proxy`) for auto-rotation.

```
ghcr.io/butterflysky/butterfly-ublue-laptop:latest
```

**Kernel requirement:** Lunar Lake needs kernel 6.12+. Bazzite stable currently ships a
sufficiently recent kernel.

## Building Locally

### Desktop

```bash
just build
```

### Laptop

Firmware files must be staged before building (see `build_files/firmware/README.md`):

```bash
cp -a /mnt/docker-swarm-volumes/firmware/yoga9-14ill10/* build_files/firmware/
just build-laptop
```

### Bootable ISOs

```bash
just build-iso          # Desktop ISO
just build-iso-laptop   # Laptop ISO
```

## Lint & Format

```bash
just lint    # shellcheck
just format  # shfmt
```
