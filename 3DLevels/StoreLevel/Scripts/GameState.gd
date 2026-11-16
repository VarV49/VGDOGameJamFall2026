extends Node

## Autoload. Project Settings -> Globals -> Autoload, add this script with the
## name "GameState". (No class_name here, it would clash with the autoload name.)

## Emitted by the player's hand when E is pressed on a computer while holding a part.
@warning_ignore("unused_signal")
signal repair_requested(computer, part)
signal score_changed(score: int)
signal job_completed(job: RepairJob)
signal job_failed(job: RepairJob)

var score: int = 0
var jobs_done: int = 0

## patience_fraction is 0..1 (how much of the customer's patience was left).
## Faster repairs earn up to a 50% tip on top of the reward.
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