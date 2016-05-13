import re
import json
import urllib.request
import multiprocessing

from slpp import slpp as lua

base_url = "http://legion.wowhead.com"

num_classes = 12

spell_id_blacklist = [
	165201,
]

spell_cat_whitelist = [
	7,     # abilities
	-12,   # specializations
	-2,    # talents

	# -14, # draenor perks
	# -13, # glyphs
	# -11, # proficiencies
]

pet_classes = [
	3, # hunter
	6, # dk
	7, # shaman
	9, # lock
]

race_map_fix = {
	# These are racials that don't specify their race properly.
	107072: [24], # pandaren
	107073: [24], # pandaren
	107074: [24], # pandaren
	107076: [24], # pandaren
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

def scrape_class_spells(classID):
	data = try_scrape_url(
		url = base_url + "/class=" + str(classID),
		regex = r"name: LANG.tab_spells.*?data: (\[.*\]).*?\}\);",
		id = "class " + str(classID))

	ids = []
	for spell in data:
		id = spell["id"]
		# wowhead uses spellIds above 1 million for "unreleased spells".
		if spell["cat"] in spell_cat_whitelist and id not in spell_id_blacklist and id < 1000000:
			ids.append(id)

	return ids



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
		url = base_url + "/spells=-4",
		regex = r"var listviewspells = (\[.*\]);",
		id = "racials")

	ids = {}
	for spell in data:
		id = spell["id"]
		if id not in spell_id_blacklist:

			if "races" not in spell:
				if id in race_map_fix:
					spell["races"] = race_map_fix[id]
				else:
					raise Exception("Unknown racial %d %s" % (v.id, v.name))

			if len(spell["races"]) > 1:
				raise Exception("Unexpected multiple races")

			if "reqclass" in spell and id not in racial_no_class_req:
				ids[id] = [spell["races"][0], spell["reqclass"] or 0]
			else:
				ids[id] = spell["races"][0]

	return ids


if __name__ == '__main__':
	pool = multiprocessing.Pool(processes = num_classes)
	results = pool.map(scrape_class_spells, range(1, num_classes + 1))
	keyed_results = {k+1: v for k, v in enumerate(results)}
	

	results = pool.map(scrape_pet_spells, pet_classes)

	all_pets = {}
	for spells in results:
		for spellID, classID in spells.items():
			all_pets[spellID] = classID

	keyed_results["PET"] = all_pets


	result = pool.apply(scrape_racial_spells)
	keyed_results["RACIAL"] = result

	output = "local Cache = " + lua.encode(keyed_results)
	output = re.sub(r"\n\t\t(.*?) = ", r'\1=', output)
	open('CSC.lua', 'w').write(output)

	print("complete. written to CSC.lua.")