/obj/item/encryptionkey/heads/bridge_officer
	name = "\proper the bridge officer's encryption key"
	icon_state = "hop_cypherkey"
	channels = list(RADIO_CHANNEL_SECURITY = 1, RADIO_CHANNEL_COMMAND = 1)

/obj/item/encryptionkey/heads/qm
	name = "\proper the quartermaster's encryption key"
	icon_state = "qm_cypherkey"
	channels = list(RADIO_CHANNEL_SUPPLY = 1, RADIO_CHANNEL_COMMAND = 1)

// Redefinition of the HoP key's valid channels. Supply is gone. We are free.
/obj/item/encryptionkey/heads/hop
	channels = list(RADIO_CHANNEL_SERVICE = 1, RADIO_CHANNEL_COMMAND = 1)
