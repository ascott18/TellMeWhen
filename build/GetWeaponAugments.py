import re
import json
import urllib.request
import multiprocessing
import itertools
import os

from slpp import slpp as lua

base_url = "https://www.wowhead.com"

max_retries = 1

name_blacklist = [
	"armor",
	"insoles",
	"lure",
	"worm",
	"hook",
	"fish",
	"bauble",
	"nightcrawler",
	"Darkmoon Doughnut",
	"Aquatic Enticer",
]

def try_scrape_url(url, regex, id, tries = 0):
	print("getting " + str(id))

	user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.75 Safari/537.36'
	headers = {'User-Agent': user_agent}
	req = urllib.request.Request(url, [], headers)
	response = urllib.request.urlopen(req)

	content = response.read().decode()
	
	match = re.search(regex, content)

	if not match:
		if tries < max_retries:
			print("retrying " + str(id))
			return try_scrape_url(url, regex, id, tries + 1)
		else:
			raise Exception("no match for " + str(id))

	data = match.group(1)
	data = re.sub(r"frommerge:1", r'"frommerge":1', data)
	data = re.sub(r"popularity:", r'"popularity":', data)
	data = re.sub(r"firstseenpatch:", r'"firstseenpatch":', data)
	data = json.loads(data)

	return data

    
def scrape_consumable_items():
	data = try_scrape_url(
		url = base_url + "/items/consumables/item-enhancements-temporary/quality:1:2:3:4:5:6:7",
		regex = r"var listviewitems = (\[.*\]);",
		id = "item-enhancements-temporary")

	ids = {}
	for spell in data:
		id = spell["id"]
		name = spell["name"]
		if not any(sub.upper() in name.upper() for sub in name_blacklist):
			ids[id] = name

	return ids

if __name__ == '__main__':

	items = scrape_consumable_items()
	output = "{"
	for key in sorted(items, key=lambda k: '%03d' % k if isinstance(k, (int)) else str(k) ):
		output += "\t" + str(key) + ", -- " + items[key] + "\n"
	output += "}"
	open(os.path.join(os.path.dirname(__file__), 'WeaponAugments.lua'), 'w').write(output)

	print("complete. written to WeaponAugments.lua.")