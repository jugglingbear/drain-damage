# Prototype 211 Mac export audit

The signed Mac game ships a 754,689,520-byte Godot resource pack. A private test copy omitting 514 entries measured
489,267,772 bytes, a saving of 265,421,748 bytes (35.2%). All 1,596 retained entries compared byte-for-byte equal.
The signed app and export presets were left intact for this audit.

## What the exclusion trial removed

| Group | Payload MB | Evidence |
| --- | ---: | --- |
| Design directory | 220.24 | Concept grids, visual guides, comic studies, reference images and planning records. |
| Controller concepts and superseded diagrams | 18.99 | Controls draws the keyboard and current callout controller. |
| Duplicate title illustrations | 10.19 | All four compiled textures match the active starting-pictures set byte for byte. |
| Development handoffs | 6.05 | Production records and historical delivery files, including engineering archives. |
| Superseded music | 5.12 | Current music director and flush/ride manifests select other recordings. |
| Earlier title and selection images | 4.77 | The title renderer and fallback reference newer art. |

Sizes are decimal MB. Directory entries and alignment explain the small difference between payload and file savings.
The runtime export uses Godot’s all-resources preset with individual exclusions. This ships importable material outside
the gameplay directories. Some gameplay metadata names design or handoff files as provenance. The tested game paths
read their generated runtime data directly. Byte-identical duplicates overlap the groups above and are counted once.

## Whole-pack accounting

| Evidence for keeping or investigating an entry | Payload MB |
| --- | ---: |
| Excluded in the trial above | 265.37 |
| Observed in the resource cache in the signed pack | 165.87 |
| Literal reference from runtime code, export configuration or linked metadata | 167.67 |
| Dynamically addressed title or loading pictures outside the sampled cache | 20.74 |
| Assets requiring further reference tracing | 134.66 |
| Other entries, including engine data | 0.16 |

The [full inventory](prototype-211-pack-inventory.tsv) has one row per packed entry, sorted by payload size.
It records the original resource, packed path, bytes, evidence class, first cache observation and packed digest.
Import redirects and compiled payloads have separate rows. Byte totals describe disk usage. Cache sampling establishes
presence at the sampled moment and cannot establish that an unobserved file is disposable.

## Verification and remaining questions

- Enumerated all 2,110 directory entries from the shipped PCK. Resolved import/remap records back to source names,
  compared duplicate payload digests, searched game scripts and followed full-path references through JSON metadata.
- Sampled the original pack headlessly at the title, prepared hero selection, Level 1 reveal, flush preparation and
  ride preparation. Found 251 distinct cached paths across those snapshots. None belonged to the exclusion set.
- Opened the trial pack outside the source checkout. Verified the menu-to-game path, current controller and keyboard art,
  four title options, six loading cards and normal/easy/hard portraits for Tony and Sean. The continuous integration
  suite passed for both heroes on all three difficulties, including retry and the campaign-to-ride transition.
- The remaining 134.66 MB includes costume atlases, cinematics, older art revisions and files named “source.”
  The vitals HUD constructs filenames at runtime, and special-attack cinematics extract frames from source sheets.
  Removing every source sheet or every earlier version would remove gameplay art. Next inspect these families
  against their specific frame manifests, plus non-campaign playtest entries.
- Before shipping export-filter changes, repeat a native visual and audio pass on the actual export and verify each
  platform package. This trial covered the Mac resource pack. It did not measure boot-time improvement or RAM savings.
  Headless checks reported shutdown resource warnings.

Audited PCK SHA-256: `485c6d6dd7b08a8cfd2da7212a570362519d60566dd9cf9cb9293957094945a2`.
