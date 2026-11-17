extends Node

## Autoload. Project Settings -> Globals -> Autoload, add this script with the
## name "GameState". (No class_name here, it would clash with the autoload name.)

## Emitted by the player's hand when E is pressed on a computer while holding a part.
@warning_ignore("unused_signal")
signal repair_requested(computer, part)
signal score_changed(score: int)
signal job_completed(job: RepairJob)
signal job_failed(job: RepairJob)
## Emitted when an enemy actually costs the player points (use it for a flash,
## a sound, a screen shake...).
signal player_hit(amount: int)

## After a hit, the player can't lose points again for this many seconds, so
## standing in a cart's path doesn't drain the whole score in one second.
@export var hit_cooldown: float = 1.0

var score: int = 0
var jobs_done: int = 0

var _hit_ready_at: float = 0.0   # time (seconds) when the next hit is allowed

func complete_job(job: RepairJob, patience_fraction: float = 0.0) -> int:
	var tip: int = roundi(job.reward * 0.5 * patience_fraction)
	var total: int = job.reward + tip
	score += total
	jobs_done += 1
	score_changed.emit(score)
	job_completed.emit(job)
	return total

func fail_job(job: RepairJob) -> void:
	score = maxi(0, score - job.penalty)
	score_changed.emit(score)
	job_failed.emit(job)

## Called by roaches, shopping carts, anything that hurts. amount is the points
## lost. Ignored while the cooldown from the last hit is still running.
func enemy_hit(amount) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < _hit_ready_at:
		return
	_hit_ready_at = now + hit_cooldown
	score = maxi(0, score - amount)
	score_changed.emit(score)
	player_hit.emit(amount)