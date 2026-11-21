#!/usr/bin/env python3
"""Original, deterministic temporary illustration masters. No downloaded artwork.
Run with python3 prototype/character_assets/build_assets.py (requires rsvg-convert).
PNG companions are engine-ready and do not depend on Godot's editor importer.
"""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent
DEFS = '''<defs>
 <linearGradient id="linen" x1="0" y1="0" x2="1" y2="0.6"><stop stop-color="#afa08a"/><stop offset=".3" stop-color="#827561"/><stop offset=".64" stop-color="#655d50"/><stop offset="1" stop-color="#383a31"/></linearGradient>
 <linearGradient id="tone" x1="0" y1="0" x2=".9" y2=".5"><stop stop-color="#efeddb"/><stop offset=".27" stop-color="#d5d3c6"/><stop offset=".55" stop-color="#a5a89e"/><stop offset="1" stop-color="#4d5750"/></linearGradient>
 <linearGradient id="metal" x1="0" y1="0" x2="1" y2=".3"><stop stop-color="#4b5553"/><stop offset=".19" stop-color="#b5c3bd"/><stop offset=".36" stop-color="#faf4dc"/><stop offset=".51" stop-color="#c6d0c8"/><stop offset=".7" stop-color="#87928c"/><stop offset="1" stop-color="#394542"/></linearGradient>
 <linearGradient id="skin" x1="0" y1="0" x2="1" y2=".7"><stop stop-color="#d3b184"/><stop offset=".4" stop-color="#b58d62"/><stop offset=".7" stop-color="#936747"/><stop offset="1" stop-color="#624732"/></linearGradient>
 <linearGradient id="leather" x1="0" y1="0" x2="1" y2=".4"><stop stop-color="#847052"/><stop offset=".35" stop-color="#655139"/><stop offset=".8" stop-color="#362f25"/><stop offset="1" stop-color="#252920"/></linearGradient>
 <linearGradient id="hair" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#66523b"/><stop offset=".5" stop-color="#3e3529"/><stop offset="1" stop-color="#242720"/></linearGradient>
 <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#e6cea0"/><stop offset=".4" stop-color="#b49a62"/><stop offset="1" stop-color="#645335"/></linearGradient>
</defs>'''

def path(d: str, fill: str = 'none', stroke: str = '#20251f', sw: float = 3, extra: str = ''):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" {extra}/>'

def ellipse(cx, cy, rx, ry, fill, stroke='#20251f', sw: float = 2):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'

def rivet(x, y, r: float = 2):
    return ellipse(x, y, r, r, '#d7d5bd', '#484e44', 1)

def write(name, body):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="384" height="512" viewBox="0 0 384 512">{DEFS}{body}</svg>'
    out = ROOT / (name + '.svg')
    out.write_text(svg)
    subprocess.run(['rsvg-convert', str(out), '-o', str(ROOT / (name + '.png'))], check=True)

# An asymmetrical full-body figure, not an armor loadout: shirt, trousers,
# boots, bare head and hands. Equipment overlays share these exact sockets.
foundation = ''.join([
    # Far trouser, turned and braced against the ground.
    path('M192 296 L232 299 Q242 334 249 355 L244 390 260 445 233 455 Q218 416 211 385 L202 352 183 327Z', 'url(#linen)', sw=4),
    path('M226 319 Q224 352 232 373 L226 391 M213 348 L226 355 M231 411 L245 430', stroke='#333a2e', sw=4),
    path('M239 442 L260 438 263 464 Q280 470 281 480 L276 486 226 483 Q222 475 229 459Z', 'url(#leather)', sw=4),
    path('M229 471 Q249 466 264 472 M229 481 L276 483 M244 446 L250 465', stroke='#aa8a5d', sw=2),
    # Near thigh bends outward: clear negative space between the shins.
    path('M157 294 L201 301 195 344 Q179 363 169 391 L157 451 129 449 Q131 408 142 379 L148 348 141 320Z', 'url(#linen)', sw=4),
    path('M156 337 Q168 355 158 377 M152 388 L144 427 M181 320 L170 338 M147 348 L171 346', stroke='#3e4436', sw=3),
    path('M131 437 L159 442 155 468 Q159 476 154 482 L108 486 Q97 483 101 477 L122 461Z', 'url(#leather)', sw=4),
    path('M119 469 Q135 464 152 473 M102 480 L152 480 M135 446 L133 463', stroke='#ad8c5f', sw=2),
    path('M128 452 L157 456 M126 459 L156 463 M233 451 L259 454', stroke='#b29567', sw=2),
    # Neck and far arm.
    path('M185 159 L216 160 218 191 181 196Z', 'url(#skin)'),
    path('M224 185 Q243 184 252 206 L262 240 281 260 268 279 Q246 269 237 248 L219 218Z', 'url(#linen)', sw=4),
    path('M244 207 L239 224 M250 232 L243 240 M255 251 L268 266', stroke='#b6a58a', sw=2),
    # Shirt torso, open V neck and worn hem.
    path('M176 177 L192 184 208 178 Q230 179 237 199 L231 251 242 300 229 319 205 314 190 322 169 315 144 318 147 282 146 219 151 190Z', 'url(#linen)', sw=4),
    path('M177 178 L192 199 209 178 M193 199 L188 235 M160 204 Q169 227 159 267 M223 205 L214 238 223 277 M152 294 L176 285 M201 289 L230 298', stroke='#c5b498', sw=2),
    path('M165 223 L159 254 M210 217 L204 254 M172 289 L165 308 M207 297 L209 311', stroke='#414337', sw=3),
    path('M188 200 L198 202 M187 207 L196 209 M187 216 L195 215', stroke='#d9c39a', sw=1.5),
    # Near sleeve and arm curl toward a shield grip.
    path('M154 187 Q135 192 128 220 L117 250 126 278 145 270 141 249 157 218Z', 'url(#linen)', sw=4),
    path('M136 208 L149 211 M129 230 L142 237 M122 253 L138 251 M129 262 L139 261', stroke='#b5a68c', sw=2),
    path('M124 272 L142 266 151 280 149 294 136 300 124 294 120 283Z', 'url(#skin)'),
    path('M135 278 L143 282 141 292 M129 284 L134 294', stroke='#6d4933', sw=1.7),
    # Bare head: jaw, ear, brow, nose, asymmetrical dark hair, beard.
    path('M176 122 Q177 104 201 105 L222 116 225 139 232 150 224 156 222 165 209 176 190 174 179 160 173 144Z', 'url(#skin)', sw=3.5),
    path('M175 134 Q164 127 166 145 L176 154 181 145Z', 'url(#skin)', sw=2),
    path('M173 137 L171 144 177 146', stroke='#775439', sw=1.8),
    path('M174 140 L171 123 Q168 105 188 99 L205 101 215 107 225 107 230 119 219 126 209 117 199 122 188 117 181 128 182 144Z', 'url(#hair)', sw=3.5),
    path('M178 119 L184 108 195 105 M194 115 L202 109 214 115 M217 119 L222 114', stroke='#9b8058', sw=1.6),
    path('M182 149 L192 157 203 152 213 157 225 152 223 169 211 179 193 177 182 164Z', 'url(#hair)', sw=2),
    path('M186 159 L192 170 M196 161 L202 174 M208 162 L208 174 M218 159 L215 168', stroke='#8c7555', sw=1.6),
    path('M187 133 L196 131 M209 131 L218 133', stroke='#443e2c', sw=3),
    path('M187 137 L194 137 M210 137 L216 138', stroke='#171f19', sw=2),
    path('M203 137 L199 150 205 151 M206 158 L216 158', stroke='#624a32', sw=2),
    path('M186 145 L191 146 M213 145 L219 145 M202 126 L203 133', stroke='#ead0a1', sw=1.5),
    # Weapon hand encloses every weapon's fixed grip at (276,279).
    path('M270 259 Q279 255 286 264 L288 281 280 290 269 286 263 275Z', 'url(#skin)', sw=3),
    path('M275 266 L282 267 M272 273 L282 275 M273 281 L282 281', stroke='#63462e', sw=1.8),
])
write('foundation', foundation)

# Shared sockets but materially different shells, not just recolors.
cap = ''.join([
    path('M170 129 Q170 106 195 99 Q216 97 225 114 L230 129 217 134 194 129 177 136Z', 'url(#metal)', sw=3.5),
    path('M174 127 L193 123 212 126 228 126 228 133 212 134 192 130 175 138Z', 'url(#tone)'),
    path('M195 101 Q187 110 190 125', stroke='#e9ecd9', sw=3),
    path('M205 104 L215 118', stroke='#66716a', sw=1.5),
] + [rivet(x, y) for x, y in [(179,130),(192,127),(206,130),(220,130)]])
write('head_cap', cap)
nasal = ''.join([
    path('M169 129 Q168 112 179 104 L200 94 218 108 228 129 214 136 192 131 175 137Z','url(#metal)',sw=3.5),
    path('M199 96 L198 125 207 130 207 154 200 159 197 134 174 139 172 131 191 126 193 100Z','url(#tone)',sw=2),
    path('M176 129 L190 125 M209 128 L224 130 M201 135 L202 151',stroke='#f6eed3',sw=1.5),
] + [rivet(x,y) for x,y in [(178,133),(190,131),(216,132),(199,108)]])
write('head_nasal', nasal)
kettle = ''.join([
    path('M169 126 L174 108 Q191 93 207 100 L221 110 226 126Z','url(#metal)',sw=3),
    path('M174 120 Q163 122 152 136 L163 144 191 136 214 137 237 145 245 137 Q236 128 221 123 L199 121Z','url(#metal)',sw=3.5),
    path('M156 137 L175 131 193 130 214 131 240 139',stroke='#edf0dc',sw=2),
    path('M192 103 L187 119 M203 104 L214 120',stroke='#e4e6ce',sw=1.5),
] + [rivet(x,y,1.5) for x,y in [(177,124),(187,124),(205,126),(219,129)]])
write('head_kettle', kettle)
bascinet = ''.join([
    path('M169 136 L172 113 181 102 199 87 Q219 103 227 120 L232 157 223 167 216 151 217 133 198 129 181 138 185 159 175 158Z','url(#metal)',sw=3.5),
    path('M199 89 Q190 108 193 128 M177 116 L176 129 M223 139 L226 158',stroke='#edf0da',sw=2.5),
    path('M211 109 L217 118 M175 147 L181 149',stroke='#68766e',sw=2),
] + [rivet(x,y) for x,y in [(177,133),(219,133),(225,157)]])
write('head_bascinet', bascinet)
# Armor masters use neutral mineral/cloth tones so the catalog's actual color
# can multiply the sprite without throwing away its shading and contour lines.
def clipped(shape, marks):
    return f'<defs><clipPath id="cut"><path d="{shape}"/></clipPath></defs><g clip-path="url(#cut)">{marks}</g>'

belt = ''.join([
    path('M148 282 Q183 294 231 282 L234 295 Q185 307 147 294Z','url(#leather)',sw=2.5),
    path('M178 290 L197 289 198 302 180 303Z','url(#gold)',sw=2),
    path('M183 293 L194 293 194 299 183 300Z','#37382b',sw=1),
    path('M188 296 L198 296',stroke='#ddc998',sw=1.5),
    path('M160 297 L170 297 168 334 159 339 156 331Z','url(#leather)',sw=2),
    path('M161 309 L166 310 M160 317 L165 318',stroke='#ae9270',sw=1.4),
    path('M211 300 L232 296 237 321 230 332 211 329 206 319Z','url(#leather)',sw=2),
    path('M209 306 L231 303 232 315 219 321 208 318Z','url(#leather)',sw=1.8),
    rivet(220,315),
])
write('foundation', foundation + belt)

shirt = 'M176 178 L192 187 209 180 Q235 179 246 203 L260 240 281 260 268 277 246 264 233 242 230 259 240 315 222 327 204 322 190 334 168 327 143 329 147 273 144 242 137 252 146 270 124 279 115 250 129 211 142 190Z'
quilt_marks = ''.join(path(f'M110 {y} L265 {y+70}',stroke='#566054',sw=1.8) + path(f'M120 {y+70} L260 {y}',stroke='#f0e9d0',sw=1.2) for y in range(150,345,14))
write('body_quilt', path(shirt,'url(#tone)',sw=4) + clipped(shirt,quilt_marks) + path('M175 181 L191 200 208 183 M158 209 L153 249 M220 214 L214 254 M166 310 L164 323 M214 308 L220 320',stroke='#eef0d8',sw=2) + belt)

mail_shapes = {
    'mail_short': 'M175 179 L193 188 210 180 237 187 249 216 234 230 222 218 230 301 218 313 157 314 146 304 153 225 141 236 126 220 140 191Z',
    'mail': 'M175 179 L191 187 211 180 238 188 250 218 258 239 280 260 267 275 245 262 228 234 231 310 215 326 198 316 178 325 144 317 148 239 139 252 145 270 124 278 116 249 130 211 141 190Z',
    'mail_long': 'M175 179 L191 187 211 180 238 188 250 218 258 239 280 260 267 275 245 262 228 234 230 290 245 341 226 356 203 350 191 322 181 351 152 356 137 343 147 290 148 239 139 252 145 270 124 278 116 249 130 211 141 190Z'
}
def rings(x0, y0, x1, y1):
    return ''.join(ellipse(x+(3 if (y-y0)//5%2 else 0),y,2.7,1.9,'none','#3d4842',1.1) + path(f'M{x-1.8} {y-.6} Q{x} {y-2.7} {x+1.9} {y-.6}',stroke='#e3e7d6',sw=.75) for y in range(y0,y1,5) for x in range(x0,x1,6))
for family, shape in mail_shapes.items():
    write('body_'+family,path(shape,'url(#metal)',sw=4)+clipped(shape,rings(112,177,286,360))+path('M175 180 L192 199 210 181 M156 221 Q166 244 156 266 M220 217 L214 262',stroke='#303d36',sw=3)+belt)

outer = 'M164 181 L179 177 192 188 209 179 226 183 237 205 226 230 228 269 238 309 219 322 191 313 165 322 144 312 154 268 153 221 146 211 149 191Z'
leather_marks = ''.join([
    path('M161 184 L165 220 158 277 M218 187 L216 226 222 275 M159 308 L181 302 M205 304 L224 310',stroke='#ece6cc',sw=2),
    path('M178 188 L177 274 M204 191 L205 276',stroke='#59604e',sw=3),
    path('M183 211 L201 213 199 225 182 222Z','#767d6b',sw=1.4),
    path('M172 235 L208 232 210 244 170 246Z','#596253',sw=2),
    rivet(181,239),rivet(201,237),
    path('M154 291 L161 281 M209 265 L216 256 M165 207 L169 201',stroke='#eee8d0',sw=1),
])
write('body_leather',path(outer,'url(#tone)',sw=4)+leather_marks+belt)
plate = 'M164 182 L177 177 Q193 196 211 179 L226 183 Q223 203 234 216 L232 246 220 276 232 291 215 306 188 302 158 309 146 294 155 275 149 240 152 215 Q164 200 164 182Z'
write('body_plate',path(plate,'url(#metal)',sw=4)+''.join([
    path('M178 183 Q194 202 211 185 M193 200 Q183 235 187 276 M157 221 Q169 241 181 241 M203 237 Q221 236 229 223',stroke='#f3f1d9',sw=2.4),
    path('M157 273 Q185 287 220 273 L221 283 Q189 296 154 284Z','url(#metal)',sw=2),
    path('M153 290 Q183 302 227 291 M162 254 L176 248 M209 218 L216 212 M211 254 L221 248',stroke='#53645b',sw=1.8),
    path('M157 245 L160 244 M168 258 L177 255 M207 234 L219 229',stroke='#eef2df',sw=1.3),
    rivet(156,220),rivet(226,218),rivet(162,291),rivet(219,290),
])+belt)
write('body_brigandine',path(outer,'url(#tone)',sw=4)+clipped(outer,''.join(path(f'M149 {y} Q190 {y+9} 235 {y-2}',stroke='#606656',sw=1.5) for y in range(210,321,14)))+''.join(rivet(x,y,1.7) for y in range(202,286,13) for x in range(165,221,12))+path('M190 192 L188 282',stroke='#3c4a3e',sw=3)+belt)
scale_marks = ''.join(path(f'M{x-5} {y} Q{x} {y+14} {x+5} {y}Z','url(#metal)','#536050',1) for y in range(193,321,10) for x in range(148+(5 if (y-193)//10%2 else 0),239,10))
write('body_scale',path(outer,'url(#tone)',sw=4)+clipped(outer,scale_marks)+path('M176 181 Q190 197 208 183',stroke='#e8ebcf',sw=4)+belt)
patches = ''.join(path(d,'url(#metal)',sw=2.2) for d in ['M158 203 L181 196 187 236 155 242Z','M192 199 L219 201 230 232 198 236Z','M159 250 L185 241 188 278 154 280Z','M195 245 L225 240 221 278 196 279Z','M153 296 L178 289 182 311 150 315Z','M198 290 L222 287 234 309 208 316Z'])
write('body_patched',path(outer,'url(#tone)',sw=4)+patches+''.join(rivet(x,y) for x,y in [(162,210),(178,207),(160,233),(222,224),(204,210),(166,259),(176,270),(203,253),(216,268)])+belt)

write('body_shoulders',''.join([
    path('M169 181 Q145 178 132 196 L129 213 145 224 165 211 177 194Z','url(#metal)',sw=3.5),
    path('M133 204 L146 215 165 203 M138 196 L150 204 169 194',stroke='#e2ead9',sw=2),
    path('M217 181 Q242 180 251 204 L248 218 233 222 220 206 209 195Z','url(#metal)',sw=3.5),
    path('M223 192 L241 203 246 204 M226 202 L239 213 247 212',stroke='#e2ead9',sw=2),
    rivet(143,191),rivet(162,189),rivet(227,189),rivet(243,201),
]))
write('body_collar',path('M179 172 Q194 185 213 173 L226 184 214 205 193 212 168 201 161 186Z','url(#metal)',sw=3)+path('M176 181 Q194 200 218 183 M175 197 L189 205 213 198',stroke='#e6ead7',sw=2)+rivet(171,189)+rivet(219,188))
for family, length in [('tabard',335),('surcoat',361)]:
    shape = f'M173 180 L190 189 210 181 220 190 212 268 228 {length-10} 204 {length} 191 {length-29} 181 {length} 153 {length-8} 169 267 163 194Z'
    folds = ''.join([path(f'M177 206 Q181 244 176 279 L167 {length-11}',stroke='#f3edd2',sw=3),path(f'M204 199 L197 274 210 {length-15}',stroke='#606a58',sw=5),path(f'M192 299 L188 {length-24}',stroke='#d2d6ba',sw=2),path('M178 222 L201 220 M189 211 L189 240',stroke='#ebe6c9',sw=4)])
    write('body_'+family,path(shape,'url(#tone)',sw=3.5)+folds+belt)
write('body_sash',path('M156 184 L171 180 226 276 232 306 216 309 211 279Z','url(#tone)',sw=3)+path('M162 185 L216 279 219 302',stroke='#f6edcd',sw=2)+path('M215 294 L230 298 244 340 232 335 225 343Z','url(#tone)',sw=2))

for family, hem in [('cloak',450),('cape',345)]:
    shape = f'M177 173 Q153 175 142 195 L125 259 93 {hem-9} 112 {hem} 134 {hem-7} 154 {hem+2} 178 {hem-13} 201 {hem-8} 231 {hem-23} 247 {hem-16} 232 240 225 188 211 174Z'
    folds = ''.join(path(d,stroke=c,sw=w) for d,c,w in [
        (f'M163 189 Q151 262 110 {hem-13}','#e3e5cc',3),
        (f'M174 197 Q172 296 146 {hem-11}','#3e4c40',8),
        (f'M186 209 L180 {hem-19}','#d3d6bd',3),
        (f'M213 207 Q206 307 230 {hem-25}','#465448',9),
        (f'M151 {hem-24} L155 {hem-5}','#e0e2c8',2),
    ])
    write('body_'+family,path(shape,'url(#tone)',sw=4)+folds+path(f'M96 {hem-12} L112 {hem-5} 134 {hem-13} 154 {hem-4} 178 {hem-19}',stroke='#adb99e',sw=1.5))
fur = 'M176 171 L188 177 211 169 224 179 235 177 237 187 252 191 248 202 260 210 247 213 245 226 233 216 224 220 215 204 204 211 190 196 179 207 169 202 157 219 146 215 135 223 134 211 123 211 131 199 128 191 144 190 152 179 163 181Z'
fur_hairs = ''.join(path(f'M{x} {y} l-3 8 6 -2 -2 7',stroke='#525f51' if x%3 else '#eff0db',sw=1.6) for x,y in [(x,184+(x*7)%23) for x in range(138,246,5)])
write('body_fur',path(fur,'url(#tone)',sw=3)+clipped(fur,fur_hairs))

# Head underlayers leave the original face visible; no fake head equipment is
# selected from legacy appearance, aggregate helmet hit points, or unit identity.
liner = 'M169 145 Q160 114 181 103 L203 101 Q224 105 228 129 L220 133 216 117 200 111 184 120 181 143 187 161 180 168 169 157Z'
write('head_liner',path(liner,'url(#tone)',sw=3)+clipped(liner,''.join(path(f'M{x} 104 L{x+4} 168',stroke='#65705f',sw=1.5) for x in range(162,230,7)))+path('M180 160 Q187 177 207 173',stroke='#dbe0c3',sw=2))
hood = 'M167 142 Q156 113 178 97 Q201 88 219 108 L231 133 224 144 218 125 208 115 190 113 182 127 184 149 194 174 215 174 220 164 231 173 239 191 216 203 194 192 174 203 151 191 165 165Z'
write('head_hood',path(hood,'url(#tone)',sw=3.5)+path('M171 135 Q165 114 179 104 M183 169 L177 191 M219 181 L226 190 M163 185 L170 174',stroke='#edf0d5',sw=2)+path('M177 142 L173 159 185 180 195 184',stroke='#56634f',sw=3))
coif = 'M170 142 Q162 114 180 103 L202 99 Q222 105 227 128 L219 137 215 119 199 114 185 124 182 146 190 173 209 176 221 160 227 170 238 190 217 202 194 191 173 201 152 188 165 163Z'
curtain = 'M168 138 L181 142 186 164 194 178 211 177 219 162 222 136 230 141 231 173 241 194 218 206 194 197 173 205 153 190 164 166Z'
for family, shape in [('coif',coif),('curtain',curtain)]:
    write('head_'+family,path(shape,'url(#metal)',sw=3)+clipped(shape,rings(150,100,244,207))+path('M174 146 Q174 169 187 185 M224 154 L220 177',stroke='#d5ddcb',sw=2))
write('head_visor',path('M178 135 L194 131 214 132 229 145 227 160 208 173 187 169 177 153Z','url(#metal)',sw=3)+path('M183 139 L197 138 M205 138 L218 139',stroke='#1b2921',sw=3)+path('M200 142 L197 158 209 164',stroke='#eff1da',sw=2)+''.join(path(f'M{x} 151 L{x} 155',stroke='#38473a',sw=1.5) for x in range(206,223,4))+rivet(180,138)+rivet(225,141))
write('head_cheeks',path('M174 136 L183 137 188 160 180 168 172 157Z','url(#metal)',sw=2.5)+path('M217 137 L227 138 229 155 220 166 215 158Z','url(#metal)',sw=2.5)+path('M176 143 L180 158 M220 142 L221 157',stroke='#e7eed9',sw=1.5)+rivet(177,140)+rivet(222,141))
plume = 'M197 102 Q187 83 197 71 L211 64 Q229 59 249 77 L243 78 254 90 241 86 249 99 234 91 236 104 224 91 212 84 206 86 205 103Z'
write('head_plume',path(plume,'url(#tone)',sw=3)+path('M201 97 Q195 81 208 76 Q226 71 243 88 M207 72 L219 73 M216 80 L233 88',stroke='#ece8cf',sw=1.5))
write('head_wrap',path('M171 120 Q194 113 224 123 L227 134 204 128 190 127 172 134Z','url(#tone)',sw=2.5)+path('M174 124 Q194 118 223 127 M182 127 L200 122',stroke='#eff0d7',sw=1.5)+path('M174 132 L179 136 167 170 158 173 162 159Z','url(#tone)',sw=2))
write('head_crest',path('M195 102 L189 91 190 78 201 72 209 82 206 100Z','url(#metal)',sw=3)+path('M198 79 L199 99',stroke='#faf0cc',sw=3))
# Main-hand artwork. The grip is at the same physical hand in every family.
grip = path('M272 264 L282 265 287 271 284 283 277 288 270 283 267 274Z','url(#skin)',sw=2.5)+path('M274 269 L283 272 M272 275 L282 277 M273 282 L280 283',stroke='#654930',sw=1.6)
def haft(d, width=7):
    return path(d,stroke='#1d251e',sw=width+3)+path(d,stroke='#896f48',sw=width)+path(d,stroke='#c3a472',sw=1.3)
def weapon(name, art):
    write('weapon_'+name,art+grip)
weapon('sword',''.join([
    path('M277 255 L319 119 330 103 330 128 289 259Z','url(#metal)',sw=3),
    path('M325 118 L283 251',stroke='#f0efd8',sw=2),
    path('M277 259 L267 297',stroke='#21281f',sw=10),
    path('M277 259 L267 297',stroke='#78624a',sw=6),
    path('M269 285 L276 287 M270 278 L278 280 M273 270 L280 273',stroke='#b9996b',sw=1.3),
    path('M264 251 Q280 259 297 262 L299 254 Q284 251 268 242Z','url(#gold)',sw=2),
    ellipse(265,302,7,7,'url(#metal)'),
]))
weapon('spear',haft('M264 402 L300 85',7)+path('M300 89 L293 69 306 18 315 67 308 89Z','url(#metal)',sw=3)+path('M306 23 L302 82',stroke='#f2efd8',sw=2)+path('M291 91 L309 93 M293 97 L307 99 M292 105 L306 107',stroke='#4c4334',sw=3)+path('M298 79 L312 80',stroke='#a68e60',sw=4))
weapon('axe',haft('M264 313 L306 146',9)+path('M301 157 Q328 154 344 130 L355 139 363 179 350 190 Q326 175 300 183Z','url(#metal)',sw=3.5)+path('M344 132 Q351 159 358 178',stroke='#eef2db',sw=4)+path('M317 162 L330 162 M317 172 L335 176',stroke='#5d6f63',sw=1.5)+path('M296 155 L310 160 305 184 291 179Z','url(#metal)',sw=2))
weapon('bow',path('M229 130 Q222 159 247 193 Q296 266 267 335 Q252 368 254 409',stroke='#20271f',sw=11)+path('M229 130 Q222 159 247 193 Q296 266 267 335 Q252 368 254 409',stroke='#ac8c56',sw=6)+path('M229 133 Q227 160 250 194 Q292 262 270 323',stroke='#e0c58c',sw=1.8)+path('M229 131 L254 409',stroke='#e1d9b3',sw=1.5)+path('M276 254 Q280 270 277 284',stroke='#392f25',sw=8)+path('M273 259 L280 259 M273 267 L281 267 M274 278 L281 278',stroke='#b59b6c',sw=1.5))
weapon('mace',haft('M265 313 L302 172',8)+path('M300 170 L286 159 286 139 300 128 310 130 322 146 316 162Z','url(#metal)',sw=3)+path('M302 130 L299 165 M310 137 L306 164 M289 143 L294 157',stroke='#ecedce',sw=3)+ellipse(304,126,5,4,'url(#metal)'))
weapon('hammer',haft('M266 314 L303 166',8)+path('M285 146 L311 151 310 172 281 165Z','url(#metal)',sw=3)+path('M309 152 L324 152 342 143 337 153 313 167Z','url(#metal)',sw=3)+path('M283 150 L306 156 M289 157 L302 159',stroke='#edf0d6',sw=2))
weapon('dagger',path('M280 267 L291 211 300 199 300 218 290 269Z','url(#metal)',sw=2.5)+path('M296 211 L285 260',stroke='#f6f1da',sw=1.5)+haft('M283 269 L272 302',6)+ellipse(272,302,6,5,'url(#gold)')+path('M272 264 L296 271',stroke='#bba16e',sw=5))
weapon('polearm',haft('M264 405 L304 73',7)+path('M302 83 L307 25 Q321 47 320 65 L335 58 334 69 319 81 316 107 308 111 309 88Z','url(#metal)',sw=3)+path('M310 30 L309 82 M321 72 L332 65',stroke='#eef1d8',sw=2))
weapon('crossbow',path('M259 321 L270 269 292 205 308 209 288 281 278 324Z','url(#leather)',sw=3.5)+path('M289 221 Q268 208 242 231 M289 221 Q319 219 336 244',stroke='#19261c',sw=9)+path('M289 221 Q268 208 242 231 M289 221 Q319 219 336 244',stroke='#a4b3a3',sw=5)+path('M242 231 L280 254 336 244',stroke='#ded9ba',sw=1.5)+path('M291 210 L273 266',stroke='#d0baa0',sw=2)+ellipse(280,263,5,7,'url(#metal)')+path('M269 292 L275 283 281 285',stroke='#d1c3a2',sw=3))
weapon('bolas',haft('M275 275 Q290 225 267 189 M275 275 Q316 259 325 220 M275 275 Q306 296 329 289',2)+ellipse(266,185,10,12,'url(#metal)')+ellipse(326,215,10,11,'url(#metal)')+ellipse(334,290,12,10,'url(#metal)')+path('M261 177 L272 187 M319 210 L333 220 M327 285 L339 294',stroke='#ede4c5',sw=2))

# Wooden shields have shaped metal rims, rivets, grain and rubbed paint rather
# than a uniform colored disc. The actual offhand definition chooses the art.
kite = 'M94 229 Q131 218 171 237 L170 295 Q166 349 131 389 Q97 342 91 290Z'
kite_inner = 'M101 237 Q132 228 164 242 L163 294 Q159 339 131 375 Q104 337 99 289Z'
shield_marks = ''.join(path(f'M{x} 229 Q{x-8} 296 {x+2} 377',stroke='#473c2b',sw=2) for x in range(106,164,12))
write('shield_kite',path(kite,'url(#metal)',sw=4)+path(kite_inner,'url(#leather)',sw=2)+clipped(kite_inner,shield_marks+path('M101 242 L126 235 127 363 113 342Z','#53635a','none')+path('M131 235 L145 236 140 357 132 372Z','#c6ba8d','none')+path('M101 273 L163 279 162 291 101 286Z','#c6ba8d','none')+path('M112 246 L120 260 M143 306 L153 294 M116 316 L121 329 M147 251 L155 265',stroke='#d3bd8c',sw=1.5))+''.join(rivet(x,y) for x,y in [(100,236),(122,231),(145,235),(167,242),(166,280),(160,319),(144,356),(102,278),(108,320),(124,360)]))
for family,radius in [('round',55),('buckler',35)]:
    cy=292 if family == 'round' else 278
    outer = ellipse(132,cy,radius,radius,'url(#metal)',sw=3.5)
    inner = ellipse(132,cy,radius-7,radius-7,'url(#leather)',sw=2)
    shape = f'M{132-radius+7} {cy} a{radius-7} {radius-7} 0 1 0 {2*(radius-7)} 0 a{radius-7} {radius-7} 0 1 0 {-2*(radius-7)} 0'
    grain = ''.join(path(f'M{x} {cy-radius} Q{x-5} {cy} {x+3} {cy+radius}',stroke='#302e22',sw=1.6) for x in range(132-radius+12,132+radius-5,11))
    paint = path(f'M{132-radius} {cy-15} L{132+radius} {cy+7} {132+radius} {cy+25} {132-radius} {cy+3}Z','#82907a','none')
    boss = ellipse(132,cy,14 if radius>40 else 10,13 if radius>40 else 10,'url(#metal)',sw=2.5)+ellipse(128,cy-4,4,3,'#d9dec6','none',0)
    rivets=''.join(rivet(132+dx,cy+dy,1.8) for dx,dy in [(0,-radius+4),(0,radius-4),(-radius+4,0),(radius-4,0),(-int(radius*.65),-int(radius*.65)),(int(radius*.65),int(radius*.65)),(-int(radius*.65),int(radius*.65)),(int(radius*.65),-int(radius*.65))])
    write('shield_'+family,outer+inner+clipped(shape,paint+grain)+boss+rivets)
# A soft ground contact blob plus restrained projected head/torso/leg silhouette.
# This does not pretend to be a light-simulated shadow of the current equipment.
shadow_defs = '<defs><radialGradient id="shadow"><stop stop-color="#111b13" stop-opacity=".56"/><stop offset=".56" stop-color="#111b13" stop-opacity=".30"/><stop offset="1" stop-color="#111b13" stop-opacity="0"/></radialGradient></defs>'
shadow_shape = path('M119 262 L145 240 180 217 179 191 Q171 178 185 166 Q200 157 207 168 L214 179 237 185 235 211 221 226 219 250 250 273 235 281 205 260 192 240 168 252 137 274Z','#111b13','none',0,extra='opacity=".13"')
write('ground_shadow',shadow_defs+ellipse(192,256,114,61,'url(#shadow)','none',0)+shadow_shape)
print('Generated original SVG masters and PNG companions in', ROOT)
