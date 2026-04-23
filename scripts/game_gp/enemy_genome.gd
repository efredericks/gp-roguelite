class_name EnemyGenome

var OP_CODES: Array[String] = [
	"WAIT_20", "AIM", "FIRE_ONE", "RADIAL_4", "WAIT_40", "RADIAL_8", "FIRE_ALL"
]

# modulate enemies based on their scariness
var template_programs: Array[Array] = [
	["WAIT_20", "AIM", "WAIT_20", "FIRE_ONE"],  # aim only
	["WAIT_20", "RADIAL_4", "FIRE_ALL", "WAIT_40"], # 4 only
	["WAIT_20", "RADIAL_8", "FIRE_ALL", "WAIT_40"], # 8 only
	["WAIT_20", "RADIAL_4", "FIRE_ALL", "WAIT_40",  # 4 & 8
	 "WAIT_20", "RADIAL_8", "FIRE_ALL", "WAIT_40"], 
]
