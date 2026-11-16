class_name JobGenerator
extends RefCounted

## Builds random RepairJobs. Hardware jobs are based on a part that exists in
## the shop (so they're always solvable); software jobs need no part.
## Tweak the lists and numbers below to change the feel.

const NAMES = ["Sam", "Jordan", "Riley", "Casey", "Morgan", "Taylor", "Jamie", "Drew", "Quinn", "Avery", "Dana", "Robin"]

# ---------------------------------------------------------------- hardware

# Shown in capitals ("CPU"), everything else is lowercased ("motherboard").
const ACRONYMS = ["CPU", "GPU", "RAM", "PSU"]

const BASE_REWARD = {
	"CPU": 120,
	"GPU": 150,
	"RAM": 80,
}

# {cat} and {socket} get filled in. The socket hint is what lets the player
# work out which part to grab when the shelf has look-alikes.
const WITH_SOCKET = [
	"My PC died and I think it's the {cat}. It takes a {socket}.",
	"Can you swap my {cat}? It's a {socket} machine.",
	"Won't boot anymore... the {cat} is toast. Needs a {socket}.",
]

const WITHOUT_SOCKET = [
	"My {cat} died, can you replace it?",
	"Something's wrong with the {cat}. Can you fix it?",
	"Need a new {cat}, please!",
]

# ---------------------------------------------------------------- software

# work_time = seconds of holding E. Add your own entries freely.
const SOFTWARE_TASKS = [
	{
		"task": "Virus removal",
		"reward": 90,
		"work_time": 5.0,
		"requests": [
			"I clicked something weird and now it's all pop-ups.",
			"It says I have 47 viruses. Help!",
		],
	},
	{
		"task": "OS reinstall",
		"reward": 140,
		"work_time": 8.0,
		"requests": [
			"It won't boot into the OS anymore.",
			"Please wipe it and put a fresh OS on.",
		],
	},
	{
		"task": "Driver update",
		"reward": 60,
		"work_time": 3.5,
		"requests": [
			"My screen flickers every few minutes.",
			"The sound cuts out. I think a driver is old?",
		],
	},
	{
		"task": "Cleanup",
		"reward": 50,
		"work_time": 3.0,
		"requests": [
			"It's so slow. It takes ten minutes to start.",
			"My disk is full and I don't know why.",
		],
	},
	{
		"task": "Data recovery",
		"reward": 160,
		"work_time": 9.0,
		"requests": [
			"I deleted my whole thesis folder. Please!",
			"All my photos vanished after an update.",
		],
	},
]

# ---------------------------------------------------------------- builders

## Hardware job. p is the part the job is based on (the customer wants one like it).
static func make(p: Part) -> RepairJob:
	var job: RepairJob = RepairJob.new()
	job.customer_name = NAMES.pick_random()
	job.required_category = p.category
	job.required_socket = p.socket_type

	var cat: String = p.category if p.category in ACRONYMS else p.category.to_lower()
	var templates: Array = WITH_SOCKET if p.socket_type != &"" else WITHOUT_SOCKET
	var text: String = templates.pick_random()
	job.request = text.format({"cat": cat, "socket": String(p.socket_type)})

	_fill_payout(job, BASE_REWARD.get(p.category, 80))
	return job

## Software job: no part needed, the player holds E on the computer.
static func make_software() -> RepairJob:
	var t: Dictionary = SOFTWARE_TASKS.pick_random()
	var job: RepairJob = RepairJob.new()
	job.customer_name = NAMES.pick_random()
	job.is_software = true
	job.software_task = t["task"]
	# Task name up front so the player can tell it's a software job at a glance.
	job.request = "[%s] %s" % [t["task"], t["requests"].pick_random()]
	job.work_time = t["work_time"] * randf_range(0.9, 1.2)

	_fill_payout(job, t["reward"])
	return job

static func _fill_payout(job: RepairJob, base: int) -> void:
	job.reward = roundi(base * randf_range(0.9, 1.25) / 5.0) * 5
	job.penalty = roundi(job.reward * 0.25 / 5.0) * 5
	job.patience = randf_range(45.0, 75.0)