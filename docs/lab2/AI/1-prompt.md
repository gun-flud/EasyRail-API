We have to create: 
1. створення EARS-вимог (WHEN <тригер>, система SHALL <реакція> / WHILE <стан>, …) 
2. написання user stories 
3. написання Gherkin-сценаріїв (Given/When/Then)
4. створення матриці трасування для передбачення усіх сценаріїв, які буде покривати наші вимоги в форматі таблиці в Markdown.

Stick to these patterns during your creation:
1) EARS https://www.modernrequirements.com/blogs/ears-notation-the-practical-guide/, https://www.jamasoftware.com/requirements-management-guide/writing-requirements/adopting-the-ears-notation-to-improve-requirements-engineering/, https://medium.com/paramtech/ears-the-easy-approach-to-requirements-syntax-b09597aae31d
2) Gherkin https://hosseinnejati.medium.com/understanding-bdd-and-gherkin-syntax-why-they-matter-in-software-development-3336804e2cf2
3) user case diagrams written in  (PlantUML / Mermaid)  з ≥2 типами акторів, include/extend, узагальненням.
4) матриця трасування «вимога-id ↔ сценарій/UC» як таблиця в Markdown.
Result: 
• spec.md: ≥2 типи акторів (людина + зовнішня система/сервіс), головні цілі.
• Написати EARS-вимоги, user stories, Gherkin; побудувати use-case-діаграму.
• Матриця трасування: зв'язки багато-до-багатьох (не 1:1); позначити непокриті вимоги/UC.
• Аудит: EARS на двозначність; include/extend; звірити акторів і сутності з моделлю даних (Завдання 1); топ-3 розбіжності.
• DEFENSE.md: чому такі межі сценаріїв.
Project's stack: 
Проєкт: EasyRail (високонадійна система бронювання залізничних квитків), лабораторні з БД.
Стек: Node 22 LTS, pnpm, TypeScript strict, Fastify 5 + fastify-type-provider-zod, Zod,
PostgreSQL 16 Alpine + Drizzle ORM (pg.Pool), Vitest, Pino, Docker Compose.
Архітектура: Модульний моноліт, Layered (Controller -> Service -> Domain pure -> Repository).
Правила домену:
- Жодної конкатенації рядків у SQL;
- Фінанси в копійках (цілі числа integer/bigint);
- Часові мітки: timestamptz (UTC);
- Місце у вагоні можна продати декільком пасажирам на неперетинні відрізки [from, to);
- Формула конфлікту: max(A_from, B_from) < min(A_to, B_to);
- Холд (HELD): 10 хвилин;
- Повернення квитка: тільки якщо (departure_time - NOW()) >= 2 hours;
- Заборона брокерів (ADR 003): черги тільки через SKIP LOCKED.
Project's description: 
EasyRail навчальний проєкт, який повністю дублює додаток Укрзалізниця. Його головними ідеями є створення додатку, який витримує high load та може працювати під великим навантаженням та хорошою швидкістю. Додаток слугує для декількох акторів:
-менеджери розкладу поїздів у укрзалізниці, які додають нові потяги в систему для можливості створення розкладів потягів та букінгу користувачів
-користувачі, які можуть бачити усі потяги при введенні дати та та локацій звідки і куди, та замовляти їх для себе
Базові вимоги та бізнес логіка: 

### Авторизація юзера
* Користувач може зареєструвати акаунт за допомогою електронної пошти (email) та пароля
* Зареєстрований користувач має доступ до свого особистого кабінету, історії взаємодії з системою

### Пошук та розклад
* Можливість ввівши станцію відправлення, станцію прибуття та необхідну(бажану) дату отримати список поїздів, з вільними місцями та цінами на них, тривалістю поїздки та інформацією про потяги
* Користувач може бачити вільні та зайняті місця в потязі
* Система автоматично приховує або маркує поїзди, які заповнені на запитуваному відрізку маршруту

### Бронювання та купівля квитків
* Користувач може обрати вільний квиток, забронювати його та здійснити оплату квитка
* Користувач може придбати квиток, як і собі, так і іншим особам, ввівши їх ім’я та прізвище
* Система підтримує бронювання одного і того ж місця різними пасажирами, якщо їхні маршрути не перетинаються

### Сповіщення та комунікація
* За годину до відправки потяга зі станції система відправляє повідомлення, що відправляється потяг
* Повідомлення за умови коли: потяг зірвано, затримується, квиток придбано чи повернено

### Система управління квитками
* Користувач може повернути квиток, якщо до відправлення залишається більше двох годин
* Користувач може переглядати заброньовані квитки та архів поїздок

### Безпека та стресостійкість системи
* Система повинна витримувати великий наплив користувачів в день появи квитка в продажі
* Система повинна не давати можливості юзеру зарезервувати один і той же квиток кілька разів через помилку, або виконати овербукінг, де декілька людей отримають місце на один і той же маршрут
* Система не буде пропускати резервацію квитка без оплати

### Збір аналітики
* Збереження всіх помилок та проблем, які стались з додатком
* Система має зберігати архів рейсів та детальну інформацію про них
* Система має проаналізовувати ці дані та виводити найпопулярніші маршрути, найпроблемніші маршрути (де частіше повертають квитки)

# Бізнес-логіка EasyRail API

### 1. Модуль користувачів та пасажирів (Users & Passengers)

**Реєстрація та безпека акаунта:** Реєстрація здійснюється за унікальним `email` та `password` (хешування через `bcrypt/argon2`, збереження у `password_hash`). Особистий профіль зберігає базові контактні дані: `full_name`, `phone`, `email`. Процес автентифікації перевіряє хеш пароля та видає криптографічно підписаний `JWT` для безстанової авторизації наступних запитів.

**Механізм «Збережені попутники» (Saved Companions):**
Якщо користувач ввів дані нової особи вручну й успішно оплатив квиток, система автоматично зберігає цю особу в таблицю `passengers` з прив'язкою до `user_id` для використання в один клік у майбутньому.

**Історія поїздок та життєвий цикл записів:**
Кабінет користувача відображає активні бронювання (`HELD`), дійсні квитки (`PAID`) та архів минулих поїздок (час прибуття вже минув). При скасуванні/видаленні фізичний рядок з бази даних не видаляється (`soft delete`, фіксація `cancelled_time = NOW()`), статус квитка змінюється на `CANCELLED`. Запис залишається видимим в архіві як недійсний («Скасовано»), водночас сегменти місця миттєво звільняються для інших.



### 2. Модуль топології, розкладу та пошуку поїздів (Search & Scheduling)

**Пошук поїздів за станціями та датою:**
Користувач вводить `station_from_id`, `station_to_id` та дату. Система валідує вхідні дані та фільтрує рейси за умовою правильного напрямку руху: `stop_order(station_from) < stop_order(station_to)`. Видача містить деталі поїзда (номер, тип), кількість вільних місць на відрізку, тривалість та динамічну ціну (залежно від класу вагона `COUPE`, `PLATZKART`, `LUX` та дистанції). За замовчуванням заповнені поїзди (`SOLD OUT`) приховуються; перемикач «Показати всі» розкриває повну сітку рейсів.



### 3. Модуль бронювання та купівлі квитків (Booking & Checkout Engine)

**Бронювання та резерв (10 хвилин):**
Користувач обирає місце і діапазон перегонів (`station_from_order -> station_to_order`). Натискання «Забронювати» створює запис у `tickets` (`status = 'HELD'`, `user_id`, `hold_expires_at = NOW() + INTERVAL '10 minutes'`) та фіксує перегони в `ticket_segments`. На час холда відрізок блокується для інших.

**Обмеження кількості активних холдів:**
Один користувач може мати не більше 1 активного холду (`status = 'HELD'` і `hold_expires_at > NOW()`). Спроба створити нове бронювання за наявності активного блокується з помилкою: «У вас вже є активне незавершене бронювання. Оплатіть його або скасуйте перед вибором нового квитка».

**Мультисегментний продаж місця:**
Фізичне місце ділиться по проміжних перегонах (`stop_order`). Воно доступне, якщо запитуваний діапазон не має перетинів з активними (`HELD`/`PAID`) сегментами цього ж місця. Пряме стикування на спільній станції (перший їде `1→3`, другий `3→5`) дозволяє повторне використання; перетин хоча б одного спільного перегону в русі блокує операцію.

**Автоматичний відкат при таймауті:**
Якщо за 10 хв оплата не підтверджена, фоновий воркер (`SKIP LOCKED`) переводить квиток у статус `EXPIRED` і видаляє зв'язані записи з `ticket_segments`.

**Оплата, фіксація та генерація PDF:**
При купівлі «для себе» дані підтягуються з `users`; «іншій особі» — з вибору збережених пасажирів або ручним введенням (з автозбереженням у `passengers`). Успішна оплата переводить статус у `PAID` і ініціює асинхронну генерацію PDF-квитка.


### 4. Модуль сповіщень та комунікацій (Notifications & Messaging)
Багаторівневі нагадування за 60, 30 та 15 хвилин до відправлення рейсу (`email/push`). Оперативні сповіщення при затримці, скасуванні, успішній оплаті (з прикріпленим PDF) та поверненні коштів.


### 5. Модуль управління квитками та повернення (Ticket Lifecycle & Refunds)
Повернення можливе для квитків у статусі `PAID`, якщо до відправлення поїзда зі станції посадки залишається понад 2 години (`departure_time - NOW() > 2 hours`). Менше або рівно 2 години — операція блокується. При поверненні статус квитка стає `CANCELLED`, фіксується `cancelled_time = NOW()`, створюється аудит-запис у таблиці `refunds` (сума, статус виплати), а пасажиру надходить email-підтвердження. Кабінет розбитий на вкладки: активні (незавершені броні `HELD` + майбутні поїздки `PAID` з доступом до PDF і кнопкою «Повернути») та архів (завершені поїздки з минулим часом прибуття + скасовані квитки `CANCELLED` з бейджем «Скасовано», датою та сумою повернення).

DB structure: 
erDiagram
    stations ||--o{ stops : "has"
    routes ||--|{ stops : "contains"
    routes ||--o{ trips : "generates"
    routes ||--o{ carriages : "assigned"
    carriage_type ||--|{ seat_templates : "defines"
    carriage_type ||--o{ carriages : "categorizes"
    seat_templates ||--o{ ticket_segment : "reserved"
    carriages ||--o{ ticket_segment : "placed_in"
    trips ||--o{ ticket_segment : "booked_on"
    users ||--o{ ticket_segment : "purchased_by"
    users ||--o{ passengers : "manages"
    passengers ||--o{ ticket_segment : "travels_as"
    stations ||--o{ ticket_segment : "origin"
    stations ||--o{ ticket_segment : "destination"

    stations {
        uuid station_id PK
        varchar name
        varchar city
    }

    stops {
        uuid stop_id PK
        uuid route_id FK
        uuid station_id FK
        timestamptz stop_time
        timestamptz departure_time
        int stop_order
    }

    routes {
        uuid route_id PK
        varchar name
        int base_segment_price
        int number
        enum status "ACTIVE, INACTIVE"
        enum schedule_rule
        enum train_type
    }

    carriage_type {
        uuid carriage_type_id PK
        enum type "CUPE, PLATZKART, LUX, SEAT"
        numeric carriage_type_price_multiplier
        int number_of_seats
    }

    seat_templates {
        uuid seat_id PK
        uuid carriage_type_id FK
        int seat_number
        boolean is_side
        enum tier_type "TOP, DOWN, SEAT"
    }

    carriages {
        uuid carriage_id PK
        uuid carriage_type_id FK
        uuid route_id FK
        int number
    }

    trips {
        uuid trip_id PK
        uuid route_id FK
        timestamptz departure_time
        enum status "SCHEDULED, DEPARTED, CANCELLED, COMPLETED"
        int delay_minutes
    }

    ticket_segment {
        uuid ticket_id PK
        uuid user_id FK
        uuid passenger_id FK 
        uuid trip_id FK
        uuid seat_id FK
        uuid carriage_id FK
        uuid from_station_id FK
        uuid to_station_id FK
        enum ticket_status "HELD, PAID, CANCELLED, EXPIRED"
        timestamptz cancelled_time
        varchar pdf_url
        int price
        int to_stop_order
        timestamptz departure_time
        timestamptz arrival_time
        timestamptz created_at
        timestamptz paid_at
        timestamptz hold_expires_at
        varchar passenger_lastname
        varchar passenger_name
        varchar from_station_name
        varchar to_station_name
        int from_stop_order
    }

    users {
        uuid user_id PK
        varchar name
        varchar hashed_password
        varchar email UK
    }

    passengers {
        uuid passenger_id PK
        uuid user_id FK
        varchar lastname
        varchar name
    }
### 1. КОНТЕКСТ ПРОЄКТУ ТА СТЕК (BASELINE З ЗАВДАННЯ 1)

* **Домен:** Система бронювання квитків із проміжними зупинками, віртуальними місцями (Lazy Evaluation) та захистом від овербукінгу на перегонах.
* **Затверджені архітектурні рішення (ADR):**
  - ADR 001: Lazy Evaluation місць (крісла описуються в `seat_templates`, запис зайнятості створюється лише в `ticket_segment`). Формула конфлікту: $\max(A_{\text{from}}, B_{\text{from}}) < \min(A_{\text{to}}, B_{\text{to}})$. Суміжні відрізки $[1, 3]$ та $[3, 5]$ НЕ конфліктують.
  - ADR 002: Усі PK та FK — виключно UUIDv7 (`uuid`).
  - ADR 003: Snapshot Pattern у `ticket_segment` (фіксація незмінних `passenger_name`, `passenger_lastname`, `from_station_name`, `to_station_name`, `price`).
  - ADR 004 / 011: Фінанси виключно в цілих числах `int` у копійках ($100\text{ грн} = 10000$). Жодних `float` чи `decimal`.
  - ADR 005: State Machine квитка без Hard Delete: `HELD` $\to$ `PAID` $\to$ `CANCELLED` або `EXPIRED`.
  - ADR 006 / 008: Очищення 10-хвилинного холду фоновим воркером через `FOR UPDATE SKIP LOCKED` (Zero-Broker, без RabbitMQ/Kafka).
  - ADR 007 / 009: Монотонний `stop_order int` у `stops`. Вектор руху валідний лише при $\text{from\_stop\_order} < \text{to\_stop\_order}$. Час — виключно `timestamptz` (UTC).
  - Правило повернення: квиток можна повернути лише якщо $\text{departure\_time} - \text{NOW}() \ge 2\text{ години}$.

* **Базова ER-модель (Завдання 1) — джерело правди для імен сутностей:**
  - `stations` (`station_id`, `name`, `city`)
  - `stops` (`stop_id`, `route_id`, `station_id`, `stop_time`, `departure_time`, `stop_order`)
  - `routes` (`route_id`, `name`, `base_segment_price`, `number`, `status`, `schedule_rule`, `train_type`)
  - `carriage_type` (`carriage_type_id`, `type`, `carriage_type_price_multiplier`, `number_of_seats`)
  - `seat_templates` (`seat_id`, `carriage_type_id`, `seat_number`, `is_side`, `tier_type`)
  - `carriages` (`carriage_id`, `carriage_type_id`, `route_id`, `number`)
  - `trips` (`trip_id`, `route_id`, `departure_time`, `status`, `delay_minutes`)
  - `users` (`user_id`, `name`, `hashed_password`, `email`)
  - `passengers` (`passenger_id`, `user_id`, `lastname`, `name`)
  - `ticket_segment` (`ticket_id`, `user_id`, `passenger_id`, `trip_id`, `carriage_id`, `seat_id`, `from_station_id`, `to_station_id`, `ticket_status`, `price`, `from_stop_order`, `to_stop_order`, `departure_time`, `arrival_time`, `passenger_name`, `passenger_lastname`, `from_station_name`, `to_station_name`, `created_at`, `paid_at`, `hold_expires_at`, `cancelled_time`, `pdf_url`)

---

### 2. КРИТЕРІЇ ПРИЙНЯТТЯ ТА ВИМОГИ ДО РЕЗУЛЬТАТУ (ЗА СКРИНШОТОМ)

Необхідно згенерувати повний, готовий до здачі пакет документів у форматі Markdown:
1. **Файл `spec.md`:**
   - **Актори:** $\ge 2$ типів акторів (люди + зовнішні системи/сервіси). Обов'язково показати узагальнення (ієрархію) акторів: наприклад, `Гість` $\to$ `Зареєстрований користувач` (Пасажир); `Провідник`, `Диспетчер розкладу`; зовнішні системи: `Платіжний шлюз (LiqPay/Monobank)`, `Сервіс сповіщень (Email/Push)`, `Системний фоновий воркер`.
   - **Головні цілі системи:** Бізнес-цілі та межі (Scope).
   - **Use Case Diagram (Діаграма прецедентів):** 
     * Код на **PlantUML** або **Mermaid**.
     * Мінімум 2 типи акторів (людина + зовнішній сервіс).
     * Обов'язкове використання зв'язків:
       - `<<include>>` (наприклад: «Бронювання квитка» включає «Перевірку перетину інтервалів місця»; «Оплата квитка» включає «Фіксацію зліпка даних (Snapshot)»);
       - `<<extend>>` (наприклад: «Оплата квитка» розширюється «Збереженням нового попутника в довідник»; «Пошук рейсів» розширюється «Відображенням затриманих рейсів»);
       - Узагальнення акторів (Generalization: `Гість` $\to$ `Авторизований юзер`) та узагальнення прецедентів (наприклад: «Оплата квитка» $\to$ «Оплата банківською карткою» / «Оплата через Google Pay / Apple Pay»).
   - **EARS-вимоги (Easy Approach to Requirements Syntax):**
     * Написати вимоги для всіх 5 класичних EARS-патернів:
       1. *Event-driven (Подієві):* `WHEN <trigger>, the system SHALL <response>`
       2. *State-driven (Станові):* `WHILE <state>, the system SHALL <response>`
       3. *Unwanted behavior (Обробка збоїв/помилок):* `IF <trigger/error condition>, THEN the system SHALL <response>`
       4. *Optional feature (Опціональні/налаштовувані):* `WHERE <feature is included>, the system SHALL <response>`
       5. *Ubiquitous (Загальні/постійні):* `The system SHALL <response>`
     * Усі вимоги мають бути однозначними, вимірюваними та тестованими (чіткі числа: 10 хвилин, 2 години, копійки, статус-коди).
   - **User Stories:** 
     * Структура: `As a <role>, I want <goal> so that <benefit>`.
     * До кожної User Story додати чіткі Acceptance Criteria (DoD).
   - **Gherkin-сценарії (BDD):**
     * Набір сценаріїв у форматі `Scenario: ... Given ... When ... Then ... And ...`.
     * Охопити: успішний флоу покупки зі Snapshot, конфлікт перетину інтервалів (овербукінг), суміжний перегін без конфлікту, відмову повернення менш ніж за 2 години, скасування холда воркером через 10 хвилин.
   - **Матриця трасування (Traceability Matrix):**
     * Оформлена як таблиця Markdown: `[Вимога EARS ID] | [User Story ID] | [Use Case ID] | [Gherkin Scenario ID] | [Сутність БД / Модель] | [Статус покриття]`.
     * **КРИТИЧНО:** Зв'язки мають бути РЕАЛЬНО багато-до-багатьох ($M:N$), а не штучно 1:1! (Один прецедент покриває декілька вимог, одна вимога трасується на декілька сценаріїв).
     * **КРИТИЧНО («Ознака відмінного виконання»):** Обов'язково позначити і пояснити **щонайменше 1 навмисно непокриту вимогу/прецедент** (Uncovered Requirement) із чітким архітектурним обґрунтуванням (наприклад, чому інтеграція фіскального реєстратора чи генерація офлайн-підпису квитка відкладена в Post-v1 Backlog і не реалізована в ядрі).
   - **Аудит вимог та моделі даних:**
     * Аудит EARS на відсутність двозначності;
     * Перевірка коректності застосування `<<include>>` та `<<extend>>`;
     * Звірка акторів і сутностей із Завданням 1;
     * Опис **Топ-3 розбіжностей** (spec ↔ артефакт), які виникли під час переходу від концептуальної моделі до функціональних вимог (наприклад: потреба у збереженні імені попутника в `passengers` vs Snapshot у `ticket_segment`; необхідність поля `delay_minutes` у прецедентах пошуку; деталізація станів State Machine).

2. **Файл `DEFENSE.md`:**
   - Чітке обґрунтування меж системи та сценаріїв: чому саме такі Use Cases винесені в ядро, а що відсічено (Out of Scope).
   - Чому зовнішні платіжні шлюзи та воркери змодельовані як окремі вторинні актори.
   - Аргументація непокритих вимог у матриці трасування.

---

### 3. ФОРМАТ ВИДАЧІ

Видай готові, вичерпні тексти двох файлів:
1. `spec.md` (з повним вмістом, валідним Mermaid або PlantUML блоком діаграми Use Case, таблицями EARS, User Stories, Gherkin та $M:N$ матрицею трасування).
2. `DEFENSE.md` (структурований захист меж сценаріїв та архітектурних компромісів).

Подививись на прикріплений файл це наш проєкт, де все є, ти можеш все в ньому побачити, його змінювати не треба , створи нову папочку AI/GEMINI-LAB2 або тут, або в easyrail-api папці, нічого не змінюй в поточній папці окрім створення власної, де ти запишеш свої рішення!!!!

[EasyRail-API](file;file:///c%3A/KPI%20%D0%9D%D0%B0%D0%B2%D1%87%D0%B0%D0%BD%D0%BD%D1%8F/easyRail_API/EasyRail-API) 