-- 1. SELECT: Показ вільних місць у вагоні
-- поїзд 705К, вагон 1, відрізок Вінниця - Львів (місце №1 зайняте до Львова, місце №2 вільне після Вінниці)

SELECT
    stl.seat_id,
    stl.seat_number,
    stl.tier_type,
    stl.is_side,
    ((s_to.stop_order - s_from.stop_order) * r.base_segment_price * ctl.carriage_type_price_multiplier / 100) AS price
FROM trips t
JOIN routes r ON r.route_id = t.route_id
JOIN carriages c ON c.route_id = r.route_id
JOIN carriage_type_list ctl ON ctl.carriage_type_id = c.carriage_type_id
JOIN seat_templates_list stl ON stl.carriage_type_id = ctl.carriage_type_id
JOIN stops s_from ON s_from.route_id = r.route_id
JOIN stations st_from ON st_from.station_id = s_from.station_id
JOIN stops s_to ON s_to.route_id = r.route_id
JOIN stations st_to ON st_to.station_id = s_to.station_id
WHERE r.route_number = '705К'
  AND t.departure_time = '2026-11-01 06:00:00+02'
  AND c.carriage_number = 1
  AND st_from.station_name = 'Вінниця'
  AND st_to.station_name = 'Львів'
  AND s_from.stop_order < s_to.stop_order
  AND t.trip_status = 'SCHEDULED'
  AND r.route_status = 'ACTIVE'
  AND NOT EXISTS (
      SELECT 1
      FROM ticket_segment ts
      WHERE ts.trip_id = t.trip_id
        AND ts.carriage_id = c.carriage_id
        AND ts.seat_id = stl.seat_id
        AND ts.from_stop_order < s_to.stop_order
        AND ts.to_stop_order > s_from.stop_order
        AND (
            ts.ticket_status = 'PAID' OR ts.ticket_status = 'HELD'
        )
  )
ORDER BY stl.seat_number;


-- 2. UPDATE: Скасування бронювання

UPDATE ticket_segment ts
SET ticket_status = 'RETURNED',
    cancelled_at = NOW(),
    hold_expires_at = NOW()
FROM users u, trips t
WHERE ts.user_id = u.user_id
  AND ts.trip_id = t.trip_id
  AND u.email = 'vlad@example.com'
  AND ts.passenger_name = 'Марія'
  AND ts.ticket_status = 'HELD'
  AND ts.boarded_at IS NULL
  AND t.trip_status = 'SCHEDULED'
RETURNING ts.ticket_id, ts.ticket_status, ts.cancelled_at;

-- 3. DELETE: Видалення користувача

DELETE FROM users u
WHERE u.email = 'petro.cond@easyrail.com'
	AND u.user_id = '01a1f02a-d44b-7816-8222-c12b4304f01f'
RETURNING u.user_id, u.user_name, u.email;

SELECT * FROM users u
WHERE u.email = 'petro.cond@easyrail.com'
