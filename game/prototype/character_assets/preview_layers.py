#!/usr/bin/env python3
"""Offline art sheet of real Godot layer_signature() outputs, NOT a game capture.
Usage: python3 preview_layers.py <scenario-signatures.json> <output.png>
Needs Pillow. The input is emitted by character_test.gd with
CHARACTER_SIGNATURE_PATH set. This script never chooses runtime equipment.
"""
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


def main():
    records = json.loads(Path(sys.argv[1]).read_text())
    output = Path(sys.argv[2])
    root = Path(__file__).resolve().parent
    width, height, columns = 256, 386, 6
    rows = (len(records) + columns - 1) // columns
    sheet = Image.new('RGBA', (width * columns, height * rows + 36), '#303b32')
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=14)
    small = ImageFont.load_default(size=11)
    draw.text((14, 11), 'ORIGINAL TEMPORARY ART  /  actual scenario equipment  /  OFFLINE layer composition, not an engine screenshot', fill='#e1d5b6', font=font)
    for i, record in enumerate(records):
        x, y = i % columns * width, 36 + i // columns * height
        draw.rectangle((x+1,y+1,x+width-1,y+height-1),fill='#3c4639' if i%2 else '#485143',outline='#67705a',width=1)
        draw.ellipse((x+61,y+309,x+202,y+333), fill='#2b352b')
        image = Image.new('RGBA', (384, 512))
        layers = sorted(record['layers'].values(), key=lambda layer: layer['priority'])
        for layer in layers:
            source = Image.open(root / layer['asset']).convert('RGBA')
            color = bytes.fromhex(layer['color'])
            bands = [band.point([round(value*c/255) for value in range(256)]) for band,c in zip(source.split(), color)]
            source = Image.merge('RGBA', bands)
            image.alpha_composite(source)
        sheet.alpha_composite(image.resize((width, 341), Image.Resampling.LANCZOS), (x,y-4))
        draw.text((x+10,y+339),record['name'],fill='#ece3c7',font=font)
        ids = [record['layers'].get(slot,{}).get('definition','bare') for slot in ['head/shell','weapon','shield']]
        draw.text((x+10,y+361),' / '.join(ids),fill='#d0c5a8',font=small)
    sheet.convert('RGB').save(output)
    print(f'OFFLINE_ART_SHEET: {output} ({len(records)} actual unit signatures)')


if __name__ == '__main__':
    main()
