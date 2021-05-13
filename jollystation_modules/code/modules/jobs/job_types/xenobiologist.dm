// -- Xenobiologist job & outfit datum --
/datum/job/xenobiologist
	title = "Xenobiologist"
	department_head = list("Research Director")
	faction = "Station"
	total_positions = 2
	spawn_positions = 3
	supervisors = "the research director"
	selection_color = "#ffeeff"
	exp_requirements = 60
	exp_type = EXP_TYPE_CREW


	outfit = /datum/outfit/job/scientist/xenobiologist
	plasmaman_outfit = /datum/outfit/plasmaman/science

	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_SCI

	display_order = JOB_DISPLAY_ORDER_SCIENTIST
	bounty_types = CIV_JOB_SCI

	family_heirlooms = list(/obj/item/toy/plush/slimeplushie)

/datum/outfit/job/scientist/xenobiologist
	name = "Xenobiologist"
	suit = /obj/item/clothing/suit/toggle/labcoat/xenobio
	uniform = /obj/item/clothing/under/rank/rnd/xenobiologist
	jobtype = /datum/job/xenobiologist
	id_trim = /datum/id_trim/job/xenobiologist
