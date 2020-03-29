/datum/tensioner_ruleset

	// At which tension should this thing ideally trigger ?
	var/ideal_tension = 0

	// Which events make this more likely to happen?
	var/list/favourable_events = list()

	// Which events make this less likely to happen?
	var/list/unfavourable_events = list()

	// Various flags
	var/flags

// Antag datums related things
/datum/tensioner_ruleset/role_based
	var/role_category

/datum/tensioner_ruleset/role_based/faction_based
	var/my_faction

// Code if this rule is acceptable or not
/datum/tensioner_ruleset/proc/acceptable()

// Code for getting the probability of this rule
/datum/tensioner_ruleset/proc/get_chance()

// Code for executing the rule
/datum/tensioner_ruleset/proc/execute()