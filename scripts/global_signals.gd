extends Node

signal OnPlayerEnterRoom(room: Room)
signal OnDefeatEnemy(enemy: Enemy)
#signal OnDefeatObstacle(obstacle: ObstaclePain)
signal OnPlayerUpdateHealth(currHP: int, maxHP: int)
signal OnDebug()
signal OnResetHold(alpha: float)
