/// The advanced antag datum - the datum that runs our advanced antags.
/datum/advanced_antag_datum
	/// The antagonist this datum is linked to.
	var/datum/antagonist/linked_antagonist
	/// Changed to "Traitor" on spawn, but can be changed by the player.
	var/name = "Advanced Antagonist"
	/// Can be changed by the player.
	var/employer = "The Badmins"
	/// This player's backstory for their antag - optional, can be empty/null
	var/backstory = ""
	/// The style of this antag's UI.
	var/style = "neutral"
	/// The starting "traitor fun points" for our antag. TC, processing power, etc.
	var/starting_points = 0
	/// Lazylist of our goals datums linked to this antag.
	var/list/datum/advanced_antag_goal/our_goals
	/// List of objectives we can add to similar objectives.
	var/static/list/possible_objectives = list()
	/// Whether our goals are finalized.
	var/finalized = FALSE
	/// All advanced traitor panels we have open (assoc list user to panel)
	var/list/open_panels

/datum/advanced_antag_datum/New(datum/antagonist/linked_antag)
	src.linked_antagonist = linked_antag
	src.name = linked_antagonist.name

/datum/advanced_antag_datum/Destroy()
	remove_verb(linked_antagonist.owner.current, /mob/proc/open_advanced_antag_panel)
	linked_antagonist = null
	QDEL_LIST(our_goals)

	for(var/panel_user in open_panels)
		var/datum/adv_traitor_panel/tgui_panel = open_panels[panel_user]
		tgui_panel.ui_close(panel_user)

	return ..()

/// Give the antagonist the verb to open their goal panel.
/datum/advanced_antag_datum/proc/setup_advanced_antag()
	linked_antagonist.antag_memory += "Use the \"Antagonist - Set Goals\" verb to set your goals.<br>"

	/// Only giving them one objective as a reminder - "Set your goals". Only shows up in their memory.
	var/datum/objective/custom/custom_objective = new
	custom_objective.explanation_text = "Set your custom goals via the IC tab."
	linked_antagonist.objectives += custom_objective

	add_advanced_goal()
	show_advanced_antag_panel(linked_antagonist.owner.current)
	add_verb(linked_antagonist.owner.current, /mob/proc/open_advanced_antag_panel)

/datum/advanced_antag_datum/proc/greet_message(mob/antagonist)
	to_chat(antagonist, "<span class='alertsyndie'>You are a [name]!</span>")
	antagonist.playsound_local(get_turf(antagonist), 'jollystation_modules/sound/radiodrum.ogg', 100, FALSE, pressure_affected = FALSE, use_reverb = FALSE)
	addtimer(CALLBACK(src, .proc/greet_message_two, antagonist), 3 SECONDS)

/// Give them details on what their role actually means to them, then move to greet_three after 3 seconds.
/datum/advanced_antag_datum/proc/greet_message_two(mob/antagonist)
	to_chat(antagonist, "<span class='danger'>You are a story driven antagonist! You can set your goals to whatever you think would make an interesting story or round. You have access to your goal panel via your IC tab.</span>")
	addtimer(CALLBACK(src, .proc/greet_message_three, antagonist), 3 SECONDS)

/// Give them a short guide on how to use the goal panel, and what all the buttons do.
/datum/advanced_antag_datum/proc/greet_message_three(mob/antagonist)
	to_chat(antagonist, "<span class='danger'>In your goal panel, you should set a few goals to get started and finalize them to recieve your uplink. If you're not sure how to use the panel or its functions, use the inbuilt tutorial.</span>")


/* Updates the user's currently open TGUI panel, or open a new panel if they don't have one.
 *
 * user - the user, opening the panel (usually, [owner.current], but sometimes admins)
 */
/datum/advanced_antag_datum/proc/show_advanced_antag_panel(mob/user)
	if(istype(user, /client))
		var/client/our_client = user
		user = our_client.mob
	else if(istype(user, /datum/mind))
		var/datum/mind/our_mind = user
		user = our_mind.current

	var/datum/adv_traitor_panel/tgui
	if(LAZYLEN(open_panels))
		tgui = open_panels[user]
		if(tgui)
			tgui.ui_interact(user, tgui.open_ui)
			return

	tgui = new(user, src)
	tgui.ui_interact(user)
	LAZYADDASSOC(open_panels, user, tgui)

/datum/advanced_antag_datum/proc/cleanup_advanced_traitor_panel(mob/viewer)
	open_panels[viewer] = null
	open_panels -= viewer

	if(!LAZYLEN(open_panels))
		open_panels = null

/// Modify the traitor's starting_points (TC or processing points) based on their goals.
/datum/advanced_antag_datum/proc/modify_antag_points()
	return 0 // Unimplemented

/// Calculate the traitor's starting TC or processing points based on their goal's intensity levels.
/datum/advanced_antag_datum/proc/get_antag_points_from_goals()
	return 0 // Unimplemented

/// Get the text that shows up in the tooltip of the finalize button
/datum/advanced_antag_datum/proc/get_finalize_text()
	return 0 // Unimplemented

/// Actions to do after the antag finalizes their goals.
/datum/advanced_antag_datum/proc/post_finalize_actions()
	SHOULD_CALL_PARENT(TRUE)
	if(finalized)
		return FALSE

	modify_antag_points()
	log_goals_on_finalize(linked_antagonist.owner.current)
	finalized = TRUE
	return TRUE

/// Miscellaneous logging for the antagonist's goals after they finalize them.
/datum/advanced_antag_datum/proc/log_goals_on_finalize(mob/antagonist)
	message_admins("[ADMIN_LOOKUPFLW(antagonist)] finalized their objectives. They began with [starting_points] antagonist points as a [linked_antagonist.name]. ")
	log_game("[key_name(antagonist)] finalized their objectives. Their began with [starting_points] antagonist points as a [linked_antagonist.name]. ")
	if(!LAZYLEN(our_goals))
		message_admins("No set goal: [ADMIN_LOOKUPFLW(antagonist)] finalized their goals with 0 goals set.")
		return

	for(var/datum/advanced_antag_goal/goals in our_goals)
		if(goals.goal)
			if(goals.intensity >= 4)
				message_admins("High intensity goal: [ADMIN_LOOKUPFLW(antagonist)] finalized an intensity [goals.intensity] goal: [goals.goal]")
			else if(goals.intensity == 0)
				message_admins("Potential error: [ADMIN_LOOKUPFLW(antagonist)] finalized an intensity 0 goal: [goals.goal]")
		else if(goals.intensity > 0)
			message_admins("Potential exploit: [ADMIN_LOOKUPFLW(antagonist)] finalized an intensity [goals.intensity] goal with no goal text. Potential exploit of goals for extra TC.")
		else
			message_admins("Potential error: [ADMIN_LOOKUPFLW(antagonist)] finalized a goal with no goal text.")

		if(goals.notes)
			message_admins("Finalized goal note: [ADMIN_LOOKUPFLW(antagonist)] finalized a goal with additional notes: [goals.notes]")

		log_game("[key_name(antagonist)] finalized an intensity [goals.intensity] goal: [goals.goal] (notes: [goals.notes]).")

/datum/advanced_antag_datum/proc/set_name(name)
	src.name = strip_html_simple(name, MAX_NAME_LEN)

/datum/advanced_antag_datum/proc/set_employer(employer)
	src.employer = strip_html_simple(employer, MAX_NAME_LEN)

/datum/advanced_antag_datum/proc/set_backstory(backstory)
	src.backstory = strip_html_simple(backstory, MAX_MESSAGE_LEN)

/// Initialize a new goal and append it to our lazylist
/datum/advanced_antag_datum/proc/add_advanced_goal()
	var/datum/advanced_antag_goal/new_goal = new(src)
	LAZYADD(our_goals, new_goal)

/// Remove a goal from our lazylist and qdel it
/// old_goal - reference to the goal we're removing
/datum/advanced_antag_datum/proc/remove_advanced_goal(datum/advanced_antag_goal/old_goal)
	LAZYREMOVE(our_goals, old_goal)
	qdel(old_goal)

/// A mob proc / verb that lets the antagonist open up their goal panel in game.
/mob/proc/open_advanced_antag_panel()
	set name = "Antagonist - Set Goals"
	set category = "IC"

	for(var/datum/antagonist/antag_datum in mind?.antag_datums)
		if(!antag_datum.linked_advanced_datum)
			continue
		antag_datum.linked_advanced_datum.show_advanced_antag_panel(src)
		return

	to_chat(src, "You shouldn't have this!")
	remove_verb(src, /mob/proc/open_advanced_antag_panel)
	return
