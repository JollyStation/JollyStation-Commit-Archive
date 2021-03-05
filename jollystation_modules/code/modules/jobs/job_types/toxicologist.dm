/datum/job/toxicologist
	title = "Toxicologist"
	department_head = list("Research Director")
	faction = "Station"
	total_positions = 1
	spawn_positions = 3
	supervisors = "the research director"
	selection_color = "#ffeeff"
	exp_requirements = 60
	exp_type = EXP_TYPE_CREW

//most likely can be subtyped later

	outfit = /datum/outfit/job/scientist/toxicologist

	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_SCI

	display_order = JOB_DISPLAY_ORDER_SCIENTIST
	bounty_types = CIV_JOB_SCI

/datum/outfit/job/scientist/toxicologist
	name = "Toxicologist"
	suit = /obj/item/clothing/suit/toggle/labcoat/toxic
	uniform = /obj/item/clothing/under/rank/rn/toxicologist
	jobtype = /datum/job/toxicologist
	id_trim = /datum/id_trim/job/toxicologist
