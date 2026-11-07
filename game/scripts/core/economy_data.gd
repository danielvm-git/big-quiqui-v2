# story: e08s03
# story: e09s01
class_name EconomyData
extends Resource
## FIX-05: tuning table for wheel prizes (weights + coin payouts) and furniture prices.

@export var wheel_spin_ticket_cost: int = 1
@export var wheel_prize_weights: Dictionary = {"a": 1, "b": 1, "c": 1}
@export var wheel_prize_coins: Dictionary = {"a": 1, "b": 2, "c": 3}
## One entry per `FurnitureCatalog.FURNITURE_IDS`. Five placed pieces open the party, so
## the cheapest five (2+3+3+3+4 = 15 coins) are reachable in a couple of care cycles.
@export var furniture_prices: Dictionary = {
	"abajur": 3,
	"armario": 8,
	"beliche": 9,
	"cadeira": 3,
	"cama": 10,
	"escada": 7,
	"estante": 6,
	"mesa": 4,
	"porta": 5,
	"sofa": 8,
	"tapete": 2,
	"vaso_planta": 3,
}


func pick_prize(rng: RandomNumberGenerator) -> String:
	var keys: Array = wheel_prize_weights.keys()
	keys.sort()
	var total: int = 0
	for key: Variant in keys:
		var w: int = maxi(int(wheel_prize_weights[key]), 0)
		total += w
	if total <= 0:
		return ""
	var roll: int = rng.randi_range(1, total)
	var acc: int = 0
	for key: Variant in keys:
		var w: int = maxi(int(wheel_prize_weights[key]), 0)
		acc += w
		if roll <= acc:
			return str(key)
	return ""
