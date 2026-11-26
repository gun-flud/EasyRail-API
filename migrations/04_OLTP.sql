INSERT INTO stations (station_name, city) VALUES
    ('Ковель', 'Ковель'),
    ('Луцьк', 'Луцьк'),
    ('Рівне', 'Рівне'),
    ('Сарни', 'Сарни'),
    ('Коростень', 'Коростень'),
    ('Шепетівка', 'Шепетівка'),
    ('Бердичів', 'Бердичів'),
    ('Хелм', 'Хелм')
ON CONFLICT (station_name, city) DO NOTHING;

INSERT INTO routes (route_name, base_segment_price, route_number, route_status, schedule_rule, train_type) VALUES
    ('Ковель — Київ (Інтерсіті)', 11000, '752К', 'ACTIVE', 'DAILY',    'INTERCITY'), -- 5 зупинок (через Луцьк, Рівне, Шепетівку)
    ('Хелм — Київ',               14000, '024Ш', 'ACTIVE', 'DAILY',    'FAST'),      -- прохідний: починається ДО Ковеля
    ('Ковель — Дніпро',            9500, '128Л', 'ACTIVE', 'DAILY',    'PASSENGER'), -- прохідний: їде ДАЛІ після Києва
    ('Ковель — Київ (Нічний)',    13000, '098Л', 'ACTIVE', 'DAILY',    'FIRM'),      -- короткий: лише 1 проміжна зупинка (Коростень)
    ('Київ — Ковель (Зворотний)', 13000, '097К', 'ACTIVE', 'DAILY',    'FIRM')       -- зворотний напрямок (не має потрапляти в Ковель -> Київ)
ON CONFLICT (route_number) DO NOTHING;

-- 3. Вагони для нових маршрутів (використовують вже існуючі carriage_type_list)
INSERT INTO carriages (carriage_type_id, route_id, carriage_number) VALUES
    -- 752К (Інтерсіті)
    ((SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'SEAT'),      (SELECT route_id FROM routes WHERE route_number = '752К'), 1),
    ((SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'SEAT'),      (SELECT route_id FROM routes WHERE route_number = '752К'), 2),
    -- 024Ш (Хелм — Київ)
    ((SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'COUPE'),     (SELECT route_id FROM routes WHERE route_number = '024Ш'), 1),
    -- 128Л (Ковель — Дніпро)
    ((SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'PLATZKART'), (SELECT route_id FROM routes WHERE route_number = '128Л'), 1),
    ((SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'COUPE'),     (SELECT route_id FROM routes WHERE route_number = '128Л'), 2),
    -- 098Л (Ковель — Київ Нічний)
    ((SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'COUPE'),     (SELECT route_id FROM routes WHERE route_number = '098Л'), 1),
    ((SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'PLATZKART'), (SELECT route_id FROM routes WHERE route_number = '098Л'), 2),
    -- 097К (Київ — Ковель)
    ((SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'COUPE'),     (SELECT route_id FROM routes WHERE route_number = '097К'), 1)
ON CONFLICT (route_id, carriage_number) DO NOTHING;

-- 4. Зупинки (різна кількість і різні проміжні станції)
INSERT INTO stops (route_id, station_id, arrival_offset_minutes, departure_offset_minutes, stop_order) VALUES
    -- 752К: Ковель (1) -> Луцьк (2) -> Рівне (3) -> Шепетівка (4) -> Київ (5)
    ((SELECT route_id FROM routes WHERE route_number = '752К'), (SELECT station_id FROM stations WHERE station_name = 'Ковель'),            0,   0,   1),
    ((SELECT route_id FROM routes WHERE route_number = '752К'), (SELECT station_id FROM stations WHERE station_name = 'Луцьк'),             65,  70,  2),
    ((SELECT route_id FROM routes WHERE route_number = '752К'), (SELECT station_id FROM stations WHERE station_name = 'Рівне'),             130, 135, 3),
    ((SELECT route_id FROM routes WHERE route_number = '752К'), (SELECT station_id FROM stations WHERE station_name = 'Шепетівка'),         215, 220, 4),
    ((SELECT route_id FROM routes WHERE route_number = '752К'), (SELECT station_id FROM stations WHERE station_name = 'Київ-Пасажирський'), 390, 390, 5),

    -- 024Ш: Хелм (1) -> Ковель (2) -> Сарни (3) -> Київ (4)
    ((SELECT route_id FROM routes WHERE route_number = '024Ш'), (SELECT station_id FROM stations WHERE station_name = 'Хелм'),              0,   0,   1),
    ((SELECT route_id FROM routes WHERE route_number = '024Ш'), (SELECT station_id FROM stations WHERE station_name = 'Ковель'),            120, 135, 2),
    ((SELECT route_id FROM routes WHERE route_number = '024Ш'), (SELECT station_id FROM stations WHERE station_name = 'Сарни'),             250, 255, 3),
    ((SELECT route_id FROM routes WHERE route_number = '024Ш'), (SELECT station_id FROM stations WHERE station_name = 'Київ-Пасажирський'), 480, 480, 4),

    -- 128Л: Ковель (1) -> Рівне (2) -> Бердичів (3) -> Київ (4) -> Дніпро (5)
    ((SELECT route_id FROM routes WHERE route_number = '128Л'), (SELECT station_id FROM stations WHERE station_name = 'Ковель'),            0,   0,   1),
    ((SELECT route_id FROM routes WHERE route_number = '128Л'), (SELECT station_id FROM stations WHERE station_name = 'Рівне'),             120, 125, 2),
    ((SELECT route_id FROM routes WHERE route_number = '128Л'), (SELECT station_id FROM stations WHERE station_name = 'Бердичів'),          260, 265, 3),
    ((SELECT route_id FROM routes WHERE route_number = '128Л'), (SELECT station_id FROM stations WHERE station_name = 'Київ-Пасажирський'), 395, 415, 4),
    ((SELECT route_id FROM routes WHERE route_number = '128Л'), (SELECT station_id FROM stations WHERE station_name = 'Дніпро-Головний'),   780, 780, 5),

    -- 098Л: Ковель (1) -> Коростень (2) -> Київ (3)
    ((SELECT route_id FROM routes WHERE route_number = '098Л'), (SELECT station_id FROM stations WHERE station_name = 'Ковель'),            0,   0,   1),
    ((SELECT route_id FROM routes WHERE route_number = '098Л'), (SELECT station_id FROM stations WHERE station_name = 'Коростень'),         240, 245, 2),
    ((SELECT route_id FROM routes WHERE route_number = '098Л'), (SELECT station_id FROM stations WHERE station_name = 'Київ-Пасажирський'), 360, 360, 3),

    -- 097К (зворотний): Київ (1) -> Коростень (2) -> Ковель (3)
    ((SELECT route_id FROM routes WHERE route_number = '097К'), (SELECT station_id FROM stations WHERE station_name = 'Київ-Пасажирський'), 0,   0,   1),
    ((SELECT route_id FROM routes WHERE route_number = '097К'), (SELECT station_id FROM stations WHERE station_name = 'Коростень'),         115, 120, 2),
    ((SELECT route_id FROM routes WHERE route_number = '097К'), (SELECT station_id FROM stations WHERE station_name = 'Ковель'),            360, 360, 3)
ON CONFLICT DO NOTHING;

-- 5. Рейси на один день (2026-11-01) + 1 рейс на наступний день для перевірки фільтрації за датою
INSERT INTO trips (route_id, departure_time, trip_status, delay_minutes) VALUES
    ((SELECT route_id FROM routes WHERE route_number = '752К'), '2026-11-01 07:15:00+02', 'SCHEDULED', 0),
    ((SELECT route_id FROM routes WHERE route_number = '024Ш'), '2026-11-01 11:00:00+02', 'SCHEDULED', 0), -- з Ковеля відправлення о 13:15 (+135 хв)
    ((SELECT route_id FROM routes WHERE route_number = '128Л'), '2026-11-01 15:30:00+02', 'SCHEDULED', 0),
    ((SELECT route_id FROM routes WHERE route_number = '098Л'), '2026-11-01 21:40:00+02', 'SCHEDULED', 0),
    ((SELECT route_id FROM routes WHERE route_number = '097К'), '2026-11-01 21:20:00+02', 'SCHEDULED', 0), -- зворотний у той же день
    ((SELECT route_id FROM routes WHERE route_number = '098Л'), '2026-11-02 21:40:00+02', 'SCHEDULED', 0)  -- інша дата
ON CONFLICT (route_id, departure_time) DO NOTHING;



















INSERT INTO ticket_segment (
    user_id, passenger_id, trip_id, seat_id, carriage_id,
    from_station_id, to_station_id, from_stop_order, to_stop_order,
    ticket_status, created_at, hold_expires_at, paid_at, cancelled_at,
    price, payment_transaction_id, pdf_url,
    passenger_lastname, passenger_name, from_station_name, to_station_name,
    departure_time, arrival_time, boarded_at
) VALUES
    -- 1) 752К, Вагон 1 (SEAT), Місце 1: PAID на 1->3 (Ковель -> Рівне) -> ЗАЙНЯТЕ для 1->5
    (
        (SELECT user_id FROM users WHERE email = 'vlad@example.com'),
        (SELECT passenger_id FROM passengers WHERE passenger_name = 'Владислав' AND passenger_lastname = 'Коваленко' LIMIT 1),
        (SELECT trip_id FROM trips WHERE route_id = (SELECT route_id FROM routes WHERE route_number = '752К') AND departure_time = '2026-11-01 07:15:00+02'),
        (SELECT seat_id FROM seat_templates_list WHERE seat_number = 1 AND carriage_type_id = (SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'SEAT')),
        (SELECT carriage_id FROM carriages WHERE carriage_number = 1 AND route_id = (SELECT route_id FROM routes WHERE route_number = '752К')),
        (SELECT station_id FROM stations WHERE station_name = 'Ковель'),
        (SELECT station_id FROM stations WHERE station_name = 'Рівне'),
        1, 3,
        'PAID',
        NOW() - INTERVAL '2 hours',
        NOW() - INTERVAL '1 hour 50 minutes',
        NOW() - INTERVAL '1 hour 55 minutes',
        NULL,
        (SELECT (3 - 1) * r.base_segment_price * ctl.carriage_type_price_multiplier / 100 FROM routes r, carriage_type_list ctl WHERE r.route_number = '752К' AND ctl.carriage_type = 'SEAT'),
        'txn_kv_752_01',
        'https://s3.easyrail.ua/tickets/kv-752-01.pdf',
        'Коваленко', 'Владислав', 'Ковель', 'Рівне',
        '2026-11-01 07:15:00+02', '2026-11-01 09:25:00+02',
        NULL
    ),

    -- 2) 752К, Вагон 1 (SEAT), Місце 2: активний HELD на 3->5 (Рівне -> Київ) -> ЗАЙНЯТЕ для 1->5
    (
        (SELECT user_id FROM users WHERE email = 'vlad@example.com'),
        (SELECT passenger_id FROM passengers WHERE passenger_name = 'Марія' AND passenger_lastname = 'Коваленко' LIMIT 1),
        (SELECT trip_id FROM trips WHERE route_id = (SELECT route_id FROM routes WHERE route_number = '752К') AND departure_time = '2026-11-01 07:15:00+02'),
        (SELECT seat_id FROM seat_templates_list WHERE seat_number = 2 AND carriage_type_id = (SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'SEAT')),
        (SELECT carriage_id FROM carriages WHERE carriage_number = 1 AND route_id = (SELECT route_id FROM routes WHERE route_number = '752К')),
        (SELECT station_id FROM stations WHERE station_name = 'Рівне'),
        (SELECT station_id FROM stations WHERE station_name = 'Київ-Пасажирський'),
        3, 5,
        'HELD',
        NOW() - INTERVAL '2 minutes',
        NOW() + INTERVAL '8 minutes',
        NULL,
        NULL,
        (SELECT (5 - 3) * r.base_segment_price * ctl.carriage_type_price_multiplier / 100 FROM routes r, carriage_type_list ctl WHERE r.route_number = '752К' AND ctl.carriage_type = 'SEAT'),
        NULL,
        NULL,
        'Коваленко', 'Марія', 'Рівне', 'Київ-Пасажирський',
        '2026-11-01 09:30:00+02', '2026-11-01 13:45:00+02',
        NULL
    ),

    -- 3) 024Ш, Вагон 1 (COUPE), Місце 1: PAID на 1->2 (Хелм -> Ковель) -> ВІЛЬНЕ для 2->4 (пасажир виходить у Ковелі)
    (
        (SELECT user_id FROM users WHERE email = 'olena@example.com'),
        (SELECT passenger_id FROM passengers WHERE passenger_name = 'Олена' AND passenger_lastname = 'Коваленко' LIMIT 1),
        (SELECT trip_id FROM trips WHERE route_id = (SELECT route_id FROM routes WHERE route_number = '024Ш') AND departure_time = '2026-11-01 11:00:00+02'),
        (SELECT seat_id FROM seat_templates_list WHERE seat_number = 1 AND carriage_type_id = (SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'COUPE')),
        (SELECT carriage_id FROM carriages WHERE carriage_number = 1 AND route_id = (SELECT route_id FROM routes WHERE route_number = '024Ш')),
        (SELECT station_id FROM stations WHERE station_name = 'Хелм'),
        (SELECT station_id FROM stations WHERE station_name = 'Ковель'),
        1, 2,
        'PAID',
        NOW() - INTERVAL '3 hours',
        NOW() - INTERVAL '2 hours 50 minutes',
        NOW() - INTERVAL '2 hours 55 minutes',
        NULL,
        (SELECT (2 - 1) * r.base_segment_price * ctl.carriage_type_price_multiplier / 100 FROM routes r, carriage_type_list ctl WHERE r.route_number = '024Ш' AND ctl.carriage_type = 'COUPE'),
        'txn_kv_024_01',
        'https://s3.easyrail.ua/tickets/kv-024-01.pdf',
        'Коваленко', 'Олена', 'Хелм', 'Ковель',
        '2026-11-01 11:00:00+02', '2026-11-01 13:00:00+02',
        NULL
    ),

    -- 4) 024Ш, Вагон 1 (COUPE), Місце 2: прострочений HELD на 2->4 -> ВІЛЬНЕ (hold_expires_at у минулому)
    (
        (SELECT user_id FROM users WHERE email = 'olena@example.com'),
        (SELECT passenger_id FROM passengers WHERE passenger_name = 'Тарас' AND passenger_lastname = 'Коваленко' LIMIT 1),
        (SELECT trip_id FROM trips WHERE route_id = (SELECT route_id FROM routes WHERE route_number = '024Ш') AND departure_time = '2026-11-01 11:00:00+02'),
        (SELECT seat_id FROM seat_templates_list WHERE seat_number = 2 AND carriage_type_id = (SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'COUPE')),
        (SELECT carriage_id FROM carriages WHERE carriage_number = 1 AND route_id = (SELECT route_id FROM routes WHERE route_number = '024Ш')),
        (SELECT station_id FROM stations WHERE station_name = 'Ковель'),
        (SELECT station_id FROM stations WHERE station_name = 'Київ-Пасажирський'),
        2, 4,
        'HELD',
        NOW() - INTERVAL '30 minutes',
        NOW() - INTERVAL '20 minutes',
        NULL,
        NULL,
        (SELECT (4 - 2) * r.base_segment_price * ctl.carriage_type_price_multiplier / 100 FROM routes r, carriage_type_list ctl WHERE r.route_number = '024Ш' AND ctl.carriage_type = 'COUPE'),
        NULL,
        NULL,
        'Коваленко', 'Тарас', 'Ковель', 'Київ-Пасажирський',
        '2026-11-01 13:15:00+02', '2026-11-01 19:00:00+02',
        NULL
    ),

    -- 5) 128Л, Вагон 1 (PLATZKART), Місце 37: PAID на 1->5 (Ковель -> Дніпро) -> ЗАЙНЯТЕ (0 вільних плацкартів)
    (
        (SELECT user_id FROM users WHERE email = 'vlad@example.com'),
        (SELECT passenger_id FROM passengers WHERE passenger_name = 'Владислав' AND passenger_lastname = 'Коваленко' LIMIT 1),
        (SELECT trip_id FROM trips WHERE route_id = (SELECT route_id FROM routes WHERE route_number = '128Л') AND departure_time = '2026-11-01 15:30:00+02'),
        (SELECT seat_id FROM seat_templates_list WHERE seat_number = 37 AND carriage_type_id = (SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'PLATZKART')),
        (SELECT carriage_id FROM carriages WHERE carriage_number = 1 AND route_id = (SELECT route_id FROM routes WHERE route_number = '128Л')),
        (SELECT station_id FROM stations WHERE station_name = 'Ковель'),
        (SELECT station_id FROM stations WHERE station_name = 'Дніпро-Головний'),
        1, 5,
        'PAID',
        NOW() - INTERVAL '4 hours',
        NOW() - INTERVAL '3 hours 50 minutes',
        NOW() - INTERVAL '3 hours 52 minutes',
        NULL,
        (SELECT (5 - 1) * r.base_segment_price * ctl.carriage_type_price_multiplier / 100 FROM routes r, carriage_type_list ctl WHERE r.route_number = '128Л' AND ctl.carriage_type = 'PLATZKART'),
        'txn_kv_128_01',
        'https://s3.easyrail.ua/tickets/kv-128-01.pdf',
        'Коваленко', 'Владислав', 'Ковель', 'Дніпро-Головний',
        '2026-11-01 15:30:00+02', '2026-11-02 04:30:00+02',
        NULL
    ),

    -- 6) 128Л, Вагон 2 (COUPE), Місце 1: PAID на 4->5 (Київ -> Дніпро) -> ВІЛЬНЕ для 1->4 (сідають вже після Києва)
    (
        (SELECT user_id FROM users WHERE email = 'olena@example.com'),
        (SELECT passenger_id FROM passengers WHERE passenger_name = 'Олена' AND passenger_lastname = 'Коваленко' LIMIT 1),
        (SELECT trip_id FROM trips WHERE route_id = (SELECT route_id FROM routes WHERE route_number = '128Л') AND departure_time = '2026-11-01 15:30:00+02'),
        (SELECT seat_id FROM seat_templates_list WHERE seat_number = 1 AND carriage_type_id = (SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'COUPE')),
        (SELECT carriage_id FROM carriages WHERE carriage_number = 2 AND route_id = (SELECT route_id FROM routes WHERE route_number = '128Л')),
        (SELECT station_id FROM stations WHERE station_name = 'Київ-Пасажирський'),
        (SELECT station_id FROM stations WHERE station_name = 'Дніпро-Головний'),
        4, 5,
        'PAID',
        NOW() - INTERVAL '4 hours',
        NOW() - INTERVAL '3 hours 50 minutes',
        NOW() - INTERVAL '3 hours 51 minutes',
        NULL,
        (SELECT (5 - 4) * r.base_segment_price * ctl.carriage_type_price_multiplier / 100 FROM routes r, carriage_type_list ctl WHERE r.route_number = '128Л' AND ctl.carriage_type = 'COUPE'),
        'txn_kv_128_02',
        'https://s3.easyrail.ua/tickets/kv-128-02.pdf',
        'Коваленко', 'Олена', 'Київ-Пасажирський', 'Дніпро-Головний',
        '2026-11-01 22:25:00+02', '2026-11-02 04:30:00+02',
        NULL
    ),

    -- 7) 098Л, Вагон 1 (COUPE), Місце 1: RETURNED на 1->3 -> ВІЛЬНЕ
    (
        (SELECT user_id FROM users WHERE email = 'vlad@example.com'),
        (SELECT passenger_id FROM passengers WHERE passenger_name = 'Марія' AND passenger_lastname = 'Коваленко' LIMIT 1),
        (SELECT trip_id FROM trips WHERE route_id = (SELECT route_id FROM routes WHERE route_number = '098Л') AND departure_time = '2026-11-01 21:40:00+02'),
        (SELECT seat_id FROM seat_templates_list WHERE seat_number = 1 AND carriage_type_id = (SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'COUPE')),
        (SELECT carriage_id FROM carriages WHERE carriage_number = 1 AND route_id = (SELECT route_id FROM routes WHERE route_number = '098Л')),
        (SELECT station_id FROM stations WHERE station_name = 'Ковель'),
        (SELECT station_id FROM stations WHERE station_name = 'Київ-Пасажирський'),
        1, 3,
        'RETURNED',
        NOW() - INTERVAL '1 day',
        NOW() - INTERVAL '23 hours 50 minutes',
        NOW() - INTERVAL '23 hours 55 minutes',
        NOW() - INTERVAL '2 hours',
        (SELECT (3 - 1) * r.base_segment_price * ctl.carriage_type_price_multiplier / 100 FROM routes r, carriage_type_list ctl WHERE r.route_number = '098Л' AND ctl.carriage_type = 'COUPE'),
        'txn_kv_098_01',
        'https://s3.easyrail.ua/tickets/kv-098-01.pdf',
        'Коваленко', 'Марія', 'Ковель', 'Київ-Пасажирський',
        '2026-11-01 21:40:00+02', '2026-11-02 03:40:00+02',
        NULL
    ),

    -- 8 і 9) 098Л, Вагон 1 (COUPE), ОДНЕ Й ТЕ САМЕ Місце 2: PAID на 1->2 і PAID на 2->3
    -- Перевіряє COUNT(DISTINCT (carriage_id, seat_id)): має рахуватися як 1 зайняте місце, а не 2!
    (
        (SELECT user_id FROM users WHERE email = 'olena@example.com'),
        (SELECT passenger_id FROM passengers WHERE passenger_name = 'Тарас' AND passenger_lastname = 'Коваленко' LIMIT 1),
        (SELECT trip_id FROM trips WHERE route_id = (SELECT route_id FROM routes WHERE route_number = '098Л') AND departure_time = '2026-11-01 21:40:00+02'),
        (SELECT seat_id FROM seat_templates_list WHERE seat_number = 2 AND carriage_type_id = (SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'COUPE')),
        (SELECT carriage_id FROM carriages WHERE carriage_number = 1 AND route_id = (SELECT route_id FROM routes WHERE route_number = '098Л')),
        (SELECT station_id FROM stations WHERE station_name = 'Ковель'),
        (SELECT station_id FROM stations WHERE station_name = 'Коростень'),
        1, 2,
        'PAID',
        NOW() - INTERVAL '5 hours',
        NOW() - INTERVAL '4 hours 50 minutes',
        NOW() - INTERVAL '4 hours 55 minutes',
        NULL,
        (SELECT (2 - 1) * r.base_segment_price * ctl.carriage_type_price_multiplier / 100 FROM routes r, carriage_type_list ctl WHERE r.route_number = '098Л' AND ctl.carriage_type = 'COUPE'),
        'txn_kv_098_02',
        'https://s3.easyrail.ua/tickets/kv-098-02.pdf',
        'Коваленко', 'Тарас', 'Ковель', 'Коростень',
        '2026-11-01 21:40:00+02', '2026-11-02 01:40:00+02',
        NULL
    ),
    (
        (SELECT user_id FROM users WHERE email = 'vlad@example.com'),
        (SELECT passenger_id FROM passengers WHERE passenger_name = 'Владислав' AND passenger_lastname = 'Коваленко' LIMIT 1),
        (SELECT trip_id FROM trips WHERE route_id = (SELECT route_id FROM routes WHERE route_number = '098Л') AND departure_time = '2026-11-01 21:40:00+02'),
        (SELECT seat_id FROM seat_templates_list WHERE seat_number = 2 AND carriage_type_id = (SELECT carriage_type_id FROM carriage_type_list WHERE carriage_type = 'COUPE')),
        (SELECT carriage_id FROM carriages WHERE carriage_number = 1 AND route_id = (SELECT route_id FROM routes WHERE route_number = '098Л')),
        (SELECT station_id FROM stations WHERE station_name = 'Коростень'),
        (SELECT station_id FROM stations WHERE station_name = 'Київ-Пасажирський'),
        2, 3,
        'PAID',
        NOW() - INTERVAL '4 hours',
        NOW() - INTERVAL '3 hours 50 minutes',
        NOW() - INTERVAL '3 hours 54 minutes',
        NULL,
        (SELECT (3 - 2) * r.base_segment_price * ctl.carriage_type_price_multiplier / 100 FROM routes r, carriage_type_list ctl WHERE r.route_number = '098Л' AND ctl.carriage_type = 'COUPE'),
        'txn_kv_098_03',
        'https://s3.easyrail.ua/tickets/kv-098-03.pdf',
        'Коваленко', 'Владислав', 'Коростень', 'Київ-Пасажирський',
        '2026-11-02 01:45:00+02', '2026-11-02 03:40:00+02',
        NULL
    );




--SELECT
--юзер вводить: звідки -> куди, (готово)
--та дату (юзер вводить свою дату, ми верифікуємо та виводимо в його таймзоні) (готово)
--повертаємо: назва маршруту(Ковель-Одеса), (готово)
--Станція start + година,  (готово)
--Станція stop + година, (готово)
--номер роута (готово)
--ВИМОГИ ВІД РОУТА: ACTIVE, SCHEDULED

-- ++ ціна квиточка, ++ кількість вільних місць за типом вагона

WITH matched_trips AS MATERIALIZED (
    SELECT
        t.trip_id,
        r.route_id,
        r.route_number,
        r.route_name,
        r.train_type,
        r.base_segment_price,
        from_s.station_name AS from_station,
        to_s.station_name AS to_station,
        from_st.stop_order AS from_stop_order,
        to_st.stop_order AS to_stop_order,
        t.departure_time + make_interval(mins => from_st.departure_offset_minutes) AS segment_departure,
        t.departure_time + make_interval(mins => to_st.arrival_offset_minutes) AS segment_arrival
    FROM routes r
    INNER JOIN trips t ON t.route_id = r.route_id
    INNER JOIN stops from_st ON from_st.route_id = r.route_id
    INNER JOIN stations from_s ON from_s.station_id = from_st.station_id
    INNER JOIN stops to_st ON to_st.route_id = r.route_id
    INNER JOIN stations to_s ON to_s.station_id = to_st.station_id
    WHERE r.route_status = 'ACTIVE'
      AND t.trip_status = 'SCHEDULED'
      AND from_s.station_name = 'Ковель'
      AND to_s.station_name = 'Київ-Пасажирський'
      AND from_st.stop_order < to_st.stop_order
	  AND (t.departure_time + make_interval(mins => from_st.departure_offset_minutes))::date = '2026-11-01'
),

route_carriages AS (
	SELECT 
		c.route_id,
        c_type.carriage_type_id,
        c_type.carriage_type,
        c_type.carriage_type_price_multiplier,
        COUNT(s_type.seat_id) AS total_seats
	FROM (SELECT DISTINCT route_id FROM matched_trips ) r
	INNER JOIN carriages c ON c.route_id = r.route_id
	INNER JOIN carriage_type_list c_type ON c_type.carriage_type_id = c.carriage_type_id
	INNER JOIN seat_templates_list s_type ON s_type.carriage_type_id = c_type.carriage_type_id
	GROUP BY
        c.route_id,
        c_type.carriage_type_id,
        c_type.carriage_type,
        c_type.carriage_type_price_multiplier
),

count_occupied_seats AS (
	SELECT
	COUNT(DISTINCT (ticket.carriage_id, ticket.seat_id)) AS booked_seats_count,
	ctl.carriage_type,
	trip.trip_id
	FROM matched_trips trip
	INNER JOIN ticket_segment ticket ON ticket.trip_id = trip.trip_id
	INNER JOIN carriages c ON c.carriage_id = ticket.carriage_id
    INNER JOIN carriage_type_list ctl ON ctl.carriage_type_id = c.carriage_type_id
		WHERE  trip.to_stop_order > ticket.from_stop_order
		AND trip.from_stop_order < ticket.to_stop_order
		AND (ticket.ticket_status = 'PAID' 
				OR (ticket.ticket_status = 'HELD'
					AND ticket.hold_expires_at > NOW()))
		GROUP BY ctl.carriage_type, trip.trip_id
)

SELECT 
	trip.trip_id,
	trip.route_number,
	trip.route_name,
	trip.train_type,
	trip.base_segment_price,
	trip.from_station,
	trip.to_station,
	trip.segment_departure,
	trip.segment_arrival,
	trip.from_stop_order,
	trip.to_stop_order,
	route.carriage_type_id,
	route.carriage_type,
	route.carriage_type_price_multiplier,
	route.total_seats,
	COALESCE(seat.booked_seats_count, 0) AS booked_seats_count
FROM matched_trips trip
	INNER JOIN route_carriages route ON route.route_id = trip.route_id
	LEFT JOIN count_occupied_seats seat 
		ON seat.trip_id = trip.trip_id 
		AND seat.carriage_type = route.carriage_type 
	ORDER BY trip.segment_departure ASC;	


--UPDATE
BEGIN;

UPDATE ticket_segment
	SET 
		ticket_status = 'PAID', 
		paid_at = NOW(),
		payment_transaction_id = 'txn_mono_566_01',
		pdf_url = 'https://s3.easyrail.ua/tickets/mono_566_01.pdf'
		WHERE ticket_id       = '01a20af7-64b5-7c2a-bfb4-7fece27f2399' 
		    --AND user_id = (SELECT user_id FROM users WHERE user_name = 'vlad_kov')
			AND user_id = '01a20af7-6456-729a-9f87-75db9902091c'
			AND hold_expires_at > NOW()
			AND ticket_status = 'HELD'
		RETURNING
		    ticket_id,
		    ticket_status,
		    paid_at,
		    payment_transaction_id,
		    pdf_url;
ROLLBACK;
COMMIT;

SELECT * FROM ticket_segment 
	WHERE user_id = (SELECT user_id FROM users WHERE user_name = 'vlad_kov')
	AND trip_id = '01a20af7-6489-7b7d-92ea-c36ed5d9124e' 
	AND passenger_id = '01a20af7-6464-7152-8fe8-ba2f010ac2d8';



--INSERT
BEGIN;
INSERT INTO passengers (user_id, passenger_lastname, passenger_name)
VALUES (
    (SELECT user_id FROM users WHERE user_name = 'vlad_kov'),
    'Тимчасовий',
    'Тест'
);
ROLLBACK;
COMMIT;
--DELETE
BEGIN;
DELETE FROM passengers p
WHERE user_id = (SELECT user_id FROM users WHERE user_name = 'vlad_kov')
      AND passenger_lastname = 'Тимчасовий'
      AND passenger_name = 'Тест'
RETURNING *;


ROLLBACK;
COMMIT;