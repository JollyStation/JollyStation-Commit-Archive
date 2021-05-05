/// -- PDA extension and additions. --
/// This proc adds modular PDAs into the PDA painter. Don't forget to update it or else you can't paint added PDAs.
/proc/get_modular_PDA_regions()
	return list(/obj/item/pda/heads/bridge_officer = list(REGION_COMMAND))

/obj/item/pda
	var/alt_icon = 'jollystation_modules/icons/obj/pda.dmi'

/obj/item/pda/heads/bridge_officer
	name = "bridge officer PDA"
	default_cartridge = /obj/item/cartridge/hos
	icon_state = "pda-bo"

/// Somewhat hacky way of swapping between modular DMI and base DMI. This needs to be defined for all modular PDAs.
/obj/item/pda/heads/bridge_officer/update_appearance()
	if(icon_state == initial(icon_state))
		icon = alt_icon
	else
		icon = initial(icon)

	. = ..()
