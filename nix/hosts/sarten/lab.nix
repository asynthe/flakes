{ ... }:
{
    flake.modules.nixos.sarten-lab = { config, lib, pkgs, ... }:
    let
        pool    = "vm";
        dataset = "vm/incus";
        profile = "lab";
    in {
        environment.systemPackages = [
            pkgs.qemu-utils

            # Boots a disk image from VulnHub and friends as an Incus VM on the
            # lab bridge. The image is written into the VM's zvol, which Incus
            # keeps with volmode=none, so the device node has to be turned on
            # for the copy and off again afterwards.
            (pkgs.writeShellApplication {
                name          = "sarten-import-vm";
                runtimeInputs = with pkgs; [
                    config.virtualisation.incus.package
                    qemu-utils zfs libarchive gnutar unzip coreutils gnused jq
                ];
                text = ''
                    if [ $# -lt 2 ]; then
                        echo "usage: sarten-import-vm NAME IMAGE [SIZE_GIB]" >&2
                        echo "  IMAGE: .ova .zip .vmdk .qcow2 .vdi .vhd .raw .img" >&2
                        exit 2
                    fi
                    name=$1; src=$2; want=''${3:-}
                    [ -r "$src" ] || { echo "cannot read $src" >&2; exit 1; }
                    if incus info "$name" >/dev/null 2>&1; then
                        echo "instance $name already exists" >&2; exit 1
                    fi

                    work=$(mktemp -d -p /srv/scratch sarten-import.XXXXXX)
                    trap 'rm -rf "$work"' EXIT

                    case "$src" in
                        *.ova|*.tar) tar -xf "$src" -C "$work" ;;
                        *.zip)       unzip -q -o "$src" -d "$work" ;;
                        *)           ln -s "$(readlink -f "$src")" "$work/$(basename "$src")" ;;
                    esac

                    # biggest disk-shaped file wins: OVAs ship a small
                    # descriptor beside the real image
                    disk=$(find -L "$work" -type f \
                        \( -iname '*.vmdk' -o -iname '*.qcow2' -o -iname '*.qcow' \
                           -o -iname '*.vdi' -o -iname '*.vhd' -o -iname '*.vhdx' \
                           -o -iname '*.raw' -o -iname '*.img' \) \
                        -printf '%s %p\n' | sort -rn | head -1 | cut -d' ' -f2-)
                    [ -n "$disk" ] || { echo "no disk image found in $src" >&2; exit 1; }
                    echo "disk: $disk"

                    virt=$(qemu-img info --output=json "$disk" | jq -r '."virtual-size"')
                    gib=$(( (virt + 1073741823) / 1073741824 + 1 ))
                    if [ -n "$want" ]; then gib=$want; fi
                    echo "size: ''${gib}GiB"

                    incus init --empty --vm "$name" -q -p ${profile}
                    incus config device override "$name" root size="''${gib}GiB" >/dev/null
                    # VulnHub images are almost all legacy BIOS; Incus is UEFI by default.
                    incus config set "$name" security.csm=true

                    vol=${dataset}/virtual-machines/$name.block
                    zfs set volmode=dev "$vol"
                    udevadm settle
                    node=/dev/zvol/$vol
                    [ -b "$node" ] || { echo "no device node at $node" >&2; exit 1; }

                    echo "writing $disk -> $node"
                    qemu-img convert -p -O raw "$disk" "$node"
                    sync
                    zfs set volmode=none "$vol"

                    echo
                    echo "imported as $name on the ${profile} profile (pool ${pool}, bridge labbr0)"
                    echo "  incus start $name"
                    echo "  incus list $name          # its address, once it has DHCP"
                    echo "  incus console $name       # serial; --type=vga needs a remote client"
                    echo "  incus snapshot create $name clean"
                '';
            })
        ];
    };
}
