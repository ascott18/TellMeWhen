import re
import json
import urllib.request
import multiprocessing
import itertools
import os

from slpp import slpp as lua

base_url = "https://tbc.wowhead.com"

num_classes = 12

spell_id_blacklist = [
	165201,
]

class_slugs = {
	# 'death-knight': 6,
	# 'demon-hunter': 12,
	'druid': 11,
	'hunter': 3,
	'mage': 8,
	# 'monk': 10,
	'paladin': 2,
	'priest': 5,
	'rogue': 4,
	'shaman': 7,
	'warlock': 9,
	'warrior': 1,
}

class_spells_urls = [
	'/spells/abilities/',
	#'/spells/pvp-talents/',
	#'/spells/specialization/',
	'/spells/talents/',
]

spell_cat_whitelist = [
	7,     # abilities
	# -12,   # specializations
	-2,    # talents
	# -16,    # pvp talents

	# -14, # draenor perks
	# -13, # glyphs
	# -11, # proficiencies
]

pet_spells_url = '/spells/pet-abilities/'

pet_classes = [
	# 'death-knight',
	'hunter',
	# 'shaman',
	'warlock',
]

# Some racials don't specify a race, but they do specify a "skill" that corresponds to a race.
race_skill_map = {
}

race_map_fix = {
}

racial_no_class_req = [
]



max_retries = 3

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

			#if len(spell["races"]) > 1:
				#raise Exception("Unexpected multiple races %d %s" % (id, spell["races"]))

			# wowhead provides multiple race IDs for some spells,
			# and TMW is able to handle these.
			# However, wowhead's data is pretty inaccurate for almost all spells
			# that have multiple race IDs. So, we still only grab the first one.
			if "reqclass" in spell and id not in racial_no_class_req:
				ids[id] = [[spell["races"][0]], spell["reqclass"] or 0]
			else:
				ids[id] = [[spell["races"][0]], 0]

	return ids


if __name__ == '__main__':
	pool = multiprocessing.Pool(processes = 5)

	keyed_results = {}



	# Run racials first since they're most prone to failure.
	# result = pool.apply(scrape_racial_spells)
	result = scrape_racial_spells()
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




	output = "local Cache = {\n"
	for key in sorted(keyed_results, key=lambda k: '%03d' % k if isinstance(k, (int)) else str(k) ):
		# in-place sort the list of spellIDs.
		if type(keyed_results[key]) is list:
			keyed_results[key].sort()

		line = lua.encode(keyed_results[key])
		line = re.sub(r"[\n\t ]", r'', line)
		output += "\t[" + lua.encode(key) + "] = " + line + ",\n"

	output += "}"
	open(os.path.join(os.path.dirname(__file__), 'CSC.lua'), 'w').write(output)

	print("complete. written to CSC.lua.")