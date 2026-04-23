extends Node

signal OnPlayerEnterRoom(room: Room)
signal OnDefeatEnemy(enemy: Enemy)
signal OnPlayerUpdateHealth(currHP: int, maxHP: int)
signal OnDebug()
signal OnResetHold(alpha: float)
