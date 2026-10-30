class_name RaftFx
extends Resource
## Raft wake/foam emitter settings (tuned in the FX tuner, page 1). Materials and particle
## process materials are tuned directly on their own .tres files.

@export var wake_enabled: bool = true
@export var wake_amount: int = 70
@export var wake_lifetime: float = 1.8
@export var wake_offset: Vector3 = Vector3(0.0, 0.16, 1.6)
@export var spray_amount: int = 24
@export var hull_foam_enabled: bool = true
@export var hull_foam_scale: float = 1.0
