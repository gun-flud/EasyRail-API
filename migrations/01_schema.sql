CREATE TYPE carriage_type AS ENUM ('CUPE', 'PLATZKART', 'LUX', 'SEAT');
CREATE TYPE route_status AS ENUM ('ACTIVE', 'UNACTIVE');
CREATE TYPE schedule_rule AS ENUM (
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY'
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


CREATE TABLE IF NOT EXISTS
    stations (
        station_id INT GENERATED ALWAYS AS IDENTITY,
        station_name VARCHAR(100) NOT NULL,
        city VARCHAR(50) NOT NULL,

        PRIMARY KEY (station_id)
    );

CREATE TABLE IF NOT EXISTS
    users (
        user_id INT GENERATED ALWAYS AS IDENTITY,
        user_name VARCHAR(50) NOT NULL,
        hashed_password VARCHAR(400) NOT NULL,
        email VARCHAR(100) NOT NULL,

        PRIMARY KEY (user_id)
    );

CREATE TABLE IF NOT EXISTS
    passengers (
        passenger_id INT GENERATED ALWAYS AS IDENTITY,
        user_id INT,
        passenger_lastname VARCHAR(50) NOT NULL,
        passenger_name VARCHAR(50) NOT NULL,

        PRIMARY KEY (passenger_id),
        FOREIGN KEY (user_id) REFERENCES users (user_id)
    );

CREATE TABLE IF NOT EXISTS
    carriage_type_list (
        carriage_type_id INT GENERATED ALWAYS AS IDENTITY,
        carriage_type carriage_type NOT NULL,
        carriage_type_price_multiplier INT NOT NULL,
        number_of_seats INT NOT NULL,

        PRIMARY KEY (carriage_type_id)
    );

CREATE TABLE IF NOT EXISTS
    routes (
        route_id INT GENERATED ALWAYS AS IDENTITY,
        route_name VARCHAR(100) NOT NULL,
        base_segment_price INT NOT NULL DEFAULT 50,
        route_number VARCHAR(10) NOT NULL,
        route_status route_status NOT NULL DEFAULT 'UNACTIVE',
        schedule_rule schedule_rule NOT NULL,
        train_type train_type NOT NULL DEFAULT 'PASSENGER',

        PRIMARY KEY (route_id)
    );

CREATE TABLE IF NOT EXISTS
    carriages (
        carriage_id INT GENERATED ALWAYS AS IDENTITY,
        carriage_type_id INT NOT NULL,
        route_id INT,
        carriage_number INT,
        
        PRIMARY KEY (carriage_id),
        FOREIGN KEY (carriage_type_id) REFERENCES carriage_type_list (carriage_type_id),
        FOREIGN KEY (route_id) REFERENCES routes (route_id)
    );

CREATE TABLE IF NOT EXISTS
    seat_templates_list (
        seat_id INT GENERATED ALWAYS AS IDENTITY,
        carriage_type_id INT NOT NULL,
        seat_number INT NOT NULL,
        is_side BOOLEAN NOT NULL,
        tier_type tier_type NOT NULL DEFAULT 'DOWN',

        PRIMARY KEY (seat_id),
        FOREIGN KEY (carriage_type_id) REFERENCES carriage_type_list (carriage_type_id)
    );

CREATE TABLE IF NOT EXISTS
    trips (
        trip_id INT GENERATED ALWAYS AS IDENTITY,
        route_id INT NOT NULL,
        trip_date DATE NOT NULL,
        trip_status trip_status NOT NULL DEFAULT 'SCHEDULED',
        delay_minutes INT,

        PRIMARY KEY (trip_id),
        FOREIGN KEY (route_id) REFERENCES routes (route_id)
    );

CREATE TABLE IF NOT EXISTS
    stops (
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