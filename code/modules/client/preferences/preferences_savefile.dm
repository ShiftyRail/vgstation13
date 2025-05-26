/// IF YOU NEED A FIELD ADDED TO THE DATABASE, CREATE A MIGRATION SO SHIT GETS UPDATED.
/// Also update SQL/players2.sql.
/// SEE code/modules/migrations/SS13_Prefs/

/datum/preferences/proc/SetChangelog(ckey,hash)
	var/datum/preference_setting/lastchangelog = get_pref_datum(/datum/preference_setting/string/changelog)
	lastchangelog.setting=hash
	var/database/query/q = new
	q.Add("UPDATE client SET lastchangelog=? WHERE ckey=?",lastchangelog.setting,ckey)
	if(!q.Execute(db))
		message_admins("Error in SetChangelog [__FILE__] ln:[__LINE__] #: [q.Error()] - [q.ErrorMsg()]")
		WARNING("Error in Setchangelog [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
		return 0

/datum/preferences/proc/load_preferences_sqlite(var/ckey)
	var/list/database_data = execute_load_pref_query(ckey)
	read_database_data_client(database_data)
	initialize_preferences()
	return 1

/datum/preferences/proc/execute_load_pref_query(var/ckey)
	var/list/preference_list_client = new
	var/database/query/check = new
	var/database/query/q = new
	check.Add("SELECT ckey FROM client WHERE ckey = ?", ckey)
	if(check.Execute(db))
		if(!check.NextRow())
			message_admins("Error in load_preferences_sqlite [__FILE__] ln:[__LINE__] #: [check.Error()] - [check.ErrorMsg()]")
			WARNING("Error in load_preferences_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
			return 0
	else
		message_admins("Error in load_preferences_sqlite [__FILE__] ln:[__LINE__] #: [check.Error()] - [check.ErrorMsg()]")
		WARNING("Error in load_preferences_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
		return 0
	q.Add("SELECT * FROM client WHERE ckey = ?", ckey)
	if(q.Execute(db))
		while(q.NextRow())
			var/list/row = q.GetRowData()
			for(var/a in row)
				preference_list_client[a] = row[a]
	else
		message_admins("Error in load_preferences_sqlite [__FILE__] ln:[__LINE__] #: [q.Error()] - [q.ErrorMsg()]")
		WARNING("Error in load_preferences_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
		return 0
	return preference_list_client

/datum/preferences/proc/read_database_data_client(var/list/database_data)
	for (var/database_setting in preference_settings_client)

		var/datum/preference_setting/setting_datum = preference_settings_client[database_setting]
		setting_datum.setting = setting_datum.load_sql(database_data) // First we load...
		setting_datum.setting = setting_datum.sanitize_setting(setting_datum.setting) // Then we sanitize

		preference_settings_client[database_setting] = setting_datum

/datum/preferences/proc/initialize_preferences(client_login = 0)
	var/attack_animation = get_pref(/datum/preference_setting/enum/attack_animations)
	if(attack_animation == PERSON_ANIMATION)
		person_animation_viewers |= client
		item_animation_viewers -= client
	else if(attack_animation == ITEM_ANIMATION)
		item_animation_viewers |= client
		person_animation_viewers -= client
	else
		item_animation_viewers -= client
		person_animation_viewers -= client

/datum/preferences/proc/save_preferences_sqlite(var/user, var/ckey)
	var/database/query/check = new
	var/database/query/q = new
	check.Add("SELECT ckey FROM client WHERE ckey = ?", ckey)
	if(check.Execute(db))
		if(!check.NextRow())
			var/list/arguments_query = new_db_entry_query_args()
			q.Add(arglist(arguments_query))
			if(!q.Execute(db))
				message_admins("Error in save_preferences_sqlite [__FILE__] ln:[__LINE__] #: [q.Error()] - [q.ErrorMsg()]. sql= [arguments_query[1]]")
				WARNING("Error in save_preferences_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				return 0
		else
			var/list/arguments_query = save_db_entry_query_args(ckey)
			q.Add(arglist(arguments_query))
			if(!q.Execute(db))
				message_admins("Error in save_preferences_sqlite [__FILE__] ln:[__LINE__] #: [q.Error()] - [q.ErrorMsg()]. sql= [arguments_query[1]]")
				WARNING("Error in save_preferences_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				return 0
	else
		message_admins("Error in save_preferences_sqlite [__FILE__] ln:[__LINE__] #: [check.Error()] - [check.ErrorMsg()]")
		WARNING("Error in save_preferences_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
		return 0
	to_chat(user, "Preferences Updated.")
	lastPolled = world.timeofday
	return 1

// -- You should not need to modify this - this automatically reads all settings and save them.
/datum/preferences/proc/new_db_entry_query_args(var/ckey)
	var/list/returned_list = list()
	var/sql_text = "INSERT into client (ckey"
	var/sql_text_end = ") VALUES (?"
	returned_list.Add(sql_text) // First item in the query is the SQL
	returned_list.Add(ckey) // Second item is the ckey (first joker)
	// This is a prepared queries. All the "?" here are jokers which will be replaced internally by BYOND with the values in the param list
	// This MEANS that the order of the param list is pretty important!
	for (var/setting in preference_settings_client)
		var/datum/preference_setting/the_setting = preference_settings_client[setting]
		sql_text += ", [the_setting.sql_name]"
		sql_text_end += ", ?"
		returned_list.Add(the_setting.setting)
	sql_text_end += ")"
	returned_list[1] = "[sql_text][sql_text_end]"
	return returned_list

/datum/preferences/proc/save_db_entry_query_args(var/ckey)
	var/list/returned_list = list()
	var/sql_text = "UPDATE client SET "
	var/sql_text_end = " WHERE ckey = ?"
	returned_list.Add(sql_text) // First item in the query is the SQL
	// This is a prepared queries. All the "?" here are jokers which will be replaced internally by BYOND with the values in the param list
	// This MEANS that the order of the param list is pretty important!
	for (var/setting in preference_settings_client)
		var/datum/preference_setting/the_setting = preference_settings_client[setting]
		sql_text += "[the_setting.sql_name]=?, "
		returned_list.Add(the_setting.setting)
	sql_text = copytext(sql_text, 1, length(sql_text)-1) // Remove the last ,
	returned_list.Add(ckey) // This time, the ckey is the last joker
	returned_list[1] = "[sql_text][sql_text_end]"
	return returned_list

/datum/preferences/proc/load_save_sqlite(var/ckey, var/user, var/slot)
	var/list/preference_list = new
	var/database/query/q     = new
	var/database/query/check = new

	check.Add("SELECT player_ckey FROM players WHERE player_ckey = ? AND player_slot = ?", ckey, slot)
	if(check.Execute(db))
		if(!check.NextRow())
			to_chat(user, "You have no character file to load, please save one first.")
			WARNING("[__LINE__]: datum/preferences/load_save_sqlite has returned")
			return 0
	else
		message_admins("load_save_sqlite Check Error #: [check.Error()] - [check.ErrorMsg()]")
		WARNING("[__LINE__]: datum/preferences/load_save_sqlite has returned")

		return 0

	var/sql = load_character_sql()
	// Ckey and slot and ?/joker parameters in the prepared query
	q.Add(sql, ckey, slot)

	if(q.Execute(db))
		while(q.NextRow())
			var/list/row = q.GetRowData()
			for(var/a in row)
				preference_list[a] = row[a]
	else
		message_admins("load_save_sqlite Error [__LINE__] #: [q.Error()] - [q.ErrorMsg()]. Dump [sql]")
		WARNING("[__LINE__]: datum/preferences/load_save_sqlite has returned")
		return 0

	for (var/setting in preference_settings_character)
		var/datum/preference_setting/the_setting = preference_settings_character[setting]
		the_setting.setting = the_setting.load_sql(preference_list[the_setting.sql_name])
		the_setting.setting = the_setting.sanitize_setting(the_setting.setting)

	// Antag roles. This is still a bit hardcoded but meeeeeh
	for(var/role_id in special_roles)
		roles[role_id]=0
	q = new
	q.Add("SELECT role, preference FROM client_roles WHERE ckey=? AND slot=?", ckey, slot)
	if(q.Execute(db))
		while(q.NextRow())
			var/list/row = q.GetRowData()
			roles[row["role"]] = text2num(row["preference"])
	else
		message_admins("Error in load_save_sqlite [__FILE__] ln:[__LINE__] #: [q.Error()] - [q.ErrorMsg()]")
		WARNING("[__LINE__]: datum/preferences/load_save_sqlite has returned")
		return 0

	// Unused.
	//if(!skills)
	//	skills = list()
	//if(!used_skillpoints)
	//	used_skillpoints= 0

	if(user)
		to_chat(user, "Successfully loaded [get_pref(/datum/preference_setting/string/real_name)].")

	return 1


/datum/preferences/proc/load_character_sql()
	var/sql = "SELECT "

	for (var/database_setting in typesof(/datum/preference_setting))
		var/datum/preference_setting/setting_datum = database_setting
		if (!initial(setting_datum.enabled))
			continue
		if (initial(setting_datum.sql_table) == "client")
			continue
		sql += "[initial(setting_datum.sql_table)].[initial(setting_datum.sql_name)], "
	sql = copytext(sql, 1, length(sql) - 1) // Get rid of the last ,
	sql += " " // Empty space
	// This is still relatively hard-coded but it's more or less fine for now
	sql += {"
	FROM
		players
	INNER JOIN
		limbs
	ON
		(
			players.player_ckey = limbs.player_ckey)
	AND (
			players.player_slot = limbs.player_slot)
	INNER JOIN
		jobs
	ON
		(
			limbs.player_ckey = jobs.player_ckey)
	AND (
			limbs.player_slot = jobs.player_slot)
	INNER JOIN
		body
	ON
		(
			jobs.player_ckey = body.player_ckey)
	AND (
			jobs.player_slot = body.player_slot)
	WHERE
		players.player_ckey = ?
	AND players.player_slot = ? ;"}
	return sql

/datum/preferences/proc/random_character_sqlite(var/user, var/ckey)
	var/database/query/q = new
	var/list/slot_list = new
	q.Add("SELECT player_slot FROM players WHERE player_ckey=?", ckey)
	if(q.Execute(db))
		while(q.NextRow())
			slot_list.Add(q.GetColumn(1))
	else
		message_admins("Error in random_character_sqlite [__FILE__] ln:[__LINE__] #: [q.Error()] - [q.ErrorMsg()]")
		WARNING("Error in random_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
		return 0
	var/random_slot = pick(slot_list)
	load_save_sqlite(ckey, user, random_slot)
	return 1

/datum/preferences/proc/save_character_sqlite(var/ckey, var/user, var/slot)
	if(slot > MAX_SAVE_SLOTS)
		to_chat(user, "You are limited to 8 character slots.")
		message_admins("[ckey] attempted to override character slot limit")
		return 0

	var/database/query/q = new

	// This checks if the DB is still connected to us.
	var/database/query/check = new

	// General player
	check.Add("SELECT player_ckey FROM players WHERE player_ckey = ? AND player_slot = ?", ckey, slot)
	if(check.Execute(db))
		if(!check.NextRow())
			var/list/sql_arguments_new_character = new_db_entry_query_character_args()
			q.Add(arglist(sql_arguments_new_character))
			if (!q.Execute(db))
				message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				return 0
			to_chat(user, "Created Character")
		else
			var/list/sql_arguments_update_character = update_db_entry_query_character_args()
			q.Add(arglist(sql_arguments_update_character))
			if(!q.Execute(db))
				message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()] sql=[sql_arguments_update_character[1]]")
				WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				return 0
			to_chat(user, "Updated Character")
	else
		message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[check.Error()] - [check.ErrorMsg()]")
		WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
		return 0

	check.Add("SELECT player_ckey FROM body WHERE player_ckey = ? AND player_slot = ?", ckey, slot)
	if(check.Execute(db))
		if(!check.NextRow())
			var/list/sql_arguments_new_body = new_db_entry_query_body_args()
			q.Add(arglist(sql_arguments_new_body))
			if(!q.Execute(db))
				message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				return 0
			to_chat(user, "Created Body")
		else
			var/list/sql_arguments_update_body = update_db_entry_query_character_args()
			q.Add(arglist(sql_arguments_update_body))
			if(!q.Execute(db))
				message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				return 0
			to_chat(user, "Updated Body")
	else
		message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #: [check.Error()] - [check.ErrorMsg()]")
		WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
		return 0

	// Jobs are left hardcoded for now since they not likely to be fundamentally changed
	// However the same proc logic could apply here if we had some job-per-character specific sett
	var/list/jobs = get_pref(/datum/preference_setting/assoc_list_setting/jobs)
	var/alternate_option = get_pref(/datum/preference_setting/enum/alternate_option)
	check.Add("SELECT player_ckey FROM jobs WHERE player_ckey = ? AND player_slot = ?", ckey, slot)
	if(check.Execute(db))
		if(!check.NextRow())
		    //                       1           2           3                4
			q.Add("INSERT INTO jobs (player_ckey,player_slot,alternate_option,jobs) \
					         VALUES (?,          ?,          ?,               ?)", \
							        ckey,        slot,       alternate_option,json_encode(jobs))
			if(!q.Execute(db))
				message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #: [q.Error()] - [q.ErrorMsg()]")
				WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				return 0
			to_chat(user, "Created Job list")
		else
		    //                     1                  2
			q.Add("UPDATE jobs SET alternate_option=?,jobs=? WHERE player_ckey = ? AND player_slot = ?",\
								   alternate_option,  json_encode(jobs),        ckey,               slot)
			if(!q.Execute(db))
				message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #: [q.Error()] - [q.ErrorMsg()]")
				WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				return 0
			to_chat(user, "Updated Job List")
	else
		message_admins("Error in save_character_sqlite ln [__LINE__] #: [check.Error()] - [check.ErrorMsg()]")
		WARNING("Error in save_character_sqlite ln [__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
		return 0

	// Limbs
	check.Add("SELECT player_ckey FROM limbs WHERE player_ckey = ? AND player_slot = ?", ckey, slot)
	if(check.Execute(db))
		if(!check.NextRow())
			q.Add("INSERT INTO limbs (player_ckey, player_slot) VALUES (?,?)", ckey, slot)
			if(!q.Execute(db))
				message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #: [q.Error()] - [q.ErrorMsg()]")
				WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
				return 0
			for(var/setting in preference_settings_character)
				var/datum/preference_setting/the_setting = preference_settings_character[setting]
				if (the_setting.sql_table != "limbs")
					continue
				q.Add("UPDATE limbs SET [the_setting.sql_name]=? WHERE player_ckey = ? AND player_slot = ?", the_setting.setting, ckey, slot)
				if(!q.Execute(db))
					message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #; [q.Error()] - [q.ErrorMsg()]")
					WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
					return 0
				organ_data[the_setting.sql_name] = the_setting.setting
			to_chat(user, "Created Limbs")
		else
			for(var/setting in preference_settings_character)
				var/datum/preference_setting/the_setting = preference_settings_character[setting]
				if (the_setting.sql_table != "limbs")
					continue
				q.Add("UPDATE limbs SET [the_setting.sql_name] = ? WHERE player_ckey = ? AND player_slot = ?", the_setting.setting, ckey, slot)
				if(!q.Execute(db))
					message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #: [q.Error()] - [q.ErrorMsg()]")
					WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
					return 0
			to_chat(user, "Updated Limbs")
	else
		message_admins("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #: [check.Error()] - [check.ErrorMsg()]")
		WARNING("Error in save_character_sqlite [__FILE__] ln:[__LINE__] #:[q.Error()] - [q.ErrorMsg()]")
		return 0

	for(var/role_id in roles)
		if(!(roles[role_id] & ROLEPREF_SAVE))
			continue
		q = new
		q.Add("INSERT OR REPLACE INTO client_roles (ckey, slot, role, preference) VALUES (?,?,?,?)", ckey, slot, role_id, (roles[role_id] & ROLEPREF_VALMASK))
		//testing("INSERT OR REPLACE INTO client_roles (ckey, slot, role, preference) VALUES ('[ckey]',[slot],'[role_id]',[roles[role_id] & ROLEPREF_VALMASK])")
		if(!q.Execute(db)) // This never triggers on error, for some reason.
			message_admins("ClientRoleInsert: Error #: [q.Error()] - [q.ErrorMsg()]")
			WARNING("ClientRoleInsert: Error #:[q.Error()] - [q.ErrorMsg()]")
			return 0

	to_chat(user, "Successfully saved [get_pref(/datum/preference_setting/string/real_name)]")

	return 1

// -- DB SQL HELPERS --

// The sql text this outputs looks like this :
// "INSERT into players (player_ckey, player_slot, var1, ...)"
// And the list it returns is like:
// list(sql, ckey, slot, var1, var2, ...)
// This list is automatically converted into arguments via arglist

/datum/preferences/proc/new_db_entry_query_character_args(var/ckey, var/slot)
	// -- You should not need to modify this - this automatically reads all settings and save them.
	var/list/returned_list = list()
	var/sql_text = "INSERT into players (player_ckey,player_slot"
	var/sql_text_end = ") VALUES (?,?"
	returned_list.Add(sql_text) // First item in the query is the SQL
	returned_list.Add(ckey) // Second item is the ckey (first joker)
	returned_list.Add(slot) // Third item is the slot (second joker)
	// This is a prepared queries. All the "?" here are jokers which will be replaced internally by BYOND with the values in the param list
	// This MEANS that the order of the param list is pretty important!
	for (var/setting in preference_settings_character)
		var/datum/preference_setting/the_setting = preference_settings_client[setting]
		if (the_setting.sql_table != "players")
			continue
		sql_text += ",[the_setting.sql_name]"
		sql_text_end += ",?"
		returned_list.Add(the_setting.setting)
	sql_text_end += ")"
	returned_list[1] = "[sql_text][sql_text_end]"
	return returned_list

// The sql text this outputs looks like this :
// "UPDATE players SET var1=?, var2=? ... WHERE player_ckey = ? AND player_slot = ?"
// And the list it returns is like:
// list(sql, var1, var2, ..., ckey, slot)
// This list is automatically converted into arguments via arglist

/datum/preferences/proc/update_db_entry_query_character_args(var/ckey, var/slot)
	// -- You should not need to modify this - this automatically reads all settings and save them.
	var/list/returned_list = list()
	var/sql_text = "UPDATE players SET " // White space is important
	var/sql_text_end = " WHERE player_ckey = ? AND player_slot = ?"
	returned_list.Add(sql_text) // First item in the query is the SQL

	// This is a prepared query. All the "?" here are jokers which will be replaced internally by BYOND with the values in the param list
	// This MEANS that the order of the param list is pretty important!
	for (var/setting in preference_settings_character)
		var/datum/preference_setting/the_setting = preference_settings_character[setting]
		if (the_setting.sql_table != "players")
			continue
		sql_text += "[the_setting.sql_name]=?,"
		returned_list.Add(the_setting.setting)
	sql_text = copytext(sql_text, 1, length(sql_text)) // Remove the last ,
	returned_list.Add(ckey) // Second-to-last item is the ckey (second to last joker)
	returned_list.Add(slot) // Last item is the slot (last joker)
	returned_list[1] = "[sql_text][sql_text_end]"
	return returned_list

// The sql text this outputs looks like this :
// "INSERT into body (player_ckey, player_slot, var1, ...)"
// And the list it returns is like:
// list(sql, ckey, slot, var1, var2, ...)
// This list is automatically converted into arguments via arglist

/datum/preferences/proc/new_db_entry_query_body_args(var/ckey, var/slot)
	// -- You should not need to modify this - this automatically reads all settings and save them.
	var/list/returned_list = list()
	var/sql_text = "INSERT into body (player_ckey,player_slot"
	var/sql_text_end = ") VALUES (?,?"
	returned_list.Add(sql_text) // First item in the query is the SQL
	returned_list.Add(ckey) // Second item is the ckey (first joker)
	returned_list.Add(slot) // Third item is the slot (second joker)
	// This is a prepared query. All the "?" here are jokers which will be replaced internally by BYOND with the values in the param list
	// This MEANS that the order of the param list is pretty important!
	for (var/setting in preference_settings_character)
		var/datum/preference_setting/the_setting = preference_settings_client[setting]
		if (the_setting.sql_table != "body")
			continue
		sql_text += ",[the_setting.sql_name]"
		sql_text_end += ",?"
		returned_list.Add(the_setting.setting)
	sql_text_end += ")"
	returned_list[1] = "[sql_text][sql_text_end]"
	return returned_list

// The sql text this outputs looks like this :
// "UPDATE body SET var1=?, var2=? ... WHERE player_ckey = ? AND player_slot = ?"
// And the list it returns is like:
// list(sql, var1, var2, ..., ckey, slot)
// This list is automatically converted into arguments via arglist

/datum/preferences/proc/update_db_entry_query_body_args(var/ckey, var/slot)
	// -- You should not need to modify this - this automatically reads all settings and save them.
	var/list/returned_list = list()
	var/sql_text = "UPDATE body SET " // White space is important
	var/sql_text_end = " WHERE player_ckey = ? AND player_slot = ?"
	returned_list.Add(sql_text) // First item in the query is the SQL

	// This is a prepared query. All the "?" here are jokers which will be replaced internally by BYOND with the values in the param list
	// This MEANS that the order of the param list is pretty important!
	for (var/setting in preference_settings_character)
		var/datum/preference_setting/the_setting = preference_settings_character[setting]
		if (the_setting.sql_table != "body")
			continue
		sql_text += "[the_setting.sql_name]=?,"
		returned_list.Add(the_setting.setting)
	sql_text = copytext(sql_text, 1, length(sql_text)) // Remove the last ,
	returned_list.Add(ckey) // Second-to-last item is the ckey (second to last joker)
	returned_list.Add(slot) // Last item is the slot (last joker)
	returned_list[1] = "[sql_text][sql_text_end]"
	return returned_list
