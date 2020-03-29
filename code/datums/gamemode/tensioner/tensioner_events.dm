/datum/tensioner_event/

/*
 * assess_tension()
 * return: the tension observed by this event
 */

/datum/tensioner_event/proc/assess_tension()

/*
 * get_flags()
 * return: the special flags observed by this event
 */

/datum/tensioner_event/proc/get_flags()

// -- HERE BE IDEAS GUYS --

// --- I. Mechanical modifications independant of round progression

// Tension slowly decreases over time
/datum/tensioner_event/tension_decrease

// ---II. Count antagonists

// Increases tension if there are active antags, depending on type, how long they've been here, where they are, etc.
/datum/tensioner_event/count_antags

// --- III. Job counters
// Counts how many people there are on station who belong to a given departement.
// Retruns tension if there's not enough jobs for a given thing
/datum/tensioner_event/job_counter

// --- IV. Prisonners

// Increases tension if the brig cells are full
/datum/tensioner_event/prisonner_count

// --- V. Shootouts

// Increases tension if people are shooting each other
/datum/tensioner_event/shoot_counts

// --- VI. Dead players count

// Decreases tension if there's plenty of people in deadchat
/datum/tensioner_event/dead_player_counts

// --- VII. Admin intervention

// Periodically asks admins if there's not enoguh or too much tension
/datum/tensioner_event/admin_pooling

