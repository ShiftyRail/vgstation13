// -- No sell. Simple mobs aren't stunned.

/mob/living/simple_animal/hostile/Stun(amount)
	return 0

/mob/living/simple_animal/hostile/Knockdown(amount)
	return 0

// They follow the same old rules as other simple mobs.

/mob/living/simple_animal/hostile/proc/simple_animal_clientmove(NewLoc, Dir)
	var/old_dir = src.dir
	delayNextMove(move_to_delay)
	set_glide_size(DELAY2GLIDESIZE(move_to_delay))
	StartMoving()
	step(src, Dir)
	last_movement=world.time
	if(dir != old_dir)
		Facing()
	EndMoving()
