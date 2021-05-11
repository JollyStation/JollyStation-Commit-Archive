// -- Modular minor gadgets/devices that go in the uplink. --
/// A small beacon / controller that can be used to send centcom reports IC.
/obj/item/item_announcer
	name = "FK-\"Deception\" Falty Announcement Device"
	desc = "Designed by MI13, the FK-Deception Falty Announcement Device allows an \
		enterprising syndicate agent attempting to maintain their cover a \
		one-time faked message (announced or classified) from a certain source."
	icon = 'icons/obj/device.dmi'
	icon_state = "locator"
	w_class = WEIGHT_CLASS_SMALL
	/// The syndicate who purchased this beacon - only they can use this item. No sharing.
	var/mob/owner = null
	/// The amount of reports we can send before breaking.
	var/uses = 1

/obj/item/item_announcer/examine(mob/user)
	. = ..()
	. += "<span class='notice'>It has [uses] uses left.</span>"

/// Deletes the item when it's used up.
/obj/item/item_announcer/proc/break_item(mob/user)
	to_chat(user, "<span class='notice'>The [src] breaks down into unrecognizable scrap and ash after being used.</span>")
	var/obj/effect/decal/cleanable/ash/spawned_ash = new(drop_location())
	spawned_ash.desc = "Ashes to ashes, dust to dust. There's a few pieces of scrap in this pile."
	qdel(src)

/// User sends a preset false alarm.
/obj/item/item_announcer/preset
	/// The name of the fake event, so we don't have to init it.
	var/fake_event_name = ""
	/// What false alarm this item triggers.
	var/fake_event = null

/obj/item/item_announcer/preset/Initialize()
	. = ..()
	if(fake_event)
		for(var/datum/round_event_control/init_event in SSevents.control)
			if(ispath(fake_event, init_event.type))
				fake_event = init_event
				break

/obj/item/item_announcer/preset/examine(mob/user)
	. = ..()
	. += "<span class='notice'>It causes a fake \"[fake_event_name]\" when used.</span>"

/obj/item/item_announcer/preset/attack_self(mob/user)
	. = ..()
	if(owner && owner != user)
		to_chat(user, "<span class='warning'>Identity check failed.</span>")
	else
		if(trigger_announcement(user) && uses <= 0)
			break_item(user)

/obj/item/item_announcer/preset/proc/trigger_announcement(mob/user)
	var/datum/round_event_control/falsealarm/triggered_event = new()
	if(!fake_event)
		return FALSE
	triggered_event.forced_type = fake_event
	triggered_event.runEvent(FALSE)
	to_chat(user, "<span class='notice'>You press the [src], triggering a false alarm for [fake_event_name].</span>")
	deadchat_broadcast("<span class='bold'>[user] has triggered a false alarm using a syndicate device!</span>", follow_target = user)
	message_admins("[ADMIN_LOOKUPFLW(user)] has triggered a false alarm using a syndicate device: \"[fake_event_name]\".")
	log_game("[key_name(user)] has triggered a false alarm using a syndicate device: \"[fake_event_name]\".")
	uses--

	return TRUE

/obj/item/item_announcer/preset/ion
	fake_event_name = "Ion Storm"
	fake_event = /datum/round_event_control/ion_storm

/obj/item/item_announcer/preset/rad
	fake_event_name = "Radiation Storm"
	fake_event = /datum/round_event_control/radiation_storm

/// Allows users to input a custom announcement message.
/obj/item/item_announcer/input
	/// The name of central command that will accompany our fake report.
	var/fake_command_name = "???"
	/// The actual contents of the report we're going to send.
	var/command_report_content
	/// Whether the report is an announced report or a classified report.
	var/announce_contents = TRUE

/obj/item/item_announcer/input/attack_self(mob/user)
	if(owner && owner != user)
		to_chat(user, "<span class='warning'>Identity check failed.</span>")
		return TRUE
	. = ..()

/obj/item/item_announcer/input/examine(mob/user)
	. = ..()
	. += "<span class='notice'>It sends messages from \"[fake_command_name]\".</span>"

/obj/item/item_announcer/input/ui_state(mob/user)
	return GLOB.inventory_state

/obj/item/item_announcer/input/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "_FakeCommandReport")
		ui.open()

/obj/item/item_announcer/input/ui_data(mob/user)
	var/list/data = list()
	data["command_name"] = fake_command_name
	data["command_report_content"] = command_report_content
	data["announce_contents"] = announce_contents

	return data

/obj/item/item_announcer/input/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("update_report_contents")
			command_report_content = params["updated_contents"]
		if("toggle_announce")
			announce_contents = !announce_contents
		if("submit_report")
			if(!command_report_content)
				to_chat(usr, "<span class='danger'>You can't send a report with no contents.</span>")
				return
			if(owner && usr != owner)
				to_chat(usr, "<span class='warning'>Identity check failed.</span>")
				return
			if(send_announcement(usr) && uses <= 0)
				break_item(usr)
				return

	return TRUE

/// Send our announcement from [user] and decrease the amount of uses.
/obj/item/item_announcer/input/proc/send_announcement(mob/user)
	/// Our current command name to swap back to after sending the report.
	var/original_command_name = command_name()
	change_command_name(fake_command_name)

	if(announce_contents)
		priority_announce(command_report_content, null, SSstation.announcer.get_rand_report_sound(), has_important_message = TRUE)
	print_command_report(command_report_content, "[announce_contents ? "" : "Classified "][fake_command_name] Update", !announce_contents)

	change_command_name(original_command_name)

	to_chat(user, "<span class='notice'>You tap on the [src], sending a [announce_contents ? "" : "classified "]report from [fake_command_name].</span>")
	deadchat_broadcast("<span class='bold'>[user] has triggered an announcement using a syndicate device!</span>", follow_target = user)
	message_admins("[ADMIN_LOOKUPFLW(user)] has sent a fake command report using a syndicate device: \"[command_report_content]\".")
	log_game("[key_name(user)] has sent a fake command report using a syndicate device: \"[command_report_content]\", sent from \"[fake_command_name]\".")
	uses--

	return TRUE

/obj/item/item_announcer/input/centcom
	fake_command_name = "Central Command"

/obj/item/item_announcer/input/syndicate
	fake_command_name = "The Syndicate"
	uses = 2
