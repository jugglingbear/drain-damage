from pathlib import Path
import json, shutil, hashlib, textwrap
from PIL import Image, ImageDraw, ImageFont, JpegImagePlugin
R=Path('/Users/sfoley/repos/drain_damage'); O=R/'design/comic-reference-pack-review-2026-11-14'; (O/'sources').mkdir(exist_ok=True)
F='/System/Library/Fonts/Supplemental/'
font=lambda n,b=False:ImageFont.truetype(F+('Arial Bold.ttf' if b else 'Arial.ttf'),n)
W,H=1600,2000; pages=[]; records=[]
def page(title,sub):
 im=Image.new('RGB',(W,H),'#f5f0e4');d=ImageDraw.Draw(im);d.rectangle((0,0,W,190),fill='#173d43');d.text((80,45),title,font=font(55,True),fill='white');d.text((80,125),sub,font=font(27),fill='#f0d69b');pages.append(im);return im,d
def txt(d,s,y,size=30,color='#26373a'):
 for para in s.split('\n'):
  for line in textwrap.wrap(para,width=int(1430/(size*.50))) or ['']:
   d.text((85,y),line,font=font(size),fill=color);y+=int(size*1.45)
 return y+15
def pic(im,p,box):
 a=Image.open(R/p).convert('RGBA');a.thumbnail((box[2],box[3]));bg=Image.new('RGBA',a.size,'#e2e4de');bg.alpha_composite(a);im.paste(bg.convert('RGB'),(box[0]+(box[2]-a.width)//2,box[1]+(box[3]-a.height)//2))
def source(p,role,status):
 dst=O/'sources'/Path(p).name;shutil.copy2(R/p,dst);records.append({'path':p,'pack_file':'sources/'+dst.name,'role':role,'status':status,'sha256':hashlib.sha256((R/p).read_bytes()).hexdigest()})
sean='assets/portraits/sean-expressions-v4.png';tony='assets/portraits/tony-expressions-v3.png';photo='references/characters/sean-original.png';cover='design/wedding-comic-pulp-refinements-v1/option-05.png';panel='design/comic-issue-01/carrier-style-v2/panel-3.png';proof='design/comic-issue-01/cup-up-carrier-proof-v1/construction-proof.png';contact='design/comic-issue-01/carrier-style-v2/style-contact.png'
for p,role,status in [(photo,'Sean likeness only; no glasses in comic','Existing authoritative identity source'),(sean,'Sean face and expressions; not comic rendering style','Existing game reference; review comic translation'),(tony,'Tony face, hair, stubble and shirt; not comic rendering style','Existing game reference; review comic translation'),(cover,'Refined-retro artistic direction only','Selected style; not blanket character/prop approval'),(panel,'Issue 1 ink, grain and faded palette only','Prior story source with known outdated carrier/footwear'),(proof,'Proposed carrier mechanics only','Provisional; orientation and access not approved'),(contact,'Issue 1 side-by-side style comparison','Prior story source; not geometry or prop canon')]:source(p,role,status)
im,d=page('DRAIN DAMAGE','Character + Issue 1 reference packs | REVIEW DRAFT | 14 November 2026')
pic(im,cover,(85,250,650,1100));y=txt(d,'Two packs, one stable identity',1420,42);txt(d,'A. Character identity: faces, expressions, proportions and costume.\nB. Issue-specific art: palette, setting, recurring objects and continuity.\nThis draft curates existing artwork. No new character or prop concept art has been generated. Selection here does not imply approval.',y,32)
d.text((790,310),'STATUS KEY',font=font(34,True),fill='#173d43');
for yy,s in [(390,'Established: backed by current requirements.'),(510,'Reference only: use its named role, not every detail.'),(670,'Provisional: requires review before propagation.'),(830,'Gap: concept/reference artwork still needed.')]:
 for j,l in enumerate(textwrap.wrap(s,32)):d.text((790,yy+j*43),l,font=font(30),fill='#26373a')
im,d=page('PACK A / Sean','Identity source + expression vocabulary, not a new character design')
pic(im,photo,(85,230,460,960));pic(im,sean,(595,230,920,960));y=txt(d,'LOCK: bald head; chin beard and soul patch. No moustache, full goatee or cheek beard. No glasses or head accessories.',1240,35)
y=txt(d,'Sean is shorter and more heavily muscled than Tony, with normal adult anatomy. Orange work shirt and blue overalls. Preserve eyes, eyebrows, nose, jaw and skull shape when expressions change.',y)
txt(d,'Source note: the existing portrait sheet is a game asset. It supplies identity and expression cues, not the issue palette. Latest Comic correction (14 November, 2:34 p.m.) reinforces chin beard + soul patch; that turn stopped at the usage limit. Missing: approved comic-style front/profile/three-quarter views.',y)
im,d=page('PACK A / Tony','Existing expression sheet and work-shirt correction')
pic(im,tony,(85,250,1430,680));y=txt(d,'LOCK: tall swept/spiky dark hair, established face and eyebrows, short stubble. Navy button-front work shirt with rolled sleeves; no bib overalls or overall straps.',1020,34)
y=txt(d,'Tony is taller than Sean. Keep recognizable face shape across anger, concern, smiles and action. Backpack jetter straps are equipment, not overalls.',y)
txt(d,'Source: tony-expressions-v3.png and tony-work-shirt-v1.json. The sheet is a game reference, not an approved comic-style turnaround. Missing: full-body neutral lineup with Sean, profile/rear views and a single settled comic costume color sample.',y)
im,d=page('PACK A / Pair continuity','Stable identity across issues; poses must not become the reference')
pic(im,panel,(85,240,1430,950));y=txt(d,'Use this panel for ink, texture and issue palette only.',1230,36)
y=txt(d,'Do NOT use it as the final footwear, carrier, facial-hair or height ruler. Perspective and bent poses make direct pixel-height comparison misleading. The old hip carrier and tall boot-cover appearances are not current canon.',y)
txt(d,'Needed next: one neutral side-by-side full-body lineup on the same ground plane, then individual front / three-quarter / profile / rear views. Preserve normal adult proportions. Do not invent exact character heights from provisional prompt measurements.',y)
im,d=page('PACK B / Issue 1 style','Something Borrowed, Something Spewed')
pic(im,contact,(85,230,1430,1090));y=txt(d,'Established direction: refined-retro detailed ink, halftone and print grain. Current story coloring: faded vintage treatment, warm paper and restrained saturation/contrast.',1380,31)
txt(d,'Use original option 05 for artistic direction; use accepted story samples for current palette. A geometry study must not replace the color or identity reference. Keep lettering editable and generate each panel independently before assembly.',y)
im,d=page('PACK B / Recurring objects','Script-first inventory: concept art must precede new panel production')
y=235
for head,body in [
('Sean’s plunger + carrier','One long straight wooden shaft, red rubber cup. Stowed cup-up / handle-down with load-bearing support and spaced restraints. Back carrier or approved tool-belt alternative. Final orientation and drawing/access remain unresolved.'),
('Tony’s backpack jetter','Red backpack unit, hose and nozzle. Fix dimensions, attachment points, hose routing and hand grips. Nozzle remains secured/off until the script explicitly changes its state.'),
('Footwear + service kit','Matching white ankle-height contractor shoe covers enclosing foot and sole; retain normal boot size. Freeze the service kit shape/scale and held/set-down states.'),
('Hotel door + chair','One persistent single door: hardware on leaf, stable hinge/swing direction. Compact single-person chair with coherent square seat, legs, back and joints. Rejected widened-door geometry is not canon.'),
('Repair + smaller hand props','Split pipe and gray duct tape/roll, towel, plugged-in power strip/cables, flashlight and smartphone. Freeze recurring shapes and states; keep workers on dry side of electrical hazard.')]:
 y=txt(d,head,y,33);y=txt(d,body,y,27)
txt(d,'Inventory is a proposed Issue 1 working set derived from the current opening script. Each object needs a labeled reference and review; these paragraphs are not completed concept artwork.',y,27,color='#964321')
im,d=page('PACK B / Carrier proof','PROVISIONAL mechanics candidate. Do not propagate yet.')
pic(im,proof,(85,240,1430,1000));y=txt(d,'This is existing Art proof, not an approved production reference.',1300,35)
y=txt(d,'Recorded self-review: closed lower socket supports the handle; separated bands constrain rotation; shoulder/belt anchors limit swing. But the generated diagonal is opposite the requested one: cup behind LEFT shoulder, handle toward RIGHT hip.',y)
txt(d,'Resolve orientation, release/access and walking clearance before reusing. A still image does not validate draw motion. Facial likeness and ankle-cover height must also meet the latest requirements, regardless of earlier proof status.',y)
im,d=page('Before any new panels','The repeatable production sequence')
y=250
for h,b in [('1 / Analyze the script','Identify recurring held, carried, worn and interacted-with objects, plus fixed fixtures that appear across views.'),('2 / Prepare the reference artwork','Make the common object concept/reference set first, with dimensions, construction, grips, attachment sides and relevant states. Use existing approved sources where appropriate; mark new concepts provisional.'),('3 / Review and freeze the set','Resolve identity, color, scale and mechanics problems before panel production. Label each reference role. Do not treat the draft in this PDF as blanket approval.'),('4 / Generate independent panels','Supply the relevant locked character and issue references on each generation, alongside scene map, script and continuity state. Avoid a chain that only references the last generated image.'),('5 / Check against the masters','Art self-review, then Comic independent QA. Compare faces, costume, props, scale and palette with the master set and neighboring panels. Keep originals and scoped corrections.')]:
 y=txt(d,h,y,36);y=txt(d,b,y,30)
im,d=page('Review decisions + provenance','What is ready, and what still needs artwork')
y=245
for s in ['READY FOR REVIEW: existing Sean/Tony identity sheets, Sean photo, selected refined-retro direction, prior issue style samples and the explicitly provisional carrier candidate.', 'NOT YET CREATED: comic-style neutral character turnarounds; same-plane height lineup; complete recurring-object reference boards; approved carrier orientation/access demonstration; stable scene map and per-panel object ledger.', 'IMPORTANT: do not use an old page as universal truth. Prior pages contain known carrier, footwear and geometry defects. Reference roles and later corrections take precedence.', 'SOURCES: AGENTS.md; docs/comic-production-requirements.md; design/first-level-narrative.md; Issue 1 opening-script-v2.json and Art delivery/proof records; portrait correction JSON; refined-retro manifest; current Comic and Art conversations.', 'SCOPE: project filename inventory and targeted current source/metadata review. Not an exhaustive visual review of every historical/exported image. Archives, duplicate export trees and unrelated gameplay assets are not promoted to comic canon.', 'All original artwork remains unchanged. The source manifest records relative paths, roles, status and checksums. This draft is a review aid, not a replacement for the canonical script or approved requirements.']:
 y=txt(d,s,y,31)
for i,im in enumerate(pages,1):
 d=ImageDraw.Draw(im);d.line((80,1900,1520,1900),fill='#b5b8aa',width=2);d.text((85,1925),'DRAIN DAMAGE  /  REFERENCE PACK REVIEW DRAFT',font=font(23),fill='#61716b');d.text((1440,1925),str(i),font=font(25),fill='#61716b');im.save(O/f'page-{i:02}.png')
pages[0].save(O/'Drain-Damage-Reference-Packs-Review.pdf',save_all=True,append_images=pages[1:],resolution=160.0)
(O/'source-manifest.json').write_text(json.dumps({'status':'draft for Sean review; no new art generated','sources':records},indent=2)+'\n')
(O/'README.txt').write_text('Draft character and Issue 1 reference packs. Open the PDF. Sources are copied unchanged for reuse with their roles and limitations in source-manifest.json. Do not treat provisional or rejected details as approved canon. No production art was changed.\n')
print(O/'Drain-Damage-Reference-Packs-Review.pdf')
