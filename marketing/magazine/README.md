# Discharge Quarterly

[magazine.json](magazine.json) is the canonical editable source for the magazine. It contains publication metadata,
ordered pages, text, captions, image references and layout templates. The PDF is generated output.

## Editing and building

1. Edit the relevant page by its stable `id`. Edit `text` for headings and paragraphs; retain paragraph markup such
   as `<b>` and `<br/>`. Asset paths are relative to the project root.
2. Adjust element coordinates and sizes when needed. Coordinates use PDF points from the bottom left; paragraph
   `top` is the top edge. Images and selected crops fit their box without distortion.
3. For a new edition, update publication metadata, visible edition/date text, page templates and the output path.
   Keep earlier PDFs intact. Keep page numbers sequential and update the contents when inserting pages.
4. Run from the project root with Python and ReportLab installed:

   ```shell
   python3 marketing/magazine/build_guide.py
   ```

5. Render the PDF with `pdftoppm` and inspect every page before delivery. The renderer rejects paragraph overflow,
   missing images and unknown element types, but visual review remains necessary.

The renderer uses the macOS fonts configured in `layout.font_directory`. Change that path and the font filenames
if building elsewhere. Shared header/footer templates use `{page_number}` and `{section}` placeholders.

## Edition 28 cover line

Replaced the redundant “Seven locals!” cover burst with “Creature Feature.”
The eight-page issue retains edition 27’s alternating action layout; `current.pdf` matches edition 28.
Website publication remains pending.

## Edition 27 playful action gallery

Action-page headings and copy alternate left/right. Tinted panels, gently tilted headings and staggered
sprite placements vary the rhythm while retaining left-to-right action sequences and existing artwork.
The issue remains eight pages; that delivery matched edition 27. Website publication remains pending.

## Edition 26 official Skitterling name

Sean confirmed Skitterling as the official name unless he chooses to change it. Removed its working-name label
and updated editorial guidance. Earlier editions remain preserved; that delivery matched edition 26.

## Edition 25 Skitterling

Skitterling joins the dense creature section after the five non-boss enemies and before the Clogfather.
The eight-page issue keeps seven entries across two creature pages. Art confirmed the existing rat/alligator
concept diptych; Storyboarding supplied descriptive copy without origin lore, fight solutions or the false-death
reveal. The selected-for-now name is marked as a working name. Encounter integration remains in progress;
artwork is not a gameplay capture and the magazine makes no current-playability claim.

The cover and contents now count seven creatures. Earlier editions and pre-revision source are preserved.
That delivery matched edition 25; website publication was not performed.

## Edition 24 density study

The creature feature now fits six entries across two pages instead of three, returning the issue to eight pages.
Existing lore is retained with tighter columns, smaller portraits, compact tip boxes and existing action-pose
insets. Body type is approximately 11 points. All five non-boss entries still precede the Clogfather.
This is the first denser layout for Sean to compare with edition 23; no new lore or artwork was generated.
Earlier editions and the pre-revision source are preserved. That delivery matched edition 24.

## Edition 23 creature order

All five non-boss creatures now precede the Clogfather in the creature feature. Gratecrawler and Sputtervalve
move to page 5; page 6 presents the Septic Air Force first and the Clogfather last. Creature numbers and section
bookmarks follow that order. Edition 22 and its source remain preserved; that delivery matched edition 23.

## Edition 22 creature roster

Edition 22 adds a paired Gratecrawler and Sputtervalve feature on page 6, bringing the issue to nine pages.
The original compact design, gameplay feature, action gallery and company advertisement are retained.
Gratecrawler remains a working name and is labeled accordingly; recovered user evidence confirms Sputtervalve
as approved. Descriptions use physical traits and verified behavior, with no invented origin stories.
Art confirmed the existing single-pose sprite
crops; no new artwork was generated. Separate marketing portraits and backstories remain pending.

The cover and contents now reflect six creatures. The Widow caption describes its repeating dive and recovery;
the swarm caption clarifies that it drifts without hunting. The Clogfather remains descriptive, with no boss
solution or claim that its encounter is playable. Runtime facts were checked against Engineering's Prototype 63
delivery; the magazine does not depend on the concurrent next-build pacing work.

All nine pages were rendered and visually inspected, and the complete extracted text and PDF metadata reviewed.
The source before this update is preserved in `guide-assets-v22/pre-publication-source.json`, with crop provenance
and checks in `guide-assets-v22/provenance.json`. Earlier PDFs remain intact. At that delivery, `current.pdf` matched
edition 22;
this is a reviewed local delivery, not confirmation of a new website deployment.

## Edition 20 portraits

Edition 20 uses Art's new hyperreal Tony and Sean portraits on page 2. The rendered crew page was visually checked;
all eight pages retain the previous edition's text apart from the edition number. Earlier PDFs are preserved.
Portrait provenance is recorded in `handoffs/hero-hyperreal-marketing-portraits.json` at the project root.

## Edition 19 feedback integration

Edition 19 incorporates the October 16 review: Storyboarding's subtle dispenser feature copy, glass-front
Tony/Sean-stocked machine artwork, Tony's Clogfather reaction, the requested Widow wording, and removal of tentative
preview and development-history captions. The approved fake-advertisement headline and tone are retained.
All eight pages were rendered and visually inspected; extracted text was reviewed. Earlier editions are preserved.
The source before integration is archived in `guide-assets-v19/pre-publication-source.json`.

## Edition 21 disclaimer removal

Removed the fictional-company footer and fictional-publication/non-affiliation paragraph. All eight pages rendered
and visually checked; extracted text audited. At that delivery, `current.pdf` matched edition 21.

## Editorial policy

Do not include fictional-company, fictional-publication or non-affiliation disclaimers in the reader edition.

Suggest the dispenser's disturbing corporate practices through euphemisms and omissions. Do not describe its
lethal mechanism or bodily processing. Never mention the viewer's screen or other fourth-wall-breaking details.

Write for people who love games. Assume no knowledge of game design or development. This rule applies to the
cover, contents, profiles, headings, captions, sidebars, credits and PDF metadata, not just body paragraphs.
Describe what readers can see or experience. Player terms such as health, attacks, checkpoint and reload are fine.

Keep sprite-sheet terminology, atlas details, frame counts, build IDs, runtime/integration status, collision rules,
validation notes and agent/process commentary out of the publication. Do not disguise technical explanations with
new headings: remove row/column/frame-count descriptions. Keep technical records in internal manifests and this
README. The `editorial_guidance` object in the JSON is internal guidance and is not rendered.

Remove tentative captions such as “Preview artwork,” “An idea we're exploring,” and “This account is still
taking shape.” Keep production status and image provenance in internal records. Picture captions should describe
the subject, action, atmosphere or useful player information. Do not discuss earlier versions, development history,
prototype status or production progress in the magazine. Never imply unfinished encounters are playable.

Actual unresolved editorial placeholders must use `TODO: <specific missing item>` in a conspicuous high-contrast
box with bold type at least 18 pt. Allow enough space to prevent clipping. Never hide TODOs in small italic captions
or vague caveats. Existing artwork does not need a TODO merely because gameplay remains unfinished.

Keep future plot spoilers, creature-origin explanations and boss solutions out of promotional copy. Preserve
approved profiles and lore, current names, and honest qualifications for unsettled stories. Preserve historical
screenshots and earlier editions. Request new illustrations through Bestiary / Art. Do not change mechanics or
canonical creature records while editing the magazine.

Extract the complete PDF text and audit it for development jargon, including bookmarks and metadata. Render and
visually inspect every affected page after rewriting; check that shorter copy still fits the layout naturally.

Follow the writing-style guidance in `../../AGENTS.md`. Prefer natural, varied sentences and specific observations
rather than repeated paired fragments or generic dramatic contrasts. Review headings, captions and body copy for
repetitive rhetorical patterns before publication.

## Edition 18 editorial revision

Edition 18 retains the eight-page design and revises repetitive headlines, captions and promotional copy.
Approved character and creature lore remains intact. The complete extracted text was reviewed and all eight
rendered pages were visually checked. Edition 17's source is archived in `guide-assets-v18/`.

## Edition 17 layout direction

Use the supplied 1990s Nintendo Power and GamePro spreads as the visual reference: large shadowed display type,
bright section banners, compact columns, small bordered pictures, cutout characters and conversational captions.
Vary the page composition by feature. Avoid returning to one large portrait and several pages per creature.

The eight-page issue contains a cover, paired crew profiles, BJ and dispenser half-page features, a two-page
creature roundup, a gameplay feature, one curated action gallery and an in-universe back-cover advertisement.
Keep full animation sheets out of the reader edition. Select a few complete poses for the action gallery and
inspect the crops against their actual artwork boundaries. Preserve proportions and original files.

All layout elements and text remain in `magazine.json`. Display text supports `angle`, `outline` and
`stroke_width`; paragraphs support an optional `font`. Font choices remain in the JSON layout settings.

## Automatic web publication

The PDF generator also refreshes `current.pdf`, the stable Git LFS publication file. After visual review, commit
and push that file to `main`. The **Publish magazine** GitHub Actions workflow renders its pages and deploys
only the reader, page images, and downloadable PDF to GitHub Pages. Local generation alone does not publish.

The HTML reader reproduces the PDF pages as images rather than reflowing the design. It includes page navigation
and the original PDF for selectable text and full-resolution zoom. Image-only pages are not a screen-reader
replacement for the document. GitHub Actions uses the finished PDF, so macOS fonts are not needed on the server.

Expected address: [Discharge Quarterly](https://jugglingbear.github.io/drain-damage/).
The workflow can also be rerun manually from GitHub Actions. Failed builds leave the previous deployment intact.

To preview the generated site locally with Poppler installed:

```sh
python3 tools/build_magazine_site.py
python3 -m http.server 8000 --directory builds/magazine-site
```

Open `http://localhost:8000` in a browser. Generated site files stay in the ignored builds folder.
