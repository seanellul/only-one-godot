extends Panel
class_name InteractiveSign

# Script attached to interactive signs to provide interaction data

var interaction_data: Dictionary = {}

func setup_interaction_data(data: Dictionary):
	"""Set up the interaction data for this sign"""
	interaction_data = data.duplicate()

func get_interaction_data() -> Dictionary:
	"""Return the interaction data for this sign"""
	return interaction_data