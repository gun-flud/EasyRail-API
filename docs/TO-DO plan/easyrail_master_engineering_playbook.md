# EasyRail: Повний інженерний плейбук, командні правила та семестрова дорожня карта

> **Статус документа:** Canonical / Approved Architecture  
> **Період реалізації:** 21 вересня — кінець грудня (14 навчальних тижнів, 7 фаз по 2 тижні)  
> **Стек:** Node.js 22 LTS, TypeScript 5 (Strict), Fastify 5 + Zod Type Provider, PostgreSQL 16 Alpine, planned Drizzle ORM (`pg.Pool`), Vitest, Docker Compose, GitHub Actions + GHCR, CodeRabbit AI. Drizzle ORM, Drizzle Kit, `fastify-type-provider-zod`, `@fastify/jwt` and `argon2` are future dependencies until they are added to `backend/package.json`; the documented implementation must not be treated as reproducible from the current manifest before then.

---

## 1. Огляд системи, цілі та матриця внеску в Лабораторні роботи БД

### 1.1. Дві паралельні місії проєкту
1. **Академічна бездоганність:** 100% закриття всіх 6 лабораторних робіт курсу «Бази даних» з персональним внеском та індивідуальним захистом кожного розробника.
2. **Комерційна зрілість (Middle+/Senior):** Модульний моноліт з архітектурою *Functional Core, Imperative Shell (FCIS)*, повною типізацією від БД до HTTP-відповіді, песимістичним блокуванням конкурентних покупок (`FOR UPDATE`), захистом від подвійного продажу полиць на відрізках, фіксацією зліпків даних (Snapshot Pattern) та чергою очищення на базі `SKIP LOCKED` без зовнішніх брокерів.


## 2. Спільні правила гри та інженерні стандарти

### 2.1. Щоденний цикл взаємодії (15 хвилин на день)
* **Ранок (Синхронізація):** 
  ```bash
  git switch main && git pull
  git switch -c feat/<назва-фічі>
  ```
* **Атомарні коміти:** 1 мікро-крок = 1 коміт. Робимо дрібні кроки, перевіряючи код локально.
* **Маленькі Pull Requests:** Кожні 1–2 дні відкриваємо PR. **PR понад 400 рядків коду суворо заборонено** — розбивайте на менші частини.
* **Правило 30 хвилин:** Якщо ви застрягли на одній помилці/багу на 30 хвилин — негайно пишіть у командний чат. Повідомлення має містити:
  1. Що саме ви робили.
  2. Що очікували отримати.
  3. Текст помилки з терміналу та точну команду запуску.  
  *Мовчати й гаяти дні заборонено.*
* **Sunday Retro (10 хвилин щонеділі):** Короткий зідзвон/чат: що злито в `master`, що заблоковано, які заглушки потрібні для суміжних модулів.

### 2.2. Конвенції Git, PR та Definition of Done (DoD)
* **Прямий пуш у `master` заблоковано.**
* **Префікси гілок:** `feat/...`, `fix/...`, `test/...`, `docs/...`, `perf/...`, `chore/...`.
* **Стандарт Conventional Commits:**
  * `feat(auth): implement argon2id password hashing and jwt issue`
  * `feat(booking): implement interval overlap check`
  * `fix(trips): fix station ordering validation`
  * `perf(indexes): add covering b-tree index with include`
  * `test(concurrency): add race condition simulation`
* **Перевірка перед комітом:** перед кожним комітом у каталозі `backend` обов'язково запустіть форматування та автоматичне виправлення lint-помилок:
  ```bash
  pnpm --dir backend format && pnpm --dir backend lint:fix
  ```
  Після цього перегляньте внесені автоматичні зміни й лише тоді створюйте коміт.
* **Обов'язковий Definition of Done (DoD) для вливання PR:**
  1. Зелений статус перевірок у GitHub Actions CI (Typecheck, Linting, Vitest).
  2. Автоматичний огляд CodeRabbit AI без критичних зауважень щодо безпеки чи витоку ресурсів.
  3. Мінімум 1 схвалення (Approve) від Владислава (як архітектора проєкту).
  4. В описі PR зазначено: як перевірити (команда в терміналі або ендпоінт Swagger).
  5. Якщо PR змінював або додавав критичні SQL-запити — обов'язково додано скриншот або текстовий вивід `EXPLAIN` з DBeaver.
  6. Злиття виключно через **Squash and merge** (або Rebase) для збереження чистої історії.

### 2.3. Як працювати з ШІ (Gemini / Claude) і не завалити захист
ШІ в EasyRail — це віртуальний напарник для парного програмування, а не генератор «магічного коду», який ви не розумієте.
* **Завжди вставляйте контекст-блок на початку нового чату з ШІ:**
  ```text
  Контекст проєкту:
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
  Моє завдання: <вставити конкретний крок із Roadmap>
  Вимога: Спочатку дай короткий план і поясни підхід, а потім пиши типізований код.
  ```
* **Принцип розуміння:** Будь-який рядок коду чи SQL, який ви не можете самостійно пояснити викладачу біля дошки/екрана, **не має права потрапити в PR**.
* **Перевірка SQL:** Кожен згенерований запит спочатку перевіряється в одноразовій staging-базі. Для `SELECT` використовуйте `EXPLAIN (ANALYZE, BUFFERS)` там; для `INSERT`, `UPDATE`, `DELETE` та cleanup-запитів використовуйте звичайний `EXPLAIN`, якщо виконання не ізольовано та явно безпечне. Не запускайте мутації через `EXPLAIN ANALYZE` на live-даних.
* **Взаємний крос-чек:** Перед кожною здачею лаби кожен учасник команди повинен вміти пояснити 2 випадкові завдання своїх колег.

### 2.4. Фундаментальні архітектурні заповіді EasyRail
1. **Functional Core, Imperative Shell (FCIS):** Уся бізнес-математика (перевірка накладання станцій, штрафи повернень, ціноутворення) пишеться як чисті функції в `*.domain.ts` без звернення до бази, файлів чи мережі.
2. **Цілісність грошей і часу:** Усі ціни зберігаються в **цілих числах** (копійки), ніяких `float` чи `number` із плаваючою комою. Усі дати зберігаються як `TIMESTAMPTZ`.
3. **Snapshot Pattern (Юридична незмінність):** У момент оплати (`PAID`) квиток отримує копію поточних імен, назв станцій, розкладу та фінальної ціни. Зміна назви станції в довіднику не змінює старі квитки.
4. **Zero-Broker Architecture (ADR 003):** Жодного RabbitMQ/Kafka. Асинхронні черги експірації будуються на рівні Postgres через патерн `FOR UPDATE SKIP LOCKED`.
5. **Connection Pooling (ADR 002):** Використовуємо клієнтський `pg.Pool` у Drizzle. PgBouncer відкладено, щоб не ламати prepared statements.

---

## 3. База знань та навчальні ресурси (Documentation & Guides)

### 3.1. Офіційна документація технологій стеку
* **Fastify 5.x:** [Fastify Guides & Lifecycle](https://fastify.dev/docs/latest/Guides/Getting-Started/) — життєвий цикл запиту, хуки, архітектура плагінів.
* **Fastify Type Provider Zod:** [fastify-type-provider-zod GitHub](https://github.com/turkerdev/fastify-type-provider-zod) — як робити 100% строгу типізацію роутів.
* **Drizzle ORM:** [Drizzle Documentation](https://orm.drizzle.team/docs/overview) та [Drizzle Kit Migrations](https://orm.drizzle.team/kit-docs/overview).
* **Zod:** [Zod Documentation](https://zod.dev/) — схеми валідації, `refine()`, трансформації.
* **Vitest:** [Vitest Guide](https://vitest.dev/guide/) — TDD, юніт-тести, моки, асинхронні перевірки.

### 3.2. Бази даних, SQL, індекси та профілювання (Критично для захисту лаб)
* **Головний підручник з індексації:** [Use The Index, Luke!](https://use-the-index-luke.com/) — обов'язково прочитати розділи про будову B-Tree, роботу композитних індексів та порядок колонок.
* **Робота планувальника та EXPLAIN:** [PostgreSQL EXPLAIN Explained](https://www.depesz.com/tag/explain/) та [Postgres Guide: Performance](https://postgresguide.com/performance/explain/).
* **Рівні ізоляції та аномалії:** [PostgreSQL 16 Manual: Transaction Isolation](https://www.postgresql.org/docs/16/transaction-iso.html) — різниця між Read Committed, Repeatable Read та Serializable.
* **Неблокуючі черги в Postgres:** [PostgreSQL Anti-Patterns: Queues with SKIP LOCKED](https://2ndquadrant.com/en/blog/what-is-select-skip-locked-for-in-postgresql/).

### 3.3. Архітектура та шаблони проектування
* **Functional Core, Imperative Shell:** [Gary Bernhardt Boundaries Screencast](https://www.destroyallsoftware.com/screencasts/catalog/functional-core-imperative-shell) — відео-концепція чистого ядра.
* **Modular Monolith:** [Modular Monolith Architecture Guide](https://khalilstemmler.com/articles/software-design-architecture/organizing-app-logic/) — розмежування сервісів та репозиторіїв.

---

## 4. Пофазний семестровий план розробки (14 тижнів, 7 фаз)

```text
Вересень ──► Жовтень ───────► Листопад ───────────► Грудень
[Фаза 1] ──► [Фаза 2] ──► [Фаза 3] ──► [Фаза 4] ──► [Фаза 5] ──► [Фаза 6] ──► [Фаза 7]
 Лаба 1       Лаба 2       Лаба 3       Лаба 4       Лаба 5       Лаба 6     Реліз/Курсовий
```

---

### Фаза 1. Інфраструктура, схема даних та Лабораторна №1 (Тижні 1–2: 21 вер – 04 жов)

* **Проблема, яку вирішуємо:** Відсутність спільного робочого середовища та ризик неконсистентних даних (наприклад, поїзд рухається у зворотному напрямку, або відрізок поїздки має від'ємну довжину).
* **Спільний результат:** Працюючий PostgreSQL 16 Alpine у Docker, Drizzle schema, зв'язана ER-діаграма в DBeaver.

#### 1. Владислав Іванников (`@gun-flud`) — Гілка: `feat/infra-core-schema`
>* **Крок 1.1:** Створити `docker-compose.yml` (Postgres 16 Alpine, volume `pgdata`, healthcheck на `pg_isready -U postgres`).
>  * *Коміт:* `feat(infra): setup postgres 16 alpine docker container with healthcheck`
>  * *Інструменти:* Docker Compose, Docker CLI.
>  * *Перевірка:* `docker compose up -d` запускає контейнер у стані `healthy`.
* **Крок 1.2:** Створити Fail-Fast валідацію середовища `backend/src/config/env.ts` через Zod (`DATABASE_URL`, `PORT`, `NODE_ENV`, `JWT_SECRET`).
  * *Коміт:* `feat(config): add fail-fast environment schema validation with zod`
  * *Інструменти:* Zod, `dotenv`.
  * *Перевірка:* Видалення `.env` призводить до негайної зупинки процесу з помилкою валідації.
* **Крок 1.3:** Ініціалізувати Drizzle ORM у `backend/src/db/index.ts` через пул з'єднань `pg.Pool` та налаштувати `backend/drizzle.config.ts`.
  * *Коміт:* `feat(db): configure pg pool connection and drizzle config`
  * *Інструменти:* `pg.Pool`, `drizzle-orm/node-postgres`, `drizzle-kit`.
  * *Перевірка:* Успішне тестове з'єднання з БД через клієнт.
* **Крок 1.4:** Описати в `backend/src/db/schema.ts` таблиці ядра: `users`, `trips`, `ticket_segments` із системним констрейнтом:
  $$\text{CHECK (from\_stop\_order < to\_stop\_order)}$$
  та налаштувати генерацію UUID через системне розширення `gen_random_uuid()`.
  * *Коміт:* `feat(schema): define core tables with check constraint for stop order`
  * *Інструменти:* Drizzle schema builder (`pgTable`, `uuid`, `check`, `sql`).
  * *Перевірка:* Спроба ручної вставки рядка з `from_stop_order >= to_stop_order` у DBeaver відхиляється СКБД.
* **Артефакт на захист Лаби №1:** Контейнер БД, пул Drizzle, `CHECK`-обмеження ядра, генерація UUID через `gen_random_uuid()`.

#### 2. Дмитро Пеньківський — Гілка: `feat/schema-logistics`
* **Крок 1.1:** Описати логістичні ENUM-типи в `backend/src/db/schema.ts`: `train_type` (`INTERCITY`, `NIGHT_EXPRESS`), `carriage_type_enum` (`COUPE`, `PLATZKART`), `tier_type` (`TOP`, `BOTTOM`).
  * *Коміт:* `feat(schema): declare logistics enums for trains and carriages`
  * *Інструменти:* `pgEnum` у Drizzle Kit.
  * *Перевірка:* ENUM-типи відображаються у системному каталозі Postgres (`\dT` у DBeaver).
* **Крок 1.2:** Описати таблиці `stations` (з `UNIQUE(name)`) та `routes`. Додати правило цілісності `ON DELETE RESTRICT` для станцій.
  * *Коміт:* `feat(schema): define stations and routes with deletion constraints`
  * *Інструменти:* Drizzle `foreignKey`, `onDelete: 'restrict'`.
  * *Перевірка:* Спроба видалити станцію, яка прив'язана до існуючого маршруту, блокується Postgres.
* **Крок 1.3:** Описати проміжну таблицю зв'язку $M:N$ `stops` (`route_id`, `station_id`, `stop_order`, `stop_duration_minutes`) із композитним ключем унікальності `UNIQUE(route_id, stop_order)`.
  * *Коміт:* `feat(schema): implement stops join table with composite uniqueness`
  * *Інструменти:* Drizzle `uniqueIndex` / `primaryKey`.
  * *Перевірка:* Візуалізація $M:N$ зв'язку в ER-діаграмі DBeaver.
* **Крок 1.4:** Описати сутності рухомого складу: `trains`, `carriages`, `seat_templates` (нумерація місць 1..54, поверх, тип полиці) із зовнішніми ключами.
  * *Коміт:* `feat(schema): define trains, carriages and seat layout templates`
  * *Інструменти:* Drizzle schema builder.
  * *Перевірка:* Успішна кодогенерація типів Drizzle через `pnpm --dir backend exec drizzle-kit generate` без помилок.
* **Артефакт на захист Лаби №1:** Логістична топологія мережі, $M:N$ таблиця `stops`, композитна унікальність зупинок, констрейнти `ON DELETE RESTRICT`.

#### 3. Мохаммад Хашим — Гілка: `feat/schema-finance-audit`
* **Крок 1.1:** Описати фінансові ENUM-типи: `ticket_status` (`HELD`, `PAID`, `CANCELLED`, `EXPIRED`), `refund_status` (`PENDING`, `COMPLETED`, `REJECTED`).
  * *Коміт:* `feat(schema): add ticket and refund status enums`
  * *Інструменти:* `pgEnum` у Drizzle Kit.
  * *Перевірка:* Перевірка наявності типів через системні таблиці DBeaver.
* **Крок 1.2:** Описати сутність збережених попутників `passengers` із зовнішнім ключем на `users.id` (`ON DELETE CASCADE`).
  * *Коміт:* `feat(schema): define passengers table with user relation`
  * *Інструменти:* Drizzle `foreignKey`, `onDelete: 'cascade'`.
  * *Перевірка:* Видалення користувача автоматично видаляє його список попутників.
* **Крок 1.3:** Описати фінансову таблицю повернень `refunds` (`refund_id`, `ticket_id`, `amount` в копійках integer, `reason`, `created_at`) зі зв'язком 1:1 до квитка.
  * *Коміт:* `feat(schema): define refunds audit table with ticket foreign key`
  * *Інструменти:* Drizzle `integer`, `timestamp(withTimezone: true)`.
  * *Перевірка:* Зв'язок 1:1 між поверненням та квитком коректно відображається в ERD.
* **Крок 1.4:** Описати таблицю журналу аудиту `system_logs` (`id`, `action`, `user_id`, `metadata`, `created_at`).
  * *Коміт:* `feat(schema): create system logs table for audit trail`
  * *Інструменти:* Drizzle `jsonb`, `timestamp`.
  * *Перевірка:* Поле `created_at` має тип `TIMESTAMPTZ DEFAULT NOW()`.
* **Крок 1.6:** Створити `.github/workflows/ci.yml` (запуск на кожен PR): typecheck, lint, Vitest, із сервіс-контейнером Postgres 16 для майбутніх інтеграційних тестів.
  * *Коміт:* `ci: add pr pipeline with typecheck, lint, vitest and postgres service`
  * *Інструменти:* GitHub Actions, `pnpm/action-setup`, service containers.
  * *Перевірка:* Тестовий PR показує зелений статус; навмисна помилка типів робить його червоним.
* **Крок 1.7:** Додати `.github/pull_request_template.md` з чеклістом DoD (як перевірити, EXPLAIN для SQL-змін, розмір PR до 400 рядків).
  * *Коміт:* `docs(process): add pull request template with definition of done checklist`
  * *Інструменти:* GitHub PR template.
  * *Перевірка:* Новий PR автоматично містить чекліст.
* **Артефакт на захист Лаби №1:** Фінансова схема обліку повернень, правила `ON DELETE CASCADE`, таблиця аудиту дій `system_logs`.

---

### Фаза 2. Каркас Fastify, авторизація, сіди та Лабораторна №2 (Тижні 3–4: 05 жов – 18 жов)

* **Проблема, яку вирішуємо:** Відсутність автоматичної API-документації, зберігання незахищених паролів у відкритому вигляді та порожня база без реалістичних маршрутів для тестування.
* **Спільний результат:** Запущений Fastify-сервер із документацією Swagger `/docs`, реєстрація користувачів з Argon2id хешуванням, наповнена база залізниць України.

#### 1. Владислав Іванников (`@gun-flud`) — Гілка: `feat/backend-core-auth`
* **Крок 2.1:** Створити Fastify-інстанс з інтеграцією `fastify-type-provider-zod` та кольоровим структурованим логером Pino (`pino-pretty`).
  * *Коміт:* `feat(server): setup fastify app with zod type provider and pino`
  * *Інструменти:* Fastify 5, `fastify-type-provider-zod`, `pino`, `pino-pretty`.
  * *Перевірка:* `pnpm --dir backend run dev` запускає сервер, логи читабельні та інформативні.
* **Крок 2.2:** Підключити `@fastify/swagger` та `@fastify/swagger-ui` за маршрутом `/docs`.
  * *Коміт:* `feat(docs): register fastify openapi swagger and swagger-ui on /docs`
  * *Інструменти:* `@fastify/swagger`, `@fastify/swagger-ui`.
  * *Перевірка:* Браузер відкриває сторінку `http://localhost:3000/docs`.
* **Крок 2.3:** Створити readiness/liveness ендпоінт `GET /health` із перевіркою з'єднання з базою через `SELECT 1`.
  * *Коміт:* `feat(health): add db readiness and liveness check endpoint`
  * *Інструменти:* Fastify route, Drizzle `sql` execute.
  * *Перевірка:* Повертає `200 OK` при живій базі та `503 Service Unavailable` при зупиненому контейнері.
* **Крок 2.4:** Реалізувати безпечну автентифікацію ядра: хешування паролів алгоритмом `Argon2id`, видача токенів через `@fastify/jwt`, ендпоінти `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me`. Реєстрація для вже наявного email повинна повертати `409 Conflict`. Після успішної автентифікації логін має виконувати DML-патерн `ON CONFLICT (email) DO UPDATE` для оновлення `last_login_at`.
  * *Коміт:* `feat(auth): implement argon2id hashing, jwt tokens, and upsert pattern`
  * *Інструменти:* `argon2`, `@fastify/jwt`, Drizzle `onConflictDoUpdate`.
  * *Перевірка:* Пароль у базі збережено як довгий хеш `$argon2id$...`. Повторна реєстрація на той самий email повертає `409 Conflict`, а успішний логін оновлює `last_login_at`.
* **Артефакт на захист Лаби №2:** SQL-запити вставки користувача, демонстрація захешованого пароля в Postgres, DML Upsert-патерн `ON CONFLICT DO UPDATE`.

#### 2. Дмитро Пеньківський — Гілка: `feat/seed-data-stations-crud`
* **Крок 2.1:** Написати масив міст у `backend/src/db/seed.ts` (Київ, Вінниця, Хмельницький, Тернопіль, Львів, Одеса, Дніпро) та пакетну вставку `db.insert(stations).values(...)`.
  * *Коміт:* `feat(seed): add ukrainian railway stations dataset`
  * *Інструменти:* Drizzle batch insert API, TypeScript.
  * *Перевірка:* Запуск `pnpm --dir backend run db:seed` створює 7 реальних станцій без помилок.
* **Крок 2.2:** Додати в сід два ключові маршрути: №705 «Київ — Львів» (проміжні: Вінниця, Хмельницький, Тернопіль) та №105 «Київ — Одеса».
  * *Коміт:* `feat(seed): seed realistic routes and stop sequences`
  * *Інструменти:* Drizzle transactions у сідах.
  * *Перевірка:* Таблиця `stops` заповнена коректними `stop_order` (від 1 до 5).
* **Крок 2.3:** Наповнити шаблони вагонів: Купе (36 місць) та Плацкарт (54 місця) із правильним розподілом полиць (`TOP`/`BOTTOM`).
  * *Коміт:* `feat(seed): seed carriage templates with seat distribution`
  * *Інструменти:* Drizzle batch insert.
  * *Перевірка:* Згенеровано 90 записів у `seat_templates`.
* **Крок 2.4:** Реалізувати ендпоінти: `GET /api/stations` (довідник міст) та `POST /api/stations` (додавання станції з перевіркою дублікатів).
  * *Коміт:* `feat(stations): implement stations read and create crud endpoints`
  * *Інструменти:* Fastify controller, Zod schema validation.
  * *Перевірка:* Успішний виклик роутів через інтерактивний Swagger UI.
* **Крок 2.5:** Розширити сід: створити 2 потяги (№705, №105), фізичні вагони (`carriages`) для кожного потяга (Купе та Плацкарт, прив'язані до `seat_templates`) та рейси `trips` на найближчі 30 днів (`departure_time` у `TIMESTAMPTZ`, `base_price` у копійках, цілим числом).
  * *Коміт:* `feat(seed): seed trains, physical carriages and 30 days of trips`
  * *Інструменти:* Drizzle batch insert, `ON CONFLICT DO NOTHING` для повторного запуску сіду.
  * *Перевірка:* `SELECT COUNT(*) FROM trips` > 0; повторний `pnpm --dir backend run db:seed` не створює дублікатів; запит Лаби №2 `UPDATE trips SET base_price = ...` змінює реальні рядки.
* **Крок 2.6:** Створити `backend/src/plugins/errors.ts` та класи доменних помилок (`NotFoundError`, `ConflictError`, `ForbiddenError`, `BusinessRuleError`). Підключити `app.setErrorHandler`, що мапить їх на 404 / 409 / 403 / 400, помилки валідації Zod на 400 і коди Postgres (`23505` $\to$ 409, `23503` $\to$ 409) в єдиний формат `{ message, code }`.
  * *Коміт:* `feat(errors): add central error handler with domain error classes`
  * *Інструменти:* Fastify `setErrorHandler`, Zod, Postgres error codes.
  * *Перевірка:* Дублікат станції повертає 409 з єдиним JSON-форматом; невалідний UUID повертає 400; у Swagger видно схему помилки.
  * *Артефакт:* Реалістичний набір даних для всіх наступних фаз та єдиний формат помилок API.
* **Артефакт на захист Лаби №2:** Скрипт масового сідування `pnpm --dir backend run db:seed`, пакетна вставка (Batch Insert), базовий CRUD станцій.

#### 3. Мохаммад Хашим — Гілка: `feat/passengers-dml-lab2`
* **Крок 2.1:** Створити Zod-схеми для додавання попутника (`first_name`, `last_name`, `document_id`) у `backend/src/modules/passengers/passengers.schemas.ts`.
  * *Коміт:* `feat(passengers): declare zod schemas for passenger input validation`
  * *Інструменти:* Zod schema definitions (`min(2)`, `max(50)`).
  * *Перевірка:* Запит з коротким ім'ям (< 2 символів) повертає помилку 400 з детальним описом валідації.
* **Крок 2.2:** Реалізувати CRUD-роути: `GET /api/passengers` (список попутників поточного юзера) та `POST /api/passengers`.
  * *Коміт:* `feat(passengers): implement passenger list retrieval and creation`
  * *Інструменти:* Fastify route handlers, Drizzle `select().where()`.
  * *Перевірка:* Юзер бачить тільки тих попутників, яких він створив особисто (фільтрація за `user_id`).
* **Крок 2.3:** Реалізувати роут видалення попутника `DELETE /api/passengers/:id`.
  * *Коміт:* `feat(passengers): add delete passenger endpoint by id`
  * *Інструменти:* Drizzle `delete()`.
  * *Перевірка:* Повертає `204 No Content`, запис коректно видаляється з БД.
* **Крок 2.4:** Скласти офіційний SQL-скрипт кафедри `docs/lab2_dml_operations.sql`:
  * Пакетна вставка пасажирів через `INSERT INTO passengers ... VALUES (...), (...)`.
  * Вибірки з предикатами `LIKE '%Київ%'`, `IN ('COUPE', 'PLATZKART')`, `BETWEEN '2026-10-01' AND '2026-10-31'`.
  * Каскадне оновлення цін поїздок: `UPDATE trips SET base_price = base_price * 1.1 WHERE ...`.
  * *Коміт:* `docs(lab2): create dml operations script covering batch and conditional queries`
  * *Інструменти:* Чистий SQL у DBeaver.
  * *Перевірка:* Скрипт виконується в DBeaver без жодної помилки.
* **Крок 2.5:** Створити сервіс аудиту `logAction(action, userId, metadata)`, що пише в `system_logs`, і підключити його до реєстрації, логіну та створення/видалення попутника.
  * *Коміт:* `feat(audit): add audit log service writing to system_logs`
  * *Інструменти:* Drizzle insert, `jsonb` для `metadata`.
  * *Перевірка:* Після реєстрації та логіну в `system_logs` з'являються рядки з правильним `user_id` та `created_at`.
* **Крок 2.6:** Додати в сід тестових користувачів: адміністратор, провідник та звичайний пасажир (паролі хешуються Argon2id, ідемпотентна вставка).
  * *Коміт:* `feat(seed): seed admin, attendant and passenger accounts`
  * *Інструменти:* Drizzle batch insert, `argon2`.
  * *Перевірка:* Логін кожного з трьох акаунтів повертає JWT; потрібне поле `role` у `users` (див. примітку нижче).
* **Артефакт на захист Лаби №2:** Канонічний DML-файл кафедри з усіма фільтрами (`LIKE`, `IN`, `BETWEEN`), контролер попутників.

---

### Фаза 3. Пошуковий рушій, розклад та Лабораторна №3 (Тижні 5–6: 19 жов – 01 лист)

* **Проблема, яку вирішуємо:** Пасажир не може знайти рейс між двома проміжними станціями або отримує поїзди зворотного напрямку; відсутність розрахунку часу стоянки та динамічної ціни.
* **Спільний результат:** Працюючий пошук поїздів з фільтрацією напрямку руху, розклад проміжних зупинок рейсу, аналітичні віконні функції.

#### 1. Владислав Іванников (`@gun-flud`) — Гілка: `feat/trips-search-pricing`
* **Крок 3.1:** Створити Zod-контракт параметрів пошуку: `fromStationId` (UUID), `toStationId` (UUID), `date` (YYYY-MM-DD).
  * *Коміт:* `feat(trips): define trip search query parameters schema`
  * *Інструменти:* Zod query schema.
  * *Перевірка:* Валідатор відхиляє запити з кривою датою або невалідним UUID.
* **Крок 3.2:** Написати SQL-запит пошуку рейсів із двома `INNER JOIN` до проміжної таблиці `stops` (`s_from` та `s_to`).
  * *Коміт:* `feat(trips): compose sql query joining stops table for route matching`
  * *Інструменти:* Drizzle Query Builder / SQL expressions.
  * *Перевірка:* Запит знаходить поїзди, які зупиняються на обох вибраних станціях.
* **Крок 3.3:** Додати строгу бізнес-умову вектора руху:
  $$\text{s\_from.stop\_order} < \text{s\_to.stop\_order}$$
  * *Коміт:* `feat(trips): enforce trip direction constraint via stop order comparison`
  * *Інструменти:* SQL `WHERE` clause.
  * *Перевірка:* Пошук поїзда «Вінниця $\to$ Львів» ніколи не повертає поїзди зворотного рейсу «Львів $\to$ Київ».
* **Крок 3.4:** Впровадити в SQL динамічний розрахунок вартості сегмента та CTE-агрегацію доступних класів:
  $$\text{Price} = \text{base\_price} \times \text{multiplier} \times (\text{order}_{\text{to}} - \text{order}_{\text{from}})$$
  * *Коміт:* `feat(trips): calculate dynamic price based on distance and carriage type`
  * *Інструменти:* PostgreSQL Common Table Expressions (CTE).
  * *Перевірка:* Ендпоінт повертає JSON із цінами для Купе та Плацкарту, пропорційними до пройденої відстані.
* **Артефакт на захист Лаби №3:** Багаторівневий SQL-запит пошуку з двома `JOIN`, фільтрацією порядку станцій та CTE.

#### 2. Дмитро Пеньківський — Гілка: `feat/trip-timetable-stops`
* **Крок 3.1:** Створити роут `GET /api/trips/:tripId/schedule` з валідацією параметра `tripId`.
  * *Коміт:* `feat(schedule): add route definition for trip schedule endpoint`
  * *Інструменти:* Fastify routing, Zod params.
  * *Перевірка:* Роут повертає HTTP 200 на валідний UUID рейсу.
* **Крок 3.2:** Написати SQL-запит вибірки всіх зупинок маршруту з сортуванням: `ORDER BY stops.stop_order ASC`.
  * *Коміт:* `feat(schedule): write query fetching ordered route stops with timestamps`
  * *Інструменти:* Drizzle `orderBy`.
  * *Перевірка:* Станції повертаються строго у хронологічному порядку слідування поїзда.
* **Крок 3.3:** Додати інтервальний розрахунок стоянки поїзда на платформі засобами SQL:
  $$\text{stop\_duration} = \text{departure\_time} - \text{arrival\_time}$$
  * *Коміт:* `feat(schedule): calculate stop duration using sql timestamp intervals`
  * *Інструменти:* PostgreSQL Interval Arithmetic (`EXTRACT(EPOCH FROM ...)`).
  * *Перевірка:* У відповіді присутнє точне поле тривалості стоянки у хвилинах.
* **Крок 3.4:** Сформувати чистий DTO графіку для пасажира (назва станції, прибуття, стоянка, відправлення).
  * *Коміт:* `feat(schedule): format timetable response dto for passenger view`
  * *Інструменти:* TypeScript interface / Zod response contract.
  * *Перевірка:* Розклад рейсу коректно рендериться у Swagger UI.
* **Крок 3.5:** Написати інтеграційні тести `test/integration/stations.routes.test.ts` та `schedule.routes.test.ts` через `app.inject()`: список станцій, створення, дублікат (409), невалідний UUID (400), неіснуючий рейс (404), порядок зупинок у розкладі за `stop_order`.
  * *Коміт:* `test(schedule): add integration tests for stations and schedule endpoints`
  * *Інструменти:* Vitest, `app.inject()`.
  * *Перевірка:* `pnpm --dir backend test` зелений; кожен ендпоінт має мінімум один happy-path та один негативний тест.
* **Артефакт на захист Лаби №3:** SQL-запит розкладу з сортуванням `ORDER BY` та часовою інтервальною арифметикою.

#### 3. Мохаммад Хашим — Гілка: `feat/lab3-complex-sql-analytics`
* **Крок 3.1:** Написати аналітичний запит із віконною функцією ранжування тарифів:
  ```sql
  SELECT trip_id, route_id, base_price,
         DENSE_RANK() OVER (PARTITION BY route_id ORDER BY base_price ASC) AS price_rank
  FROM trips;
  ```
  * *Коміт:* `feat(analytics): add dense_rank window function for trip pricing analysis`
  * *Інструменти:* PostgreSQL Window Functions (`DENSE_RANK`, `PARTITION BY`).
  * *Перевірка:* Запуск у DBeaver показує ранжування цін у межах кожного маршруту.
* **Крок 3.2:** Написати запит групування з фільтром `HAVING` для виявлення перевантажених рейсів:
  ```sql
  SELECT trip_id, COUNT(ticket_id) AS total_sold
  FROM ticket_segments
  WHERE status = 'PAID'
  GROUP BY trip_id
  HAVING COUNT(ticket_id) > 5;
  ```
  * *Коміт:* `feat(analytics): compose having aggregation query for overloaded trips`
  * *Інструменти:* `GROUP BY`, `HAVING COUNT()`.
  * *Перевірка:* Відсікання груп, що не відповідають критерію заповненості.
* **Крок 3.3:** Скласти великий SQL-запит з об'єднанням 5 таблиць (`trips`, `routes`, `stops`, `stations`, `trains`).
  * *Коміт:* `feat(analytics): write 5-table join query for master trip overview`
  * *Інструменти:* 5-table `INNER JOIN` у SQL.
  * *Перевірка:* Дані узгоджені, всі зовнішні ключі сходяться без втрати рядків.
* **Крок 3.4:** Зберегти розроблені запити у файл `backend/src/db/queries/lab3_analytics.sql` з поясненнями для комісії.
  * *Коміт:* `docs(lab3): document analytical queries with comments for lab defense`
  * *Інструменти:* SQL-файл із документацією.
  * *Перевірка:* Файл готовий до здачі Лаби №3.
* **Артефакт на захист Лаби №3:** Аналітичний файл з віконними функціями `DENSE_RANK`, агрегаціями `HAVING` та з'єднанням 5 таблиць.

---

### Фаза 4. Booking Engine, B-Tree індекси та Лабораторна №4 (Тижні 7–8: 02 лист – 15 лист)

* **Проблема, яку вирішуємо:** Овербукінг (подвійний продаж одного місця на тій самій ділянці рейсу) та повільна перевірка зайнятості крісел при зростанні бази.
* **Спільний результат:** 100% покрите тестами чисто-функціональне ядро бронювання, 10-хвилинне утримання (HELD), створені B-Tree, часткові, композитні та функціональні індекси.

#### 1. Владислав Іванников (`@gun-flud`) — Гілка: `feat/pure-booking-domain-seats`
* **Крок 4.1:** Створити файл чистого доменного ядра `backend/src/modules/booking/booking.domain.ts` та реалізувати чисту функцію перевірки накладання інтервалів:
  $$\text{doIntervalsOverlap}(A, B) = \max(A_{\text{from}}, B_{\text{from}}) < \min(A_{\text{to}}, B_{\text{to}})$$
  * *Коміт:* `feat(booking): implement pure interval overlap algorithm in domain layer`
  * *Інструменти:* Pure TypeScript (Functional Core).
  * *Перевірка:* Функція детермінована, не має жодних зовнішніх залежностей чи звернень до бази.
* **Крок 4.2:** Покрити алгоритм повним набором юніт-тестів Vitest (`backend/src/modules/booking/booking.domain.test.ts`):
  * Суміжні станції $[1, 3]$ та $[3, 5]$ $\to$ `false` (дозволено).
  * Частковий перетин $[1, 4]$ та $[2, 5]$ $\to$ `true` (конфлікт).
  * Повне вкладення $[1, 8]$ та $[3, 5]$ $\to$ `true` (конфлікт).
  * Невалідний інтервал ($from \ge to$) $\to$ викидання бізнес-помилки.
  * *Коміт:* `test(booking): cover interval overlap algorithm with comprehensive vitest suite`
  * *Інструменти:* Vitest runner.
  * *Перевірка:* `pnpm --dir backend test` проходить за < 150 мс, 100% зелених тестів.
* **Крок 4.3:** Реалізувати ендпоінт карти зайнятості місць вагона `GET /api/trips/:tripId/seats?fromStationId=...&toStationId=...`.
  * *Коміт:* `feat(booking): implement carriage seat occupancy map endpoint`
  * *Інструменти:* Fastify controller, Drizzle queries.
  * *Перевірка:* Місце, зайняте на іншій ділянці маршруту, для поточного діапазону станцій відображається вільним.
* **Крок 4.4:** Створити композитний 4-колонковий B-Tree індекс ядра та функціональний індекс електронної пошти:
  ```sql
  CREATE INDEX idx_tickets_conflict ON ticket_segments(trip_id, carriage_id, seat_id, status);
  CREATE INDEX idx_users_email_lower ON users(LOWER(email));
  ```
  Провести аналіз селективності через каталог `pg_stats`.
  * *Коміт:* `feat(db): create composite and functional b-tree indexes for seat conflicts`
  * *Інструменти:* Drizzle schema indexes, `pg_stats`.
  * *Перевірка:* Інформація про індекси відображається у системному каталозі Postgres.
* **Артефакт на захист Лаби №4:** Композитний B-Tree індекс ядра на 4 колонки, функціональний індекс `LOWER(email)`, юніт-тести ядра на Vitest.

#### 2. Дмитро Пеньківський — Гілка: `feat/ticket-hold-reservation`
* **Крок 4.1:** Створити Zod-схему резервування місця `holdSeatSchema` (ідентифікатори рейсу, вагона, полиці, станції посадки/висадки).
  * *Коміт:* `feat(booking): define zod schema for ticket hold reservation request`
  * *Інструменти:* Zod schema validation.
  * *Перевірка:* Валідатор видає помилку, якщо `fromStopOrder >= toStopOrder`.
* **Крок 4.2:** Впровадити обмеження: 1 авторизований користувач не може мати більше 1 активного незавершеного холду одночасно.
  * *Коміт:* `feat(booking): validate single active hold limitation per authorized user`
  * *Інструменти:* Fastify service logic.
  * *Перевірка:* Спроба зробити другий холд під час дії першого повертає `409 Conflict`.
* **Крок 4.3:** Реалізувати ендпоінт 10-хвилинного резерву: `POST /api/tickets/hold`. Перевірку кількості активних холдів, перевірку накладання інтервалу та вставку холду виконувати в одній транзакції. Конфліктні холди мають блокуватися та відхилятися на рівні бази даних, а `hold_expires_at` фіксувати як `NOW() + INTERVAL '10 minutes'`.
  * *Коміт:* `feat(booking): implement 10-minute hold reservation endpoint`
  * *Інструменти:* Fastify controller, Drizzle insert.
  * *Перевірка:* У базі з'являється рядок зі статусом `HELD` та часом життя рівно 10 хвилин.
* **Крок 4.4:** Створити B-Tree індекси на зовнішні ключі логістичних таблиць (`stops.route_id`, `carriages.train_id`), щоб прискорити пошук рядків, які посилаються на батьківські записи, під час перевірок зовнішніх ключів і каскадних операцій. Вони не запобігають і не усувають блокування таблиць. Також створити функціональний індекс пошуку станцій без урахування регістру:
  ```sql
  CREATE INDEX idx_stations_name_lower ON stations(LOWER(name));
  ```
  * *Коміт:* `feat(db): index foreign keys across logistics entities and add case-insensitive station search index`
  * *Інструменти:* Drizzle schema index creation, DBeaver `\d stops`.
  * *Перевірка:* Перевірка наявності індексів через DBeaver.
* **Артефакт на захист Лаби №4:** Ендпоінт резервування місця, B-Tree індексація зовнішніх ключів для прискорення перевірок зовнішніх ключів і каскадних операцій, функціональний індекс `LOWER(stations.name)`.

#### 3. Мохаммад Хашим — Гілка: `feat/lab4-b-tree-indexes`
* **Крок 4.1:** Створити частковий індекс (Partial Index), що індексує виключно активні холди:
  ```sql
  CREATE INDEX idx_tickets_active_holds 
  ON ticket_segments(hold_expires_at) 
  WHERE status = 'HELD';
  ```
  * *Коміт:* `feat(db): create partial b-tree index for active hold reservations`
  * *Інструменти:* Drizzle `index().where(sql`status = 'HELD'`)`.
  * *Перевірка:* Індекс займає в рази менше місця, оскільки не включає рядки `PAID` та `CANCELLED`.
* **Крок 4.2:** Створити композитний індекс для аудиту фінансових операцій:
  ```sql
  CREATE INDEX idx_refunds_created_status ON refunds(created_at DESC, status);
  ```
  * *Коміт:* `feat(db): add composite index for financial refund audit reporting`
  * *Інструменти:* Drizzle schema definition.
  * *Перевірка:* Оптимізація вибірки останніх повернень коштів.
* **Крок 4.3:** Написати SQL-скрипт моніторингу лічильників використання індексів:
  ```sql
  SELECT relname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch 
  FROM pg_stat_user_indexes 
  WHERE schemaname = 'public';
  ```
  * *Коміт:* `docs(lab4): create index usage verification queries in system statistics`
  * *Інструменти:* PostgreSQL системний каталог `pg_stat_user_indexes`.
  * *Перевірка:* Значення `idx_scan` збільшується після кожного пошуку в системі.
* **Крок 4.4:** Оформити звіт Лабораторної №4 `docs/lab4_indexes_report.md` із поясненням різниці між B-Tree, частковими, функціональними та композитними індексами.
  * *Коміт:* `docs(lab4): complete lab 4 documentation on b-tree index design`
  * *Інструменти:* Markdown звіт.
  * *Перевірка:* Звіт оформлено та готовий до захисту.
* **Артефакт на захист Лаби №4:** Частковий індекс `WHERE status = 'HELD'`, аудит-індекс повернень, скрипт моніторингу `pg_stat_user_indexes`.

---

### Фаза 5. ACID-транзакції, блокування, зліпки та Лабораторна №5 (Тижні 9–10: 16 лист – 29 лист)

* **Проблема, яку вирішуємо:** Стан гонитви (Race Condition), коли двоє людей одночасно купують останній квиток на одне місце; історичне викривлення даних квитка при зміні тарифів або прізвища знайомого; повернення квитка в останню мить перед відправленням.
* **Спільний результат:** Checkout-транзакція з песимістичним блокуванням рядка `FOR UPDATE`, патерн Snapshot, робоче місце провідника (`boarded_at`), модуль повернень із правилом 2 годин, скрипт аномалій рівнів ізоляції.

#### 1. Владислав Іванников (`@gun-flud`) — Гілка: `feat/transactions-pessimistic-lock`
* **Крок 5.1:** Відкрити транзакцію оплати квитка через Drizzle: `await db.transaction(async (tx) => ...)`.
  * *Коміт:* `feat(checkout): open strict acid transaction wrapper for ticket payment`
  * *Інструменти:* Drizzle ORM transactions.
  * *Перевірка:* Помилка всередині транзакції призводить до повного відкату (Rollback).
* **Крок 5.2:** Застосувати песимістичне блокування всіх потенційно конфліктних рядків для захисту від паралельних покупок:
  ```sql
  SELECT * FROM ticket_segments 
  WHERE trip_id = :trip_id
    AND carriage_id = :carriage_id
    AND seat_id = :seat_id
    AND status = 'HELD'
    AND from_stop_order < :to_stop_order
    AND to_stop_order > :from_stop_order
  FOR UPDATE;
  ```
  Усередині тієї самої транзакції повторно перевірити накладання інтервалів і переконатися, що заблокований рядок належить поточному `ticket_id`; конфлікт з іншим холдом має завершуватися `409 Conflict`. Тест конкурентності повинен використовувати два різні холди на те саме місце з перекривними сегментами.
  * *Коміт:* `feat(checkout): apply pessimistic row locking with select for update`
  * *Інструменти:* Drizzle `.for('update')`.
  * *Перевірка:* Транзакція в одній сесії DBeaver блокує паралельне редагування рядка іншою сесією.
* **Крок 5.3:** Реалізувати скрипт штучного взаємного блокування (Deadlock) у двох транзакціях з аналізом помилки `deadlock detected`.
  * *Коміт:* `feat(checkout): add artificial deadlock simulation script for demonstration`
  * *Інструменти:* DBeaver (2 паралельні сесії з вимкненим автокомітом).
  * *Перевірка:* Postgres фіксує дедлок та автоматично обриває одну з транзакцій із кодом `40P01`.
* **Крок 5.4:** Написати стрес-тест конкурентності на Vitest: запуск двох паралельних `Promise.all()` на покупку того самого квитка. Один отримує успіх, другий — безпечну відмову `409 Conflict`.
  * *Коміт:* `test(concurrency): add race condition concurrency test for ticket checkout`
  * *Інструменти:* Vitest, асинхронні проміси `Promise.all`.
  * *Перевірка:* Нуль випадків овербукінгу під стресовим паралельним навантаженням.
* **Артефакт на захист Лаби №5:** Песимістичне блокування рядків `FOR UPDATE`, скрипт дедлоку, Vitest стрес-тест паралелізму.

#### 2. Дмитро Пеньківський — Гілка: `feat/snapshot-pattern-conductor-verify`
* **Крок 5.1:** Реалізувати **Snapshot Pattern** у момент успішної оплати: скопіювати з релейшнів у рядок квитка незмінні дані (`passenger_name`, `departure_station_name`, `arrival_station_name`, `departure_time`, `arrival_time`, `final_price`).
  * *Коміт:* `feat(tickets): implement snapshot pattern saving immutable trip details`
  * *Інструменти:* Drizzle transaction update.
  * *Перевірка:* Подальша зміна профілю пасажира чи тарифу маршруту ніяк не впливає на вже куплений квиток.
* **Крок 5.2:** Змінити статус квитка на `PAID` та зафіксувати точний таймштамп `paid_at = NOW()`.
  * *Коміт:* `feat(tickets): finalize ticket status as paid with payment timestamp`
  * *Інструменти:* Drizzle ORM.
  * *Перевірка:* Квиток успішно переходить у статус оплаченого.
* **Крок 5.3:** Реалізувати ендпоінт для провідника вагонів: `POST /api/attendant/verify-ticket` із валідацією токена персоналу.
  * *Коміт:* `feat(attendant): create ticket verification route for train attendants`
  * *Інструменти:* Fastify route, JWT verification hook.
  * *Перевірка:* Валідація відхиляє неоплачені або скасовані квитки.
* **Крок 5.4:** Реалізувати посадку пасажира у вагон: фіксація `boarded_at = NOW()` із захистом від повторного використання.
  * *Коміт:* `feat(attendant): record passenger boarding timestamp with duplicate check`
  * *Інструменти:* Drizzle update with duplicate check.
  * *Перевірка:* Спроба повторного сканування повертає попередження про вже здійснену посадку.
* **Крок 5.5:** Реалізувати `GET /api/tickets` (мої квитки) з фільтром за статусом. Для `PAID` повертати дані зі зліпка (Snapshot), а не з поточних довідників.
  * *Коміт:* `feat(tickets): add my tickets endpoint reading from snapshot fields`
  * *Інструменти:* Fastify controller, Drizzle `select().where()`, Zod query.
  * *Перевірка:* Користувач бачить лише свої квитки; після перейменування станції старий квиток не змінюється.
* **Крок 5.6:** Реалізувати `DELETE /api/tickets/:ticketId/hold`: користувач скасовує власний холд, статус `HELD` $\to$ `CANCELLED`, місце звільняється миттєво.
  * *Коміт:* `feat(booking): allow user to release own active hold`
  * *Інструменти:* Drizzle update з умовою `status = 'HELD'` та `user_id`.
  * *Перевірка:* Чужий холд повертає 403, оплачений квиток повертає 409, після звільнення місце знову доступне в карті місць.
  * *Артефакт:* Повний життєвий цикл квитка з боку пасажира: холд, перегляд, скасування.
* **Артефакт на захист Лаби №5:** Snapshot Pattern (незмінний зліпок фінансових даних), робоче місце провідника з атомарною фіксацією посадки.

#### 3. Мохаммад Хашим — Гілка: `feat/refunds-isolation-levels`
* **Крок 5.1:** Реалізувати ендпоінт добровільного повернення квитка: `POST /api/tickets/:ticketId/refund`.
  * *Коміт:* `feat(refunds): create ticket refund endpoint route`
  * *Інструменти:* Fastify controller.
  * *Перевірка:* Ендпоінт доступний авторизованому власнику квитка.
* **Крок 5.2:** Впровадити транзакційну перевірку правила 2 годин:
  $$\text{ticket.departure\_time} - \text{NOW}() \ge 2\text{ hours}$$
  Якщо до відправлення рейсу залишилося менше 2 годин — операція скасовується з помилкою `400 Bad Request`.
  * *Коміт:* `feat(refunds): enforce 2-hour departure threshold validation for cancellation`
  * *Інструменти:* Drizzle transaction validation.
  * *Перевірка:* Квиток на рейс, який відправляється через 1 годину, повернути неможливо.
* **Крок 5.3:** При успішному поверненні змінити статус на `CANCELLED` та атомарно вставити запис у таблицю `refunds`.
  * *Коміт:* `feat(refunds): set ticket status to cancelled and insert refund audit log`
  * *Інструменти:* Drizzle transaction (`update` ticket + `insert` refund).
  * *Перевірка:* Фінансовий запит повернення збережено в аудиторській таблиці.
* **Крок 5.4:** Скласти демонстраційний SQL-скрипт рівнів ізоляції транзакцій `docs/lab5_isolation_levels.sql`: симуляція брудного читання, неповторюваного читання та фантомів у `Read Committed` проти `Repeatable Read`.
  * *Коміт:* `docs(lab5): add isolation level concurrency anomaly demonstration scripts`
  * *Інструменти:* SQL скрипти ізоляцій у DBeaver.
  * *Перевірка:* Наочна демонстрація різниці поведінки ізоляцій у двох паралельних вкладках DBeaver.
* **Крок 5.5:** Написати інтеграційні тести повернення: успіх за > 2 години, `400` за < 2 години, `403` для чужого квитка, повторне повернення (`409`), а також запис у `system_logs` при кожному поверненні.
  * *Коміт:* `test(refunds): add integration tests for refund rules and audit trail`
  * *Інструменти:* Vitest, `app.inject()`, тестова БД.
  * *Перевірка:* Усі сценарії зелені; після успішного повернення є рядок у `refunds` і в `system_logs`.
  * *Артефакт:* Перевірене ядро повернень (чиста функція плюс інтеграційні тести) та аудиторський слід.
* **Артефакт на захист Лаби №5:** Модуль повернень із перевіркою правила 2 годин, SQL-скрипт демонстрації аномалій рівнів ізоляції.

---

### Фаза 6. Воркери (`SKIP LOCKED`), оптимізація та Лабораторна №6 (Тижні 11–12: 30 лист – 13 груд)

* **Проблема, яку вирішуємо:** «Завислі» неоплачені броні блокують місця; фонові скрипти очищення блокують усю таблицю квитків; падіння продуктивності бази при зростанні обсягу даних до десятків тисяч рядків.
* **Спільний результат:** Конкурентний фоновий воркер очищення на патерні `SKIP LOCKED`, диспетчерські затримки поїздів, згенерований стрес-датасет на 10k+ записів, оптимізація запитів за допомогою `EXPLAIN (ANALYZE, BUFFERS)` та тюнінг пам'яті.

#### 1. Владислав Іванников (`@gun-flud`) — Гілка: `feat/cleanup-worker-delays`
* **Крок 6.1:** Створити автономний інтервальний процес `backend/src/modules/workers/cleanup.worker.ts`, що спрацьовує раз на 60 секунд.
  * *Коміт:* `feat(worker): setup interval background runner for expired holds`
  * *Інструменти:* Node.js timer loop, structured Pino logger.
  * *Перевірка:* Воркер циклічно стартує та пише структуровані логи.
* **Крок 6.2:** Написати неблокуюче очищення прострочених сегментів за допомогою `FOR UPDATE SKIP LOCKED`:
  ```sql
  WITH expired AS (
    SELECT segment_id
    FROM ticket_segments
    WHERE status = 'HELD' AND hold_expires_at < NOW()
    FOR UPDATE SKIP LOCKED
  )
  UPDATE ticket_segments AS ts
  SET status = 'EXPIRED'
  FROM expired
  WHERE ts.segment_id = expired.segment_id
    AND ts.status = 'HELD'
    AND ts.hold_expires_at < NOW();
  ```
  * *Коміт:* `feat(worker): implement skip locked pattern for non-blocking hold expiration`
  * *Інструменти:* Drizzle raw SQL transaction / subquery.
  * *Перевірка:* Воркер очищає прострочені броні, взагалі не блокуючи клієнтів, які в цей момент купують квитки.
* **Крок 6.3:** Створити покриваючий індекс з `INCLUDE` та продемонструвати перехід від `Index Scan` до `Index Only Scan`:
  ```sql
  CREATE INDEX idx_trips_covering ON trips (route_id, departure_time) INCLUDE (base_price, status);
  ```
  Профілювати в DBeaver та зафіксувати `Heap Fetches: 0` лише як спостережуваний результат для конкретного плану після відповідного обслуговування таблиці. `INCLUDE` не гарантує нульових звернень до heap: якщо біти visibility map не встановлені, PostgreSQL все одно може читати heap-сторінки.
  * *Коміт:* `perf(db): create covering index with include for pure index only scan`
  * *Інструменти:* PostgreSQL Covering Index (`INCLUDE`), DBeaver EXPLAIN GUI.
  * *Перевірка:* У плані `EXPLAIN` відображається `Index Only Scan`; нульові `Heap Fetches` заявляються лише після підтвердження в конкретному плані та виконання потрібного обслуговування (наприклад, `VACUUM`).
* **Крок 6.4:** Продемонструвати тюнінг пам'яті сортування (`work_mem`): усунути скидання сортування на диск `Sort Method: external merge Disk` $\to$ `quicksort Memory` на стрес-масиві. Проаналізувати ноду блокування `LockRows` у плані виконання воркера.
  * *Коміт:* `perf(db): optimize sort operations via work_mem and profile lockrows node`
  * *Інструменти:* PostgreSQL `SET work_mem`, EXPLAIN execution graph.
  * *Перевірка:* Сортування виконується повністю в оперативній пам'яті за лічені мілісекунди.
* **Артефакт на захист Лаби №6:** Воркер `SKIP LOCKED`, покриваючий індекс з `INCLUDE` (`Index Only Scan`; `Heap Fetches: 0` — лише підтверджений результат конкретного плану після обслуговування), оптимізація `work_mem` (Disk $\to$ Memory), аналіз ноди `LockRows`.

#### 2. Дмитро Пеньківський — Гілка: `feat/stress-data-generator`
* **Крок 6.1:** Створити скрипт генератора навантажувальних даних `backend/src/db/generate_stress_data.ts`.
  * *Коміт:* `feat(stress): bootstrap stress dataset generator script`
  * *Інструменти:* `tsx`, Drizzle Client, `crypto`.
  * *Перевірка:* Скрипт запускається через `pnpm --dir backend exec tsx src/db/generate_stress_data.ts`.
* **Крок 6.2:** Згенерувати 5 000+ випадкових пасажирів пакетними порціями по 500 записів.
  * *Коміт:* `feat(stress): generate 5000 realistic passengers using batch chunks`
  * *Інструменти:* Drizzle Batch Insert.
  * *Перевірка:* Таблиця `passengers` заповнюється за лічені секунди.
* **Крок 6.3:** Згенерувати 10 000+ куплених, зарезервованих та повернутих квитків на різні напрямки.
  * *Коміт:* `feat(stress): populate database with 10000+ diverse ticket records`
  * *Інструменти:* TypeScript loops, Batch chunks.
  * *Перевірка:* Кількість рядків у `ticket_segments` перевищує 10 000.
* **Крок 6.4:** Зафіксувати наочний бенчмарк для викладача та проаналізувати зміну алгоритмів з'єднання оптимізатора (`Nested Loop` $\to$ `Hash Join` при масштабуванні з 10 до 10 000 рядків):
  * Пошук квитка без індексу: `Seq Scan` (~45–60 мс).
  * Пошук квитка з B-Tree індексом: `Index Scan` (~1.2 мс). Прискорення у 40+ разів.
  * *Коміт:* `docs(lab6): document performance benchmark comparing seq scan vs index scan and join strategy transitions`
  * *Інструменти:* DBeaver `EXPLAIN (ANALYZE, BUFFERS)`.
  * *Перевірка:* Заміри та графіки планів зафіксовано в Markdown-звіті.
* **Артефакт на захист Лаби №6:** Генератор стрес-датасету (10 000+ квитків), демонстраційний бенчмарк різниці `Seq Scan` проти `Index Scan`, аналіз трансформації `Nested Loop` $\to$ `Hash Join`.

#### 3. Мохаммад Хашим — Гілка: `feat/lab6-explain-analyze-reports`
* **Крок 6.1:** Провести глибоке профілювання аналітичних вибірок через `EXPLAIN (ANALYZE, BUFFERS)` на стрес-базі:
  ```sql
  EXPLAIN (ANALYZE, BUFFERS)
  SELECT * FROM ticket_segments 
  WHERE trip_id = '...' AND status = 'PAID';
  ```
  * *Коміт:* `docs(lab6): profile ticket selection queries with explain analyze buffers`
  * *Інструменти:* DBeaver Query Profiler.
  * *Перевірка:* Отримано точні плани виконання з метриками `Cost`, `Actual Time` та `Buffers`.
* **Крок 6.2:** Розрахувати коефіцієнт потрапляння в кеш буферів (Buffer Cache Hit Ratio):
  $$\text{Hit Ratio} = \frac{\text{shared hit}}{\text{shared hit} + \text{shared read}} \times 100\%$$
  Довести, що результат перевищує 98% (база працює з RAM, а не повільним диском).
  * *Коміт:* `docs(lab6): calculate shared buffer cache hit ratio metrics`
  * *Інструменти:* PostgreSQL Buffer Cache статистика.
  * *Перевірка:* Математичний розрахунок внесено до звіту.
* **Крок 6.3:** Реалізувати адміністративні аналітичні маршрути звітності:
  * `GET /api/admin/reports/occupancy` (відсоток заповненості вагонів за рейсами).
  * `GET /api/admin/reports/refunds` (коефіцієнт повернень коштів за напрямками).
  * *Коміт:* `feat(reports): implement admin analytical endpoints for occupancy and refunds`
  * *Інструменти:* Fastify routing, Drizzle aggregation queries.
  * *Перевірка:* Ендпоінти повертають агреговані статистичні звіти у JSON.
* **Крок 6.4:** Скласти підсумковий звіт Лабораторної №6 `docs/lab6_query_optimization.md` із графіками дерев запитів та аналізом Total Cost.
  * *Коміт:* `docs(lab6): assemble comprehensive query optimization report`
  * *Інструменти:* Markdown звіт.
  * *Перевірка:* Фінальний звіт готовий до захисту.
* **Артефакт на захист Лаби №6:** Звіт оптимізації з розрахунком Buffer Cache Hit Ratio, профілювання `EXPLAIN (ANALYZE, BUFFERS)`, аналітичні API-роути.

---

### Фаза 7. CI/CD, публікація контейнера та захист курсового (Тижні 13–14: 14 груд – 25 груд)

* **Проблема, яку вирішуємо:** Труднощі із запуском на комп'ютері екзаменаційної комісії, відсутність автоматизованої перевірки перед злиттям, неструктурований виступ.
* **Спільний результат:** Зелений CI-пайплайн у GitHub Actions, публічний контейнер бекенду в GitHub Container Registry (GHCR), автоматизований E2E сценарій у Postman, `README.md` комерційного рівня, захист курсового на 100 балів.

#### 1. Владислав Іванников (`@gun-flud`) — Гілка: `feat/ghcr-release-pipeline`
* **Крок 7.1:** Налаштувати GitHub Actions CI `.github/workflows/ci.yml` (запуск `tsc --noEmit`, ESLint та прогін юніт-тестів Vitest на кожен відкритий PR).
  * *Коміт:* `ci: add automated lint, typecheck, and vitest testing pipeline`
  * *Інструменти:* GitHub Actions, `pnpm/action-setup`, Node 22 setup.
  * *Перевірка:* Зелений статус CI-чеклистів у кожному PR на GitHub.
* **Крок 7.2:** Написати безпечний 4-етапний `Dockerfile` (Base $\to$ Deps $\to$ Builder $\to$ Runner), що виконує процес під непривілейованим користувачем `USER node`.
  * *Коміт:* `build(docker): implement secure multi-stage non-root container build`
  * *Інструменти:* Docker multi-stage build.
  * *Перевірка:* Вага фінального образу менше 130 МБ.
* **Крок 7.3:** Створити `.github/workflows/docker-publish.yml` для автоматичного білду та пушу контейнера в **GitHub Container Registry (GHCR)**.
  * *Коміт:* `ci: configure automated ghcr container build and package release`
  * *Інструменти:* GHCR, GitHub Token permissions.
  * *Перевірка:* Публічний образ `ghcr.io/.../easyrail-backend:latest` відображається у розділі Packages вашого репозиторію.
* **Артефакт:** Зелений статус CI/CD, безпечний Dockerfile, готовий опублікований пакет у GHCR.

#### 2. Дмитро Пеньківський — Гілка: `test/postman-full-e2e`
* **Крок 7.1:** Створити колекцію в Postman зі змінними середовища `baseUrl` та автооновлюваним `authToken`.
  * *Коміт:* `test(postman): initialize postman e2e collection environment`
  * *Інструменти:* Postman Environments & Collections.
  * *Перевірка:* Змінні автоматично оновлюються між запитами через Scripts.
* **Крок 7.2:** Побудувати наскрізний тестовий сценарій: Реєстрація $\to$ Вхід $\to$ Пошук поїзда «Київ — Львів» $\to$ Холд місця на 10 хвилин.
  * *Коміт:* `test(postman): implement automated flow from registration to seat hold`
  * *Інструменти:* Postman Requests.
  * *Перевірка:* Усі кроки повертають `200 OK` або `201 Created`.
* **Крок 7.3:** Завершити ланцюжок: Оплата квитка (Snapshot) $\to$ Валідація посадки провідником $\to$ Тест добровільного повернення за правилом 2 годин.
  * *Коміт:* `test(postman): complete payment, boarding check, and refund test suite`
  * *Інструменти:* Postman Tests scripts.
  * *Перевірка:* Автотести перевіряють статус-коди та тіло відповідей.
* **Крок 7.4:** Експортувати колекцію у `backend/tests/EasyRail_E2E.postman_collection.json`.
  * *Коміт:* `test(postman): export complete automated e2e collection for grading`
  * *Інструменти:* Postman Export.
  * *Перевірка:* Колекція запускається в 1 клік через Postman Collection Runner.
* **Артефакт:** Повна автоматизована E2E-колекція з автотестами для показу комісії.

#### 3. Мохаммад Хашим — Гілка: `docs/final-readme-presentation`
* **Крок 7.1:** Оформити головний `README.md` із бейджами, архітектурними схемами та інструкцією запуску проєкту однією командою:
  ```bash
  docker compose up --build
  ```
  * *Коміт:* `docs(readme): describe project mission and one-line docker compose launch`
  * *Інструменти:* Markdown, GitHub Badges.
  * *Перевірка:* Чиста інструкція дозволяє запустити систему на будь-якому ноутбуці.
* **Крок 7.2:** Скласти архітектурні висновки: чому обрано Drizzle замість Prisma, чому відхилено брокери (ADR 003), чому відкладено PgBouncer (ADR 002).
  * *Коміт:* `docs(readme): articulate senior architectural decisions and trade-offs`
  * *Інструменти:* ADR summaries.
  * *Перевірка:* Аргументи звучать переконливо для екзаменаційної комісії.
* **Крок 7.3:** Вставити в документацію згенеровану ER-діаграму та пряме посилання на Swagger UI (`http://localhost:3000/docs`).
  * *Коміт:* `docs(readme): embed entity relationship diagram and interactive swagger link`
  * *Інструменти:* Mermaid / SVG діаграми.
  * *Перевірка:* Документація виглядає на рівні провідних Open-Source проєктів.
* **Крок 7.4:** Скласти регламент фінального захисту на 10 хвилин: чіткі тези виступу для Владислава (архітектура ядра, блокування, CI/CD), Дмитра (логістика, сідування, E2E) та Хашима (база даних, аналітика, оптимізація).
  * *Коміт:* `docs(presentation): prepare structured defense speech outline for all members`
  * *Інструменти:* Презентаційні тези.
  * *Перевірка:* Кожен учасник чітко знає свій таймінг та що саме він відкриває на екрані.
* **Артефакт:** Професійний `README.md`, регламент виступу, готовність команди до захисту.

---

## 5. Шпаргалка індивідуального захисту кожної лаби

| Лабораторна | Що відкриває і пояснює Владислав (`@gun-flud`) | Що відкриває і пояснює Мохаммад Хашим | Що відкриває і пояснює Дмитро Пеньківський |
| :--- | :--- | :--- | :--- |
| **Лаба 1: DDL & Схема** | DBeaver: таблиці ядра (`users`, `trips`, `ticket_segments`), системний констрейнт `CHECK (from_stop_order < to_stop_order)`, роботу `gen_random_uuid()`. | DBeaver: схему повернень `refunds`, зв'язки попутників `passengers` з правилом `ON DELETE CASCADE`, таблицю `system_logs`. | DBeaver: логістичну мережу, проміжну таблицю $M:N$ `stops` із композитною унікальністю, правила `ON DELETE RESTRICT` для захисту міст від видалення. |
| **Лаба 2: DML & CRUD** | Swagger `/docs`: реєстрацію юзера з хешуванням Argon2id. DBeaver: наявність захешованого пароля, патерн `ON CONFLICT DO UPDATE`. | DBeaver: виконання скрипта `docs/lab2_dml_operations.sql` з предикатами `LIKE`, `IN`, `BETWEEN` та пакетною вставкою пасажирів. | Термінал: запуск скрипта сідування `pnpm --dir backend run db:seed`. Swagger: вибірку списку станцій `GET /api/stations` та створення станції. |
| **Лаба 3: Складний SQL** | Swagger / DBeaver: пошуковий SQL-запит із двома `JOIN` до `stops`, фільтрацію напрямку $s_{\text{from}} < s_{\text{to}}$ та CTE динамічної ціни. | DBeaver: виконання віконних функцій `DENSE_RANK() OVER (PARTITION BY ...)` та агрегації з фільтром груп `HAVING COUNT(*) > 5`. | Swagger: роут розкладу `GET /api/trips/:id/schedule` з сортуванням `ORDER BY stop_order` та розрахунком часу стоянки через `INTERVAL`. |
| **Лаба 4: Індексація** | Термінал: запуск `pnpm --dir backend test` (зелені юніт-тести Vitest алгоритму перетинів). DBeaver: композитний B-Tree індекс ядра `idx_tickets_conflict` та функціональний індекс `LOWER(email)`. | DBeaver: частковий індекс `WHERE status = 'HELD'`, запит до системної статистики `pg_stat_user_indexes` (ріст лічильника `idx_scan`). | DBeaver: B-Tree індекси зовнішніх ключів (`stops.route_id`, `carriages.train_id`) для прискорення перевірок зовнішніх ключів і каскадних операцій та регістронезалежний індекс `LOWER(stations.name)`. |
| **Лаба 5: ACID & Блокування** | DBeaver (2 сесії): паралельне виконання транзакцій із блокуванням рядка `SELECT ... FOR UPDATE`, обробку дедлоків. Vitest: concurrency-тест. | DBeaver (2 сесії): демонстрацію аномалій рівнів ізоляції (`Read Committed` проти `Repeatable Read`). Swagger: відхилення повернення за правилом 2 годин. | DBeaver: збережений рядок квитка з незмінними даними (Snapshot Pattern). Swagger: ендпоінт провідника `verify-ticket` із фіксацією `boarded_at`. |
| **Лаба 6: Оптимізація & EXPLAIN** | DBeaver: `EXPLAIN (ANALYZE, BUFFERS)` покриваючого індексу з `INCLUDE` (`Index Only Scan`; зафіксувати `Heap Fetches: 0` лише якщо це підтверджено конкретним планом після обслуговування). Демонстрація `SKIP LOCKED` та тюнінгу `work_mem`. | DBeaver: профілювання планів виконання аналітичних звітів, математичний розрахунок `Buffer Cache Hit Ratio` (> 98%). | Термінал: запуск генератора стрес-датасету на 10 000+ квитків. DBeaver: бенчмарк прискорення запиту `Seq Scan` vs `Index Scan` та аналіз `Nested Loop` $\to$ `Hash Join`. |

---

## 6. Повна файлова структура проєкту (Target Architecture)

```text
easyrail/
├── backend/
│   ├── drizzle/                       # Згенеровані файли SQL-міграцій
│   │   ├── 0000_init_schema.sql
│   │   └── meta/
│   ├── src/
│   │   ├── config/
│   │   │   └── env.ts                 # Валідація process.env через Zod (Fail-Fast)
│   │   ├── db/
│   │   │   ├── index.ts               # Пул з'єднань pg.Pool та клієнт Drizzle
│   │   │   ├── schema.ts              # Джерело правди: всі таблиці, типи та індекси
│   │   │   ├── seed.ts                # Сід реальної мережі залізниць України
│   │   │   └── generate_stress_data.ts# Генератор 10 000+ тестових квитків
│   │   ├── modules/
│   │   │   ├── auth/              # Реєстрація, логін, Argon2id, JWT, Upsert
│   │   │   │   ├── auth.routes.ts
│   │   │   │   ├── auth.schemas.ts
│   │   │   │   ├── auth.service.ts
│   │   │   │   └── auth.repository.ts
│   │   │   ├── passengers/        # Збережені попутники пасажира
│   │   │   │   ├── passengers.routes.ts
│   │   │   │   ├── passengers.schemas.ts
│   │   │   │   └── passengers.service.ts
│   │   │   ├── stations/          # Довідники міст і зупинок
│   │   │   │   ├── stations.routes.ts
│   │   │   │   └── stations.schemas.ts
│   │   │   ├── trips/             # Пошуковий алгоритм, розклад, динамічні ціни
│   │   │   │   ├── trips.routes.ts
│   │   │   │   ├── trips.schemas.ts
│   │   │   │   └── trips.service.ts
│   │   │   ├── booking/           # Чисте ядро, перевірка перетинів, 10-хв холд, оплата
│   │   │   │   ├── booking.routes.ts
│   │   │   │   ├── booking.schemas.ts
│   │   │   │   ├── booking.service.ts
│   │   │   │   ├── booking.repository.ts
│   │   │   │   ├── booking.domain.ts
│   │   │   │   └── booking.domain.test.ts
│   │   │   ├── attendant/         # Робоче місце провідника
│   │   │   │   ├── attendant.routes.ts
│   │   │   │   └── attendant.schemas.ts
│   │   │   ├── refunds/           # Модуль добровільних повернень
│   │   │   │   ├── refunds.routes.ts
│   │   │   │   ├── refunds.schemas.ts
│   │   │   │   └── refunds.service.ts
│   │   │   ├── admin/             # Адміністративні звіти
│   │   │   │   ├── admin.routes.ts
│   │   │   │   └── admin.schemas.ts
│   │   │   ├── health/            # Liveness/Readiness перевірка бази
│   │   │   │   └── health.routes.ts
│   │   │   └── workers/           # Фонові воркери на базі SKIP LOCKED
│   │   │       └── cleanup.worker.ts
│   │   ├── plugins/
│   │   │   ├── swagger.ts
│   │   │   ├── jwt.ts
│   │   │   └── errors.ts
│   │   ├── app.ts
│   │   └── server.ts
│   ├── tests/
│   │   ├── concurrency/
│   │   │   └── race-condition.test.ts # Concurrency-тест подвійної оплати на Vitest
│   │   └── EasyRail_E2E.postman_collection.json # Повний наскрізний E2E сценарій
│   ├── drizzle.config.ts              # Конфігурація CLI міграцій Drizzle
│   ├── package.json
│   ├── pnpm-lock.yaml
│   ├── tsconfig.json                  # Строга типізація TypeScript
│   └── vitest.config.ts               # Конфігурація тест-ранера Vitest
├── .github/
│   └── workflows/
│       ├── ci.yml                 # Linting, Typecheck, Vitest на кожен PR
│       └── docker-publish.yml     # Збірка і пуш у GitHub Container Registry (GHCR)
├── docs/
│   ├── lab2_dml_operations.sql    # Скрипт кафедральних DML-вибірок
│   ├── lab4_indexes_report.md     # Звіт з проєктування B-Tree індексів
│   ├── lab5_isolation_levels.sql  # Демонстрація аномалій рівнів ізоляції
│   └── lab6_query_optimization.md # Профілювання EXPLAIN (ANALYZE, BUFFERS)
├── .dockerignore
├── .env.example
├── .gitignore
├── docker-compose.yml             # Контейнер PostgreSQL 16 Alpine з healthcheck
├── Dockerfile                     # Multi-stage non-root build (USER node)
```

---

## 7. Чек-лист перед показом викладачу (Demo Day Protocol)

Перед тим як заходити до аудиторії або підключатися на захист, у терміналі по черзі виконується строгий протокол перевірки:

1. **Повне скидання та перезбірка з нуля:**
   ```bash
   docker compose down -v
   docker compose up --build -d
   ```
2. **Перевірка стану здоров'я контейнерів:**
   ```bash
   docker compose ps
   ```
   *Переконайтеся, що статус Postgres — `healthy`.*
3. **Застосування схеми та наповнення даними:**
   ```bash
   pnpm --dir backend exec drizzle-kit push
   pnpm --dir backend run db:seed
   ```
4. **Запуск тестового набору Vitest:**
   ```bash
   pnpm --dir backend test
   ```
   *Усі юніт-тести ядра перетину інтервалів та тести конкурентності мають світитися зеленим (100% pass).*
5. **Запуск бекенду:**
   ```bash
   pnpm --dir backend run dev
   ```
   *Сервер повинен запуститися за < 500 мс без жодного варнінгу або помилки валідації Zod.*
6. **Перевірка у браузері:**
   * Відкрити `http://localhost:3000/docs` — інтерактивний Swagger UI відображає всі задокументовані ендпоінти із Zod-схемами.
   * Відкрити `http://localhost:3000/health` — отримати `{"status": "ok", "db": "healthy"}`.
7. **Перевірка у DBeaver:**
   * Підключитися до `localhost:5432` (`postgres / postgres`).
   * Перевірити, що всі таблиці наповнені, а безпечний staging-профіль `EXPLAIN (ANALYZE, BUFFERS)` показує роботу індексів.

---

## 8. Enterprise Backlog: Масштабування системи (Post-v1)

Ці архітектурні рішення свідомо зафіксовані в нашому беклізі, щоб продемонструвати екзаменаційній комісії зріле сеньйорське бачення розвитку продукту без передчасного оверінжинірингу на етапі MVP:

1. **Redis для розподіленого Rate-Limiting та субсекундних холдів:**
   * Використання Redis-ключів із TTL для 10-хвилинного резервування замість оновлень рядків у PostgreSQL за високої інтенсивності запитів (10 000+ холдів на секунду під час відкриття продажу квитків на святкові поїзди).
2. **WebSockets / Server-Sent Events (SSE) для живого табло вокзалу:**
   * Реальний стрімінг затримок рейсів диспетчера на клієнтські екрани в режимі реального часу без постійного HTTP-поллінгу.
3. **Генерація PDF-квитка з захищеним QR-кодом:**
   * Асинхронний воркер створення квитка з криптографічно підписаним хешем (HMAC-SHA256), який провідник може сканувати офлайн без доступу до центральної мережі.
4. **Інтеграція тестового платіжного шлюзу (Webhook Sandbox):**
   * Обробка вебхуків від платіжних систем (наприклад, LiqPay або Monobank) з верифікацією цифрового підпису та захистом від повторних запитів (Idempotency Key).
5. **PgBouncer у режимі Transaction Pooling:**
   * Підключення легкої проксі з'єднань у разі горизонтального масштабування бекенду на декілька інстансів у Kubernetes.
