# felix86 rootfs image generation

Run the `BuildAll.sh` script to build all the rootfs images.

Alternatively, if you have [Nix](https://nixos.org) installed with [Flakes enabled](https://wiki.nixos.org/wiki/Flakes#Setup), you can build a reproducible rootfs with:

```shellSession
nix run #<image-name>-rootfs -L
```

Or, to build all images, run:

```shellSession
nix run .#build-all -L
```

See [images.nix](./nix/images.nix) for the available images.
