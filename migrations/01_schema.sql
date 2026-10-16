CREATE TYPE carriage_type AS ENUM ('COUPE', 'PLATZKART', 'LUX', 'SEAT');

CREATE TYPE route_status AS ENUM ('ACTIVE', 'UNACTIVE');

CREATE TYPE schedule_rule AS ENUM (
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
    'DAILY',
    'WEEKDAYS',
    'WEEKENDS'
);

CREATE TYPE train_type AS ENUM (
    'INTERCITY',
    'REGIONAL',
    'PASSENGER',
    'FAST',
    'FIRM'
);

CREATE TYPE tier_type AS ENUM ('TOP', 'DOWN', 'SEAT');

CREATE TYPE trip_status AS ENUM ('SCHEDULED', 'DEPARTED', 'CANCELLED', 'COMPLETED');

CREATE TYPE ticket_status AS ENUM ('HOLD', 'PAID', 'RETURNED', 'EXPIRED');

CREATE TABLE IF NOT EXISTS stations (
        station_id INT GENERATED ALWAYS AS IDENTITY,
        station_name VARCHAR(100) NOT NULL,
        city VARCHAR(50) NOT NULL,
        PRIMARY KEY (station_id)
    );

CREATE TABLE IF NOT EXISTS users (
        user_id INT GENERATED ALWAYS AS IDENTITY,
        user_name VARCHAR(50) NOT NULL,
        hashed_password VARCHAR(400) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        PRIMARY KEY (user_id)
    );

CREATE TABLE IF NOT EXISTS passengers (
        passenger_id INT GENERATED ALWAYS AS IDENTITY,
        user_id INT,
        passenger_lastname VARCHAR(50) NOT NULL,
        passenger_name VARCHAR(50) NOT NULL,
        PRIMARY KEY (passenger_id),
        FOREIGN KEY (user_id) REFERENCES users (user_id)
    );

CREATE TABLE IF NOT EXISTS carriage_type_list (
        carriage_type_id INT GENERATED ALWAYS AS IDENTITY,
        carriage_type carriage_type NOT NULL UNIQUE,
        carriage_type_price_multiplier NUMERIC(3, 2) NOT NULL,
        number_of_seats INT NOT NULL,
        PRIMARY KEY (carriage_type_id)
    );

CREATE TABLE IF NOT EXISTS routes (
        route_id INT GENERATED ALWAYS AS IDENTITY,
        route_name VARCHAR(100) NOT NULL,
        base_segment_price NUMERIC(9, 2) NOT NULL DEFAULT 50,
        route_number VARCHAR(10) NOT NULL,
        route_status route_status NOT NULL DEFAULT 'UNACTIVE',
        schedule_rule schedule_rule NOT NULL,
        train_type train_type NOT NULL DEFAULT 'PASSENGER',
        PRIMARY KEY (route_id)
    );

CREATE TABLE IF NOT EXISTS carriages (
        carriage_id INT GENERATED ALWAYS AS IDENTITY,
        carriage_type_id INT NOT NULL,
        route_id INT,
        carriage_number INT,
        UNIQUE (route_id, carriage_number),
        PRIMARY KEY (carriage_id),
        FOREIGN KEY (carriage_type_id) REFERENCES carriage_type_list (carriage_type_id),
        FOREIGN KEY (route_id) REFERENCES routes (route_id)
    );

CREATE TABLE IF NOT EXISTS seat_templates_list (
        seat_id INT GENERATED ALWAYS AS IDENTITY,
        carriage_type_id INT NOT NULL,
        seat_number INT NOT NULL,
        is_side BOOLEAN NOT NULL,
        tier_type tier_type NOT NULL DEFAULT 'DOWN',
        UNIQUE (carriage_type_id, seat_number),
        PRIMARY KEY (seat_id),
        FOREIGN KEY (carriage_type_id) REFERENCES carriage_type_list (carriage_type_id)
    );

CREATE TABLE IF NOT EXISTS trips (
        trip_id INT GENERATED ALWAYS AS IDENTITY,
        route_id INT NOT NULL,
        departure_time TIMESTAMP NOT NULL,
        trip_status trip_status NOT NULL DEFAULT 'SCHEDULED',
        delay_minutes INT,
        PRIMARY KEY (trip_id),
        FOREIGN KEY (route_id) REFERENCES routes (route_id)
    );

CREATE TABLE IF NOT EXISTS stops (
        stop_id INT GENERATED ALWAYS AS IDENTITY,
        route_id INT,
        station_id INT,
        stop_time TIME,
        departure_time TIME,
        stop_order INT,
        PRIMARY KEY (stop_id),
        FOREIGN KEY (route_id) REFERENCES routes (route_id),
        FOREIGN KEY (station_id) REFERENCES stations (station_id)
    );

CREATE TABLE IF NOT EXISTS ticket_segment (
        ticket_id BIGINT GENERATED ALWAYS AS IDENTITY,
        user_id INT NOT NULL,
        trip_id INT NOT NULL,
        carriage_id INT NOT NULL,
        seat_id INT NOT NULL,
        from_station_id INT NOT NULL,
        to_station_id INT NOT NULL,
        from_station_name VARCHAR(100) NOT NULL,
        to_station_name VARCHAR(100) NOT NULL,
        from_stop_order INT NOT NULL,
        to_stop_order INT NOT NULL,
        departure_time TIMESTAMP NOT NULL,
        arrival_time TIMESTAMP NOT NULL,
        passanger_lastname VARCHAR(50) NOT NULL,
        passanger_name VARCHAR(50) NOT NULL,
        ticket_status ticket_status NOT NULL DEFAULT 'HOLD',
        cancelled_time TIMESTAMP NULL DEFAULT NULL, --ТРЕАБА ПОДУМАТИ ЧИ НОРМ РЕАЛІЗАЦІЯ
        pdf_url TEXT, --ПОСИЛАННЯ НА S3 БАКЕТ
        price NUMERIC(9, 2) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT NOW (),
        paid_at TIMESTAMP NULL DEFAULT NULL,
        hold_expires_at TIMESTAMP DEFAULT (NOW () + INTERVAL '10 minutes'),


        PRIMARY KEY (ticket_id),
        FOREIGN KEY (user_id) REFERENCES users (user_id),
        FOREIGN KEY (trip_id) REFERENCES trips (trip_id),
        FOREIGN KEY (carriage_id) REFERENCES carriages (carriage_id),
        FOREIGN KEY (seat_id) REFERENCES seat_templates_list (seat_id),
        FOREIGN KEY (from_station_id) REFERENCES stations (station_id) ON DELETE RESTRICT,
        FOREIGN KEY (to_station_id) REFERENCES stations (station_id) ON DELETE RESTRICT,
        -- we should add index to not allow holding simutaniosly for one person
        -- we should add index to prevent situations from_stop_order > to_stop_order
    );