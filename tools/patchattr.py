# V1.65: android-23-SDK kennt neuere Attribute nicht -> Platzhalter-Attribut im fertigen Binär-XML auf die echte ID umschreiben
import sys, struct
f, old, new = sys.argv[1], int(sys.argv[2], 16), int(sys.argv[3], 16)
b = bytearray(open(f, 'rb').read())
pos = 8; n = 0
while pos < len(b):
    t, hs, sz = struct.unpack_from('<HHI', b, pos)
    if t == 0x0180:                                   # RES_XML_RESOURCE_MAP_TYPE
        for i in range(pos + hs, pos + sz, 4):
            if struct.unpack_from('<I', b, i)[0] == old:
                struct.pack_into('<I', b, i, new); n += 1
    pos += sz
open(f, 'wb').write(b)
print(f, 'ersetzt:', n)
assert n == 1
