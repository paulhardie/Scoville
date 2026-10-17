extends RefCounted
## The one place wall-clock time enters (D021). The simulation never calls
## this; the screen reads it to work out time away. Tests swap in their own
## clock: anything with a now() in seconds.


func now() -> float:
	return Time.get_unix_time_from_system()
