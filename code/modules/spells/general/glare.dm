/spell/glare
	name = "Glare"
	desc = "A scary glare that incapacitates people for a short while around you."
	abbreviation = "GL"

	school = "vampire"
	user_type = USER_TYPE_VAMPIRE

	charge_type = Sp_RECHARGE
	charge_max = 30 SECONDS
	invocation_type = SpI_NONE
	range = 0
	spell_flags = NEEDSHUMAN
	cooldown_min = 20 SECONDS

	override_base = "vamp"
	hud_state = "vampire_glare"

	var/blood_cost = 1

/spell/glare/cast_check(var/skipcharge = 0, var/mob/user = usr)
	if (!user.vampire_power(blood_cost, 0))
		to_chat(world, "vampire_power failed.")
		return FALSE
	if (istype(user.get_item_by_slot(slot_glasses), /obj/item/clothing/glasses/sunglasses/blindfold))
		to_chat(user, "<span class='warning'>You're blindfolded!</span>")
		return FALSE
	. = ..()
	if (!.)
		to_chat(world, "cast_check() failed.")

/spell/glare/choose_targets(var/mob/user = usr)
	var/list/targets = list()
	for(var/mob/living/carbon/C in view(3))
		if(!C.vampire_affected(user.mind))
			continue
		targets += C
	return targets

/spell/glare/cast(var/list/targets, var/mob/user)
	var/datum/role/vampire/V = isvampire(user) // Shouldn't ever be null, as cast_check checks if we're a vamp.
	user.visible_message("<span class='danger'>\The [user]'s eyes emit a blinding flash!</span>")
	for (var/T in targets)
		to_chat(world, "Target : [T]")
		var/mob/living/carbon/C = T
		var/dist = get_dist(user, C)
		switch (dist)
			if (0 to 1) // Close mobs
				C.Stun(8)
				C.Knockdown(8)
				C.stuttering += 20
				C.blinded += 6
			else // Further away mobs
				var/distance_value = max(0, abs(dist-3) + 1)
				C.Stun(distance_value)
				if(distance_value > 1)
					C.Knockdown(distance_value)
				C.stuttering += 5+distance_value * ((VAMP_CHARISMA in V.powers) ? 2 : 1) //double stutter time with Charisma
				if(!C.blinded)
					C.blinded = 1
				C.blinded += max(1, distance_value)
		to_chat(C, "<span class='warning'>You are blinded by [user]'s glare</span>")
