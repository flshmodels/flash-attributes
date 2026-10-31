from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

class PackageTests(unittest.TestCase):
    def test_package_matches_source(self):
        root = Path(__file__).resolve().parents[1]
        models = list(root.glob('*.rbxmx'))
        self.assertEqual(len(models), 1)
        items = ET.parse(models[0]).getroot().findall('.//Item')
        expected = {p.stem: p for p in (root / 'src').glob('*.luau') if p.name != 'Plugin.server.luau'}
        expected[models[0].stem] = root / 'src/Plugin.server.luau'
        self.assertEqual(len(items), len(expected))
        self.assertEqual(items[0].get('class'), 'Script')
        for item in items:
            props = item.find('Properties')
            name = props.find("string[@name='Name']").text
            source = props.find("ProtectedString[@name='Source']").text
            self.assertEqual(source, expected.pop(name).read_text(encoding='utf-8'))
        self.assertFalse(expected)

if __name__ == '__main__':
    unittest.main()
