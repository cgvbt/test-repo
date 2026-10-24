FOODTRAIL — OFFLINE PHILIPPINES MAP EDITION

WHAT'S INCLUDED
- Local food diary with login, restaurant create/edit/delete, ratings, reviews, photos, search and JSON backup/restore.
- Offline-capable map renderer using MapLibre GL JS + PMTiles, both open-source.
- Setup script that creates a Philippines basemap archive from Protomaps' OpenStreetMap-derived vector tiles.
- Restaurant pins continue to be stored in your existing browser data format (latitude/longitude fields); this update does not clear localStorage.

FIRST-TIME SETUP (Windows)
1. In your current FoodTrail app, click Export backup first so your existing restaurant data and photos are preserved.
2. Extract this ZIP into a new folder.
3. Ensure Python 3 is installed (needed to serve local files with byte-range support).
4. While connected to the internet, right-click setup-offline-map.ps1 and choose Run with PowerShell, or open PowerShell in this folder and run:
   Set-ExecutionPolicy -Scope Process Bypass
   .\setup-offline-map.ps1
   This downloads the local map renderer libraries, the PMTiles command-line utility, a Philippines map extract, and a small set of map label fonts. The map download can take time and requires disk space.
5. Run:
   .\start-local.ps1
6. FoodTrail opens at http://127.0.0.1:8765. Keep the PowerShell window open while using it.
7. Import your previously exported JSON backup using FoodTrail’s Import backup control. Browser storage is isolated by origin, so a file:// copy and this local-server copy do not share localStorage automatically.

OFFLINE AFTER SETUP
- Map rendering, roads, map labels, and saved restaurant pins use files on your own computer; no public map tile server is queried.
- Search by typed address uses the online OpenStreetMap Nominatim service and therefore needs internet. Without internet, click the map to set a pin or type latitude and longitude manually.
- Keep the entire folder together, especially philippines.pmtiles, vendor/, and fonts/.

MAP DATA & LICENSE
- Map data is derived from OpenStreetMap and distributed under the Open Database License (ODbL); attribution is shown in the map. See https://www.openstreetmap.org/copyright and https://docs.protomaps.com/basemaps/downloads.
- MapLibre GL JS is BSD-3-Clause; PMTiles is BSD-3-Clause. The setup script downloads the official distributable libraries from unpkg and does not use public online tile services at runtime.
- The setup script extracts a country bounding box to max zoom 15. Map coverage is the Philippines with detailed city streets where OpenStreetMap has that data. Map completeness varies by location.

YOUR DATA
- Restaurant entries, images, usernames and passwords remain local in this browser. This is a local prototype, not secure server-side authentication.
- Export a JSON backup regularly. Browser localStorage has size limits.
- The restaurant record schema and coordinate fields remain compatible. Since browsers isolate localStorage by origin (file:// vs http://localhost), use Export backup in the old app and Import backup in the new app to move existing entries and photos.
