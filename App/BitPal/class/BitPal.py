import time

class BitPal:
	
	def __init__(self, data):
		self.name = data.get("name", "Bitpal")
		self.level = data.get("level", 1)
		self.xp = data.get("xp", 0)
		self.xp_next = data.get("xp_next", 100)
		self.mood = data.get("mood", "happy")
		self.last_visit = data.get("last_visit", int(time.time()))
		self.missions_completed = data.get("missions_completed", 0)
	
	def get_face(self):
		match self.mood:
			case "excited":	face = "[^o^]"
			case "happy":	face = "[^-^]"
			case "neutral":	face = "[-_-]"
			case "sad":		face = "[;_;]"
			case "angry":	face = "[>_<]"
			case "surprised": face = "[O_O]"
			case _:			face = "[^-^]"