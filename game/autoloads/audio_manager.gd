extends Node

func create_bus(enemy_id: String) -> String:
	var bus_name = "EnemyBus_" + enemy_id
	var bus_count = AudioServer.bus_count
	
	AudioServer.add_bus(bus_count)
	AudioServer.set_bus_name(bus_count, bus_name)
	
	AudioServer.set_bus_send(bus_count, &"SFX")
	
	return bus_name

func remove_bus(bus_name: String):
	var index = AudioServer.get_bus_index(bus_name)
	if index != -1:
		AudioServer.remove_bus(index)
