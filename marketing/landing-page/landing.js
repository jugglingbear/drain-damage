const routes = {
  comic: 'comic/',
  magazine: '../magazine/current.pdf',
  journey: '../../storybook/storybook.html',
  game: '../../dist/',
};
const subtitles = {
  comic: 'The comic book',
  magazine: 'Discharge Quarterly',
  journey: 'Making-of storybook',
  game: 'Download the game',
};
const mobile = window.matchMedia('(max-width: 600px)');
const namespace = 'http://www.w3.org/2000/svg';

function svgElement(name, attributes) {
  const element = document.createElementNS(namespace, name);
  for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value);
  return element;
}

async function buildDesk() {
  const response = await fetch('desk-interaction-geometry-v1.json');
  if (!response.ok) throw new Error('Could not load the desk interaction geometry.');
  const geometry = await response.json();
  const views = [];
  for (const region of geometry.regions) {
    const link = document.createElement('a');
    link.className = 'destination';
    link.href = routes[region.id];
    link.setAttribute('aria-label', `${region.label} — ${subtitles[region.id]}`);
    const svg = svgElement('svg', { viewBox: geometry.viewBox.join(' '), 'aria-hidden': 'true' });
    svg.append(svgElement('image', {
      href: geometry.source, width: geometry.viewBox[2], height: geometry.viewBox[3], class: 'thumbnail',
    }));
    const highlight = svgElement('g', { class: 'highlight' });
    for (const [key, className] of [['object_polygon', 'object-outline'], ['plaque_polygon', 'plaque-light']]) {
      const points = region[key].map(point => point.join(',')).join(' ');
      highlight.append(svgElement('polygon', { points, class: className }));
      svg.append(svgElement('polygon', { points, class: 'hit' }));
    }
    svg.append(highlight);
    const label = document.createElement('span');
    label.className = 'mobile-label';
    label.textContent = region.label;
    const subtitle = document.createElement('small');
    subtitle.textContent = subtitles[region.id];
    label.append(subtitle);
    link.append(svg, label);
    document.getElementById('destinations').append(link);
    const xs = region.object_polygon.map(point => point[0]);
    const ys = region.object_polygon.map(point => point[1]);
    const x = Math.min(...xs) - 12;
    const y = Math.min(...ys) - 12;
    const crop = [x, y, Math.max(...xs) - x + 12, Math.max(...ys) - y + 12];
    const clip = svgElement('clipPath', { id: `crop-${region.id}` });
    clip.append(svgElement('rect', { x, y, width: crop[2], height: crop[3] }));
    const definitions = svgElement('defs', {});
    definitions.append(clip);
    svg.prepend(definitions);
    svg.querySelector('.thumbnail').setAttribute('clip-path', `url(#crop-${region.id})`);
    views.push({ svg, crop });
  }
  function updateViews() {
    for (const { svg, crop } of views) {
      svg.setAttribute('viewBox', (mobile.matches ? crop : geometry.viewBox).join(' '));
    }
  }
  mobile.addEventListener('change', updateViews);
  updateViews();
}

buildDesk().catch(error => {
  document.querySelector('.preview-note').textContent = 'The preview could not load. Please reload the page.';
  console.error(error);
});
