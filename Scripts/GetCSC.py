import re
import json
import urllib.request
import multiprocessing
import itertools

from slpp import slpp as lua

base_url = "http://www.wowhead.com"

num_classes = 12

spell_id_blacklist = [
	165201,
]

class_slugs = {
	'death-knight': 6,
	'demon-hunter': 12,
	'druid': 11,
	'hunter': 3 ,
	'mage': 8,
	'monk': 10,
	'paladin': 2,
	'priest': 5,
	'rogue': 4,
	'shaman': 7,
	'warlock': 9,
	'warrior': 1,
}

class_spells_urls = [
	'/spells/abilities/',
	# '/spells/artifact-traits/', # Artifacts are gone.
	# '/spells/azerite-traits/', # The bulk of azerite traits are passive, or things you don't care about. Lets not include them.
	'/spells/pvp-talents/',
	'/spells/specialization/',
	'/spells/talents/',
]

spell_cat_whitelist = [
	7,     # abilities
	-12,   # specializations
	-2,    # talents
	-16,    # pvp talents

	# -14, # draenor perks
	# -13, # glyphs
	# -11, # proficiencies
]

pet_spells_url = '/spells/pet-abilities/'

pet_classes = [
	'death-knight',
	'hunter',
	'shaman',
	'warlock',
]

# Some racials don't specify a race, but they do specify a "skill" that corresponds to a race.
race_skill_map = {
	899: [24], # pandaren
	2423: [29], # void elf
	2421: [30], # lightforged
	2420: [28], # highmountain
	2419: [27], # nightborne
}

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

def try_scrape_url(url, regex, id, tries = 0):
	print("getting " + str(id))

	response = urllib.request.urlopen(url)

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
	data = json.loads(data)

	return data;

def scrape_class_spells(urlAndId):
	classId = urlAndId[1]

	data = try_scrape_url(
		url = base_url + urlAndId[0],
		regex = r"var listviewspells = (\[.*\]);",
		id = urlAndId[0])

	ids = []
	for spell in data:
		id = spell["id"]
		# wowhead uses spellIds above 1 million for "unreleased spells".
		if id not in spell_id_blacklist and id < 1000000:
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
	for spell in data:
		id = spell["id"]
		if id not in spell_id_blacklist:

			if id in race_map_fix:
				spell["races"] = race_map_fix[id]

			if spell["skill"] and spell["skill"][0] in race_skill_map:
				spell["races"] = race_skill_map[spell["skill"][0]]

			if "races" not in spell:
				raise Exception("Unknown racial %d %s" % (spell["id"], spell["name"]))

			if len(spell["races"]) > 1:
				raise Exception("Unexpected multiple races %d %s" % (id, spell["races"]))

			if "reqclass" in spell and id not in racial_no_class_req:
				ids[id] = [spell["races"][0], spell["reqclass"] or 0]
			else:
				ids[id] = spell["races"][0]

	return ids


if __name__ == '__main__':
	pool = multiprocessing.Pool(processes = 5)

	keyed_results = {}



	# Run racials first since they're most prone to failure.
	result = pool.apply(scrape_racial_spells)
	keyed_results["RACIAL"] = result




	# class spells
	all_spell_pages = list(itertools.product(class_spells_urls, class_slugs))
	results = pool.map(scrape_class_spells, [(b + c, class_slugs[c]) for (b, c) in all_spell_pages])

	for classIDAndSpells in results:
		classID = classIDAndSpells[0]
		keyed_results[classID] = keyed_results.get(classID, []) + classIDAndSpells[1]





	# pet spells
	results = pool.map(scrape_class_spells, [(pet_spells_url + c, class_slugs[c]) for c in pet_classes])

	keyed_results["PET"] = {}
	for classIDAndSpells in results:
		classID = classIDAndSpells[0]
		keyed_results["PET"].update({id: classID for id in classIDAndSpells[1]})





	output = "local Cache = " + lua.encode(keyed_results)
	output = re.sub(r"\n\t\t(.*?) = ", r'\1=', output)
	open('CSC.lua', 'w').write(output)

	print("complete. written to CSC.lua.")