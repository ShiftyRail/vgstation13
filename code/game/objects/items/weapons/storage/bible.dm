/obj/item/weapon/storage/bible
	var/datum/religion/my_rel = /datum/religion
	name = "bible"
	desc = "Apply to head repeatedly."
	icon_state = "bible"
	throw_speed = 1
	throw_range = 5
	w_class = W_CLASS_MEDIUM
	force = 2.5 //A big book, solely used for non-Chaplains trying to use it on people
	flags = FPRINT
	attack_verb = list("whacks", "slaps", "slams", "forcefully blesses")
	var/mob/affecting = null

	autoignition_temperature = 522 // Kelvin
	fire_fuel = 2

/obj/item/weapon/storage/bible/suicide_act(mob/living/user)
	user.visible_message("<span class='danger'>[user] is farting on \the [src]! It looks like \he's trying to commit suicide!</span>")
	user.emote("fart")
	spawn(10) //Wait for it
		user.fire_stacks += 5
		user.IgniteMob()
		user.emote("scream",,, 1)
		return FIRELOSS //Set ablaze and burned to crisps

// Religious converting
/obj/item/weapon/storage/bible/verb/convert(mob/living/target as mob in view(1))
	set name = "Convert"
	set category = "Object"
	if (usr.isUnconscious() || usr.incapacitated() || usr.lying || usr.locked_to || !ishigherbeing(usr) || usr.isDead()) // Sanity
		return FALSE
	if (!usr.mind.faith)
		to_chat(usr, "<span class='warning'> You do not have a religion to convert people to.")
		return FALSE
	if (target.isUnconscious() || target.incapacitated() || target.lying || target.locked_to || !ishigherbeing(target) || target.isDead() || !target.mind) // Sanity
		to_chat(usr, "<span class='warning'> \The [target] does not seem receptive to conversion.")
	else
		usr.mind.faith.convertAct(usr, target, src) // usr = preacher ; target = subject
		return TRUE

//"Special" Bible with a little gift on introduction
/obj/item/weapon/storage/bible/booze

	autoignition_temperature = 0 //Not actually paper
	fire_fuel = 0

/obj/item/weapon/storage/bible/booze/New()
	. = ..()
	new /obj/item/weapon/reagent_containers/food/drinks/beer(src)
	new /obj/item/weapon/reagent_containers/food/drinks/beer(src)
	new /obj/item/weapon/spacecash(src)
	new /obj/item/weapon/spacecash(src)
	new /obj/item/weapon/spacecash(src)

//What happens when you slap things with the Bible in general
/obj/item/weapon/storage/bible/attack(mob/living/M as mob, mob/living/user as mob)

	var/chaplain = 0 //Are we the Chaplain ? Used for simplification
	if(user.mind && (user.mind.assigned_role == "Chaplain"))
		chaplain = 1 //Indeed we are


	M.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been attacked with [src.name] by [user.name] ([user.ckey])</font>")
	user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [src.name] to attack [M.name] ([M.ckey])</font>")

	if(!iscarbon(user))
		M.LAssailant = null
	else
		M.LAssailant = user

	log_attack("<font color='red'>[user.name] ([user.ckey]) attacked [M.name] ([M.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>")

	if(!chaplain) //The user is not a Chaplain. BLASPHEMY !
		//Using the Bible as a member of the occult will get you smithed, aka holy cleansing fire. You'd have to be stupid to remotely consider it
		if(isvampire(user)) //Vampire trying to use it
			to_chat(user, "<span class='danger'>[my_rel.deity_name] channels through \the [src] and sets you ablaze for your blasphemy!</span>")
			user.fire_stacks += 5
			user.IgniteMob()
			user.emote("scream",,, 1)
			M.mind.vampire.smitecounter += 50 //Once we are extinguished, we will be quite vulnerable regardless
		else if(iscult(user)) //Cultist trying to use it
			to_chat(user, "<span class='danger'>[my_rel.deity_name] channels through \the [src] and sets you ablaze for your blasphemy!</span>")
			user.fire_stacks += 5
			user.IgniteMob()
			user.emote("scream",,, 1)
		else //Literally anyone else than a Cultist using it, at this point it's just a big book
			..() //WHACK
		return 1 //Non-chaplains can't use the holy book, at least not properly

	if(clumsy_check(user) && prob(50)) //Using it while clumsy, let's have some fun
		user.visible_message("<span class='warning'>\The [src] slips out of [user]'s hands and hits \his head.</span>",
		"<span class='warning'>\The [src] slips out of your hands and hits your head.</span>")
		user.apply_damage(10, BRUTE, LIMB_HEAD)
		user.Stun(5)
		return 1

	//From this point onwards we are done with the user, let's check whoever is on the receiving end
	//Let us also note that if we made it this far, the user IS a Chaplain. No need to check
	//Worthy of note, blessings are done on craniums. I guess this is the best way to send the message across

	if(M == user) //We are trying to smack ourselves
		return 1 //That's dumb, don't do it

	if(ishuman(M)) //We're forced to do two ishuman() code paragraphs because this one blocks the others
		var/mob/living/carbon/human/H = M
		if(istype(H.head, /obj/item/clothing/head/helmet) || istype(H.head, /obj/item/clothing/head/hardhat) || istype(H.head, /obj/item/clothing/head/fedora) || istype(H.head, /obj/item/clothing/head/culthood)) //Blessing blocked
			user.visible_message("<span class='warning'>[user] [pick(attack_verb)] [H]'s head with \the [src], but their headgear blocks the hit.</span>",
			"<span class='warning'>You try to bless [H]'s head with \the [src], but their headgear blocks the blessing. Blasphemy!</span>")
			return 1 //That's it. Helmets are very haram

	if(M.stat == DEAD) //Our target is dead. RIP in peace
		user.visible_message("<span class='warning'>[user] [pick(attack_verb)] [M]'s lifeless body with \the [src].</span>",
		"<span class='warning'>You bless [M]'s lifeless body with \the [src], trying to conjure [my_rel.deity_name]'s mercy on them.</span>")
		playsound(get_turf(src), "punch", 25, 1, -1)

		//TODO : Way to bring people back from death if they are your followers
		return 1 //Otherwise, there's so little we can do

	//Our target is alive, prepare the blessing
	user.visible_message("<span class='warning'>[user] [pick(attack_verb)] [M]'s head with \the [src].</span>",
	"<span class='warning'>You bless [M]'s head with \the [src]. In the name of [my_rel.deity_name], bless thee!</span>")
	playsound(get_turf(src), "punch", 25, 1, -1)

	if(ishuman(M)) //Only humans can be vampires or cultists
		var/mob/living/carbon/human/H = M
		if(H.mind && isvampire(H) && !(VAMP_MATURE in H.mind.vampire.powers)) //The user is a "young" Vampire, fuck up his vampiric powers and hurt his head
			to_chat(H, "<span class='warning'>[my_rel.deity_name]'s power nullifies your own!</span>")
			if(H.mind.vampire.nullified < 5) //Don't actually reduce their debuff if it's over 5
				H.mind.vampire.nullified = max(5, H.mind.vampire.nullified + 2)
			H.mind.vampire.smitecounter += 10 //Better get out of here quickly before the problem shows. Ten hits and you are literal toast
			return 1 //Don't heal the mob

		if(H.mind && iscult(H)) //The user is a Cultist. We are thus deconverting him
			if(prob(20))
				to_chat(H, "<span class='notice'>The power of [my_rel.deity_name] suddenly clears your mind of heresy. Your allegiance to Nar'Sie wanes!</span>")
				to_chat(user, "<span class='notice'>You see [H]'s eyes become clear. Nar'Sie no longer controls his mind, [my_rel.deity_name] saved \him!</span>")
				ticker.mode.remove_cultist(H.mind)
			else //We aren't deconverting him this time, give the Cultist a fair warning
				to_chat(H, "<span class='warning'>The power of [my_rel.deity_name] is overwhelming you. Your mind feverishly questions Nar'Sie's teachings!</span>")
			return 1 //Don't heal the mob

		if(H.mind && H.mind.special_role == "VampThrall")
			ticker.mode.remove_thrall(H.mind)
			H.visible_message("<span class='notice'>[H] suddenly becomes calm and collected again, \his eyes clear up.</span>",
			"<span class='notice'>Your blood cools down and you are inhabited by a sensation of untold calmness.</span>")
			return 1 //That's it, game over

		bless_mob(user, H) //Let's outsource the healing code, because we can

//Bless thee. Heals followers fairly, potentially heals everyone a bit (or gives them brain damage)
/obj/item/weapon/storage/bible/proc/bless_mob(mob/living/carbon/human/user, mob/living/carbon/human/H)
	var/datum/organ/internal/brain/sponge = H.internal_organs_by_name["brain"]
	if(sponge && sponge.damage >= 60) //Massive brain damage
		to_chat(user, "<span class='warning'>[H] responds to \the [src]'s blessing with drooling and an empty stare. [my_rel.deity_name]'s teachings appear to be lost on this poor soul.</span>")
		return //Brainfart
	//TODO: Put code for followers right here
	if(prob(20)) //1/5 chance of adding some brain damage. You can't just heal people for free
		H.adjustBrainLoss(5)
	if(prob(50)) //1/2 chance of healing at all
		for(var/datum/organ/external/affecting in H.organs)
			if(affecting.heal_damage(5, 5)) //5 brute and burn healed per bash. Not wonderful, but it can help if someone has Alkyzine handy
				H.UpdateDamageIcon()
	return //Nothing else to add

//We're done working on mobs, let's check if we're blessing something else
/obj/item/weapon/storage/bible/afterattack(var/atom/A, var/mob/user, var/proximity_flag)
	if(!proximity_flag)
		return
	user.delayNextAttack(5)
	if(user.mind && (user.mind.assigned_role == "Chaplain")) //Make sure we still are a Chaplain, just in case
		if(A.reagents && A.reagents.has_reagent(WATER)) //Blesses all the water in the holder
			user.visible_message("<span class='notice'>[user] blesses \the [A].</span>",
			"<span class='notice'>You bless \the [A].</span>")
			//Ugly but functional conversion proc
			var/water2holy = A.reagents.get_reagent_amount(WATER)
			A.reagents.del_reagent(WATER)
			A.reagents.add_reagent(HOLYWATER, water2holy)

/obj/item/weapon/storage/bible/attackby(obj/item/weapon/W as obj, mob/user as mob)
	playsound(get_turf(src), "rustle", 50, 1, -5)
	. = ..()

/obj/item/weapon/storage/bible/pickup(mob/living/user as mob)
	if(user.mind && user.mind.assigned_role == "Chaplain") //We are the Chaplain, yes we are
		to_chat(user, "<span class ='notice'>You feel [my_rel.deity_name]'s holy presence as you pick up \the [src].</span>")
	if(ishuman(user)) //We are checking for antagonists, only humans can be antagonists
		var/mob/living/carbon/human/H = user
		if(isvampire(H) && (!(VAMP_UNDYING in H.mind.vampire.powers))) //We are a Vampire, we aren't very smart
			to_chat(H, "<span class ='danger'>[my_rel.deity_name]'s power channels through \the [src]. You feel extremely uneasy as you grab it!</span>")
			H.mind.vampire.smitecounter += 10
		if(iscult(H)) //We are a Cultist, we aren't very smart either, but at least there will be no consequences for us
			to_chat(H, "<span class ='danger'>[my_rel.deity_name]'s power channels through \the [src]. You feel uneasy as you grab it, but Nar'Sie protects you from its influence!</span>")
