# story: e15s03
class_name PairsModifier
extends RefCounted
## Two face-up cards with the same pair key match.


func is_match(first_key: String, second_key: String) -> bool:
	return first_key == second_key and not first_key.is_empty()
