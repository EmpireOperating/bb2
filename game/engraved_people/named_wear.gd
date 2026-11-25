extends RefCounted
## Fitted pigments only. A Named item keeps its original cut key for joint,
## contact, grip, projectile, wear, sleeve, frame and depth dispatch.
const Named = preload("res://src/named_equipment.gd")
const Catalog = preload("res://hollow_campaign/catalog.gd")
const MAX_BYTES := 550000
const SPECS := {
 "heavy_crossbow": {
  "bytes": 79181,
  "catalog_slot": "weapon",
  "channel": "weapon",
  "part": "weapon/heavy-crossbow",
  "path": "res://engraved_people/named_wear/heavy-crossbow-fitted.png",
  "physical_slot": "weapon",
  "rows": {
   "idle": [
    229,
    145,
    1,
    120,
    169,
    111
   ],
   "utility/recover/0": [
    224,
    155,
    360,
    1,
    174,
    115
   ],
   "utility/recover/1": [
    218,
    170,
    1,
    1,
    177,
    117
   ],
   "utility/switch/0": [
    222,
    149,
    536,
    1,
    174,
    114
   ],
   "utility/switch/1": [
    217,
    158,
    180,
    1,
    178,
    117
   ]
  },
  "sha256": "07eb1afacb786049f53d28ec164bc0187c28d1c3cc8d52bdd393652840b0de3b",
  "size": [
   768,
   232
  ]
 },
 "hm_trial_v1:additional_fighting_axe": {
  "bytes": 468983,
  "catalog_slot": "weapon",
  "channel": "weapon",
  "part": "weapon/t1-fighting-axe",
  "path": "res://engraved_people/named_wear/fighting-axe-fitted.png",
  "physical_slot": "weapon",
  "rows": {
   "attack/0": [
    74,
    99,
    1,
    329,
    97,
    154
   ],
   "attack/1": [
    44,
    111,
    397,
    633,
    131,
    129
   ],
   "attack/2": [
    148,
    115,
    68,
    165,
    61,
    160
   ],
   "attack/3": [
    196,
    192,
    156,
    885,
    162,
    65
   ],
   "attack/4": [
    209,
    211,
    612,
    766,
    151,
    79
   ],
   "attack/5": [
    180,
    206,
    320,
    885,
    161,
    63
   ],
   "attack/6": [
    158,
    139,
    595,
    485,
    121,
    136
   ],
   "attack/7": [
    139,
    111,
    131,
    165,
    60,
    160
   ],
   "idle": [
    93,
    100,
    193,
    165,
    79,
    160
   ],
   "melee/high/0": [
    110,
    82,
    1,
    1,
    69,
    162
   ],
   "melee/high/1": [
    76,
    63,
    1,
    633,
    130,
    131
   ],
   "melee/high/2": [
    155,
    40,
    72,
    1,
    66,
    162
   ],
   "melee/high/3": [
    231,
    69,
    235,
    485,
    107,
    144
   ],
   "melee/high/4": [
    250,
    90,
    143,
    766,
    150,
    108
   ],
   "melee/high/5": [
    234,
    114,
    451,
    766,
    159,
    84
   ],
   "melee/high/6": [
    174,
    91,
    100,
    329,
    62,
    154
   ],
   "melee/level/0": [
    110,
    82,
    140,
    1,
    69,
    162
   ],
   "melee/level/1": [
    76,
    63,
    133,
    633,
    130,
    131
   ],
   "melee/level/2": [
    155,
    40,
    211,
    1,
    66,
    162
   ],
   "melee/level/3": [
    219,
    119,
    295,
    766,
    154,
    100
   ],
   "melee/level/4": [
    246,
    175,
    483,
    885,
    160,
    62
   ],
   "melee/level/5": [
    233,
    196,
    1,
    885,
    153,
    67
   ],
   "melee/level/6": [
    174,
    91,
    164,
    329,
    62,
    154
   ],
   "melee/low/0": [
    110,
    82,
    279,
    1,
    69,
    162
   ],
   "melee/low/1": [
    76,
    63,
    265,
    633,
    130,
    131
   ],
   "melee/low/2": [
    155,
    40,
    350,
    1,
    66,
    162
   ],
   "melee/low/3": [
    210,
    192,
    1,
    954,
    157,
    60
   ],
   "melee/low/4": [
    241,
    200,
    1,
    766,
    140,
    117
   ],
   "melee/low/5": [
    231,
    199,
    467,
    485,
    126,
    139
   ],
   "melee/low/6": [
    174,
    91,
    228,
    329,
    62,
    154
   ],
   "melee/near_high/0": [
    110,
    82,
    418,
    1,
    69,
    162
   ],
   "melee/near_high/1": [
    76,
    49,
    1,
    485,
    115,
    146
   ],
   "melee/near_high/2": [
    155,
    40,
    489,
    1,
    66,
    162
   ],
   "melee/near_high/3": [
    109,
    72,
    530,
    633,
    136,
    122
   ],
   "melee/near_high/4": [
    135,
    34,
    413,
    165,
    91,
    157
   ],
   "melee/near_high/5": [
    109,
    45,
    420,
    329,
    108,
    151
   ],
   "melee/near_high/6": [
    174,
    91,
    292,
    329,
    62,
    154
   ],
   "melee/near_low/0": [
    110,
    82,
    557,
    1,
    69,
    162
   ],
   "melee/near_low/1": [
    76,
    49,
    118,
    485,
    115,
    146
   ],
   "melee/near_low/2": [
    155,
    40,
    628,
    1,
    66,
    162
   ],
   "melee/near_low/3": [
    184,
    182,
    530,
    329,
    112,
    149
   ],
   "melee/near_low/4": [
    183,
    208,
    696,
    1,
    65,
    162
   ],
   "melee/near_low/5": [
    175,
    215,
    274,
    165,
    75,
    160
   ],
   "melee/near_low/6": [
    174,
    91,
    356,
    329,
    62,
    154
   ],
   "utility/recover/0": [
    90,
    115,
    506,
    165,
    97,
    156
   ],
   "utility/recover/1": [
    95,
    129,
    644,
    329,
    109,
    149
   ],
   "utility/switch/0": [
    114,
    93,
    1,
    165,
    65,
    162
   ],
   "utility/switch/1": [
    144,
    89,
    351,
    165,
    60,
    158
   ],
   "utility/switch_shield/0": [
    80,
    110,
    605,
    165,
    95,
    156
   ],
   "utility/switch_shield/1": [
    59,
    139,
    344,
    485,
    121,
    141
   ]
  },
  "sha256": "7a8691ad7eeda8e48ed06de30087a4d4e1cb5e86edca8c9482e65b2b8f49a317",
  "size": [
   768,
   1015
  ]
 },
 "hm_trial_v1:headwear-03-iron-skullcap": {
  "bytes": 7557,
  "catalog_slot": "head",
  "channel": "head",
  "part": "head/t1-skullcap",
  "path": "res://engraved_people/named_wear/skullcap-fitted.png",
  "physical_slot": "head/shell",
  "rows": {
   "idle": [
    201,
    43,
    1,
    1,
    80,
    51
   ]
  },
  "sha256": "83abe0fc3b17e7d551cad8a4b31469e439fb6638c8d7a39eac2624ac5b2f9330",
  "size": [
   768,
   53
  ]
 },
 "hm_trial_v1:headwear-04-kettle-helm": {
  "bytes": 7657,
  "catalog_slot": "head",
  "channel": "head",
  "part": "head/t1-kettle",
  "path": "res://engraved_people/named_wear/kettle.png",
  "physical_slot": "head/shell",
  "rows": {
   "idle": [
    180,
    39,
    0,
    0,
    123,
    62
   ]
  },
  "sha256": "6ec44d6ead4ff29a8783a208ffc33ea97e046da53fe50b49f97a40d2f26a5268",
  "size": [
   123,
   62
  ]
 },
 "hm_trial_v1:old24-archer_heavy": {
  "bytes": 281547,
  "catalog_slot": "weapon",
  "channel": "weapon",
  "part": "weapon/t1-heavy-hunting-bow",
  "path": "res://engraved_people/named_wear/hunting-bow-fitted.png",
  "physical_slot": "weapon",
  "rows": {
   "aimed_shot/0": [
    235,
    93,
    298,
    520,
    154,
    232
   ],
   "aimed_shot/1": [
    263,
    62,
    146,
    266,
    120,
    249
   ],
   "aimed_shot/2": [
    236,
    48,
    1,
    266,
    143,
    252
   ],
   "bow_alt/0": [
    268,
    79,
    102,
    1,
    101,
    260
   ],
   "bow_alt/1": [
    270,
    43,
    205,
    1,
    105,
    257
   ],
   "bow_alt/2": [
    260,
    41,
    531,
    1,
    115,
    254
   ],
   "bow_alt/3": [
    230,
    45,
    518,
    266,
    156,
    245
   ],
   "bow_alt/4": [
    303,
    28,
    1,
    1,
    99,
    263
   ],
   "bow_alt/5": [
    284,
    47,
    422,
    1,
    107,
    256
   ],
   "bow_alt/6": [
    266,
    78,
    312,
    1,
    108,
    257
   ],
   "bow_alt/7": [
    242,
    108,
    268,
    266,
    123,
    248
   ],
   "idle": [
    242,
    108,
    393,
    266,
    123,
    248
   ],
   "utility/recover/0": [
    236,
    114,
    1,
    520,
    144,
    238
   ],
   "utility/recover/1": [
    230,
    121,
    454,
    520,
    159,
    229
   ],
   "utility/switch/0": [
    238,
    108,
    147,
    520,
    149,
    236
   ],
   "utility/switch/1": [
    235,
    111,
    1,
    760,
    184,
    211
   ]
  },
  "sha256": "a5dc025a3a01603d10097a478caca9cb09717f7c5535e678157e96966673f5d1",
  "size": [
   768,
   972
  ]
 },
 "hm_trial_v1:old24-archer_weapon": {
  "bytes": 271921,
  "catalog_slot": "weapon",
  "channel": "weapon",
  "part": "weapon/t1-ash-longbow",
  "path": "res://engraved_people/named_wear/ash-longbow-fitted.png",
  "physical_slot": "weapon",
  "rows": {
   "aimed_shot/0": [
    225,
    65,
    316,
    588,
    171,
    266
   ],
   "aimed_shot/1": [
    256,
    34,
    593,
    1,
    125,
    285
   ],
   "aimed_shot/2": [
    236,
    26,
    266,
    301,
    140,
    280
   ],
   "bow_alt/0": [
    264,
    50,
    1,
    1,
    104,
    298
   ],
   "bow_alt/1": [
    266,
    15,
    107,
    1,
    106,
    294
   ],
   "bow_alt/2": [
    260,
    16,
    1,
    301,
    115,
    285
   ],
   "bow_alt/3": [
    230,
    25,
    161,
    588,
    153,
    270
   ],
   "bow_alt/4": [
    282,
    6,
    118,
    301,
    146,
    283
   ],
   "bow_alt/5": [
    260,
    25,
    564,
    301,
    155,
    273
   ],
   "bow_alt/6": [
    260,
    50,
    215,
    1,
    114,
    293
   ],
   "bow_alt/7": [
    237,
    79,
    331,
    1,
    129,
    286
   ],
   "idle": [
    237,
    79,
    462,
    1,
    129,
    286
   ],
   "utility/recover/0": [
    229,
    84,
    408,
    301,
    154,
    275
   ],
   "utility/recover/1": [
    223,
    92,
    489,
    588,
    172,
    264
   ],
   "utility/switch/0": [
    232,
    79,
    1,
    588,
    158,
    273
   ],
   "utility/switch/1": [
    226,
    82,
    1,
    863,
    202,
    244
   ]
  },
  "sha256": "6f801aa485c878890e06b1132d3fa17496c379408456a531cc0382c7ce3eda16",
  "size": [
   768,
   1108
  ]
 },
 "hm_trial_v1:old24-banded_mail": {
  "bytes": 30796,
  "catalog_slot": "body",
  "channel": "body",
  "part": "torso/t1-banded-mail",
  "path": "res://engraved_people/named_wear/banded-mail-fitted.png",
  "physical_slot": "body/outer",
  "rows": {
   "idle": [
    186,
    118,
    1,
    1,
    111,
    159
   ]
  },
  "sha256": "30b854e8a55f524e8e546f577382dcd7fdd16c3bcc8e25d486e06f28900eeb70",
  "size": [
   768,
   161
  ]
 },
 "hm_trial_v1:old24-gatewarden_blade": {
  "bytes": 210350,
  "catalog_slot": "weapon",
  "channel": "weapon",
  "part": "weapon/t1-gatewardens-blade",
  "path": "res://engraved_people/named_wear/gatewarden-fitted.png",
  "physical_slot": "weapon",
  "rows": {
   "attack/0": [
    64,
    85,
    1,
    196,
    121,
    162
   ],
   "attack/1": [
    20,
    114,
    543,
    196,
    165,
    123
   ],
   "attack/2": [
    144,
    81,
    1,
    1,
    53,
    193
   ],
   "attack/3": [
    201,
    195,
    179,
    360,
    183,
    73
   ],
   "attack/4": [
    207,
    206,
    364,
    360,
    193,
    58
   ],
   "attack/5": [
    184,
    213,
    559,
    360,
    188,
    56
   ],
   "attack/6": [
    161,
    111,
    235,
    1,
    110,
    173
   ],
   "attack/7": [
    136,
    77,
    112,
    1,
    52,
    192
   ],
   "idle": [
    90,
    80,
    347,
    1,
    96,
    173
   ],
   "utility/recover/0": [
    81,
    100,
    563,
    1,
    119,
    164
   ],
   "utility/recover/1": [
    82,
    119,
    254,
    196,
    134,
    154
   ],
   "utility/riposte/0": [
    151,
    82,
    124,
    196,
    128,
    162
   ],
   "utility/riposte/1": [
    160,
    122,
    1,
    360,
    176,
    91
   ],
   "utility/switch/0": [
    120,
    65,
    166,
    1,
    67,
    186
   ],
   "utility/switch/1": [
    137,
    53,
    56,
    1,
    54,
    193
   ],
   "utility/switch_shield/0": [
    73,
    96,
    445,
    1,
    116,
    165
   ],
   "utility/switch_shield/1": [
    39,
    136,
    390,
    196,
    151,
    139
   ]
  },
  "sha256": "9e2aeea74263d5a6af25d0697e471d21d888e8572031a5795ceb04440de0b6b4",
  "size": [
   768,
   452
  ]
 },
 "hm_trial_v1:old24-quarry_estoc": {
  "bytes": 152609,
  "catalog_slot": "weapon",
  "channel": "weapon",
  "part": "weapon/t1-quarry-estoc",
  "path": "res://engraved_people/named_wear/quarry-estoc-fitted.png",
  "physical_slot": "weapon",
  "rows": {
   "idle": [
    102,
    42,
    241,
    1,
    66,
    212
   ],
   "point/0": [
    102,
    42,
    309,
    1,
    66,
    212
   ],
   "point/1": [
    121,
    13,
    1,
    1,
    43,
    220
   ],
   "point/2": [
    176,
    145,
    310,
    223,
    193,
    117
   ],
   "point/3": [
    246,
    176,
    219,
    404,
    222,
    42
   ],
   "point/4": [
    242,
    187,
    443,
    404,
    220,
    42
   ],
   "point/5": [
    189,
    175,
    505,
    223,
    206,
    87
   ],
   "point/6": [
    148,
    49,
    46,
    1,
    41,
    220
   ],
   "point/7": [
    113,
    42,
    180,
    1,
    59,
    215
   ],
   "utility/recover/0": [
    87,
    62,
    469,
    1,
    94,
    203
   ],
   "utility/recover/1": [
    84,
    80,
    565,
    1,
    113,
    194
   ],
   "utility/riposte/0": [
    150,
    76,
    141,
    223,
    167,
    151
   ],
   "utility/riposte/1": [
    159,
    135,
    1,
    404,
    216,
    62
   ],
   "utility/switch/0": [
    134,
    30,
    89,
    1,
    43,
    220
   ],
   "utility/switch/1": [
    146,
    22,
    134,
    1,
    44,
    219
   ],
   "utility/switch_shield/0": [
    79,
    56,
    377,
    1,
    90,
    205
   ],
   "utility/switch_shield/1": [
    35,
    98,
    1,
    223,
    138,
    179
   ]
  },
  "sha256": "9fde591b5aff8bea361dc257e6f96b23156120af7d3c5c12d18530d61ac53a52",
  "size": [
   768,
   467
  ]
 },
 "hm_trial_v1:old24-shieldbearer_heavy": {
  "bytes": 206962,
  "catalog_slot": "weapon",
  "channel": "weapon",
  "part": "weapon/t1-war-mace",
  "path": "res://engraved_people/named_wear/war-mace-fitted.png",
  "physical_slot": "weapon",
  "rows": {
   "blunt/0": [
    93,
    107,
    378,
    1,
    78,
    147
   ],
   "blunt/1": [
    44,
    97,
    330,
    164,
    117,
    123
   ],
   "blunt/2": [
    16,
    67,
    1,
    298,
    142,
    94
   ],
   "blunt/3": [
    246,
    180,
    288,
    298,
    156,
    63
   ],
   "blunt/4": [
    219,
    203,
    107,
    164,
    109,
    129
   ],
   "blunt/5": [
    173,
    222,
    446,
    298,
    161,
    43
   ],
   "blunt/6": [
    142,
    110,
    91,
    1,
    43,
    159
   ],
   "blunt/7": [
    102,
    106,
    306,
    1,
    70,
    152
   ],
   "idle": [
    93,
    107,
    458,
    1,
    78,
    147
   ],
   "melee/base/0": [
    146,
    86,
    47,
    1,
    42,
    160
   ],
   "melee/base/1": [
    162,
    68,
    1,
    1,
    44,
    161
   ],
   "melee/base/2": [
    179,
    105,
    218,
    164,
    110,
    127
   ],
   "melee/base/3": [
    207,
    137,
    145,
    298,
    141,
    91
   ],
   "melee/base/4": [
    238,
    192,
    1,
    394,
    160,
    42
   ],
   "melee/base/5": [
    226,
    200,
    568,
    164,
    141,
    96
   ],
   "melee/base/6": [
    176,
    98,
    240,
    1,
    64,
    155
   ],
   "utility/recover/0": [
    92,
    126,
    538,
    1,
    93,
    140
   ],
   "utility/recover/1": [
    97,
    142,
    1,
    164,
    104,
    132
   ],
   "utility/switch/0": [
    114,
    94,
    180,
    1,
    58,
    156
   ],
   "utility/switch/1": [
    143,
    83,
    136,
    1,
    42,
    159
   ],
   "utility/switch_shield/0": [
    81,
    121,
    633,
    1,
    93,
    140
   ],
   "utility/switch_shield/1": [
    59,
    156,
    449,
    164,
    117,
    120
   ]
  },
  "sha256": "7135d255ffa9216ec594b9935f923b020e26434a08949b676236d835df81f3e8",
  "size": [
   768,
   437
  ]
 },
 "hm_trial_v1:old24-ward_spear": {
  "bytes": 267728,
  "catalog_slot": "weapon",
  "channel": "weapon",
  "part": "weapon/t1-ward-spear",
  "path": "res://engraved_people/named_wear/ward-spear-fitted.png",
  "physical_slot": "weapon",
  "rows": {
   "haftthrust/0": [
    54,
    192,
    1,
    631,
    394,
    83
   ],
   "haftthrust/1": [
    11,
    208,
    1,
    1137,
    396,
    75
   ],
   "haftthrust/2": [
    37,
    180,
    1,
    716,
    394,
    83
   ],
   "haftthrust/3": [
    66,
    166,
    1,
    363,
    389,
    88
   ],
   "haftthrust/4": [
    59,
    175,
    1,
    1055,
    395,
    80
   ],
   "haftthrust/5": [
    27,
    182,
    1,
    453,
    389,
    88
   ],
   "haftthrust/6": [
    43,
    199,
    1,
    971,
    392,
    82
   ],
   "haftthrust/7": [
    59,
    192,
    1,
    801,
    391,
    83
   ],
   "idle": [
    59,
    192,
    1,
    886,
    391,
    83
   ],
   "utility/brace/0": [
    44,
    188,
    368,
    1,
    379,
    120
   ],
   "utility/brace/1": [
    52,
    157,
    1,
    543,
    389,
    86
   ],
   "utility/recover/0": [
    46,
    211,
    1,
    1214,
    396,
    75
   ],
   "utility/recover/1": [
    47,
    201,
    1,
    165,
    392,
    103
   ],
   "utility/switch/0": [
    56,
    183,
    1,
    270,
    393,
    91
   ],
   "utility/switch/1": [
    76,
    97,
    1,
    1,
    365,
    162
   ]
  },
  "sha256": "d7852986f2bd9702d8f388e7bad6b55d4ed41815e82fb0ad4e6a86486aa697cb",
  "size": [
   768,
   1290
  ]
 },
 "hm_trial_v1:twohand_sword": {
  "bytes": 481451,
  "catalog_slot": "weapon",
  "channel": "weapon",
  "part": "weapon/t1-two-handed-sword",
  "path": "res://engraved_people/named_wear/two-handed-sword-fitted.png",
  "physical_slot": "weapon",
  "rows": {
   "greatswing/0": [
    251,
    53,
    187,
    291,
    195,
    222
   ],
   "greatswing/1": [
    250,
    3,
    166,
    1,
    91,
    282
   ],
   "greatswing/2": [
    250,
    24,
    453,
    1,
    184,
    231
   ],
   "greatswing/3": [
    189,
    167,
    1,
    1525,
    287,
    80
   ],
   "greatswing/4": [
    244,
    170,
    227,
    719,
    224,
    190
   ],
   "greatswing/5": [
    204,
    193,
    1,
    1409,
    271,
    114
   ],
   "greatswing/6": [
    222,
    108,
    244,
    1094,
    247,
    161
   ],
   "greatswing/7": [
    244,
    75,
    1,
    524,
    220,
    193
   ],
   "idle": [
    244,
    75,
    223,
    524,
    220,
    193
   ],
   "sword_overhead/0": [
    235,
    14,
    384,
    291,
    218,
    198
   ],
   "sword_overhead/1": [
    219,
    -158,
    356,
    1,
    95,
    277
   ],
   "sword_overhead/10": [
    244,
    75,
    445,
    524,
    220,
    193
   ],
   "sword_overhead/2": [
    218,
    -110,
    259,
    1,
    95,
    279
   ],
   "sword_overhead/3": [
    226,
    -62,
    83,
    1,
    81,
    284
   ],
   "sword_overhead/4": [
    229,
    -19,
    1,
    1,
    80,
    288
   ],
   "sword_overhead/5": [
    213,
    71,
    1,
    719,
    224,
    191
   ],
   "sword_overhead/6": [
    217,
    182,
    1,
    1264,
    257,
    143
   ],
   "sword_overhead/7": [
    234,
    174,
    236,
    912,
    236,
    176
   ],
   "sword_overhead/8": [
    229,
    167,
    1,
    912,
    233,
    180
   ],
   "sword_overhead/9": [
    211,
    125,
    493,
    1094,
    256,
    144
   ],
   "utility/recover/0": [
    213,
    127,
    260,
    1264,
    260,
    135
   ],
   "utility/recover/1": [
    184,
    209,
    274,
    1409,
    289,
    81
   ],
   "utility/riposte/0": [
    227,
    68,
    1,
    1094,
    241,
    168
   ],
   "utility/riposte/1": [
    204,
    44,
    474,
    912,
    240,
    172
   ],
   "utility/switch/0": [
    238,
    85,
    453,
    719,
    230,
    183
   ],
   "utility/switch/1": [
    258,
    33,
    1,
    291,
    184,
    231
   ]
  },
  "sha256": "8c4f85ef294a1b8526279246a1b76c02ddf6534431b670ed1274a2a2ced776e4",
  "size": [
   768,
   1606
  ]
 },
 "march_mail": {
  "bytes": 40561,
  "catalog_slot": "body",
  "channel": "body",
  "part": "torso/t1-marchers-mail",
  "path": "res://engraved_people/named_wear/march-mail-fitted.png",
  "physical_slot": "body/outer",
  "rows": {
   "idle": [
    184,
    118,
    1,
    1,
    111,
    177
   ]
  },
  "sha256": "fca80eff530b2db552e95deaf11b8d9d566dc7e1558b437ead5a27d86261f2e6",
  "size": [
   768,
   179
  ]
 }
}
static var _catalog: Dictionary = {}
static var _sheets: Dictionary = {}

static func select(record: Dictionary, slot: String, channel: String, part: String) -> String:
 var id: Variant=record.get("definition")
 var legacy: Variant=record.get("legacy_weight",false)
 if not id is String or not SPECS.has(id) or not record.has("named") or record.has("instance_roll") or not legacy is bool or legacy:return ""
 var row: Dictionary=SPECS[id]
 if row.part!=part or row.channel!=channel or row.physical_slot!=slot:return ""
 # `id` on arms, `item` on armor parts. Do not use a display name, apparent
 # rarity, matching silhouette, or stale stash selection to identify paint.
 var field := "id" if channel=="weapon" else "item"
 var uid: Variant=record.get(field)
 if not uid is String or not uid.begins_with("item_") or not uid.substr(5).is_valid_int() or int(uid.substr(5))<=0:return ""
 if record.has("id") and record.has("item") and (not record.id is String or not record.item is String or record.id!=record.item):return ""
 if _catalog.is_empty():_catalog=Catalog.equipment()
 var d: Variant=_catalog.get(id)
 if not d is Dictionary or not d.get("slot") is String or d.slot!=row.catalog_slot:return ""
 if channel!="weapon":
  if not d.get("group") is String or not d.get("layer") is String or d.group+"/"+d.layer!=slot:return ""
 if not Named.valid(record,_catalog):return ""
 return id if _ready(id,row) else ""

static func _ready(id: String, spec: Dictionary) -> bool:
 # FileAccess is needed in the prepared ZIP (the new PNGs are raw members,
 # not imported Texture2Ds). Check the same bounded bytes before a warm hit.
 if not FileAccess.file_exists(spec.path):
  _sheets.erase(id);return false
 var file:=FileAccess.open(spec.path,FileAccess.READ)
 if file==null or file.get_length()!=spec.bytes or spec.bytes<1 or spec.bytes>MAX_BYTES:
  _sheets.erase(id);return false
 var encoded:=file.get_buffer(spec.bytes)
 if encoded.size()!=spec.bytes:
  _sheets.erase(id);return false
 var h:=HashingContext.new()
 h.start(HashingContext.HASH_SHA256);h.update(encoded)
 if h.finish().hex_encode()!=spec.sha256:
  _sheets.erase(id);return false
 if _sheets.has(id):return true
 var img:=Image.new()
 if img.load_png_from_buffer(encoded)!=OK or img.get_size()!=Vector2i(spec.size[0],spec.size[1]):return false
 img.convert(Image.FORMAT_RGBA8)
 for row: Array in spec.rows.values():
  var region:=Rect2i(row[2],row[3],row[4],row[5])
  if not region.has_area() or not Rect2i(Vector2i.ZERO,img.get_size()).encloses(region):return false
 _sheets[id]=img
 return true

static func _row(id: String, key: String, pose: String) -> Array:
 if not _sheets.has(id):return []
 var spec: Dictionary=SPECS[id]
 return spec.rows.get(pose,[]) if spec.part==key else []

static func stamp(dst: Image, key: String, shift: Vector2i, r: Dictionary, pose: String = "idle") -> bool:
 var id: String=r.get("named_paint",{}).get(key,"")
 if id.is_empty():return false
 var row:=_row(id,key,pose)
 if row.is_empty():return false
 dst.blend_rect(_sheets[id],Rect2i(row[2],row[3],row[4],row[5]),Vector2i(row[0],row[1])+shift)
 return true

static func collapse_source(r: Dictionary, key: String) -> Dictionary:
 var id: String=r.get("named_paint",{}).get(key,"")
 if id.is_empty():return {}
 var row:=_row(id,key,"idle")
 if row.is_empty():return {}
 return {"key":key,"at":Vector2i(row[0],row[1]),"im":_sheets[id].get_region(Rect2i(row[2],row[3],row[4],row[5]))}

static func head_recipe(r: Dictionary) -> Dictionary:
 var out:={"face":r.face,"head":r.head,"head_wear":r.head_wear}
 var id: String=r.get("named_paint",{}).get(r.head,"")
 if not id.is_empty():out.named_paint={r.head:id}
 return out
