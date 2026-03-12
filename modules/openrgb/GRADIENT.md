# Sunset Gradient — Arctic Liquid Freezer III 360 A-RGB

48 LEDs: pump head (12) + 3x fans (12 each), per-device gradient repeated 4x.

## Per-device gradient (12 LEDs)

| LED | Hex    | Description        |
|-----|--------|--------------------|
| 1   | 701800 | Deep burnt amber   |
| 2   | FF6000 | Orange             |
| 3   | FF2050 | Red-pink           |
| 4   | FF1048 | Hot pink           |
| 5   | FF0060 | Magenta            |
| 6   | C00090 | Purple             |
| 7   | 8010D0 | Lilac              |
| 8   | C00090 | Purple             |
| 9   | FF0060 | Magenta            |
| 10  | FF1048 | Hot pink           |
| 11  | FF4010 | Red-orange         |
| 12  | 701800 | Deep burnt amber   |

## CLI command

```bash
openrgb --noautoconnect -d 0 -z 1 --size 48 --mode Direct --color \
  701800,FF6000,FF2050,FF1048,FF0060,C00090,8010D0,C00090,FF0060,FF1048,FF4010,701800,\
  701800,FF6000,FF2050,FF1048,FF0060,C00090,8010D0,C00090,FF0060,FF1048,FF4010,701800,\
  701800,FF6000,FF2050,FF1048,FF0060,C00090,8010D0,C00090,FF0060,FF1048,FF4010,701800,\
  701800,FF6000,FF2050,FF1048,FF0060,C00090,8010D0,C00090,FF0060,FF1048,FF4010,701800
```

## Notes

- Direct mode does NOT persist across power loss — must be re-applied
- Detector config in `~/.config/OpenRGB/OpenRGB.json` locks out all SMBus/GPU probing (only ASUS Aura USB enabled)
- Do NOT run `openrgb -sp` after setting Direct mode colors — it saves all-black
