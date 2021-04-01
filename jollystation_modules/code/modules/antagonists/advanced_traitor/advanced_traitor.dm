/// "Traitor plus" or "Advanced traitor" - a traitor that is able to set their own goals and objectives when in game.
/// Loosely based on the ambitions system from skyrat, but made less bad.
/datum/antagonist/traitor/traitor_plus
	/// Changed to "Traitor" on spawn, but can be changed by the player.
	name = "Advanced Traitor"
	/// Edited to ([starting_tc] / 40).
	hijack_speed = 0.5
	/// Can be changed by the player.
	employer = "The Syndicate"
	/// We don't give them standard traitor objectives.
	give_objectives = FALSE
	/// We don't give any codewords out.
	should_give_codewords = FALSE
	/// We equip our traitor after they finish their goals.
	should_equip = FALSE
	/// We finalize our antag when they finish their goals.
	finalize_antag = FALSE
	/// List of objectives AIs can get, because apparently they're not initialized anywhere like normal objectives.
	var/static/list/ai_objectives = list("no organics on shuttle" = /datum/objective/block, "no mutants on shuttle" = /datum/objective/purge, "robot army" = /datum/objective/robot_army, "survive AI" = /datum/objective/survive/malf)

/datum/antagonist/traitor/traitor_plus/on_gain()
	if(!GLOB.admin_objective_list)
		generate_admin_objective_list()

	var/list/objectives_to_choose = GLOB.admin_objective_list.Copy() - blacklisted_similar_objectives
	switch(traitor_kind)
		if(TRAITOR_AI)
			name = "Malfunctioning AI"
			objectives_to_choose -= blacklisted_ai_objectives
			objectives_to_choose += ai_objectives
		if(TRAITOR_HUMAN)
			name = "Traitor"

	linked_advanced_datum = new /datum/advanced_antag_datum/traitor(src)
	linked_advanced_datum.setup_advanced_antag()
	linked_advanced_datum.possible_objectives = objectives_to_choose
	return ..()

/datum/antagonist/traitor/traitor_plus/on_removal()
	qdel(linked_advanced_datum)
	return ..()

/// Greet the antag with big menacing text, then move to greet_two after 3 seconds.
/datum/antagonist/traitor/traitor_plus/greet()
	linked_advanced_datum.greet_message(owner.current)

/datum/antagonist/traitor/traitor_plus/roundend_report()
	var/list/result = list()

	result += printplayer(owner)
	result += "<b>[owner]</b> was \a <b>[name]</b>[employer? " employed by <b>[employer]</b>":""]."
	if(linked_advanced_datum.backstory)
		result += "<b>[owner]'s</b> backstory was the following: <br>[linked_advanced_datum.backstory]"

	var/TC_uses = 0
	var/uplink_true = FALSE
	var/purchases = ""

	if(should_equip)
		LAZYINITLIST(GLOB.uplink_purchase_logs_by_key)
		var/datum/uplink_purchase_log/H = GLOB.uplink_purchase_logs_by_key[owner.key]
		if(H)
			uplink_true = TRUE
			TC_uses = H.total_spent
			purchases += H.generate_render(FALSE)

	if(LAZYLEN(linked_advanced_datum.our_goals))
		var/count = 1
		for(var/datum/advanced_antag_goal/goal in linked_advanced_datum.our_goals)
			result += goal.get_roundend_text(count)
			count++
		if(uplink_true)
			result += "<br>They were afforded <b>[linked_advanced_datum.starting_points]</b> tc to accomplish these tasks."

	if(uplink_true)
		var/uplink_text = "(used [TC_uses] TC) [purchases]"
		result += uplink_text
		if (contractor_hub)
			result += contractor_round_end()
	else if (!should_equip)
		result += "<br>The [name] never obtained their uplink!"

	return result.Join("<br>")

/datum/antagonist/traitor/traitor_plus/roundend_report_footer()
	return "<br>And thus ends another story on board [station_name()]."

/// An extra button for the TP, to open the goal panel
/datum/antagonist/traitor/traitor_plus/get_admin_commands()
	. = ..()
	.["View Goals"] = CALLBACK(src, .proc/show_advanced_traitor_panel, usr)

/// An extra button for check_antagonists, to open the goal panel
/datum/antagonist/traitor/traitor_plus/antag_listing_commands()
	. = ..()
	. += "<a href='?_src_=holder;[HrefToken()];admin_check_goals=[REF(src)]'>Show Goals</a>"

/datum/advanced_antag_datum/traitor
	name = "Advanced Traitor"
	employer = "The Syndicate"
	style = "syndicate"
	starting_points = 8
	var/datum/antagonist/traitor/traitor_plus/our_traitor
	var/antag_type

/datum/advanced_antag_datum/traitor/New(datum/antagonist/linked_antag)
	. = ..()
	our_traitor = linked_antag
	antag_type = our_traitor.traitor_kind

/datum/advanced_antag_datum/traitor/modify_antag_points()
	switch(antag_type)
		if(TRAITOR_HUMAN)
			var/datum/component/uplink/made_uplink = linked_antagonist.owner.find_syndicate_uplink()
			if(!made_uplink)
				return

			starting_points = get_antag_points_from_goals()
			made_uplink.telecrystals = starting_points
			linked_antagonist.hijack_speed = (20 / starting_points) // 20 tc traitor = 0.5 (default traitor hijack speed)
		if(TRAITOR_AI)
			var/mob/living/silicon/ai/traitor_ai = linked_antagonist.owner.current
			var/datum/module_picker/traitor_ai_uplink = traitor_ai.malf_picker
			starting_points = get_antag_points_from_goals()
			traitor_ai_uplink.processing_time = starting_points

/datum/advanced_antag_datum/traitor/get_antag_points_from_goals()
	switch(antag_type)
		if(TRAITOR_HUMAN)
			var/finalized_starting_tc = TRAITOR_PLUS_INITIAL_TC
			for(var/datum/advanced_antag_goal/goal in our_goals)
				finalized_starting_tc += (goal.intensity * 2)

			return min(finalized_starting_tc, TRAITOR_PLUS_MAX_TC)
		if(TRAITOR_AI)
			var/finalized_starting_points = TRAITOR_PLUS_INITIAL_MALF_POINTS
			for(var/datum/advanced_antag_goal/goal in our_goals)
				finalized_starting_points += (goal.intensity * 5)

			return min(finalized_starting_points, TRAITOR_PLUS_MAX_MALF_POINTS)

/datum/advanced_antag_datum/traitor/get_finalize_text()
	switch(antag_type)
		if(TRAITOR_AI)
			return "Finalizing will begin installlation of your malfunction module with [get_antag_points_from_goals()] processing power. You can still edit your goals after finalizing!"
		if(TRAITOR_HUMAN)
			return "Finalizing will send you your uplink to your preferred location with [get_antag_points_from_goals()] telecrystals. You can still edit your goals after finalizing!"

/datum/advanced_antag_datum/traitor/post_finalize_actions()
	. = ..()
	if(!.)
		return

	our_traitor.should_equip = TRUE
	our_traitor.finalize_traitor()
	modify_antag_points()

/datum/advanced_antag_datum/traitor/set_employer(employer)
	. = ..()
	our_traitor.employer = src.employer
