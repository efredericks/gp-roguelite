class_name RoomGenome 

var obstacles: Array
var enemies: Array

enum Functions {
	PLACE_OBSTACLE, PLACE_ENEMY, PLACE_ITEM,
}
enum Terminals {
	OBSTACLE_BLOCKING, OBSTACLE_PASSTHRU, OBSTACLE_HARM,
	ENEMY_FOLLOW, ENEMY	
}
