# The archive

`~/archive` on the laptop is the personal archive — media, roms, games, books,
knowledge dumps — and the laptop is its source of truth. The server holds a
mirror of the parts worth serving, at `/srv/archive` on its own ZFS dataset.
Nothing on `sarten` writes into that tree; a sync script on the laptop pushes,
and that is the only way bytes get there.

This is deliberately *not* `/srv/media`. That tree belongs to the arr stack,
which renames and deletes inside it as it imports — see
[The media stack](MEDIA.md). A one-way mirror with `--delete` pointed at the
same directory would erase everything Lidarr had grabbed on the next run. Two
trees, two owners, no argument.

## The laptop tree

```
~/archive/                                                            1.9 TB
├── media/                                                            416 GB
│   ├── music/         the nine-root taxonomy below                   309 GB
│   ├── anime/         release-named directories, 12 series            79 GB
│   ├── book/          fanatical/ humble_bundle/ lang/ reading/ sec+/  13 GB
│   ├── youtube/       one directory per channel                      8.5 GB
│   ├── movies/        <Title (Year)>/                                6.5 GB
│   └── series/  tv/   empty                                              —
│
├── roms/              16 platforms; ps3_isos alone is 389 GB         532 GB
├── games/             22 titles: PC ports, mods, decomps             409 GB
├── other/             1_fix/ backup/ programs/ wallpaper/            322 GB
├── db/                monero/ — a full node's chain                  222 GB
├── vn/                13 visual novels, ryuugames rips                45 GB
│
├── docs/              *.md wishlists and notes, not documentation    324 KB
├── scripts/           flat, `category_description.py`                120 KB
└── knowledge/         map/ wiki/ — offline dumps                      empty
```

`scripts/` and `docs/*.md` are the only version-tracked parts (jj, colocated
git); everything else is gitignored bulk data. The `docs/*.md` files are personal
content — wishlists, reading lists — not documentation about the archive.

### It does not all fit

`tank` is 1.81 TB, of which 1.75 TB is free, against 1.9 TB of archive. The whole
thing was never going to mirror onto this pool, so `sys.archive.trees` names the
subtrees that do go up, one at a time. Music is 309 GB and is the first.

Anime (79 GB), book (13 GB) and youtube (8.5 GB) are the obvious next three and
would still leave over a terabyte. `roms/`, `games/`, `other/` and `db/` are
1.5 TB between them and are not mirror candidates on this pool — they need
either their own disks or a different backup target.

## The music taxonomy

`~/archive/media/music` is filed by hand into nine roots. An album lives in
exactly one of them — there are no duplicates across roots, so the 309 GB is
309 GB of distinct audio, not a tree of cross-filed copies.

| root | shape | contents |
| --- | --- | --- |
| `ARTIST/` | `<Artist>/<Artist - Album>/` | 77 artists, the deepest root — 151 GB |
| `LABEL/` | `<Label>/<Artist - Album>/` | 14 labels — 54 GB |
| `ALBUM/` | `<Artist - Album>/` | 114 one-offs, no artist or label grouping — 45 GB |
| `OST/` | `ANIME\|GAME\|MOVIE/<...>/` | 25 GB |
| `GENRE/` | `<GENRE>/<Artist - Album>/` | AMBIENT, ELECTRONIC, VAPORWAVE — 18 GB |
| `PODCAST/` | `<Show - Episode range>/` | 14 GB |
| `SINGLE/` | `<Artist - Title>/` | 29 singles — 2.6 GB |
| `OTHER/` | `<Whatever>/` | 1.7 GB |
| `MP3/` | `NO_ALBUM/` | the untagged strays — 154 MB |

11,136 audio files: 10,057 flac, 1,078 mp3, one opus. Each album directory also
carries a `cover.jpg`. `~/archive/scripts/music_normalize_names.py` is what keeps
the naming consistent enough for that table to be true.

Three things in the tree are not part of the library and never sync:
`.musicbee/` (the MusicBee library, playlists and lyrics — a Windows
application's state, meaningless to Jellyfin), `.lyrics/`, and `docs/`.

## Syncing it up

```sh
~/archive/scripts/music_send_to_server.py           # preview, then confirm
~/archive/scripts/music_send_to_server.py --dry-run # preview only
```

rsync over ssh to `asynthe@sarten`, one-way, `--delete`: the server ends up
matching the laptop exactly, including removals. It carries audio and cover art
and nothing else — see the extension list at the top of the script. The first run
moves 309 GB over a gigabit link, so budget most of an hour; every run after that
moves only what changed.

Files land `664 asynthe:media` in directories `2775` — the same trade the arr
library makes: both admins in `media` can write, and Jellyfin reads the tree
without being in the group. `--chmod=D2775,F664` on the rsync side is what
enforces it, because a plain push would leave the group without write. The group
comes from the setgid bit rather than from rsync, which runs `--no-owner
--no-group` precisely so it does not try to preserve the laptop's `meow:users`
onto a machine that has neither.

The companion script `music_send_to_phone.py` mirrors the same library to
`/sdcard/Music` over ADB. It predates this one and is stricter — audio only, no
cover art — because the phone's player reads tags rather than files.

## The aspect

`nix/nixos/services/archive.nix` is small on purpose. It creates the tree and
sets the permissions; it runs no service, because nothing on `sarten` is
responsible for this data.

| option | default | notes |
| --- | --- | --- |
| `sys.archive.dir` | `/srv/archive` | mirror root, on `tank/archive` |
| `sys.archive.group` | `media` | must match `sys.arr.group` to share one gid |
| `sys.archive.trees` | `[ "music" ]` | subdirectories to create; add one when you start mirroring it |

Adding a name to `trees` only creates the directory. Nothing starts syncing on
its own, and a directory already present that is no longer listed is left where
it is rather than removed.

### The dataset is not created by Nix

`fileSystems."/srv/archive"` mounts `tank/archive`, and a mount of a dataset that
does not exist fails the boot — `nofail` is what keeps that from being fatal, but
the directory is then empty and the next sync writes 309 GB onto the root ext4
disk instead. Create it once, by hand, before the first deploy:

```sh
ssh sarten 'sudo zfs create -o mountpoint=legacy -o compression=zstd -o recordsize=1M tank/archive'
```

`recordsize=1M` matches `tank/media` and suits whole-album files. `zstd` earns
almost nothing on flac, and costs almost nothing either; it is set for
consistency with the rest of the pool rather than for the ratio.

Confirm the mount is real before trusting a sync:

```sh
ssh sarten 'findmnt /srv/archive && zfs list -r tank'
```

## Jellyfin

The mirror is a second music library, added in Jellyfin's UI alongside the four
from [Layout](MEDIA.md#layout) — point it at `/srv/archive/music`, type Music.

Jellyfin groups music by tags, not by directories, so the nine roots do not
become nine sections; they are how the files are filed on disk, and the library
view is by artist and album regardless. That is the whole reason the taxonomy can
be as opinionated as it is without Jellyfin having an opinion about it.

Lidarr's `/srv/media/music` stays a separate library. Anything it grabs that
earns a place gets filed into the taxonomy on the laptop and comes back up on the
next sync — the mirror is one-way, so nothing flows the other direction on its
own.
