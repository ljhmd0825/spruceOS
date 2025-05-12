import time
import os

class Mission:
	
	def __init__(self, data):
		
		missing_data = []
		for key in ("type", "rompath", "duration"):
			if not data.get(key):
				missing_data.append(key)
		if missing_data:
			raise ValueError(f"Missing required fields: {', '.join(missing_data)}")

		self.type = data.get("type")
		self.rompath = data.get("rompath")
		self.duration = data.get("duration")
		self.startdate = data.get("startdate", int(time.time()))
		self.enddate = data.get("enddate", 0)
		self.time_spent = data.get("time_spent", 0)

		self.console = self.rompath.split("/")[3]
		self.gamename = os.path.splitext(self.rompath.split("/")[-1])[0]

		match self.type:
			case "surprise":
				xp_mult = 8
				display_text = "SURPRISE GAME!"
			case "discover":
				xp_mult = 7
				display_text = f"Try {self.gamename} ({self.console}) for {self.duration} minutes!"
			case "rediscover":
				xp_mult = 7
				display_text = f"Rediscover {self.gamename} ({self.console}) for {self.duration} minutes!"
			case "system":
				xp_mult = 6
				display_text = f"Play any {self.console} game for {self.duration} minutes."
			case "any":
				xp_mult = 5
				display_text = f"Play any game you want for {self.duration} minutes!"
		
		self.xp_reward = xp_mult * self.duration
		self.display_text = display_text