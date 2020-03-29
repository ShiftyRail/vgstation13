/datum/gamemode/tensioner
	// The global current tension
	var/global_tension = 0
	var/list/tension_over_time = list()

	// All the current listed events
	var/list/datum/tensioner_event/our_events = list()

	// Executed rulesets
	var/list/datum/tensioner_ruleset/all_rulesets = list()
	var/list/datum/tensioner_ruleset/executed_rulesets = list()

	// The config we have
	var/datum/tensioner_config/config

	// Player-related things
	var/list/living_players = list()
	var/list/living_antags = list()
	var/list/dead_players = list()
	var/list/list_observers = list()

// -- Initial loop --
/datum/gamemode/tensioner/Setup()
	for (var/type in subtypesof(/datum/tensioner_ruleset))
		all_rulesets += new type
	
	// ...

// -- MAIN GAMEPLAY LOOP --
/datum/gamemode/tensioner/process()

	var/loop_tension = 0
	var/list/current_event_flags = list()
	var/list/trial_rulesets = list()

	// Phase 1 : collect tension 
	for (var/datum/tensioner_event/event in our_events)
		loop_tension += event.assess_tension()
		current_event_flags += event.get_flags()

	tension_over_time.Add(loop_tension)

	// Phase 2 : draft rulesets
	for (var/datum/tensioner_ruleset/rule in all_rulesets)

		// Unacceptable ruleset : happens once and only once
		if (!rule.acceptable(loop_tension, current_event_flags))
			continue

		trial_rulesets[rule] = rule.get_chance(loop_tension, current_event_flags)

	// Phase 3 : pick one of those rulesets

	var/datum/tensioner_ruleset/chosen_ruleset = pickweight(trial_rulesets)
	chosen_ruleset.execute()

	
// Configuration mode for the tensioner
/datum/tensioner_config/