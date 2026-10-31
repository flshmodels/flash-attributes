"""Package the source as an inspectable Roblox plugin model. Python 3.11+."""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
NAME = "FlashAttributes"

def build():
    document = ET.Element("roblox", {"version": "4"})
    script = ET.SubElement(document, "Item", {"class": "Script", "referent": "RBX0"})
    files = [(NAME, ROOT / 'src/Plugin.server.luau')]
    files += [(path.stem, path) for path in sorted((ROOT / 'src').glob('*.luau')) if path.name != 'Plugin.server.luau']
    for index, (name, path) in enumerate(files):
        item = script if index == 0 else ET.SubElement(script, "Item", {"class": "ModuleScript", "referent": f"RBX{index}"})
        properties = ET.SubElement(item, "Properties")
        ET.SubElement(properties, "string", {"name": "Name"}).text = name
        ET.SubElement(properties, "ProtectedString", {"name": "Source"}).text = path.read_text(encoding='utf-8')
    ET.indent(document, space='  ')
    destination = ROOT / (NAME + '.rbxmx')
    destination.write_bytes(ET.tostring(document, encoding='utf-8', xml_declaration=True))
    return destination

if __name__ == '__main__':
    print(build())
