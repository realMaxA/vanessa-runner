///////////////////////////////////////////////////////////////////////////////////////////////////
//
// Объединение cf-файла с конфигурацией базы
// 
// Служебный модуль с набором методов работы с командами приложения
//
// Структура модуля реализована в соответствии с рекомендациями 
// oscript-app-template (C) EvilBeaver
//
///////////////////////////////////////////////////////////////////////////////////////////////////

#Использовать logos
#Использовать v8runner

Перем Лог;
Перем МенеджерКонфигуратора;

///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт

	ТекстОписания = 
		"     Объединение cf-файла c конфигурацией из инф.базы.
		|     ";

	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, 
		ТекстОписания);

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--src", "Путь к cf-файлу, пример: --src=./1Cv8.cf");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-s", "Краткая команда 'путь к cf --src', пример: -s ./1Cv8.cf");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--merge-settings", "Файл с настройками объединения конфигураций (обязательный параметр)");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--enable-support", "Флаг необходимости установки конфигурации на поддержку, если есть возможность поставки на поддержку");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--disable-support", "Флаг запрета установки конфигурации на поддержку, даже если есть возможность поставки на поддержку");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--IncludeObjectsByUnresolvedRefs", "Флаг небходимости включения в объединение объектов, 
		|не включенных в список объединяемых и отсутствующих в основной конфигурации");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--ClearUnresolvedRefs", "Флаг очистки ссылок на объекты, не включенные в список объединяемых");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--force", "Флаг принудительного обновления");
	
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры // ЗарегистрироватьКоманду

// Выполняет логику команды
// 
// Параметры:
//   ПараметрыКоманды - Соответствие - Соответствие ключей командной строки и их значений
//   ДополнительныеПараметры - Соответствие - дополнительные параметры (необязательно)
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды, Знач ДополнительныеПараметры = Неопределено) Экспорт

	Попытка
		Лог = ДополнительныеПараметры.Лог;
	Исключение
		Лог = Логирование.ПолучитьЛог(ПараметрыСистемы.ИмяЛогаСистемы());
	КонецПопытки;

	Лог.Информация("Начинаю объединение конфигураций");

	ДанныеПодключения = ПараметрыКоманды["ДанныеПодключения"];
	
	ПутьВходящий = ОбщиеМетоды.ПолныйПуть(ОбщиеМетоды.ПолучитьПараметры(ПараметрыКоманды, "-s", "--src"));
	
	ПутьФайлаНастройки = ПараметрыКоманды["--merge-settings"];
	Если Не ЗначениеЗаполнено(ПутьФайлаНастройки) Тогда
		ВызватьИсключение "Необходимо задать к файлу с настройками объединения конфигураций,
		|Параметр --merge-settings является обязательным."
	КонецЕсли;

	ПоставитьНаПоддержку = ПараметрыКоманды["--enable-support"];
	НеСтавитьНаПоддержку = ПараметрыКоманды["--disable-support"];
	ВключитьВОбъединениеОбъектыПоНеразрешеннымСсылкам = ПараметрыКоманды["--IncludeObjectsByUnresolvedRefs"];
	ОчищатьОбъектыПоНеразрешеннымСсылкам = ПараметрыКоманды["--ClearUnresolvedRefs"];
	Принудительно = ПараметрыКоманды["--force"];

	Лог.Отладка("ПутьВходящий %1", ПутьВходящий);
	Лог.Отладка("ПутьФайлаНастройки %1", ПутьФайлаНастройки);
	Лог.Отладка("ПоставитьНаПоддержку %1", ПоставитьНаПоддержку);
	Лог.Отладка("НеСтавитьНаПоддержку %1", НеСтавитьНаПоддержку);
	Лог.Отладка("ВключитьВОбъединениеОбъектыПоНеразрешеннымСсылкам %1", ВключитьВОбъединениеОбъектыПоНеразрешеннымСсылкам);
	Лог.Отладка("Принудительно %1", Принудительно);
	
	ВерсияПлатформы = ПараметрыКоманды["--v8version"];
	СтрокаПодключения = ДанныеПодключения.СтрокаПодключения;
	
	МенеджерКонфигуратора = Новый МенеджерКонфигуратора;
	
	Попытка
		МенеджерКонфигуратора.Инициализация(ДанныеПодключения.СтрокаПодключения, ДанныеПодключения.Пользователь, ДанныеПодключения.Пароль,
				ВерсияПлатформы, ПараметрыКоманды["--uccode"], ДанныеПодключения.КодЯзыка);

		УправлениеКонфигуратором = МенеджерКонфигуратора.УправлениеКонфигуратором();

		ПараметрПоставитьНаПоддержку = Неопределено;
		Если ПоставитьНаПоддержку Тогда
			ПараметрПоставитьНаПоддержку = Истина;
		ИначеЕсли НеСтавитьНаПоддержку Тогда
			ПараметрПоставитьНаПоддержку = Ложь;
		КонецЕсли;

		ПараметрВключитьВОбъединениеОбъектыПоНеразрешеннымСсылкам = Неопределено;
		Если ВключитьВОбъединениеОбъектыПоНеразрешеннымСсылкам Тогда
			ПараметрВключитьВОбъединениеОбъектыПоНеразрешеннымСсылкам = Истина;
		ИначеЕсли ОчищатьОбъектыПоНеразрешеннымСсылкам Тогда
			ПараметрВключитьВОбъединениеОбъектыПоНеразрешеннымСсылкам = Ложь;
		КонецЕсли;

		УправлениеКонфигуратором.ОбъединитьКонфигурациюСФайлом(ПутьВходящий, ПутьФайлаНастройки, ПараметрПоставитьНаПоддержку, 
		ПараметрВключитьВОбъединениеОбъектыПоНеразрешеннымСсылкам, Принудительно);

		Лог.Информация(УправлениеКонфигуратором.ВыводКоманды());

		Лог.Информация("Успешно завершено объединение конфигураций");
		
	Исключение
		МенеджерКонфигуратора.Деструктор();
		ВызватьИсключение ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
	КонецПопытки;
		
	МенеджерКонфигуратора.Деструктор();

	Возврат МенеджерКомандПриложения.РезультатыКоманд().Успех;
КонецФункции // ВыполнитьКоманду
