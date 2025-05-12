import json
import random
import time

class BitPal:

	DATA_PATH = "/mnt/SDCARD/Saves/spruce/bitpal_data/bitpal.json"

	MOODS = ("excited", "happy", "neutral", "sad", "angry", "surprised")
	GOOD_MOODS = ("excited", "happy", "surprised")
	OKAY_MOODS = ("neutral", "surprised")
	BAD_MOODS = ("neutral", "sad", "angry", "surprised")

	def __init__(self, data):
		self.name = data.get("name", "Bitpal")
		self.level = data.get("level", 1)
		self.xp = data.get("xp", 0)
		self.xp_next = data.get("xp_next", 100)
		self.mood = data.get("mood", "happy")
		self.last_visit = data.get("last_visit", int(time.time()))
		self.missions_completed = data.get("missions_completed", 0)
	
	def reset(self):
		self.name = "BitPal"
		self.level = "1"
		self.xp = 0
		self.xp_next = 100
		self.mood = "happy"
		self.last_visit = int(time.time())
		self.missions_completed = 0

	@classmethod
	def load(cls):
		try:
			with open(cls.DATA_PATH) as file:
				data = json.load(file)
		except FileNotFoundError:
			data = {}
		except json.JSONDecodeError:
			raise ValueError("BitPal save file is corrupted.")
		return cls(data)
	
	def save(self):
		data = {
			"name" : self.name,
			"level" : self.level,
			"xp" : self.xp,
			"xp_next" : self.xp_next,
			"mood" : self.mood,
			"last_visit" : self.last_visit,
			"missions_completed" : self.missions_completed}
		with open(self.DATA_PATH, "w") as file:
			json.dump(data, file, indent=2)

	def get_face(self):
		match self.mood:
			case "excited":	face = "[^o^]"
			case "happy":	face = "[^-^]"
			case "neutral":	face = "[-_-]"
			case "sad":		face = "[;_;]"
			case "angry":	face = "[>_<]"
			case "surprised": face = "[O_O]"
			case _:			face = "[^-^]"
		return face

	def set_random_mood(self):
		self.mood = random.choice(BitPal.MOODS)

	def set_random_good_mood(self):
		self.mood = random.choice(BitPal.GOOD_MOODS)

	def set_random_okay_mood(self):
		self.mood = random.choice(BitPal.OKAY_MOODS)

	def set_random_bad_mood(self):
		self.mood = random.choice(BitPal.BAD_MOODS)

	def level_up(self):
		while self.xp >= self.xp_next:
			self.level += 1
			self.xp -= self.xp_next
			self.xp_next = (self.level + 1) * 50