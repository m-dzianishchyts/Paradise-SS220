/datum/mutation/disability/tourettes/on_life(mob/living/carbon/human/H)
	. = ..()
	if(rand(0, 10000) == 0)
		H.say("Ублюдок, мать твою, а ну иди сюда говно собачье, решил ко мне лезть? Ты, засранец вонючий, мать твою, а? Ну иди сюда, попробуй меня трахнуть, я тебя сам трахну ублюдок, онанист чертов, будь ты проклят, иди идиот, трахать тебя и всю семью, говно собачье, жлоб вонючий, дерьмо, сука, падла, иди сюда, мерзавец, негодяй, гад, иди сюда ты - говно, жопа!")

/mob/living/carbon/human/handle_disabilities()
	. = ..()
	if(getBrainLoss() >= 60 && stat != DEAD)
		if(prob(3))
			var/list/crazysay = list(
				"Я НЕПОБЕДИМ!!!",
				"Я НЕУЯЗВИМ!!!",
				"Я НЕОСТАНОВИМ!!!",
				"Я КОРОЛЬ [pick("ЯЩЕРИЦ", "МОЛЕЙ", "ВУЛЬП", "КЛОУНОВ", "СТАНЦИИ", "ЗВЕРЕЙ", "БЕЗ КОРОНЫ", "ЦК", "ТСФ", "ССП", "СИНДИКАТА")]!!!",
				"Ха-ха, не догонишь!",
				"Че вылупился?!",
				"ААААА ЗАХЛОПНИСЬ!!!",
				"ХВАТИТ ГОВОРИТЬ!!!",
				"КАК ВЫ МНЕ ВСЕ НАДОЕЛИ!!!",
				"СЛИШКОМ ШУМНО!!!",
				"КАК ПРОЙТИ В БИБЛИОТЕКУ?!",
				"ВОССЛАВЬ СОЛНЦЕ!",
				"МНЕ БОРЩ БЕЗ СВЕКЛЫ!",
				"Я люблю пельмени без начинки.",
				"Я люблю ананасовую пиццу.",
				"Самое вкусное в пицце - бортики!",
				"Я ХОЧУ [pick("СЕБЯ", "ТЕБЯ", "ПОНИ", "ЭТО", "ЕГО", "КУШАТЬ", "ПИТЬ", "ПИСЯТЬ", "НЕ ХОЧУ", "РАДУЖНЫЙ КАРАНДАШ", "ИЗМЕНИТЬ ТЕБЕ", "ОРАТЬ",
				"[pick("УДАРИТЬ", "ОБНЯТЬ", "ПОЦЕЛОВАТЬ", "ЗАДУШИТЬ", "ПОГЛАДИТЬ", "НАКРИЧАТЬ НА", "ИЗБАВИТЬ ОТ СТРАДАНИЙ", "ПОСЛАТЬ")] [pick(
					"ТЕБЯ", "СЕБЯ", "КЛОУНА", "МИМА", "ЩИТКУРА", "ОФИЦЕРА", "ПОВАРА", "МЕДИКА", "КОРОВУ", "САНЮ")]")]!",
				// вспоминаем мемы
				"ЗДОРОВЕННЫЙ ЯЗЬ!!!",
				"ЙААААААААЗЬ!",
				"ЯЯЯЯЯЯЯЗЬ!",
				"АННИГИЛЯТОРНАЯ ПУШКА!",
				"КУРВА КОСМОБОБЁР!",
				"ЭТО КОСМОБОБЁР!",
				"Денег нет, но я держусь!",
				"КАК ТЕБЕ ТАКОЕ, ИЛОН СПАСК?",
				"НО Я ЖЕ ЛЮБЛЮ ТЕБЯ!",
				"ВРАЧА, ВРАЧА, ПОЗОВИТЕ ВРАЧА!",
				"У неё преждеродовые начались. Мы не можем ей помочь.",
				"ТЫ УКРАЛ МОЁ СЕРДЕЧКО!",
				// Проклятые мемы
				"Наташа вставай, мы всё уронили!",
				"ПРЕВЕД!",
				"ПРЕВЕЕЕЕД!",
				"ПРЕВЕД МЕДВЕД!",
				"УЧИТЕ ОЛБАНСКИЙ ЯЗЫК!",
				"ржунимагу",
				"пацталом",
				"многабукаф",
				"стопицот",
				"ЖЫВТОНЕ ЧОЧО УПЯЧКА!!!",
				"УПЯЧКА УПЯЧКА!!!",
				"ШЯЧЛО ПОПЯЧТСА!!!",
				"ПОПЯЧТСА!!!",
				"Я идиот! Убейте меня кто-нибудь!",
				"УПЯЧКА!",
				"Я ДУРАК У МЕНЯ СПРАВКА ЕСТЬ!",
				"Мне борщ с капустой, но не красный!",
				"Котлетки... С пюрешкой!..",
				"шлакоблокунь",
				"MINE LAVALAND CRAFT ЭТО МОЯ ЖИЗНЬ!!!",
				"Ну умер я и умер, че бубнить то.",
				"Ты на станцию прилетел - косарь отдал!",
				"БРАТИШКА, Я ТЕБЕ ПОКУШАТЬ ПРИНЕС!",
				"ГДЕ ПРУФЫ, БИЛЛИ?!",
				"ЭТО НОРМА!",
				"ЭТО НЕ НОРМА!",
				"ЭТО НИХУЯ НЕ НОРМА!",
				"Ты втираешь мне какую-то дичь!",
				"ЭТО ОБМАН ЧТОБЫ НАБРАТЬ КЛАССЫ!",
				"ЭТО БУДЕТ ФИАСКО!",
				"ЭТО ФИАСКО, БРАТАН!",
				"ЧИВО",
				"ЧИВО БЛЯТ?",
				// Будь проклято онеме
				"В ЭЛЬФИЙСКОЙ ПЕСНЕ НЕ БЫЛО ЭЛЬФОВ!!!",
				"БОКУ НО ПИКО НЕ В БОКУ!",
				"КОВБОЙ БИБОП НЕ КОВБОЙ И НЕ БИБОП!",
				"ЭТОТ ГЛУПЫЙ СВИН НЕ ПОНИМАЕТ МЕЧТЫ ДЕВОЧКИ ЗАЙКИ!",
				// А теперь цитаты настоящего пацана с брейндамагом.
				"Не важно кто - важно кто!",
				"Если волк молчит - то лучше его не перебивать!",
				"Не важно кто слабее - важно кто сильный!",
				"Вы меня не поправляйте, я вам не трусы.",
				"Лучше быть последним-первым, чем первым-последним.",
				"Лучше иметь друга, чем друг друга.",
				"Моего друга сбила машина и он больше мне не друг, ведь друзья на дороге не валяются.",
				"Побеждать по жизни могут только победители.",
				"Безумно можно быть первым!",
				"Если предали один раз - то это только первый раз. Если предали еще - то это второй.",
				"Сделал дело - дело сделано.",
				"Не важно в какой жопе ты находишься, главное чтобы в твоей жопе никто не находился!",
				"Срать вечно.",
				"Одна ошибка и ты ошибся!",
				"Поссать без пука, это как поесть шашлык без лука!",
				"Если хочешь идти - иди.",
				"Если хочешь забыть - забудь.",
				"Жи ши пиши от души.",
				"Клади навоз густо - в амбаре будет не пусто.",
				"Лучше с пацанами на подике, чем с чертями на шаттле.",
				"Я ЗАПРЕЩАЮ ВАМ СРАТЬ!",
				"Безумно можно.",
				"Живи, кайфуй, гуляй, играй, упал - вставай, наглей, ругай, чужих роняй, NTOS обновляй, картошка, суп, пельмени, чай.",
				// возвращаемся к дебильным фразам
				"СЛАВА КРЫСИНОМУ СУПЕРСАТАНЕ!!!",
				"ХОНК КРЫСБАР!!!",
				"Я ПОЖАЛУЮСЬ НА ТЕБЯ В КОСМИЧЕСКОЕ СПОРТЛОТО!",
				"СССП ПРИДИ ПОРЯДОК НАВЕДИ!",
				"СЛАВА? КТО ТАКОЙ СЛАВА!?",
				"Я МАШИНА",
				"Я в своем познании настолько преисполнился...",
				"Я в своем познании настолько преисполнился, что как будто бы уже сто триллионов миллиардов лет проживаю на триллионах и триллионах таких же станций, понимаешь?",
				"ЧТО ЭТО НА ПОТОЛКЕ?!",
				"ОНО СМОТРИТ НА МЕНЯ!!!",
				"ГЛАЗА НА ПОТОЛКЕ!!!",
				"ЧТО ЭТО ЗА РОЖА НА ПОТОЛКЕ?!",
				"ГДЕ НАШ ПОТОЛОК?!",
				"КУДА ВЫ ДЕЛИ ПОТОЛОК?!",
				"А где потолок?!",
				"ОЙ ДОГОНЮ!",
				"АЙ НЕ ДОГОНИШЬ!",
				"НЕ СМОТРИТЕ НА МЕНЯ!",
				"ВСЕ СМОТРИТЕ НА МЕНЯ!",
				"СМОТРИТЕ, СМОТРИТЕ НА МЕНЯ!",
				"ПРЕКРАТИТЬ ХУЙНЮ!",
				"ОГУЗКИ, ОГРЫЗКИ!",
				"Я ЗНАКОМ С КОРОНОПРИНЦЕМ!",
				"МОЙ ПАПА ГЛАВНЫЙ [pick("НА ЦК", "У ССП", "У ТСФ", "У СИНДИКАТА", "БАНДЮГАН", "И УВАЖАЕМЫЙ ЧЕЛОВЕК", "ОТЕЦ")]!!!",
				"Мама мыла раму...",
				"Ыыыы...",
				"Ээээ...",
				"ААА ААААА ААААААААА!!!",
				"У меня слюна потекла...",
				"Вытрите мою слюну!..",
				"Мне нужна присыпка...",
				"КОГДА ДОБАВЯТ ПОДЫ?!",

			)
			if(prob(95))
				say(pick(crazysay))
			else
				var/list/flipsay = list(
					"Зацени сальтуху!",
					"Ща ебану сальтуху!",
					"Сальтуха!",
					"ЗАЦЕНИ ЧЕ МОГУ!!!",
					"Опля!",
					"Але ОП!",
					"Волки в цирке не выступают - а делают сальтуху!",
					"ЗАЦЕНИ!",
					"А ТЫ ТАК СМОЖЕШЬ?!",
				)
				say(pick(flipsay))
				emote("flip")
