/// -- Extensions of species and species procs. --
/datum/species
	/// Assoc list of [sounds that play on speech] to [volume].
	var/speech_sounds = list('jollystation_modules/sound/voice/speak_1.ogg' = 120, \
							'jollystation_modules/sound/voice/speak_2.ogg' = 120, \
							'jollystation_modules/sound/voice/speak_3.ogg' = 120, \
							'jollystation_modules/sound/voice/speak_4.ogg' = 120)
	/// Assoc list of [sounds that play on question] to [volume].
	var/speech_sounds_ask = list('jollystation_modules/sound/voice/speak_1_ask.ogg' = 120, \
								'jollystation_modules/sound/voice/speak_2_ask.ogg' = 120, \
								'jollystation_modules/sound/voice/speak_3_ask.ogg' = 120, \
								'jollystation_modules/sound/voice/speak_4_ask.ogg' = 120)
	/// Assoc list of [sounds that play on exclamation] to [volume].
	var/speech_sounds_exclaim = list('jollystation_modules/sound/voice/speak_1_exclaim.ogg' = 120, \
								'jollystation_modules/sound/voice/speak_2_exclaim.ogg' = 120, \
								'jollystation_modules/sound/voice/speak_3_exclaim.ogg' = 120, \
								'jollystation_modules/sound/voice/speak_4_exclaim.ogg' = 120)
