"""Verify production routing and reject missing publication inputs."""

import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools import build_magazine_site as site


class PublicSiteTests(unittest.TestCase):
    """Keep local preview paths and unpublished issue links out of the release site."""

    def test_landing_routes_and_disabled_comic(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'marketing/landing-page'
            source.mkdir(parents=True)
            for name in ('index.html', 'landing.css', 'landing.js', 'desk-interaction-geometry-v1.json',
                         'concepts-v1/01-service-desk-v4.png', 'comic/index.html', 'comic/comic-shop-shelf-v1.png',
                         'comic/issue-01-cover-v5.png'):
                target = source / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(site.ROOT / 'marketing/landing-page' / name, target)
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
            self.assertNotIn('<a ', (output / 'comic/index.html').read_text())
            self.assertEqual((source / 'comic/issue-01-cover-v5.png').read_bytes(),
                             (output / 'comic/issue-01-cover-v5.png').read_bytes())
            self.assertFalse((output / 'dist/private.zip').exists())
            self.assertTrue((output / 'dist/index.html').exists())

    def test_source_directory_cannot_be_replaced(self) -> None:
        for path in (site.ROOT, site.ROOT / 'storybook', site.ROOT.parent):
            with self.assertRaises(ValueError):
                site.build_site(path)
