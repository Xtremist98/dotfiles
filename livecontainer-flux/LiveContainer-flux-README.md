# LiveContainer+SideStore-flux.ipa — why this file exists

Patched build of LiveContainer so **Flux** (iPhone as webcam / keyboard / clipboard /
remote display for an Omarchy Linux box) can pair inside LiveContainer.

## The one change

`Payload/LiveContainer.app/Info.plist`

```
NSBonjourServices: [...47 existing entries...] + "_flux._udp"   →  48
```

LiveContainer only permits guest apps to browse/publish the Bonjour service types
declared in the **host's** Info.plist — the guest's own `NSBonjourServices` is
ignored. Flux needs exactly one type, `_flux._udp`, which LiveContainer did not
declare. So Flux was invisible on mDNS in both directions: the app just said
"No computers found" forever, with no error and no crash, while its TCP port
still worked. That silence is what makes it look like a network fault.

Verified upstream as a request to add the string:
**https://github.com/LiveContainer/LiveContainer/issues/1666**

## Which build

```
CFBundleShortVersionString = 3.8.10
LCVersionInfo              = Release (main/4dbe0f9)
```

Byte-identical build to the one it replaces. The `LiveContainer` binary itself is
byte-for-byte unchanged (`cmp` clean), all 375 files present, all 85 Info.plist
keys intact — only the one array changed.

**Use the `+SideStore` variant, not the plain one.** The plain
`LiveContainer.ipa` contains the same binary but *omits*
`Frameworks/SideStoreApp.framework` and `SideStoreSupport.framework`, and lacks
the `ALTAppGroups` / `INIntentsSupported` / `NSUserActivityTypes` keys and the
`sidestore` URL scheme. Installing it would drop SideStore integration silently.
A plain-build variant was produced first and then deleted so it cannot be
grabbed by mistake.

## Install

1. Copy this IPA to the phone.
2. Add it from **SideStore/AltStore**. Same bundle id `com.kdt.livecontainer`, so
   it replaces in place and **uses no extra app slot**.
3. **Do not uninstall LiveContainer first** — that is the one action that would
   delete guest apps and their data. Over-the-top install preserves the data
   container.
4. Open Flux inside LiveContainer, stay on the Chat/Computers tab, allow the
   Local Network prompt (it is attributed to **LiveContainer**, not Flux).

SideStore's own settings and pairing file live in SideStore's own data container
and are untouched by this.

## Verify on the laptop

```sh
timeout 10 avahi-browse -rtp _flux._udp   # a 2nd entry must appear at 192.168.8.100
flux-cli status                           # iPhone ... connected ... paired
```

Confirmed working: `iPhone · phone · connected · 95% · 192.168.8.100 · paired`,
and `flux-cli doctor` reports 0 problems.

## Does the patch survive?

Yes. LiveContainer's Info.plist has **no `sideLoadURL` / `sourceURL`**, so
SideStore has nothing to auto-download from and only re-signs the IPA it has
cached — which is this one. The patch is lost only if LiveContainer is
reinstalled from the official release, or if #1666 lands (in which case you no
longer need this file).

## Location

`/mnt/media/Dots/livecontainer-flux/` — same directory as this note. Tracked in
the Dots git repo (`backup-dots` → `github.com/Xtremist98/dotfiles`), so it is
also backed up to GitHub.

## To redo it from scratch

```sh
git clone --depth 1 https://github.com/ProcursusTeam/ldid && cd ldid && make   # optional
curl -sL -o LC.ipa "https://github.com/LiveContainer/LiveContainer/releases/download/nightly/LiveContainer%2BSideStore.ipa"
unzip -q LC.ipa -d x
# add "_flux._udp" to Payload/LiveContainer.app/Info.plist NSBonjourServices (plistlib, FMT_BINARY)
cd x && zip -qry -y ../LiveContainer+SideStore-flux.ipa Payload
```

md5 of the file beside this note: see below.
md5  ec088d4692133df95c7dc838aab273dc
