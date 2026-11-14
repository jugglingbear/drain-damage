"""Verify production routing and reject missing publication inputs."""

import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools import build_magazine_site as site


class PublicSiteTests(unittest.TestCase):
    """Keep local preview paths and unpublished issue links out of the release site."""

    def test_landing_routes_and_comic_preview(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'marketing/landing-page'
            source.mkdir(parents=True)
            for name in ('index.html', 'landing.css', 'landing.js', 'desk-interaction-geometry-v1.json',
                         'concepts-v1/01-service-desk-v4.png', 'comic/index.html', 'comic/comic-shop-shelf-v1.png',
                         'comic/issue-01-cover-v5.png', 'comic/issue-01/index.html'):
                target = source / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(site.ROOT / 'marketing/landing-page' / name, target)
            preview = 'comic/issue-01/drain-damage-issue-01-preview.pdf'
            (source / preview).write_bytes(b'%PDF-1.7\nFixture publication bytes')
            (source / 'comic/issue-01/private-notes.txt').write_text('Not approved for publication')
            (root / 'dist').mkdir()
            (root / 'dist/index.html').write_text('<a href="https://example.test/game.zip">Download</a>')
            (root / 'dist/private.zip').write_bytes(b'not public site content')
            output = root / 'builds/site'
            with patch.object(site, 'ROOT', root):
                site.assemble_landings(output)
            script = (output / 'landing.js').read_text()
            self.assertIn("magazine: 'magazine/'", script)
            self.assertIn("journey: 'storybook/storybook.html'", script)
            self.assertIn("game: 'dist/'", script)
            self.assertNotIn('../', script)
            self.assertNotIn('Interactive preview', (output / 'index.html').read_text())
            self.assertIn('href="issue-01/"', (output / 'comic/index.html').read_text())
            directory_index = (output / 'comic/issue-01/index.html').read_text()
            self.assertIn('href="drain-damage-issue-01-preview.pdf" download', directory_index)
            self.assertIn('Partial work-in-progress preview', directory_index)
            self.assertEqual((source / preview).read_bytes(), (output / preview).read_bytes())
            self.assertFalse((output / 'comic/issue-01/private-notes.txt').exists())
            (source / preview).write_bytes(b'version https://git-lfs.github.com/spec/v1\n')
            with patch.object(site, 'ROOT', root), self.assertRaisesRegex(ValueError, 'Unresolved publication'):
                site.assemble_landings(output)
            self.assertEqual((source / 'comic/issue-01-cover-v5.png').read_bytes(),
                             (output / 'comic/issue-01-cover-v5.png').read_bytes())
            self.assertFalse((output / 'dist/private.zip').exists())
            self.assertTrue((output / 'dist/index.html').exists())

    def test_source_directory_cannot_be_replaced(self) -> None:
        for path in (site.ROOT, site.ROOT / 'storybook', site.ROOT.parent):
            with self.assertRaises(ValueError):
                site.build_site(path)
