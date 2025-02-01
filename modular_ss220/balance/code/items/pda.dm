// MARK: PDA
/obj/item/pda
	default_cartridge = /obj/item/cartridge/common

	/// Radio to call security.
	var/obj/item/radio/radio

/obj/item/pda/Initialize(mapload)
	. = ..()
	radio = new /obj/item/radio(src)
	radio.listening = FALSE
	radio.config(list("Security" = 0))
	radio.follow_target = src

/obj/item/pda/Destroy()
	qdel(radio)
	return ..()

/obj/item/pda/syndicate
	default_cartridge = null

// MARK: Alarm Button App
/datum/data/pda/app/alarm
	name = "Call Security"
	icon = "exclamation-triangle"
	title = "Alarm Button"
	category = "Danger"
	template = "pda_alarm_button"

	/// Tells the alarm priority. TRUE for command members.
	var/prioritized = FALSE

	/// Timer to prevent spamming the alarm.
	COOLDOWN_DECLARE(alarm_cooldown)
	var/alarm_timeout = 5 MINUTES

	/// Tells if the app is on the home screen
	var/is_home = TRUE

	/// App response
	var/last_response_title = null
	var/last_response_text = null
	var/last_response_success = null
	var/last_response_acts = list()

/datum/data/pda/app/alarm/update_ui(mob/user, list/data)
	data["is_home"] = is_home
	data["last_response"] = list(
		"title" = last_response_title,
		"text" = last_response_text,
		"success" = last_response_success,
		"acts" = last_response_acts
	)
	return data

/datum/data/pda/app/alarm/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	
	if(!pda.silent)
		playsound(pda, 'sound/machines/terminal_select.ogg', 15, TRUE)
	
	switch(action)
		if("submit")
			handle_alarm_button()
		if("ok")
			is_home = TRUE

/datum/data/pda/app/alarm/proc/handle_alarm_button()
	is_home = FALSE

	if(!COOLDOWN_FINISHED(src, alarm_cooldown))
		var/remaining_time = COOLDOWN_TIMELEFT(src, alarm_cooldown)
		last_response_title = "Ошибка"
		last_response_text = "Вы недавно отправили запрос. Подождите [round(remaining_time / (1 SECONDS))] секунд, прежде чем попытаться снова."
		last_response_success = FALSE
		last_response_acts = list("ok")
		return
	
	var/turf/location = get_turf(pda)
	if(!pda.radio.on || (!is_station_level(location.z) && !is_mining_level(location.z)))
		last_response_title = "Ошибка"
		last_response_text = "Вызов службы безопасности недоступен. Попробуйте позже."
		last_response_success = FALSE
		last_response_acts = list("ok")
		return

	call_security()
	COOLDOWN_START(src, alarm_cooldown, alarm_timeout)
	last_response_title = "Запрос принят"
	last_response_text = "Служба безопасности получила ваш запрос. Пожалуйста, ожидайте прибытия офицеров."
	last_response_success = TRUE
	last_response_acts = list("ok")

/datum/data/pda/app/alarm/proc/call_security()
	var/area/area = get_area(pda)
	var/message = "Внимание! [pda.owner], [pda.ownrank], использует тревожную кнопку в [area.name]! \
		Необходимо[prioritized ? " немедленное" : ""] реагирование."
	pda.radio.autosay(
		from = "Система Оповещения",
		message = message,
		channel = DEPARTMENT_SECURITY,
		follow_target_override = pda
	)
	if(!pda.silent)
		playsound(pda, 'sound/machines/terminal_success.ogg', vol = 50, vary = TRUE)

	notify_ghosts(
		title = "Система Оповещения",
		message = "Кто-то вызвал службу безопасности!",
		ghost_sound = 'sound/effects/electheart.ogg',
		enter_link = "<a href=byond://?src=[pda.UID()];follow=1>(Click to follow)</a>",
		source = pda,
		action = NOTIFY_FOLLOW
	)

/datum/data/pda/app/alarm/heads
	prioritized = TRUE
	alarm_timeout = 2 MINUTES

/datum/data/pda/app/alarm/centcom
	prioritized = TRUE
	alarm_timeout = 1 MINUTES

// MARK: Cartidges
/obj/item/cartridge
	var/is_nt_cartridge = TRUE
	var/alarm_app_type = /datum/data/pda/app/alarm

/obj/item/cartridge/Initialize(mapload)
	. = ..()
	if(!is_nt_cartridge)
		return
	for(var/program in programs)
		if(istype(program, /datum/data/pda/app/alarm))
			return // somehow the alarm app is already in the cartridge
	programs += new alarm_app_type

/// Cartridge for broke assistants
/obj/item/cartridge/common
	name = "Crew-I Cartridge"
	desc = "A data cartridge for portable microcomputers. Has alarm button app."

/obj/item/cartridge/head
	alarm_app_type = /datum/data/pda/app/alarm/heads

/obj/item/cartridge/captain
	alarm_app_type = /datum/data/pda/app/alarm/heads

/obj/item/cartridge/hop
	alarm_app_type = /datum/data/pda/app/alarm/heads

/obj/item/cartridge/hos
	alarm_app_type = /datum/data/pda/app/alarm/heads

/obj/item/cartridge/ce
	alarm_app_type = /datum/data/pda/app/alarm/heads

/obj/item/cartridge/rd
	alarm_app_type = /datum/data/pda/app/alarm/heads

/obj/item/cartridge/cmo
	alarm_app_type = /datum/data/pda/app/alarm/heads

/obj/item/cartridge/qm
	alarm_app_type = /datum/data/pda/app/alarm/heads

/obj/item/cartridge/supervisor
	alarm_app_type = /datum/data/pda/app/alarm/heads

/obj/item/cartridge/centcom
	alarm_app_type = /datum/data/pda/app/alarm/centcom

/obj/item/cartridge/syndicate
	is_nt_cartridge = FALSE

/obj/item/cartridge/frame
	is_nt_cartridge = FALSE
