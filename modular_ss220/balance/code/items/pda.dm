/obj/item/pda
	/// Radio to call security.
	var/obj/item/radio/radio
	/// Timer to prevent spamming the alarm.
	COOLDOWN_DECLARE(alarm_cooldown)
	var/alarm_timeout = 5 MINUTES

/obj/item/pda/Initialize(mapload)
	. = ..()
	radio = new /obj/item/radio(src)
	radio.listening = FALSE
	radio.config(list("Security" = 0))
	radio.follow_target = src

/obj/item/pda/Destroy()
	qdel(radio)
	return ..()

/obj/item/pda/proc/handle_alarm_button()
	if(!COOLDOWN_FINISHED(src, alarm_cooldown))
		var/remaining_time = COOLDOWN_TIMELEFT(src, alarm_cooldown)
		tgui_alert(
			user = usr,
			title = "Ошибка",
			message = "Вы недавно отправили запрос. Подождите [round(remaining_time / 10)] секунд, прежде чем попытаться снова.",
			buttons = list("Ок"),
			autofocus = TRUE
		)
		return

	if(!radio.on || (!is_station_level(usr.z) && !is_mining_level(usr.z)))
		tgui_alert(
			user = usr,
			title = "Ошибка",
			message = "Вызов службы безопасности недоступен. Попробуйте позже.",
			buttons = list("Ок"),
			autofocus = TRUE
		)
		return

	var/response = tgui_alert(
		user = usr,
		message = "Вы уверены, что хотите запросить службу безопасности в эту область?",
		title = "Тревога",
		buttons = list("Да", "Нет"),
		autofocus = TRUE
	)
	if(response != "Да")
		return
	
	call_security()
	COOLDOWN_START(src, alarm_cooldown, alarm_timeout)

/obj/item/pda/proc/call_security()
	var/area/area = get_area(src)
	radio.autosay(
		from = "Система Оповещения",
		message = "Внимание! [owner], [ownrank], требует помощи в [area.name]! Необходимо немедленное реагирование.",
		channel = DEPARTMENT_SECURITY,
		follow_target_override = src
	)
	if(!silent)
		playsound(src, 'sound/machines/terminal_success.ogg', vol = 50, vary = TRUE)

	notify_ghosts(
		title = "Система Оповещения",
		message = "Кто-то вызвал службу безопасности!",
		ghost_sound = 'sound/effects/electheart.ogg',
		enter_link = "<a href=byond://?src=[UID()];follow=1>(Click to follow)</a>",
		source = src,
		action = NOTIFY_FOLLOW
	)

	log_game("[usr] called for security at ([usr.x], [usr.y], [usr.z]) using PDA of [owner] ([ownrank])")

/datum/data/pda/app/main_menu
	template = "pda_main_menu220"

/datum/data/pda/app/main_menu/ui_act(action, list/params)
	. = ..()
	switch(action)
		if("security")
			pda.handle_alarm_button()
			return TRUE

/obj/item/pda/captain
	alarm_timeout = 2 MINUTES

/obj/item/pda/heads
	alarm_timeout = 2 MINUTES

/obj/item/pda/heads/centcom
	alarm_timeout = 1 MINUTES
