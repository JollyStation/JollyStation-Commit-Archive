/// -- The loadout manager and UI --
/// Defines for what loadout slot a corresponding item belongs to.
#define LOADOUT_ITEM_BELT "belt"
#define LOADOUT_ITEM_EARS "ears"
#define LOADOUT_ITEM_GLASSES "glasses"
#define LOADOUT_ITEM_GLOVES "gloves"
#define LOADOUT_ITEM_HEAD "head"
#define LOADOUT_ITEM_MASK "mask"
#define LOADOUT_ITEM_NECK "neck"
#define LOADOUT_ITEM_SHOES "shoes"
#define LOADOUT_ITEM_SUIT "suit"
#define LOADOUT_ITEM_UNIFORM "under"
#define LOADOUT_ITEM_INHAND "inhand_items" //Divides into the two below slots
#define LOADOUT_ITEM_LEFT_HAND "left_hand"
#define LOADOUT_ITEM_RIGHT_HAND "right_hand"
#define LOADOUT_ITEM_MISC "pocket_items" //Divides into the three below slots
#define LOADOUT_ITEM_BACKPACK_1 "backpack_1"
#define LOADOUT_ITEM_BACKPACK_2 "backpack_2"
#define LOADOUT_ITEM_BACKPACK_3 "backpack_3"

/* Takes an assoc list of [string]s to [typepaths]s
 * (Such as the global assoc lists of loadout items)
 * And formats it into an object for TGUI.
 *
 *  - list[name] is the string / key of the item.
 *  - list[path] is the typepath of the item.
 */
/proc/list_to_data(assoc_item_list)
	if(!LAZYLEN(assoc_item_list))
		return null

	var/list/formatted_list = new(length(assoc_item_list))

	var/array_index = 1
	for(var/path_id in assoc_item_list)
		var/list/formatted_item = list()
		formatted_item["name"] = path_id
		formatted_item["path"] = assoc_item_list[path_id]
		formatted_list[array_index++] = formatted_item

	return formatted_list

/// An empty outfit we fill in with our loadout items to dress our dummy.
/datum/outfit/player_loadout
	name = "Player Loadout"

/// Tracking when a client has an open loadout manager, to prevent funky stuff.
/client
	/// A ref to loadout_manager datum.
	var/datum/loadout_manager/open_loadout_ui = null

/// Datum holder for the loadout manager UI.
/datum/loadout_manager
	/// The client of the person using the UI
	var/client/owner
	/// The loadout list we had when we opened the UI.
	var/list/loadout_on_open
	/// The key of the dummy we use to generate sprites
	var/dummy_key
	/// The dir the dummy is facing.
	var/list/dummy_dir = list(SOUTH)
	/// A ref to the dummy outfit we're using
	var/datum/outfit/player_loadout/custom_loadout
	/// Whether we see our favorite job's clothes on the dummy
	var/view_job_clothes = TRUE
	/// Whether we see tutorial text in the UI
	var/tutorial_status = FALSE

/datum/loadout_manager/New(user)
	owner = CLIENT_FROM_VAR(user)
	custom_loadout = new()
	owner.open_loadout_ui = src
	if(!owner.prefs.loadout_list)
		owner.prefs.loadout_list = list()
	loadout_on_open = owner.prefs.loadout_list.Copy()
	loadout_to_outfit()

/datum/loadout_manager/ui_close(mob/user)
	owner.open_loadout_ui = null
	clear_human_dummy(dummy_key)
	qdel(custom_loadout)
	qdel(src)

/// Initialize our dummy and dummy_key.
/datum/loadout_manager/proc/init_dummy()
	dummy_key = "loadoutmanagerUI_[owner.mob]"
	generate_dummy_lookalike(dummy_key, owner.mob)
	unset_busy_human_dummy(dummy_key)
	return

/datum/loadout_manager/ui_state(mob/user)
	return GLOB.always_state

/datum/loadout_manager/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "_LoadoutManager")
		ui.open()

/datum/loadout_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		// Turns the tutorial on and off.
		if("toggle_tutorial")
			tutorial_status = !tutorial_status

		// Either equips or de-equips the params["path"] item into params["category"]
		if("select_item")
			var/category_slot = params["category"]
			if(params["doReset"])
				if(category_slot == LOADOUT_ITEM_MISC || category_slot == LOADOUT_ITEM_INHAND)
					for(var/slot_key in owner.prefs.loadout_list)
						if(owner.prefs.loadout_list[slot_key] == params["path"])
							category_slot = slot_key
							break

				owner.prefs.loadout_list[category_slot] = null
				loadout_to_outfit()
				owner.prefs.loadout_list -= category_slot
			else
				if(category_slot == LOADOUT_ITEM_MISC)
					if(!owner.prefs.loadout_list[LOADOUT_ITEM_BACKPACK_1])
						category_slot = LOADOUT_ITEM_BACKPACK_1
					else if(!owner.prefs.loadout_list[LOADOUT_ITEM_BACKPACK_2])
						category_slot = LOADOUT_ITEM_BACKPACK_2
					else
						category_slot = LOADOUT_ITEM_BACKPACK_3
				if(category_slot == LOADOUT_ITEM_INHAND)
					if(!owner.prefs.loadout_list[LOADOUT_ITEM_LEFT_HAND])
						category_slot = LOADOUT_ITEM_LEFT_HAND
					else
						category_slot = LOADOUT_ITEM_RIGHT_HAND

				owner.prefs.loadout_list[category_slot] = params["path"]

		// Clears the loadout list entirely.
		if("clear_all_items")
			owner.prefs.loadout_list.Cut()

		// Toggles between viewing favorite job clothes on the dummy.
		if("toggle_job_clothes")
			view_job_clothes = !view_job_clothes

		// Rotates the dummy left or right depending on params["dir"]
		if("rotate_dummy")
			if(dummy_dir.len > 1)
				dummy_dir = list(SOUTH)
			else
				if(params["dir"] == "left")
					switch(dummy_dir[1])
						if(SOUTH)
							dummy_dir[1] = WEST
						if(EAST)
							dummy_dir[1] = SOUTH
						if(NORTH)
							dummy_dir[1] = EAST
						if(WEST)
							dummy_dir[1] = NORTH
				else
					switch(dummy_dir[1])
						if(SOUTH)
							dummy_dir[1] = EAST
						if(EAST)
							dummy_dir[1] = NORTH
						if(NORTH)
							dummy_dir[1] = WEST
						if(WEST)
							dummy_dir[1] = SOUTH

		// Toggles between showing all dirs of the dummy at once.
		if("show_all_dirs")
			if(dummy_dir.len > 1)
				dummy_dir = list(SOUTH)
			else
				dummy_dir = GLOB.cardinals

		// Closes the UI, reverting our loadout to before edits if params["revert"] is set
		if("close_ui")
			if(params["revert"])
				owner.prefs.loadout_list = loadout_on_open
			SStgui.close_uis(src)
			return

	// Always update our loadout after we do something.
	loadout_to_outfit()
	return TRUE

/datum/loadout_manager/ui_data(mob/user)
	var/list/data = list()
	if(!dummy_key)
		init_dummy()

	var/icon/dummysprite = get_flat_human_icon(null,
		dummy_key = dummy_key,
		outfit_override = custom_loadout,
		showDirs = dummy_dir,
		)
	data["icon64"] = icon2base64(dummysprite)

	var/list/all_selected_paths = list()
	for(var/path_id in owner.prefs.loadout_list)
		all_selected_paths += owner.prefs.loadout_list[path_id]

	data["selected_loadout"] = all_selected_paths
	data["mob_name"] = owner.prefs.real_name
	data["ismoth"] = istype(owner.prefs.pref_species, /datum/species/moth) // Moth's humanflaticcon isn't the same dimensions for some reason
	data["job_clothes"] = view_job_clothes
	data["tutorial_status"] = tutorial_status
	if(tutorial_status)
		data["tutorial_text"] = get_tutorial_text()

	return data

/datum/loadout_manager/ui_static_data()
	var/list/data = list()

	// [ID] is the displayed name of the slot.
	// [slot] is the internal name of the slot.
	// [contents] is a formatted list of all the possible items for that slot.
	//  - [contents.name] is the key of the item in the global assoc list.
	//  - [contents.path] is the typepath of the item in the global assoc list.
	var/list/loadout_tabs = list()
	loadout_tabs += list(list("id" = "Belt", "slot" = LOADOUT_ITEM_BELT, "contents" = list_to_data(GLOB.loadout_belts)))
	loadout_tabs += list(list("id" = "Ears", "slot" = LOADOUT_ITEM_EARS, "contents" = list_to_data(GLOB.loadout_ears)))
	loadout_tabs += list(list("id" = "Glasses", "slot" = LOADOUT_ITEM_GLASSES, "contents" = list_to_data(GLOB.loadout_glasses)))
	loadout_tabs += list(list("id" = "Gloves", "slot" = LOADOUT_ITEM_GLOVES, "contents" = list_to_data(GLOB.loadout_gloves)))
	loadout_tabs += list(list("id" = "Head", "slot" = LOADOUT_ITEM_HEAD, "contents" = list_to_data(GLOB.loadout_helmets)))
	loadout_tabs += list(list("id" = "Mask", "slot" = LOADOUT_ITEM_MASK, "contents" = list_to_data(GLOB.loadout_masks)))
	loadout_tabs += list(list("id" = "Neck", "slot" = LOADOUT_ITEM_NECK, "contents" = list_to_data(GLOB.loadout_necks)))
	loadout_tabs += list(list("id" = "Shoes", "slot" = LOADOUT_ITEM_SHOES, "contents" = list_to_data(GLOB.loadout_shoes)))
	loadout_tabs += list(list("id" = "Suit", "slot" = LOADOUT_ITEM_SUIT, "contents" = list_to_data(GLOB.loadout_exosuits)))
	loadout_tabs += list(list("id" = "Jumpsuit", "slot" = LOADOUT_ITEM_UNIFORM, "contents" = list_to_data(GLOB.loadout_jumpsuits)))
	loadout_tabs += list(list("id" = "Formal", "slot" = LOADOUT_ITEM_UNIFORM, "contents" = list_to_data(GLOB.loadout_undersuits)))
	loadout_tabs += list(list("id" = "Misc. Under", "slot" = LOADOUT_ITEM_UNIFORM, "contents" = list_to_data(GLOB.loadout_miscunders)))
	loadout_tabs += list(list("id" = "Inhand (2 max)", "slot" = LOADOUT_ITEM_INHAND, "contents" = list_to_data(GLOB.loadout_inhand_items)))
	loadout_tabs += list(list("id" = "Misc. (3 max)", "slot" = LOADOUT_ITEM_MISC, "contents" = list_to_data(GLOB.loadout_pocket_items)))

	data["loadout_tabs"] = loadout_tabs

	return data

/// Returns a formatted string for use in the UI.
/datum/loadout_manager/proc/get_tutorial_text()
	return {"This is the Loadout Manager.
It allows you to customize what your character will wear on shift start in addition to their job's uniform.

Only one item can be selected per tab, with some exceptions.
Inhand items (one item is allowed per hand)
Miscellaneous items (three items are allowed in total - they will spawn in your backpack).

Your loadout items will override the corresponding item in your job's outfit,
with the exception being BELT, EAR, and GLASSES items,
which will be placed in your backpack to prevent important items being deleted.

Additionally, UNDERSUITS, HELMETS, MASKS, and GLOVES loadout items
selected by plasmamen will spawn in their backpack instead of overriding their clothes
to avoid an untimely and sudden death by fire or suffocation at the start of the shift."}

/// Turns our client's assoc list of loadout items into actual items on our dummy outfit.
/// Also loads job clothes into our custom list to show what gets overriden.
/datum/loadout_manager/proc/loadout_to_outfit()
	var/datum/outfit/default_outfit
	if(view_job_clothes)
		var/datum/job/fav_job = SSjob.GetJob("Assistant")
		for(var/selected_job in owner.prefs.job_preferences)
			if(owner.prefs.job_preferences[selected_job] == JP_HIGH)
				fav_job = SSjob.GetJob(selected_job)
				break

		if(istype(owner.prefs.pref_species, /datum/species/plasmaman) && fav_job.plasmaman_outfit)
			default_outfit = new fav_job.plasmaman_outfit()
		else
			default_outfit = new fav_job.outfit()
	else
		default_outfit = new()

	custom_loadout.copy_from(default_outfit)
	qdel(default_outfit)

	var/list/loadout = owner.prefs.loadout_list
	if(!LAZYLEN(loadout))
		return

	for(var/slot in loadout)
		switch(slot)
			if(LOADOUT_ITEM_BELT)
				custom_loadout.belt = loadout[slot]
			if(LOADOUT_ITEM_EARS)
				custom_loadout.ears = loadout[slot]
			if(LOADOUT_ITEM_GLASSES)
				custom_loadout.glasses = loadout[slot]
			if(LOADOUT_ITEM_GLOVES)
				custom_loadout.gloves = loadout[slot]
			if(LOADOUT_ITEM_HEAD)
				custom_loadout.head = loadout[slot]
			if(LOADOUT_ITEM_MASK)
				custom_loadout.mask = loadout[slot]
			if(LOADOUT_ITEM_NECK)
				custom_loadout.neck = loadout[slot]
			if(LOADOUT_ITEM_SHOES)
				custom_loadout.shoes = loadout[slot]
			if(LOADOUT_ITEM_SUIT)
				custom_loadout.suit = loadout[slot]
			if(LOADOUT_ITEM_UNIFORM)
				custom_loadout.uniform = loadout[slot]
			if(LOADOUT_ITEM_LEFT_HAND)
				custom_loadout.l_hand = loadout[slot]
			if(LOADOUT_ITEM_RIGHT_HAND)
				custom_loadout.r_hand = loadout[slot]

/* Actually equip our mob with our job outfit and our loadout items.
 * Loadout items override the pre-existing item in the corresponding slot of the job outfit.
 * Some job items are preserved after being overridden - belt items, ear items, and glasses.
 * The rest of the slots, the items are overridden completely and deleted.
 *
 * Plasmamen are snowflaked to not have any envirosuit pieces removed just in case.
 * Their loadout items for those slots will be added to their backpack on spawn.
 *
 * outfit - the job outfit we're equipping
 * visuals_only - whether we call special equipped procs, or if we just look like we equipped it
 * preference_source - the client belonging to the thing we're equipping
 */
/mob/living/carbon/human/proc/equip_outfit_and_loadout(outfit, visuals_only = FALSE, client/preference_source)
	var/datum/outfit/equipped_outfit

	if(ispath(outfit))
		equipped_outfit = new outfit()
	else if(outfit)
		equipped_outfit = outfit
		if(!istype(equipped_outfit))
			return FALSE

	if(!outfit)
		return FALSE

	if(LAZYLEN(preference_source?.prefs?.loadout_list))
		var/list/loadout = preference_source?.prefs?.loadout_list
		for(var/slot in loadout)
			var/move_to_backpack = null
			switch(slot)
				if(LOADOUT_ITEM_BELT)
					if(equipped_outfit.belt)
						move_to_backpack = equipped_outfit.belt
					equipped_outfit.belt = loadout[slot]
				if(LOADOUT_ITEM_EARS)
					if(equipped_outfit.ears)
						move_to_backpack = equipped_outfit.ears
					equipped_outfit.ears = loadout[slot]
				if(LOADOUT_ITEM_GLASSES)
					if(equipped_outfit.glasses)
						move_to_backpack = equipped_outfit.glasses
					equipped_outfit.glasses = loadout[slot]
				if(LOADOUT_ITEM_GLOVES)
					if(isplasmaman(src))
						to_chat(src, "Your loadout gloves were not equipped directly due to your envirosuit gloves.")
						move_to_backpack = loadout[slot]
					else
						equipped_outfit.gloves = loadout[slot]
				if(LOADOUT_ITEM_HEAD)
					if(isplasmaman(src))
						to_chat(src, "Your loadout helmet was not equipped directly due to your envirosuit helmet.")
						move_to_backpack = loadout[slot]
					else
						equipped_outfit.head = loadout[slot]
				if(LOADOUT_ITEM_MASK)
					if(isplasmaman(src))
						move_to_backpack = loadout[slot]
						to_chat(src, "Your loadout mask was not equipped directly due to your envirosuit mask.")
					else
						equipped_outfit.mask = loadout[slot]
				if(LOADOUT_ITEM_NECK)
					equipped_outfit.neck = loadout[slot]
				if(LOADOUT_ITEM_SHOES)
					equipped_outfit.shoes = loadout[slot]
				if(LOADOUT_ITEM_SUIT)
					equipped_outfit.suit = loadout[slot]
				if(LOADOUT_ITEM_UNIFORM)
					if(isplasmaman(src))
						to_chat(src, "Your loadout jumpsuit was not equipped directly due to your envirosuit.")
						move_to_backpack = loadout[slot]
					else
						equipped_outfit.uniform = loadout[slot]
				if(LOADOUT_ITEM_LEFT_HAND)
					if(equipped_outfit.l_hand)
						move_to_backpack = equipped_outfit.l_hand
					equipped_outfit.l_hand = loadout[slot]
				if(LOADOUT_ITEM_RIGHT_HAND)
					if(equipped_outfit.r_hand)
						move_to_backpack = equipped_outfit.r_hand
					equipped_outfit.r_hand = loadout[slot]
				else
					move_to_backpack = loadout[slot]
			if(move_to_backpack)
				LAZYADD(equipped_outfit.backpack_contents, move_to_backpack)

	return equipped_outfit.equip(src, visuals_only)

#undef LOADOUT_ITEM_BELT
#undef LOADOUT_ITEM_EARS
#undef LOADOUT_ITEM_GLASSES
#undef LOADOUT_ITEM_GLOVES
#undef LOADOUT_ITEM_HEAD
#undef LOADOUT_ITEM_MASK
#undef LOADOUT_ITEM_NECK
#undef LOADOUT_ITEM_SHOES
#undef LOADOUT_ITEM_SUIT
#undef LOADOUT_ITEM_UNIFORM
#undef LOADOUT_ITEM_INHAND
#undef LOADOUT_ITEM_LEFT_HAND
#undef LOADOUT_ITEM_RIGHT_HAND
#undef LOADOUT_ITEM_MISC
#undef LOADOUT_ITEM_BACKPACK_1
#undef LOADOUT_ITEM_BACKPACK_2
#undef LOADOUT_ITEM_BACKPACK_3
