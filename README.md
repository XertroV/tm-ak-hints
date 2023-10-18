#  AK Hints

This plugin provides a visual indicator for when an Action Key is pressed and, if so, which AK. It only works for the local player.

AK detection is not perfect, but is very good. AK Hints should be consistent with the game in these cases:
* pressing / holding an AK prior to the race start: do not set AK
* changing an AK while respawning: set AK (after you press respawn but before you regain control of the car)
* pressing multiple AKs: set the AK most recently pressed down
* restore an AK when respawning, except if it's a standing respawn (which resets the AK)
* start of race: always reset to AK5 (no limit on steering)

AK hints also has desync detection:
- If steering ever exceeds the current AK value, then the AK value is set to the lowest it could possibly be. Full steering will therefore set the AK to 5 (which hides the indicator).
- If steering is at an AK value (0.2, 0.4, 0.6, 0.8) for at least 40 ms and at least 4 frames, then the active AK is set to that value. (Tolerance is +- 0.0001 which is 1 / 10,000; should be impossible to trigger without an AK or macros / mechanical aid)

You can customize:
- the position and size of the indicator
- text and stroke color
- the background color for each AK

Known issues:

- If running at under 100 FPS then it is possible to miss inputs. This is because the inputs are read directly from game memory and this gets updated 100 times per second. This is only an issue if you press and release the AK key / button within 1 frame. If you are steering with an AK, then desync detection should fix this fairly quickly.

---

License: Public Domain

Authors: XertroV

Suggestions/feedback: @XertroV on Openplanet discord

Code/issues: [https://github.com/XertroV/tm-ak-hints](https://github.com/XertroV/tm-ak-hints)

GL HF
