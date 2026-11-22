SELECT p.passenger_id, p.passenger_lastname, p.passenger_name, u.email FROM passengers p
INNER JOIN users u ON p.user_id = u.user_id
WHERE u.email = 'vlad@example.com' AND p.passenger_lastname ILIKE 'Ковал%'
ORDER BY p.passenger_lastname, p.passenger_name
LIMIT 10 OFFSET 0;


UPDATE ticket_segment
SET ticket_status = 'EXPIRED'
WHERE ticket_status = 'HELD' AND hold_expires_at < NOW()
RETURNING ticket_id, ticket_status, hold_expires_at;

DELETE FROM routes
WHERE route_status = 'INACTIVE' AND NOT EXISTS (
    SELECT 1 FROM trips WHERE trips.route_id = routes.route_id
)
RETURNING route_id, route_number, route_name;