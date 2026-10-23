#!/usr/bin/env bash
# Fetch the Idle Planet Miner wiki pages the skeleton copies (docs/SKELETON.md)
# as wikitext through the MediaWiki API (the plain pages refuse scripted reads).
# Usage: bash tools/ipm/fetch_pages.sh <out_dir>
set -euo pipefail
out="${1:?out dir}"
mkdir -p "$out"
for p in Ores Alloys Items Planets Projects Smelters Crafters Credit Rooms \
	Engineering Forge Aeronautical Astronomy Packaging Workshop Laboratory Lounge \
	Backup_Generator Underforge Dorm Sales Marketing Planetary_Upgrades; do
	curl -sS --fail "https://idle-planet-miner.fandom.com/api.php?action=parse&page=$p&prop=wikitext&format=json&redirects=1" -o "$out/$p.json"
done
