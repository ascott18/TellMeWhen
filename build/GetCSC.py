import re
import json
import urllib.request
import itertools
import os
import logging
from concurrent.futures import ProcessPoolExecutor, as_completed

from slpp import slpp as lua


# Set to a regex pattern to restrict scraping to matching IDs (for debugging)
# Example: '.*shaman.*' to match all shaman URLs, or None to disable
debug_only_id = None #'.*shaman.*'

VERSION = 'classic'

# Game version configurations
GAME_VERSIONS = {
    'retail': {
        'base_url': 'https://www.wowhead.com',
        'output_file': 'CSC.lua',
        'classes': {
            'death-knight': 6,
            'demon-hunter': 12,
            'evoker': 13,
            'druid': 11,
            'hunter': 3,
            'mage': 8,
            'monk': 10,
            'paladin': 2,
            'priest': 5,
            'rogue': 4,
            'shaman': 7,
            'warlock': 9,
            'warrior': 1,
        },
        'pet_classes': ['death-knight', 'hunter', 'shaman', 'warlock'],
        'class_spells_urls': [
            '/spells/abilities/',
            # '/spells/artifact-traits/', # Artifacts are gone.
            # '/spells/azerite-traits/', # The bulk of azerite traits are passive, or things you don't care about. Lets not include them.
            '/spells/pvp-talents/',
            '/spells/specialization/',
            '/spells/talents/',
        ]
    },
    'mop': {
        'base_url': 'https://www.wowhead.com/mop-classic',
        'output_file': 'CSC-MoP.lua',
        'classes': {
            'death-knight': 6,
            'druid': 11,
            'hunter': 3,
            'mage': 8,
            'monk': 10,
            'paladin': 2,
            'priest': 5,
            'rogue': 4,
            'shaman': 7,
            'warlock': 9,
            'warrior': 1,
        },
        'pet_classes': ['death-knight', 'hunter', 'shaman', 'warlock'],
        'class_spells_urls': [
            '/spells/abilities/',
            '/spells/specialization/',
            '/spells/talents/',
        ]
    },
    'classic': {
        'base_url': 'https://www.wowhead.com/classic',
        'output_file': 'CSC-Classic.lua',
        'classes': {
            'druid': 11,
            'hunter': 3,
            'mage': 8,
            'paladin': 2,
            'priest': 5,
            'rogue': 4,
            'shaman': 7,
            'warlock': 9,
            'warrior': 1,
        },
        'pet_classes': ['hunter', 'shaman', 'warlock'],
        'class_spells_urls': [
            '/spells/abilities/',
            '/spells/talents/',
        ]
    }
}

base_url = GAME_VERSIONS[VERSION]['base_url']
class_slugs = GAME_VERSIONS[VERSION]['classes']
class_spells_urls = GAME_VERSIONS[VERSION]['class_spells_urls']

spell_id_blacklist = [
	165201,
]

pet_spells_url = '/spells/pet-abilities/'

# Backward compatibility - default pet classes
pet_classes = GAME_VERSIONS[VERSION]['pet_classes']

# Some racials don't specify a race, but they do specify a "skill" that corresponds to a race.
race_skill_map = {
	899: [24], # pandaren
	2423: [29], # void elf
	2421: [30], # lightforged
	2420: [28], # highmountain
	2419: [27], # nightborne
	2597: [34], # dark iron dwarf
	2598: [36], # maghar orc
	2775: [35], # vulpera
	2774: [37], # mechagnome
	2808: [52, 70], # dracthyr alliance/horde
	2895: [84, 85], # earthen alliance/horde
}

# Race ID to bitmask mapping for reqrace field
# WH.setPageData("wow.race.masks"
race_bitmasks = {
	1: 1,          # human
	2: 2,          # orc
	3: 4,          # dwarf
	4: 8,          # night elf
	5: 16,         # undead
	6: 32,         # tauren
	7: 64,         # gnome
	8: 128,        # troll
	9: 256,        # goblin
	10: 512,       # blood elf
	11: 1024,      # draenei
	22: 2097152,   # worgen
	24: 8388608,   # pandaren
	25: 16777216,  # pandaren alliance
	26: 33554432,  # pandaren horde
	27: 67108864,  # nightborne
	28: 134217728, # highmountain tauren
	29: 268435456, # void elf
	30: 536870912, # lightforged draenei
	31: 1073741824, # zandalari troll
	32: 2147483648, # kul tiran
	34: 2048,      # dark iron dwarf
	35: 4096,      # vulpera
	36: 8192,      # maghar orc
	37: 16384,     # mechagnome
	52: 65536,     # dracthyr
	70: 32768,     # dracthyr
	84: 131072,    # earthen alliance
	85: 262144,    # earthen horde
}

def parse_reqrace_bitmask(reqrace_value):
	"""Parse reqrace bitmask to get list of race IDs"""
	races = []
	for race_id, bitmask in race_bitmasks.items():
		if reqrace_value & bitmask:
			races.append(race_id)
	return races

race_map_fix = {
	# These are racials that don't specify their race properly.
	107079: [24], # pandaren
}

racial_no_class_req = [
	# Worgen racials have massive class req fields for no reason.
	68975,
	68976,
	68978,
	68992,
	68996,
	87840,
	94293,
]



max_retries = 3

def init_worker():
	"""Initialize logging for worker processes"""
	logging.basicConfig(
		level=logging.INFO,
		format='%(asctime)s - %(processName)s - %(levelname)s - %(message)s',
		handlers=[logging.StreamHandler()]
	)

def try_scrape_url(url, regex, id, tries = 0):
	# If debug_only_id is set, only process IDs that match the regex pattern
	if debug_only_id and not re.match(debug_only_id, str(id)):
		return []
	
	logger = logging.getLogger(__name__)
	# logger.info(f"getting {str(id)}")

	user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.75 Safari/537.36'
	headers = {'User-Agent': user_agent}
	req = urllib.request.Request(url, [], headers)
	response = urllib.request.urlopen(req)

	content = response.read().decode()
	
	match = re.search(regex, content)

	if not match:
		if tries < max_retries:
			logger.warning(f"retrying {str(id)}")
			return try_scrape_url(url, regex, id, tries + 1)
		else:
			raise Exception("no match for " + str(id))

	data = match.group(1)
	data = re.sub(r"frommerge:1", r'"frommerge":1', data)
	data = re.sub(r"popularity:", r'"popularity":', data)
	data = re.sub(r"quality:", r'"quality":', data)
	data = json.loads(data)

	return data

def scrape_class_spells(urlAndId):
	classId = urlAndId[1]

	data = try_scrape_url(
		url = base_url + urlAndId[0],
		regex = r"var listviewspells = (\[.*\]);",
		id = urlAndId[0])

	ids = []
	for spell in data:
		id = spell["id"]
		# wowhead uses spellIds above ????  for "unreleased spells".
		# used to be 1 million, but now there are real SPELLIDs in the millions, so idk.
		if id not in spell_id_blacklist and id < 2000000:
			ids.append(id)

	return (classId, ids)



def scrape_pet_spells(classID):
	data = try_scrape_url(
		url = base_url + "/spells=-3." + str(classID),
		regex = r"var listviewspells = (\[.*\]);",
		id = "pet class " + str(classID))

	ids = {}
	for spell in data:
		id = spell["id"]
		if id not in spell_id_blacklist:
			ids[id] = classID

	return ids

def scrape_racial_spells():
	data = try_scrape_url(
		url = base_url + "/racial-traits",
		regex = r"var listviewspells = (\[.*\]);",
		id = "racials")

	ids = {}
	errors = []
	for spell in data:
		id = spell["id"]
		if id not in spell_id_blacklist:

			# if "Passive" in spell["rank"]:
			# 	continue

			if id in race_map_fix:
				spell["races"] = race_map_fix[id]

			if spell["skill"] and spell["skill"][0] in race_skill_map:
				spell["races"] = race_skill_map[spell["skill"][0]]

			# If races still not defined, try to parse reqrace bitmask
			if "races" not in spell and "reqrace" in spell and spell["reqrace"]:
				parsed_races = parse_reqrace_bitmask(spell["reqrace"])
				if parsed_races:
					spell["races"] = parsed_races

			if "races" not in spell:
				skill_id = spell["skill"][0] if spell["skill"] else "None"
				reqrace = spell.get("reqrace", "None")
				errors.append("Unknown racial %d %s (skillID %s, reqrace %s)" % (spell["id"], spell["name"], skill_id, reqrace))
				continue

			#if len(spell["races"]) > 1:
				#errors.append("Unexpected multiple races %d %s" % (id, spell["races"]))

			# wowhead provides multiple race IDs for some spells,
			# and TMW is able to handle these.
			# However, wowhead's data is pretty inaccurate for almost all spells
			# that have multiple race IDs. So, we still only grab the first one.
			if "reqclass" in spell and id not in racial_no_class_req:
				ids[id] = [[spell["races"][0]], spell["reqclass"] or 0]
			else:
				ids[id] = [[spell["races"][0]], 0]

	if errors:
		raise Exception("Errors found while processing racial spells:\n" + "\n".join(errors))

	return ids


if __name__ == '__main__':
	# Configure logging
	logging.basicConfig(
		level=logging.INFO,
		format='%(asctime)s - %(processName)s - %(levelname)s - %(message)s',
		handlers=[logging.StreamHandler()]
	)
	
	keyed_results = {}

	# Run racials first since they're most prone to failure.
	result = scrape_racial_spells()
	keyed_results["RACIAL"] = result

	# class spells
	all_spell_pages = list(itertools.product(class_spells_urls, class_slugs))
	
	with ProcessPoolExecutor(max_workers=5, initializer=init_worker) as executor:
		# Submit all class spell tasks
		future_to_info = {
			executor.submit(scrape_class_spells, (b + c, class_slugs[c])): (b + c, class_slugs[c])
			for b, c in all_spell_pages
		}
		
		# Process results as they complete
		for future in as_completed(future_to_info):
			url, classID = future_to_info[future]
			try:
				result = future.result()
				if result is not None:
					classID, spells = result
					keyed_results[classID] = keyed_results.get(classID, []) + spells
					logging.info(f"Processed {url}: {len(spells)} spells")
			except Exception as exc:
				logging.error(f"URL {url} generated an exception: {exc}")

	# pet spells
	with ProcessPoolExecutor(max_workers=5, initializer=init_worker) as executor:
		# Submit all pet spell tasks
		future_to_info = {
			executor.submit(scrape_class_spells, (pet_spells_url + c, class_slugs[c])): (pet_spells_url + c, class_slugs[c])
			for c in pet_classes
		}
		
		keyed_results["PET"] = {}
		for future in as_completed(future_to_info):
			url, classID = future_to_info[future]
			try:
				result = future.result()
				if result is not None:
					classID, spells = result
					keyed_results["PET"].update({id: classID for id in spells})
					logging.info(f"Processed pet spells {url}: {len(spells)} spells")
			except Exception as exc:
				logging.error(f"Pet URL {url} generated an exception: {exc}")




	output = "local Cache = {\n"
	for key in sorted(keyed_results, key=lambda k: '%03d' % k if isinstance(k, (int)) else str(k) ):
		# Skip None values
		if keyed_results[key] is None:
			continue
			
		# in-place sort the list of spellIDs.
		if type(keyed_results[key]) is list:
			keyed_results[key].sort()

		line = lua.encode(keyed_results[key])
		if line is None:
			line = "{}"  # Handle empty lists that lua.encode returns None for
		line = re.sub(r"[\n\t ]", r'', line)
		output += "\t[" + lua.encode(key) + "] = " + line + ",\n"

	output += "}"
	
	version_config = GAME_VERSIONS[VERSION]

	open(os.path.join(os.path.dirname(__file__), version_config['output_file']), 'w').write(output)

	logging.info(f"complete. written to {version_config['output_file']}.")