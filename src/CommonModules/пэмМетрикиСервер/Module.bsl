#Область Push

Процедура СформироватьМетрикиРегламентнымЗаданием(Метрика = Неопределено) Экспорт
					
	Если НЕ пэмМетрикиСерверПовтИсп.РазрешеноИспользованиеМетодаPush() Тогда
		Возврат;
	КонецЕсли;
			
	АдресСервера = Константы.пэмАдресСервераPushgateway.Получить();
	ПортСервера = Константы.пэмПортСервераPushgateway.Получить();
	ПутьНаСервере = Константы.пэмПутьНаСервереPushgateway.Получить();
			    			
	Метрики = ПолучитьМетрики(Перечисления.пэмМетодыПолученияМетрик.Push, Метрика);
	HTTPСоединение = Новый HTTPСоединение(АдресСервера, ПортСервера, , , , 30);
	HTTPЗапрос = Новый HTTPЗапрос(ПутьНаСервере);
	HTTPЗапрос.Заголовки.Вставить("Content-Type", "text/plain; version=0.0.4");
		
	HTTPЗапрос.УстановитьТелоИзСтроки(Метрики, КодировкаТекста.UTF8, ИспользованиеByteOrderMark.НеИспользовать);
	
	Результат = HTTPСоединение.ВызватьHTTPМетод("POST", HTTPЗапрос);
	
	Если Результат.КодСостояния > 300 Тогда
		ЗаписьЖурналаРегистрации("Prometheus data exporter",
		УровеньЖурналаРегистрации.Ошибка,
		,
		,
		"Ошибка отправки метрик. Код ответа Pushgateway: " + Результат.КодСостояния);	
	КонецЕсли; 
		
КонецПроцедуры

#КонецОбласти

#Область Pull

Функция СформироватьМетрикиПоЗапросу() Экспорт
	
	Возврат ПолучитьМетрики(Перечисления.пэмМетодыПолученияМетрик.Pull, Неопределено);
	
КонецФункции

#КонецОбласти

#Область Описание_сервиса

Функция ВернутьОписаниеСервиса() Экспорт
	
	Ответ = Новый HTTPСервисОтвет(200);
	
	Ответ.Заголовки.Вставить("Content-Type", "text/html;charset=UTF-8");
	Ответ.Заголовки.Вставить("Pragma", "no-cache");
	Ответ.Заголовки.Вставить("Cache-Control", "no-cache");
	Ответ.Заголовки.Вставить("Cache-Control", "no-store");
	Ответ.Заголовки.Вставить("Content-Language", "en");

	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	пэмМетрики.Ссылка КАК Ссылка,
	|	пэмМетрики.МетодПолученияМетрики КАК МетодПолученияМетрики,
	|	пэмМетрики.Активность КАК Активность
	|ПОМЕСТИТЬ втСправочникМетрик
	|ИЗ
	|	Справочник.пэмМетрики КАК пэмМетрики
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	втСправочникМетрик.МетодПолученияМетрики КАК Type,
	|	""Active"" КАК State,
	|	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ втСправочникМетрик.Ссылка) КАК Count
	|ИЗ
	|	втСправочникМетрик КАК втСправочникМетрик
	|ГДЕ
	|	втСправочникМетрик.Активность = ИСТИНА
	|
	|СГРУППИРОВАТЬ ПО
	|	втСправочникМетрик.МетодПолученияМетрики
	|
	|ОБЪЕДИНИТЬ ВСЕ
	|
	|ВЫБРАТЬ
	|	втСправочникМетрик.МетодПолученияМетрики,
	|	""Inactive"",
	|	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ втСправочникМетрик.Ссылка)
	|ИЗ
	|	втСправочникМетрик КАК втСправочникМетрик
	|ГДЕ
	|	втСправочникМетрик.Активность = ЛОЖЬ
	|
	|СГРУППИРОВАТЬ ПО
	|	втСправочникМетрик.МетодПолученияМетрики";
	Результат = Запрос.Выполнить().Выгрузить();

	СтрокаHTML =
	"<p><h1>Prometheus data exporter</h1></p>
	|%1
	|<p>&nbsp;</p>";
	
	Если Результат.Количество() Тогда
		Данные =
		"<h2>Metrics information:</h2>
		|<table border=""1"" cellpadding=""2"" cellspacing=""0"" >
		|<tbody>
		|	<tr>";
		Для Каждого Колонка Из Результат.Колонки Цикл
			Данные = Данные + Символы.ПС + "<td><h4>" + Колонка.Заголовок + "</h4></td>";
		КонецЦикла;
		Данные = Данные + Символы.ПС + "</tr>";
		Для Каждого Строка Из Результат Цикл
			Данные = Данные + Символы.ПС + "<tr>";
			Для Каждого КолонкаСтроки Из Строка Цикл
				Данные = Данные + Символы.ПС + "<td>" + КолонкаСтроки + "</td>";
			КонецЦикла;
			Данные = Данные + Символы.ПС + "</tr>";
		КонецЦикла;
		Данные = Данные + "
		|</tbody>
		|</table>";
	Иначе
		Данные = "<p><h2>Metrics is not set yet</h2></p>";
	КонецЕсли;
	
	СтрокаHTML = СтрЗаменить(СтрокаHTML, "%1", Данные);
	
	Ответ.УстановитьТелоИзСтроки(СтрокаHTML);
	
	Возврат Ответ;
	
КонецФункции

#КонецОбласти

#Область Формирование_метрик 

Функция ПолучитьМетрики(МетодПолученияМетрики, Метрика) Экспорт
	
	Метрики = "";
	Асинхронно = Константы.пэмМногопоточныйРасчетМетрик.Получить();
				
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	пэмМетрики.Код КАК ИмяМетрики,
	|	пэмМетрики.Алгоритм КАК Алгоритм,
	|	пэмМетрики.ТипМетрики КАК ТипМетрики,
	|	пэмМетрики.Ссылка КАК Метрика
	|ИЗ
	|	Справочник.пэмМетрики КАК пэмМетрики
	|ГДЕ
	|	ИСТИНА=ИСТИНА";

	Если Метрика = Неопределено Тогда
		УсловиеЗапроса = "пэмМетрики.Активность = ИСТИНА
						 |	И пэмМетрики.МетодПолученияМетрики = &МетодПолученияМетрики
						 |	И пэмМетрики.ИдентификаторРегламента = &ПустойИдентификатор";
	Иначе
		УсловиеЗапроса = "пэмМетрики.Активность = ИСТИНА
						 |	И пэмМетрики.МетодПолученияМетрики = &МетодПолученияМетрики
						 |  И пэмМетрики.Код = &КодМетрики";
	КонецЕсли;
	Запрос.Текст = СтрЗаменить(Запрос.Текст,"ИСТИНА=ИСТИНА",УсловиеЗапроса);
	Запрос.УстановитьПараметр("КодМетрики",Метрика);
	Запрос.УстановитьПараметр("МетодПолученияМетрики", МетодПолученияМетрики);
	Запрос.УстановитьПараметр("ТекущаяДата", ТекущаяДата());
	Запрос.УстановитьПараметр("ПустойИдентификатор",Новый УникальныйИдентификатор("00000000-0000-0000-0000-000000000000"));
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Асинхронно Тогда
		Метрики = СформироватьМетрикиАсинхронно(Выборка, МетодПолученияМетрики);
	Иначе
		Метрики = СформироватьМетрикиСинхронно(Выборка, МетодПолученияМетрики);
	КонецЕсли;
	
	Возврат Метрики;
		
КонецФункции

Функция СформироватьМетрикиАсинхронно(Выборка, МетодПолученияМетрики)
	
	МетрикиСтрокой = "";	
	МассивФоновыхЗаданий = Новый Массив;
	МассивПараметров = Новый Массив;
		
	// старт расчета
	Пока Выборка.Следующий() Цикл
		
		УникальныйИдентификатор = Новый УникальныйИдентификатор;
		АдресВХранилище = ПоместитьВоВременноеХранилище("", УникальныйИдентификатор);
		
		МассивПараметров.Очистить();
		МассивПараметров.Добавить(Выборка.ИмяМетрики);
		МассивПараметров.Добавить(Выборка.ТипМетрики);
		МассивПараметров.Добавить(Выборка.Алгоритм);
		МассивПараметров.Добавить(АдресВХранилище);
		МассивПараметров.Добавить(Выборка.Метрика);
		
		ФоновоеЗадание = ФоновыеЗадания.Выполнить("пэмМетрикиСервер.СформироватьМетрикуФоновымЗаданием", МассивПараметров, АдресВХранилище);
		МассивФоновыхЗаданий.Добавить(ФоновоеЗадание);
		
	КонецЦикла;
	
	Если НЕ МассивФоновыхЗаданий.Количество() Тогда
		Возврат МетрикиСтрокой;
	КонецЕсли;
	
	// Ожидание окончания расчета всех метрик
	МассивЗаданийКУдалению = Новый Массив;	
	Пока Истина Цикл
		
		Пауза(1);
		МассивЗаданийКУдалению.Очистить();
		Для Каждого ФоновоеЗадание Из МассивФоновыхЗаданий Цикл
			
			Если ФоновыеЗадания.НайтиПоУникальномуИдентификатору(ФоновоеЗадание.УникальныйИдентификатор).Состояние = СостояниеФоновогоЗадания.Активно Тогда
				Продолжить;
			КонецЕсли;
			
			Попытка
				сткВозврат = ПолучитьИзВременногоХранилища(ФоновоеЗадание.Ключ);
				Если НЕ сткВозврат.Ошибка Тогда
					МетрикиСтрокой = МетрикиСтрокой + сткВозврат.МетрикаСтрокой;
				КонецЕсли;
			Исключение
				МетрикиСтрокой = МетрикиСтрокой + "";
			КонецПопытки;
			
			МассивЗаданийКУдалению.Добавить(ФоновоеЗадание);
		КонецЦикла;
		
		// Удаление уже расчитаных метрик из массива контроля
		Для Каждого ЗаданиеКУдалению Из МассивЗаданийКУдалению Цикл
			МассивФоновыхЗаданий.Удалить(МассивФоновыхЗаданий.Найти(ЗаданиеКУдалению));
		КонецЦикла;
		
		// Если нечего больше ждать - завершаем общее ожидание
		Если НЕ МассивФоновыхЗаданий.Количество() Тогда
			Прервать;
		КонецЕсли;
		
	КонецЦикла;
	
	Возврат МетрикиСтрокой;
		      	
КонецФункции

Функция СформироватьМетрикиСинхронно(Выборка, МетодПолученияМетрики)
	
	СтрокаМетрик = "";
		                      		
	Пока Выборка.Следующий() Цикл
				
		ДатаНачалаРасчета = ТекущаяДата();
		ДатаНачалаРасчетаВМиллисекундах = ТекущаяУниверсальнаяДатаВМиллисекундах();
		
		сткВозврат = СформироватьМетрику(Выборка.Алгоритм);
		Если сткВозврат.Ошибка Тогда
			Продолжить;
		КонецЕсли;
		
		сткВозврат = ПривестиТаблицуРасчетаМетрикиКСтрокеPrometheus(Выборка.ИмяМетрики, Выборка.ТипМетрики, сткВозврат.МетрикаТаблицей);
		Если сткВозврат.Ошибка Тогда
			Продолжить;
		КонецЕсли;
		
		СтрокаМетрик = СтрокаМетрик + сткВозврат.МетрикаСтрокой; 
		
		ЗаписатьИнформациюОРасчетеМетрикиФоновымЗаданием(Выборка.Метрика, ДатаНачалаРасчетаВМиллисекундах, ДатаНачалаРасчета);
		
	КонецЦикла;
	
	Возврат СтрокаМетрик;
		
КонецФункции

Процедура СформироватьМетрикуФоновымЗаданием(ИмяМетрики, ТипМетрики, Алгоритм, ИдентификаторХранилища, Метрика) Экспорт
		
	ДатаНачалаРасчета = ТекущаяДата();
	ДатаНачалаРасчетаВМиллисекундах = ТекущаяУниверсальнаяДатаВМиллисекундах();
		
	сткВозврат = СформироватьМетрику(Алгоритм);
	Если сткВозврат.Ошибка Тогда
		ПоместитьВоВременноеХранилище(сткВозврат, ИдентификаторХранилища);
		Возврат;
	КонецЕсли;
	
	сткВозврат = ПривестиТаблицуРасчетаМетрикиКСтрокеPrometheus(ИмяМетрики, ТипМетрики, сткВозврат.МетрикаТаблицей);
	Если сткВозврат.Ошибка Тогда
		ПоместитьВоВременноеХранилище(сткВозврат, ИдентификаторХранилища);
		Возврат;
	КонецЕсли;
	
	ПоместитьВоВременноеХранилище(сткВозврат, ИдентификаторХранилища);
	ЗаписатьИнформациюОРасчетеМетрикиФоновымЗаданием(Метрика, ДатаНачалаРасчетаВМиллисекундах, ДатаНачалаРасчета);
	
КонецПроцедуры

Функция СформироватьМетрику(Алгоритм) Экспорт
	
	сткВозврат = Новый Структура;
	сткВозврат.Вставить("МетрикаТаблицей", Новый ТаблицаЗначений);
	сткВозврат.Вставить("ОписаниеОшибки", "");
	сткВозврат.Вставить("Ошибка", Ложь);
	
	ТаблицаЗначений = Новый ТаблицаЗначений;
	
	Попытка
		УстановитьПривилегированныйРежим(Истина);
		Выполнить(Алгоритм);
		УстановитьПривилегированныйРежим(Ложь);
	Исключение
		ОписаниеОшибки = ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Prometheus data exporter",
			УровеньЖурналаРегистрации.Ошибка,
			,
			,
			ОписаниеОшибки);
		сткВозврат.Ошибка = Истина;
		сткВозврат.ОписаниеОшибки = ОписаниеОшибки;
		Возврат сткВозврат;
	КонецПопытки;
	
	сткВозврат.МетрикаТаблицей = ТаблицаЗначений;
	
	Возврат сткВозврат;
		
КонецФункции

Функция ПривестиТаблицуРасчетаМетрикиКСтрокеPrometheus(ИмяМетрики, ТипМетрики, МетрикаТаблицейЗначений) Экспорт
	
	сткВозврат = Новый Структура();
	сткВозврат.Вставить("МетрикаСтрокой", "");
	сткВозврат.Вставить("Ошибка", Ложь);
	сткВозврат.Вставить("ОписаниеОшибки", "");
	
	Если НЕ МетрикаТаблицейЗначений.Количество() Тогда
		сткВозврат.Ошибка = Истина;
		сткВозврат.ОписаниеОшибки = "Пустая метрика";
		Возврат сткВозврат;
	КонецЕсли;
			
	Попытка
	
		ЗаписьJSON = Новый ЗаписьJSON;
		ЗаписьJSON.УстановитьСтроку();
	
		Если ЗначениеЗаполнено(ТипМетрики) Тогда
			ЗаписьJSON.ЗаписатьБезОбработки("# TYPE ");
			ЗаписьJSON.ЗаписатьБезОбработки(ИмяМетрики);
			ЗаписьJSON.ЗаписатьБезОбработки(" ");
			ЗаписьJSON.ЗаписатьБезОбработки(Метаданные.Перечисления.пэмТипыМетрик.ЗначенияПеречисления[Перечисления.пэмТипыМетрик.Индекс(ТипМетрики)].Синоним);
			ЗаписьJSON.ЗаписатьБезОбработки(Символы.ПС);
		КонецЕсли; 
		
		Если МетрикаТаблицейЗначений.Колонки.Найти("value") = Неопределено Тогда
			ВызватьИсключение "Метрика " + ИмяМетрики + " не содержит колонки value";		
		КонецЕсли;
	
		Для Каждого Строка Из МетрикаТаблицейЗначений Цикл
		
			ЗаписьJSON.ЗаписатьБезОбработки(ИмяМетрики);
			ЗаписьJSON.ЗаписатьБезОбработки("{");

			ВыводительРазделитель = Неопределено;
		
			Для Каждого Колонка Из МетрикаТаблицейЗначений.Колонки Цикл
				Если Колонка.Имя = "value" Тогда
					Продолжить;
				КонецЕсли;
			
				Если ВыводительРазделитель = Истина Тогда
					ЗаписьJSON.ЗаписатьБезОбработки(", ");
				КонецЕсли;  
			
				ЗаписьJSON.ЗаписатьБезОбработки(Колонка.Имя);
				ЗаписьJSON.ЗаписатьБезОбработки("=""");
				ЗаписьJSON.ЗаписатьБезОбработки(Строка[Колонка.Имя]);
				ЗаписьJSON.ЗаписатьБезОбработки("""");
			
				Если ВыводительРазделитель = Неопределено Тогда
				    ВыводительРазделитель  = Истина;
				КонецЕсли;  
			
			КонецЦикла; 

			ЗаписьJSON.ЗаписатьБезОбработки("} ");
			ЗаписьJSON.ЗаписатьБезОбработки(Строка(Формат(Строка["value"], "ЧРД=.; ЧРГ=; ЧДЦ=4; ЧН=; ЧГ=;")));
			ЗаписьJSON.ЗаписатьБезОбработки(Символы.ПС);
		
		КонецЦикла;
	Исключение
		ОписаниеОшибки = ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Prometheus data exporter",
			УровеньЖурналаРегистрации.Ошибка,
			,
			,
			ОписаниеОшибки);
		сткВозврат.Ошибка = Истина;
		сткВозврат.ОписаниеОшибки = ОписаниеОшибки;
		Возврат сткВозврат;
	КонецПопытки;
	
	сткВозврат.МетрикаСтрокой = ЗаписьJSON.Закрыть();
		  	
	Возврат сткВозврат;

КонецФункции

// Таймаут - число. Квант равен 1 секунде
Процедура Пауза(Знач Таймаут) Экспорт

	СистемнаяИнформация = Новый СистемнаяИнформация(); 
	ЭтоWindows = (СистемнаяИнформация.ТипПлатформы = ТипПлатформы.Windows_x86) 
	Или (СистемнаяИнформация.ТипПлатформы = ТипПлатформы.Windows_x86_64); 
	
	Таймаут = Таймаут + 1;

	Если ЭтоWindows Тогда 
		ШаблонКоманды = "ping localhost -n " + Таймаут + " -w 1000"; 
	Иначе 
		ШаблонКоманды = "ping -c " + Таймаут + " -w 1000 localhost"; 
	КонецЕсли; 
	
	ЗапуститьПриложение(ШаблонКоманды, , Истина);
	
КонецПроцедуры

Процедура ЗаписатьИнформациюОРасчетеМетрикиФоновымЗаданием(Метрика, ДатаНачалаРасчетаВМиллисекундах, ДатаНачалаРасчета)
	
		МассивПараметровРасчетаМетрик = Новый Массив;
		МассивПараметровРасчетаМетрик.Добавить(Метрика);
		МассивПараметровРасчетаМетрик.Добавить(ДатаНачалаРасчетаВМиллисекундах);
		МассивПараметровРасчетаМетрик.Добавить(ТекущаяУниверсальнаяДатаВМиллисекундах());
		МассивПараметровРасчетаМетрик.Добавить(ДатаНачалаРасчета);
		ФоновыеЗадания.Выполнить("пэмМетрикиСервер.ЗаписатьИнформациюОРасчетеМетрики", МассивПараметровРасчетаМетрик);	
		
КонецПроцедуры

Процедура ЗаписатьИнформациюОРасчетеМетрики(Метрика, ДатаНачалаРасчетаВМиллисекундах, ДатаОкончанияРасчетаВМиллисекундах, ДатаНачалаРасчета) Экспорт
	
	МенеджерЗаписи = РегистрыСведений.пэмСостояниеМетрик.СоздатьМенеджерЗаписи();
	МенеджерЗаписи.Метрика = Метрика; 
	МенеджерЗаписи.Прочитать();
	
	МенеджерЗаписи.Метрика = Метрика;
	МенеджерЗаписи.ДатаРасчета = ДатаНачалаРасчета;
	МенеджерЗаписи.Длительность = ДатаОкончанияРасчетаВМиллисекундах - ДатаНачалаРасчетаВМиллисекундах;
		
	МенеджерЗаписи.Записать();
	
КонецПроцедуры

// Маска - текстовая строка. Допустимы следующие символы:
// . - любой символ
// + - один или более раз, пример ".+" - один или более любой символ.
// * - ноль или более раз, пример ".*" - любое количество любых символов (даже ни одного).
// [n-m] - символ от m до n. Например: [a-zA-Z_:]* - строка любой длины, состоящая из больших и маленьких латинских символов, знаков "_" и ":" , Еще пример: "[0-9]+" - одна или более цифр(а).
// \d - цифра, пример 
// \d+ - одна или более цифр(а).
// \D - не цифра.
// \s - пробельный символ - ТАБ, пробел, перенос строки, возврат каретки и т.п.
// \S - непробельный символ.
// \w - буква, цифра, подчеркивание.
// \W - не буква, не цифра и не подчеркивание соответственно.
// ^ - начало текста, например "^\d+" - строка начинается с цифры.
// $ - конец текста, например "\D+$" - строка заканчивается НЕ цифрой.
// {m,n} - шаблон для от m до n символов, например "\d{2,4}" - от двух до четырех цифр. Можно указать одну и всего цифру для строгого соответвия.
// \ - экранирует спецсимволы. Например, "\." - символ точки.
Функция ПроверитьСтрокуНаСоответствиеМаске(Строка, Маска) Экспорт
	
	сткВозврат = Новый Структура;
	сткВозврат.Вставить("ЕстьОшибка", Истина);
	сткВозврат.Вставить("ОписаниеОшибки", "Ошибка в коде");
	сткВозврат.Вставить("Результат", Неопределено);
		
    Чтение = Новый ЧтениеXML;
    Чтение.УстановитьСтроку(
                "<Model xmlns=""http://v8.1c.ru/8.1/xdto"" xmlns:xs=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xsi:type=""Model"">
                |<package targetNamespace=""sample-my-package"">
                |<valueType name=""testtypes"" base=""xs:string"">
                |<pattern>" + Маска + "</pattern>
                |</valueType>
                |<objectType name=""TestObj"">
                |<property xmlns:d4p1=""sample-my-package"" name=""TestItem"" type=""d4p1:testtypes""/>
                |</objectType>
                |</package>
                |</Model>");

    Модель = ФабрикаXDTO.ПрочитатьXML(Чтение);
	
	Попытка
    	МояФабрикаXDTO = Новый ФабрикаXDTO(Модель);
	Исключение
		сткВозврат.ЕстьОшибка = Истина;
		сткВозврат.ОписаниеОшибки = "Ошибка маски";
		Возврат сткВозврат;
	КонецПопытки;
		
    Пакет = МояФабрикаXDTO.Пакеты.Получить("sample-my-package");
    Тест = МояФабрикаXDTO.Создать(Пакет.Получить("TestObj"));

    Попытка
        Тест.TestItem = Строка;
    Исключение
        сткВозврат.ЕстьОшибка = Истина;
		сткВозврат.ОписаниеОшибки = "Строка не соответствует маске";
		сткВозврат.Результат = Ложь;
		Возврат сткВозврат;
	КонецПопытки;
	
	сткВозврат.ЕстьОшибка = Ложь;
	сткВозврат.ОписаниеОшибки = "";
	сткВозврат.Результат = Истина;
    Возврат сткВозврат;
   
КонецФункции

#КонецОбласти

#Область Служебный_программный_интерфейс

Процедура ВыполнитьПервоначальноеЗаполнение() Экспорт

	МассивМетрикДляЗаписи = Новый Массив;
	
	ОписаниеМетрики = Справочники.пэмМетрики.pde_scrape_duration.ПолучитьОбъект();
	ОписаниеМетрики.Наименование = "Длительность расчета метрик (миллисекунд)";
	ОписаниеМетрики.ТипМетрики = Перечисления.пэмТипыМетрик.Gauge;
	ОписаниеМетрики.МетодПолученияМетрики = Перечисления.пэмМетодыПолученияМетрик.Pull;
	ОписаниеМетрики.Активность = Истина;
	ОписаниеМетрики.ИдентификаторРегламента = Новый УникальныйИдентификатор("00000000-0000-0000-0000-000000000000");
	ОписаниеМетрики.Алгоритм = "
	|ТаблицаЗначений = Новый ТаблицаЗначений;                             
	|ТаблицаЗначений.Колонки.Добавить(""label"", Новый ОписаниеТипов(""Строка""));
	|ТаблицаЗначений.Колонки.Добавить(""value"", Новый ОписаниеТипов(""Число""));	
	|
	|Запрос = Новый Запрос;
	|Запрос.Текст = 
	|""ВЫБРАТЬ
	||	пэмСостояниеМетрик.Метрика.Код КАК label,
	||	пэмСостояниеМетрик.Длительность КАК value
	||ИЗ
	||	РегистрСведений.пэмСостояниеМетрик КАК пэмСостояниеМетрик"";
	|Результат = Запрос.Выполнить();
	|
	|Если НЕ Результат.Пустой() Тогда
	|	ТаблицаЗначений = Результат.Выгрузить();
	|КонецЕсли;
	|";
	МассивМетрикДляЗаписи.Добавить(ОписаниеМетрики);
	
	ОписаниеМетрики = Справочники.пэмМетрики.pde_last_refresh.ПолучитьОбъект();
	ОписаниеМетрики.Наименование = "Задержка обновления метрик (секунд)";
	ОписаниеМетрики.ТипМетрики = Перечисления.пэмТипыМетрик.Counter;
	ОписаниеМетрики.МетодПолученияМетрики = Перечисления.пэмМетодыПолученияМетрик.Pull;
	ОписаниеМетрики.Активность = Истина;
	ОписаниеМетрики.ИдентификаторРегламента = Новый УникальныйИдентификатор("00000000-0000-0000-0000-000000000000");
	ОписаниеМетрики.Алгоритм = "
	|ТаблицаЗначений = Новый ТаблицаЗначений;
	|ТаблицаЗначений.Колонки.Добавить(""label"", Новый ОписаниеТипов(""Строка""));
	|ТаблицаЗначений.Колонки.Добавить(""value"", Новый ОписаниеТипов(""Число""));	
	|
	|Запрос = Новый Запрос;
	|Запрос.Текст = 
	|""ВЫБРАТЬ
	||	пэмСостояниеМетрик.Метрика.Код КАК label,
	||	РАЗНОСТЬДАТ(пэмСостояниеМетрик.ДатаРасчета, &ТекущаяДата, СЕКУНДА) КАК value
	||ИЗ
	||	РегистрСведений.пэмСостояниеМетрик КАК пэмСостояниеМетрик"";
	|Запрос.УстановитьПараметр(""ТекущаяДата"",ТекущаяДата());
	|Результат = Запрос.Выполнить();
	|
	|Если НЕ Результат.Пустой() Тогда
	|	ТаблицаЗначений = Результат.Выгрузить();
	|КонецЕсли;
	|";	
	МассивМетрикДляЗаписи.Добавить(ОписаниеМетрики);
	
	НачатьТранзакцию();
	Константы.пэмПервоначальноеЗаполнениеВыполнено.Установить(Истина);
	Для Каждого Метрика Из МассивМетрикДляЗаписи Цикл
		Метрика.Записать();
	КонецЦикла;
	ЗафиксироватьТранзакцию();
	
КонецПроцедуры

Процедура РегламентныеОперации() Экспорт
	
	УстановитьПривилегированныйРежим(Истина);
	
	Если НЕ Константы.пэмПервоначальноеЗаполнениеВыполнено.Получить() Тогда
		ВыполнитьПервоначальноеЗаполнение();
	КонецЕсли;
		      
	ЗаписьРегистраСостояний = РегистрыСведений.пэмСостояниеМетрик.СоздатьМенеджерЗаписи();
	ЗаписьРегистраСостояний.Метрика = Справочники.пэмМетрики.ПустаяСсылка();
	ЗаписьРегистраСостояний.Прочитать();
	Если ЗаписьРегистраСостояний.Выбран() Тогда
		ЗаписьРегистраСостояний.Удалить();
	КонецЕсли;
	
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ РАЗЛИЧНЫЕ
	               |	пэмСостояниеМетрик.Метрика КАК Метрика
	               |ИЗ
	               |	РегистрСведений.пэмСостояниеМетрик КАК пэмСостояниеМетрик
	               |ГДЕ
	               |	пэмСостояниеМетрик.Метрика.Активность = ЛОЖЬ";
	Выборка = Запрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		ЗаписьРегистраСостояний.Метрика = Выборка.Метрика;
		ЗаписьРегистраСостояний.Удалить();
	КонецЦикла;
	
	УстановитьПривилегированныйРежим(Ложь);
	           	
КонецПроцедуры

Функция ПолучитьПараметрыРегламентногоЗадания(Идентификатор = Неопределено) Экспорт

	ОписаниеРегламентногоЗадания = ПолучитьОписаниеПараметровРегламентногоЗадания();
	РегламентноеЗадание = ПолучитьРегламентноеЗаданиеПоИдентификатору(Идентификатор);
			
	ЗаполнитьЗначенияСвойств(ОписаниеРегламентногоЗадания, РегламентноеЗадание);
	          	
	Возврат ОписаниеРегламентногоЗадания;
	
КонецФункции

Процедура ОбновитьРегламентноеЗадание(ПараметрыРегламентногоЗадания) Экспорт

	УстановитьПривилегированныйРежим(Истина);
	
	Если 
		(ПараметрыРегламентногоЗадания.Предопределенное 
		И ЗначениеЗаполнено(ПараметрыРегламентногоЗадания.УникальныйИдентификатор)) 
		ИЛИ
		(НЕ ПараметрыРегламентногоЗадания.Предопределенное 
		И ЗначениеЗаполнено(ПараметрыРегламентногоЗадания.УникальныйИдентификатор) 
		И НЕ ПараметрыРегламентногоЗадания.Использование)
		Тогда
		УдалитьРегламентноеЗаданиеПоИдентификатору(ПараметрыРегламентногоЗадания.УникальныйИдентификатор);		
		ПараметрыРегламентногоЗадания.УникальныйИдентификатор = Новый УникальныйИдентификатор("00000000-0000-0000-0000-000000000000");
	КонецЕсли;
	
	Если НЕ ПараметрыРегламентногоЗадания.Предопределенное И НЕ ПараметрыРегламентногоЗадания.Использование Тогда
		ПараметрыРегламентногоЗадания.УникальныйИдентификатор = Новый УникальныйИдентификатор("00000000-0000-0000-0000-000000000000");
		Возврат;
	КонецЕсли;
				  
	Если ПараметрыРегламентногоЗадания.Предопределенное Тогда 
		РегламентноеЗадание = РегламентныеЗадания.НайтиПредопределенное(Метаданные.РегламентныеЗадания.пэмВыполнитьРасчетМетрик);
	Иначе
		Попытка
			РегламентноеЗадание = РегламентныеЗадания.НайтиПоУникальномуИдентификатору(ПараметрыРегламентногоЗадания.УникальныйИдентификатор);
			Если РегламентноеЗадание.Предопределенное Тогда
				РегламентноеЗадание = РегламентныеЗадания.СоздатьРегламентноеЗадание(Метаданные.РегламентныеЗадания.пэмВыполнитьРасчетМетрик);
			КонецЕсли;
		Исключение
			РегламентноеЗадание = РегламентныеЗадания.СоздатьРегламентноеЗадание(Метаданные.РегламентныеЗадания.пэмВыполнитьРасчетМетрик);
		КонецПопытки;
	КонецЕсли;
		 			
	ЗаполнитьЗначенияСвойств(РегламентноеЗадание, ПараметрыРегламентногоЗадания,,"УникальныйИдентификатор");
	РегламентноеЗадание.Записать();
	
	Если ПараметрыРегламентногоЗадания.Предопределенное Тогда
		ПараметрыРегламентногоЗадания.УникальныйИдентификатор = Новый УникальныйИдентификатор("00000000-0000-0000-0000-000000000000");
	Иначе
		ПараметрыРегламентногоЗадания.УникальныйИдентификатор = РегламентноеЗадание.УникальныйИдентификатор;
	КонецЕсли;
	
	УстановитьПривилегированныйРежим(Ложь);
	
КонецПроцедуры

Функция ПолучитьРегламентноеЗаданиеПоИдентификатору(Идентификатор = Неопределено)
	
	УстановитьПривилегированныйРежим(Истина);
	
	Если ЗначениеЗаполнено(Идентификатор) Тогда 
		Попытка
			РегламентноеЗадание = РегламентныеЗадания.НайтиПоУникальномуИдентификатору(Идентификатор);
		Исключение
			РегламентноеЗадание = РегламентныеЗадания.СоздатьРегламентноеЗадание(Метаданные.РегламентныеЗадания.пэмВыполнитьРасчетМетрик);
		КонецПопытки;
	Иначе
		РегламентноеЗадание = РегламентныеЗадания.НайтиПредопределенное(Метаданные.РегламентныеЗадания.пэмВыполнитьРасчетМетрик);
	КонецЕсли;

	УстановитьПривилегированныйРежим(Ложь);
	
	Возврат РегламентноеЗадание;
	
КонецФункции

Функция УдалитьРегламентноеЗаданиеПоИдентификатору(Идентификатор)
	
	Результат = Ложь;
	
	Попытка
		РегламентноеЗадание = РегламентныеЗадания.НайтиПоУникальномуИдентификатору(Идентификатор);
		РегламентноеЗадание.Удалить();
		Результат = Истина;
	Исключение
		Результат = Истина;
	КонецПопытки;
	
	Возврат Результат;
	                  	
КонецФункции

#КонецОбласти	

#Область Служебные_процедуры_и_функции

Функция ПолучитьОписаниеПараметровРегламентногоЗадания()
	
	сткПараметрыЗадания = Новый Структура;
	сткПараметрыЗадания.Вставить("Использование", Ложь);
	сткПараметрыЗадания.Вставить("Предопределенное", Ложь);
	сткПараметрыЗадания.Вставить("Расписание", Новый РасписаниеРегламентногоЗадания);
	сткПараметрыЗадания.Вставить("Наименование", "");
	сткПараметрыЗадания.Вставить("Ключ", "");
	сткПараметрыЗадания.Вставить("Параметры", Неопределено);
	сткПараметрыЗадания.Вставить("УникальныйИдентификатор", Новый УникальныйИдентификатор("00000000-0000-0000-0000-000000000000"));
	  	
	Возврат сткПараметрыЗадания;

КонецФункции

#КонецОбласти	
