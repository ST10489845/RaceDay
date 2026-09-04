
-- Drop database 
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'RaceDay')
BEGIN
    ALTER DATABASE RaceDay SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDay;
END
GO

-- Create Database
CREATE DATABASE RaceDay;
GO

USE RaceDay;
GO

-- ============================================
-- Table: Users
-- Stores user authentication and basic info
-- ============================================
CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('Organiser', 'Participant')),
    created_at DATETIME DEFAULT GETDATE(),
    last_login DATETIME NULL,
    is_active BIT DEFAULT 1
);
GO

-- ============================================
-- Table: Organisers
-- Extends Users for organiser-specific data
-- ============================================
CREATE TABLE Organisers (
    organiser_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    organisation_name VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    is_verified BIT DEFAULT 0,
    CONSTRAINT FK_Organisers_Users FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);
GO

-- ============================================
-- Table: Participants
-- Extends Users for participant-specific data
-- ============================================
CREATE TABLE Participants (
    participant_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    emergency_contact_name VARCHAR(100) NOT NULL,
    emergency_contact_phone VARCHAR(20) NOT NULL,
    medical_conditions VARCHAR(MAX) NULL,
    CONSTRAINT FK_Participants_Users FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);
GO

-- ============================================
-- Table: Events
-- Main event information
-- ============================================
CREATE TABLE Events (
    event_id INT IDENTITY(1,1) PRIMARY KEY,
    organiser_id INT NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_description VARCHAR(MAX) NULL,
    event_date DATETIME NOT NULL,
    registration_deadline DATETIME NOT NULL,
    venue VARCHAR(200) NOT NULL,
    city VARCHAR(50) NOT NULL,
    province VARCHAR(50) NOT NULL,
    is_active BIT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Events_Organisers FOREIGN KEY (organiser_id) REFERENCES Organisers(organiser_id) ON DELETE CASCADE,
    CONSTRAINT CHK_RegistrationDeadline CHECK (registration_deadline <= event_date)
);
GO

-- ============================================
-- Table: Categories
-- Event categories with distance and eligibility
-- ============================================
CREATE TABLE Categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    event_id INT NOT NULL,
    category_name VARCHAR(50) NOT NULL,
    category_type VARCHAR(20) NOT NULL CHECK (category_type IN ('Running', 'Walking', 'Cycling')),
    distance_km DECIMAL(5,2) NOT NULL,
    age_min INT NULL,
    age_max INT NULL,
    gender_restriction VARCHAR(10) NULL CHECK (gender_restriction IN ('Male', 'Female', NULL)),
    entry_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    max_participants INT NULL,
    CONSTRAINT FK_Categories_Events FOREIGN KEY (event_id) REFERENCES Events(event_id) ON DELETE CASCADE,
    CONSTRAINT CHK_AgeRange CHECK (age_min <= age_max)
);
GO

-- ============================================
-- Table: Enrolments
-- Participant registrations for events
-- ============================================
CREATE TABLE Enrolments (
    enrolment_id INT IDENTITY(1,1) PRIMARY KEY,
    participant_id INT NOT NULL,
    category_id INT NOT NULL,
    event_id INT NOT NULL,
    enrolment_date DATETIME DEFAULT GETDATE(),
    status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Confirmed', 'Paid', 'Cancelled', 'Withdrawn')),
    paid BIT DEFAULT 0,
    bib_number INT NULL,
    start_time TIME NULL,
    CONSTRAINT FK_Enrolments_Participants FOREIGN KEY (participant_id) REFERENCES Participants(participant_id) ON DELETE CASCADE,
    CONSTRAINT FK_Enrolments_Categories FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    CONSTRAINT FK_Enrolments_Events FOREIGN KEY (event_id) REFERENCES Events(event_id),
    CONSTRAINT UQ_Participant_Event_Category UNIQUE (participant_id, event_id, category_id),
    CONSTRAINT UQ_BibNumber_Event UNIQUE (event_id, bib_number)
);
GO

-- ============================================
-- Table: Results
-- Participant race results
-- ============================================
CREATE TABLE Results (
    result_id INT IDENTITY(1,1) PRIMARY KEY,
    enrolment_id INT NOT NULL,
    participant_id INT NOT NULL,
    event_id INT NOT NULL,
    category_id INT NOT NULL,
    finish_time TIME NOT NULL,
    overall_rank INT NULL,
    category_rank INT NULL,
    is_verified BIT DEFAULT 0,
    verified_by INT NULL,
    verified_at DATETIME NULL,
    CONSTRAINT FK_Results_Enrolments FOREIGN KEY (enrolment_id) REFERENCES Enrolments(enrolment_id) ON DELETE CASCADE,
    CONSTRAINT FK_Results_Participants FOREIGN KEY (participant_id) REFERENCES Participants(participant_id),
    CONSTRAINT FK_Results_Events FOREIGN KEY (event_id) REFERENCES Events(event_id),
    CONSTRAINT FK_Results_Categories FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    CONSTRAINT FK_Results_VerifiedBy FOREIGN KEY (verified_by) REFERENCES Organisers(organiser_id)
);
GO

-- ============================================
-- Table: Weather_Info
-- Event weather forecasts
-- ============================================
CREATE TABLE Weather_Info (
    weather_id INT IDENTITY(1,1) PRIMARY KEY,
    event_id INT NOT NULL,
    forecast_date DATE NOT NULL,
    temperature_high INT NULL,
    temperature_low INT NULL,
    conditions VARCHAR(50) NULL,
    wind_speed INT NULL,
    humidity INT NULL,
    last_updated DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Weather_Info_Events FOREIGN KEY (event_id) REFERENCES Events(event_id) ON DELETE CASCADE
);
GO

-- ============================================
-- Table: Route_Info
-- Event route information
-- ============================================
CREATE TABLE Route_Info (
    route_id INT IDENTITY(1,1) PRIMARY KEY,
    event_id INT NOT NULL,
    route_name VARCHAR(100) NOT NULL,
    route_description VARCHAR(MAX) NULL,
    start_point VARCHAR(200) NOT NULL,
    end_point VARCHAR(200) NOT NULL,
    elevation_gain INT NULL,
    elevation_loss INT NULL,
    route_gpx VARCHAR(MAX) NULL,
    last_updated DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Route_Info_Events FOREIGN KEY (event_id) REFERENCES Events(event_id) ON DELETE CASCADE
);
GO

-- ============================================
-- INSERT SAMPLE DATA
-- ============================================

-- 1. Insert Users (2 Organisers, 4 Participants)
INSERT INTO Users (email, password_hash, full_name, role, created_at, is_active)
VALUES 
    ('john.organiser@email.com', '$2a$12$HASHED_PASSWORD', 'John Smith', 'Organiser', GETDATE(), 1),
    ('sarah.organiser@email.com', '$2a$12$HASHED_PASSWORD', 'Sarah Johnson', 'Organiser', GETDATE(), 1),
    ('mike.runner@email.com', '$2a$12$HASHED_PASSWORD', 'Mike Thompson', 'Participant', GETDATE(), 1),
    ('lisa.walker@email.com', '$2a$12$HASHED_PASSWORD', 'Lisa Williams', 'Participant', GETDATE(), 1),
    ('david.cyclist@email.com', '$2a$12$HASHED_PASSWORD', 'David Brown', 'Participant', GETDATE(), 1),
    ('anna.marathon@email.com', '$2a$12$HASHED_PASSWORD', 'Anna Davis', 'Participant', GETDATE(), 1);
GO

-- 2. Insert Organisers
INSERT INTO Organisers (user_id, organisation_name, contact_phone, is_verified)
VALUES 
    (1, 'Cape Town Events', '+27 82 123 4567', 1),
    (2, 'Joburg Running Club', '+27 83 987 6543', 1);
GO

-- 3. Insert Participants
INSERT INTO Participants (user_id, date_of_birth, gender, emergency_contact_name, emergency_contact_phone, medical_conditions)
VALUES 
    (3, '1990-05-15', 'Male', 'Jane Thompson', '+27 84 456 7890', NULL),
    (4, '1985-09-22', 'Female', 'Mark Williams', '+27 73 654 3210', 'Asthma'),
    (5, '1992-11-03', 'Male', 'Emma Brown', '+27 72 789 0123', NULL),
    (6, '1988-07-08', 'Female', 'Tom Davis', '+27 76 321 6547', NULL);
GO

-- 4. Insert Events
INSERT INTO Events (organiser_id, event_name, event_description, event_date, registration_deadline, venue, city, province, is_active)
VALUES 
    (1, 'Cape Town Cycle Tour', 'World-renowned cycling event through Cape Town', '2026-03-08 06:00:00', '2026-02-28 23:59:59', 'Cape Town Stadium', 'Cape Town', 'Western Cape', 1),
    (1, 'Two Oceans Marathon', 'Ultra-marathon in Cape Town', '2026-04-18 05:30:00', '2026-04-10 23:59:59', 'Newlands Stadium', 'Cape Town', 'Western Cape', 1),
    (2, 'Soweto Marathon', 'Historic marathon through Soweto', '2026-11-01 06:00:00', '2026-10-25 23:59:59', 'FNB Stadium', 'Johannesburg', 'Gauteng', 1),
    (2, 'Joburg 10km Run', '10km road race in Johannesburg', '2026-05-24 07:00:00', '2026-05-18 23:59:59', 'Sandton City', 'Johannesburg', 'Gauteng', 1);
GO

-- 5. Insert Categories
INSERT INTO Categories (event_id, category_name, category_type, distance_km, age_min, age_max, gender_restriction, entry_fee, max_participants)
VALUES 
    -- Cape Town Cycle Tour categories
    (1, 'Men 18-34', 'Cycling', 109.00, 18, 34, 'Male', 250.00, 500),
    (1, 'Men 35-49', 'Cycling', 109.00, 35, 49, 'Male', 250.00, 500),
    (1, 'Women 18-34', 'Cycling', 109.00, 18, 34, 'Female', 250.00, 500),
    (1, 'Women 35-49', 'Cycling', 109.00, 35, 49, 'Female', 250.00, 500),
    
    -- Two Oceans Marathon categories
    (2, 'Ultra Marathon Men', 'Running', 56.00, 20, NULL, 'Male', 350.00, 3000),
    (2, 'Ultra Marathon Women', 'Running', 56.00, 20, NULL, 'Female', 350.00, 3000),
    (2, 'Half Marathon Men', 'Running', 21.10, 16, NULL, 'Male', 180.00, 4000),
    (2, 'Half Marathon Women', 'Running', 21.10, 16, NULL, 'Female', 180.00, 4000),
    
    -- Soweto Marathon categories
    (3, 'Full Marathon Men', 'Running', 42.20, 18, NULL, 'Male', 300.00, 5000),
    (3, 'Full Marathon Women', 'Running', 42.20, 18, NULL, 'Female', 300.00, 5000),
    (3, '10km Run Men', 'Running', 10.00, 12, NULL, 'Male', 100.00, 3000),
    (3, '10km Run Women', 'Running', 10.00, 12, NULL, 'Female', 100.00, 3000),
    
    -- Joburg 10km Run categories
    (4, 'Men Open', 'Running', 10.00, 16, NULL, 'Male', 80.00, 2000),
    (4, 'Women Open', 'Running', 10.00, 16, NULL, 'Female', 80.00, 2000),
    (4, 'Junior Boys', 'Running', 10.00, 10, 15, 'Male', 50.00, 500),
    (4, 'Junior Girls', 'Running', 10.00, 10, 15, 'Female', 50.00, 500);
GO

-- 6. Insert Enrolments
INSERT INTO Enrolments (participant_id, category_id, event_id, enrolment_date, status, paid, bib_number, start_time)
VALUES 
    (1, 1, 1, DATEADD(day, -30, GETDATE()), 'Confirmed', 1, 101, '06:30:00'),
    (1, 6, 2, DATEADD(day, -45, GETDATE()), 'Paid', 1, 201, '05:45:00'),
    (2, 2, 1, DATEADD(day, -25, GETDATE()), 'Confirmed', 1, 102, '06:45:00'),
    (2, 5, 2, DATEADD(day, -50, GETDATE()), 'Paid', 1, 202, '05:30:00'),
    (3, 9, 3, DATEADD(day, -60, GETDATE()), 'Confirmed', 1, 301, '06:15:00'),
    (3, 14, 4, DATEADD(day, -20, GETDATE()), 'Pending', 0, 401, '07:00:00'),
    (4, 10, 3, DATEADD(day, -55, GETDATE()), 'Paid', 1, 302, '06:20:00'),
    (4, 13, 4, DATEADD(day, -18, GETDATE()), 'Confirmed', 1, 402, '07:15:00');
GO

-- 7. Insert Results
INSERT INTO Results (enrolment_id, participant_id, event_id, category_id, finish_time, overall_rank, category_rank, is_verified, verified_by, verified_at)
VALUES 
    (1, 1, 1, 1, '02:45:30', 15, 2, 1, 1, GETDATE()),
    (3, 2, 1, 2, '02:52:15', 25, 5, 1, 1, GETDATE()),
    (2, 1, 2, 6, '04:12:45', 8, 1, 1, 1, GETDATE()),
    (4, 2, 2, 5, '05:08:20', 45, 12, 1, 1, GETDATE()),
    (1, 1, 1, 1, '02:44:50', 14, 1, 0, NULL, NULL);
GO

-- 8. Insert Weather Info
INSERT INTO Weather_Info (event_id, forecast_date, temperature_high, temperature_low, conditions, wind_speed, humidity)
VALUES 
    (1, '2026-03-08', 28, 18, 'Sunny', 15, 65),
    (2, '2026-04-18', 22, 14, 'Partly Cloudy', 20, 70),
    (3, '2026-11-01', 25, 16, 'Clear', 10, 55),
    (4, '2026-05-24', 23, 15, 'Cloudy', 12, 60);
GO

-- 9. Insert Route Info
INSERT INTO Route_Info (event_id, route_name, route_description, start_point, end_point, elevation_gain, elevation_loss, route_gpx)
VALUES 
    (1, 'Cape Town Cycle Tour Route', 'Scenic route along the coast and through Cape Town', 'Cape Town Stadium', 'Cape Town Stadium', 800, 800, '[GPX Data]'),
    (2, 'Two Oceans Ultra Route', 'Challenging route with Chapman''s Peak', 'Newlands Stadium', 'Newlands Stadium', 1200, 1200, '[GPX Data]'),
    (3, 'Soweto Marathon Route', 'Historic route through Soweto townships', 'FNB Stadium', 'FNB Stadium', 500, 500, '[GPX Data]'),
    (4, 'Joburg 10km Route', 'Urban route through Sandton', 'Sandton City', 'Sandton City', 200, 200, '[GPX Data]');
GO

-- ============================================
-- CREATE VIEWS 
-- ============================================

-- View: Event Participants with Enrolment Details
CREATE VIEW vw_EventParticipants AS
SELECT 
    e.event_id,
    e.event_name,
    e.event_date,
    u.full_name AS participant_name,
    p.participant_id,
    c.category_name,
    c.distance_km,
    en.status,
    en.bib_number,
    en.enrolment_date,
    en.paid
FROM Events e
JOIN Enrolments en ON e.event_id = en.event_id
JOIN Participants p ON en.participant_id = p.participant_id
JOIN Users u ON p.user_id = u.user_id
JOIN Categories c ON en.category_id = c.category_id;
GO

-- View: Event Results Summary
CREATE VIEW vw_EventResults AS
SELECT 
    e.event_id,
    e.event_name,
    e.event_date,
    u.full_name AS participant_name,
    p.participant_id,
    c.category_name,
    c.distance_km,
    r.finish_time,
    r.overall_rank,
    r.category_rank,
    r.is_verified,
    r.verified_at,
    o.full_name AS verified_by_name
FROM Events e
JOIN Results r ON e.event_id = r.event_id
JOIN Participants p ON r.participant_id = p.participant_id
JOIN Users u ON p.user_id = u.user_id
JOIN Categories c ON r.category_id = c.category_id
LEFT JOIN Organisers org ON r.verified_by = org.organiser_id
LEFT JOIN Users o ON org.user_id = o.user_id;
GO

-- View: Organiser Dashboard
CREATE VIEW vw_OrganiserDashboard AS
SELECT 
    o.organiser_id,
    u.full_name AS organiser_name,
    COUNT(DISTINCT e.event_id) AS total_events,
    COUNT(DISTINCT en.enrolment_id) AS total_enrolments,
    COUNT(DISTINCT r.result_id) AS total_results,
    ISNULL(SUM(CASE WHEN en.paid = 1 THEN c.entry_fee ELSE 0 END), 0) AS total_revenue,
    ISNULL(AVG(CASE WHEN en.paid = 1 THEN c.entry_fee ELSE NULL END), 0) AS average_entry_fee
FROM Organisers o
JOIN Users u ON o.user_id = u.user_id
LEFT JOIN Events e ON o.organiser_id = e.organiser_id
LEFT JOIN Enrolments en ON e.event_id = en.event_id
LEFT JOIN Categories c ON en.category_id = c.category_id
LEFT JOIN Results r ON en.enrolment_id = r.enrolment_id
GROUP BY o.organiser_id, u.full_name;
GO

-- View: Participant Performance Summary 
CREATE VIEW vw_ParticipantPerformance AS
SELECT 
    p.participant_id,
    u.full_name AS participant_name,
    ISNULL(COUNT(DISTINCT r.result_id), 0) AS total_races_completed,
    MIN(r.finish_time) AS personal_best_time,
    CASE 
        WHEN COUNT(DISTINCT r.result_id) > 0 
        THEN DATEADD(SECOND, AVG(DATEDIFF(SECOND, '00:00:00', r.finish_time)), '00:00:00')
        ELSE NULL 
    END AS average_finish_time,
    ISNULL(AVG(CAST(r.overall_rank AS FLOAT)), 0) AS average_rank,
    ISNULL(COUNT(DISTINCT e.event_id), 0) AS total_events_entered
FROM Participants p
JOIN Users u ON p.user_id = u.user_id
LEFT JOIN Enrolments en ON p.participant_id = en.participant_id
LEFT JOIN Events e ON en.event_id = e.event_id
LEFT JOIN Results r ON p.participant_id = r.participant_id
GROUP BY p.participant_id, u.full_name;
GO

-- View: Event Analytics 
CREATE VIEW vw_EventAnalytics AS
SELECT 
    e.event_id,
    e.event_name,
    e.event_date,
    ISNULL(COUNT(DISTINCT en.enrolment_id), 0) AS total_entries,
    ISNULL(COUNT(DISTINCT CASE WHEN en.paid = 1 THEN en.enrolment_id END), 0) AS paid_entries,
    ISNULL(COUNT(DISTINCT r.result_id), 0) AS total_finishers,
    ISNULL(SUM(CASE WHEN en.paid = 1 THEN c.entry_fee ELSE 0 END), 0) AS total_revenue,
    -- Convert TIME to seconds, average, then convert back to TIME
    CASE 
        WHEN COUNT(DISTINCT r.result_id) > 0 
        THEN DATEADD(SECOND, AVG(DATEDIFF(SECOND, '00:00:00', r.finish_time)), '00:00:00')
        ELSE NULL 
    END AS average_finish_time
FROM Events e
LEFT JOIN Enrolments en ON e.event_id = en.event_id
LEFT JOIN Categories c ON en.category_id = c.category_id
LEFT JOIN Results r ON en.enrolment_id = r.enrolment_id
GROUP BY e.event_id, e.event_name, e.event_date;
GO

-- ============================================
-- CREATE INDEXES
-- ============================================

CREATE INDEX idx_users_email ON Users(email);
CREATE INDEX idx_users_role ON Users(role);
CREATE INDEX idx_enrolments_participant ON Enrolments(participant_id);
CREATE INDEX idx_enrolments_event ON Enrolments(event_id);
CREATE INDEX idx_enrolments_category ON Enrolments(category_id);
CREATE INDEX idx_enrolments_status ON Enrolments(status);
CREATE INDEX idx_results_participant ON Results(participant_id);
CREATE INDEX idx_results_event ON Results(event_id);
CREATE INDEX idx_results_category ON Results(category_id);
CREATE INDEX idx_events_organiser ON Events(organiser_id);
CREATE INDEX idx_events_date ON Events(event_date);
CREATE INDEX idx_categories_event ON Categories(event_id);
CREATE INDEX idx_weather_event ON Weather_Info(event_id);
CREATE INDEX idx_route_event ON Route_Info(event_id);
GO

-- ============================================
-- SELECT QUERIES FOR TESTING AND VERIFICATION
-- ============================================

PRINT '============================================';
PRINT 'TESTING SELECT QUERIES';
PRINT '============================================';
GO

-- 1. View all Users
PRINT '1. All Users:';
SELECT * FROM Users;
GO

-- 2. View all Organisers with their user details
PRINT '2. All Organisers:';
SELECT 
    o.organiser_id,
    u.email,
    u.full_name,
    o.organisation_name,
    o.contact_phone,
    o.is_verified
FROM Organisers o
JOIN Users u ON o.user_id = u.user_id;
GO

-- 3. View all Participants with their user details
PRINT '3. All Participants:';
SELECT 
    p.participant_id,
    u.email,
    u.full_name,
    p.date_of_birth,
    p.gender,
    p.emergency_contact_name,
    p.emergency_contact_phone,
    p.medical_conditions
FROM Participants p
JOIN Users u ON p.user_id = u.user_id;
GO

-- 4. View all Events
PRINT '4. All Events:';
SELECT 
    e.event_id,
    e.event_name,
    e.event_description,
    e.event_date,
    e.registration_deadline,
    e.venue,
    e.city,
    e.province,
    e.is_active,
    u.full_name AS organiser_name
FROM Events e
JOIN Organisers o ON e.organiser_id = o.organiser_id
JOIN Users u ON o.user_id = u.user_id;
GO

-- 5. View all Categories with Event details
PRINT '5. All Categories:';
SELECT 
    c.category_id,
    e.event_name,
    c.category_name,
    c.category_type,
    c.distance_km,
    c.age_min,
    c.age_max,
    c.gender_restriction,
    c.entry_fee,
    c.max_participants
FROM Categories c
JOIN Events e ON c.event_id = e.event_id;
GO

-- 6. View all Enrolments
PRINT '6. All Enrolments:';
SELECT 
    en.enrolment_id,
    u.full_name AS participant_name,
    e.event_name,
    c.category_name,
    en.enrolment_date,
    en.status,
    en.paid,
    en.bib_number,
    en.start_time
FROM Enrolments en
JOIN Participants p ON en.participant_id = p.participant_id
JOIN Users u ON p.user_id = u.user_id
JOIN Events e ON en.event_id = e.event_id
JOIN Categories c ON en.category_id = c.category_id;
GO

-- 7. View all Results
PRINT '7. All Results:';
SELECT 
    r.result_id,
    u.full_name AS participant_name,
    e.event_name,
    c.category_name,
    r.finish_time,
    r.overall_rank,
    r.category_rank,
    r.is_verified,
    r.verified_at,
    ver.full_name AS verified_by_name
FROM Results r
JOIN Participants p ON r.participant_id = p.participant_id
JOIN Users u ON p.user_id = u.user_id
JOIN Events e ON r.event_id = e.event_id
JOIN Categories c ON r.category_id = c.category_id
LEFT JOIN Organisers org ON r.verified_by = org.organiser_id
LEFT JOIN Users ver ON org.user_id = ver.user_id;
GO

-- 8. View Weather Info
PRINT '8. Weather Information:';
SELECT 
    wi.weather_id,
    e.event_name,
    wi.forecast_date,
    wi.temperature_high,
    wi.temperature_low,
    wi.conditions,
    wi.wind_speed,
    wi.humidity,
    wi.last_updated
FROM Weather_Info wi
JOIN Events e ON wi.event_id = e.event_id;
GO

-- 9. View Route Info
PRINT '9. Route Information:';
SELECT 
    ri.route_id,
    e.event_name,
    ri.route_name,
    ri.route_description,
    ri.start_point,
    ri.end_point,
    ri.elevation_gain,
    ri.elevation_loss,
    ri.last_updated
FROM Route_Info ri
JOIN Events e ON ri.event_id = e.event_id;
GO

-- 10. Event Participants View
PRINT '10. Event Participants (View):';
SELECT * FROM vw_EventParticipants;
GO

-- 11. Event Results View
PRINT '11. Event Results (View):';
SELECT * FROM vw_EventResults;
GO

-- 12. Organiser Dashboard View
PRINT '12. Organiser Dashboard (View):';
SELECT * FROM vw_OrganiserDashboard;
GO

-- 13. Participant Performance View - FIXED
PRINT '13. Participant Performance (View):';
SELECT * FROM vw_ParticipantPerformance;
GO

-- 14. Event Analytics View - FIXED
PRINT '14. Event Analytics (View):';
SELECT * FROM vw_EventAnalytics;
GO

-- 15. Find all events in a specific city (Cape Town)
PRINT '15. Events in Cape Town:';
SELECT * FROM Events WHERE city = 'Cape Town';
GO

-- 16. Find all paid enrolments
PRINT '16. Paid Enrolments:';
SELECT 
    u.full_name,
    e.event_name,
    c.category_name,
    en.paid,
    en.status
FROM Enrolments en
JOIN Participants p ON en.participant_id = p.participant_id
JOIN Users u ON p.user_id = u.user_id
JOIN Events e ON en.event_id = e.event_id
JOIN Categories c ON en.category_id = c.category_id
WHERE en.paid = 1;
GO

-- 17. Find all verified results
PRINT '17. Verified Results:';
SELECT 
    u.full_name,
    e.event_name,
    c.category_name,
    r.finish_time,
    r.overall_rank,
    r.category_rank
FROM Results r
JOIN Participants p ON r.participant_id = p.participant_id
JOIN Users u ON p.user_id = u.user_id
JOIN Events e ON r.event_id = e.event_id
JOIN Categories c ON r.category_id = c.category_id
WHERE r.is_verified = 1;
GO

-- 18. Count participants per event
PRINT '18. Participant Count per Event:';
SELECT 
    e.event_name,
    COUNT(en.enrolment_id) AS total_participants
FROM Events e
LEFT JOIN Enrolments en ON e.event_id = en.event_id
GROUP BY e.event_name
ORDER BY total_participants DESC;
GO

-- 19. Total revenue per event
PRINT '19. Total Revenue per Event:';
SELECT 
    e.event_name,
    ISNULL(SUM(c.entry_fee), 0) AS total_revenue,
    COUNT(en.enrolment_id) AS participants
FROM Events e
JOIN Enrolments en ON e.event_id = en.event_id
JOIN Categories c ON en.category_id = c.category_id
WHERE en.paid = 1
GROUP BY e.event_name
ORDER BY total_revenue DESC;
GO

-- 20. Top 5 fastest finishers overall
PRINT '20. Top 5 Fastest Finishers:';
SELECT TOP 5
    u.full_name,
    e.event_name,
    c.category_name,
    r.finish_time,
    r.overall_rank
FROM Results r
JOIN Participants p ON r.participant_id = p.participant_id
JOIN Users u ON p.user_id = u.user_id
JOIN Events e ON r.event_id = e.event_id
JOIN Categories c ON r.category_id = c.category_id
WHERE r.is_verified = 1
ORDER BY r.finish_time;
GO

-- 21. Participants with medical conditions
PRINT '21. Participants with Medical Conditions:';
SELECT 
    u.full_name,
    p.medical_conditions,
    COUNT(en.enrolment_id) AS events_entered
FROM Participants p
JOIN Users u ON p.user_id = u.user_id
LEFT JOIN Enrolments en ON p.participant_id = en.participant_id
WHERE p.medical_conditions IS NOT NULL
GROUP BY u.full_name, p.medical_conditions;
GO

-- 22. Event capacity analysis
PRINT '22. Event Capacity Analysis:';
SELECT 
    e.event_name,
    c.category_name,
    c.max_participants,
    COUNT(en.enrolment_id) AS current_participants,
    CASE 
        WHEN c.max_participants IS NULL THEN 'No Limit'
        WHEN COUNT(en.enrolment_id) >= c.max_participants THEN 'FULL'
        ELSE 'Available'
    END AS status
FROM Categories c
JOIN Events e ON c.event_id = e.event_id
LEFT JOIN Enrolments en ON c.category_id = en.category_id
GROUP BY e.event_name, c.category_name, c.max_participants
ORDER BY e.event_name, c.category_name;
GO

-- 23. Participant summary - FIXED
PRINT '23. Participant Summary (Total events, races completed, etc):';
SELECT 
    u.full_name,
    ISNULL(COUNT(DISTINCT en.event_id), 0) AS events_entered,
    ISNULL(COUNT(DISTINCT r.result_id), 0) AS races_completed,
    MIN(r.finish_time) AS personal_best,
    ISNULL(AVG(CAST(r.overall_rank AS FLOAT)), 0) AS avg_rank
FROM Users u
JOIN Participants p ON u.user_id = p.user_id
LEFT JOIN Enrolments en ON p.participant_id = en.participant_id
LEFT JOIN Results r ON p.participant_id = r.participant_id
WHERE u.role = 'Participant'
GROUP BY u.full_name;
GO

-- 24. Upcoming events (next 30 days)
PRINT '24. Upcoming Events (Next 30 Days):';
SELECT 
    event_name,
    event_date,
    city,
    province,
    DATEDIFF(day, GETDATE(), event_date) AS days_until
FROM Events
WHERE event_date > GETDATE() 
    AND event_date <= DATEADD(day, 30, GETDATE())
    AND is_active = 1
ORDER BY event_date;
GO

-- 25. Database statistics
PRINT '25. Database Statistics:';
SELECT 
    (SELECT COUNT(*) FROM Users) AS total_users,
    (SELECT COUNT(*) FROM Organisers) AS total_organisers,
    (SELECT COUNT(*) FROM Participants) AS total_participants,
    (SELECT COUNT(*) FROM Events) AS total_events,
    (SELECT COUNT(*) FROM Categories) AS total_categories,
    (SELECT COUNT(*) FROM Enrolments) AS total_enrolments,
    (SELECT COUNT(*) FROM Results) AS total_results,
    (SELECT COUNT(*) FROM Weather_Info) AS weather_records,
    (SELECT COUNT(*) FROM Route_Info) AS route_records;
GO

-- ============================================
-- STORED PROCEDURES
-- ============================================

-- Stored Procedure: Enrol Participant
CREATE PROCEDURE sp_EnrolParticipant
    @participant_id INT,
    @category_id INT,
    @event_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    -- Check if already enrolled
    IF EXISTS (
        SELECT 1 FROM Enrolments 
        WHERE participant_id = @participant_id 
        AND event_id = @event_id 
        AND category_id = @category_id
    )
    BEGIN
        RAISERROR('Participant is already enrolled in this event category', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    -- Check if event is still accepting registrations
    DECLARE @registration_deadline DATETIME;
    SELECT @registration_deadline = registration_deadline 
    FROM Events 
    WHERE event_id = @event_id;
    
    IF @registration_deadline < GETDATE()
    BEGIN
        RAISERROR('Registration deadline has passed', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    -- Check if category has space
    DECLARE @max_participants INT;
    DECLARE @current_count INT;
    
    SELECT @max_participants = max_participants 
    FROM Categories 
    WHERE category_id = @category_id;
    
    SELECT @current_count = COUNT(*) 
    FROM Enrolments 
    WHERE category_id = @category_id 
    AND status IN ('Pending', 'Confirmed', 'Paid');
    
    IF @max_participants IS NOT NULL AND @current_count >= @max_participants
    BEGIN
        RAISERROR('Category is full', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    -- Generate bib number
    DECLARE @bib_number INT;
    SELECT @bib_number = ISNULL(MAX(bib_number), 0) + 1 
    FROM Enrolments 
    WHERE event_id = @event_id;
    
    -- Insert enrolment
    INSERT INTO Enrolments (
        participant_id, 
        category_id, 
        event_id, 
        enrolment_date, 
        status, 
        paid, 
        bib_number
    )
    VALUES (
        @participant_id, 
        @category_id, 
        @event_id, 
        GETDATE(), 
        'Pending', 
        0, 
        @bib_number
    );
    
    COMMIT TRANSACTION;
    
    SELECT 'Enrolment successful' AS Message, @bib_number AS BibNumber;
END;
GO

-- Stored Procedure: Record Result
CREATE PROCEDURE sp_RecordResult
    @enrolment_id INT,
    @finish_time TIME,
    @overall_rank INT = NULL,
    @category_rank INT = NULL,
    @verified_by INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    DECLARE @participant_id INT;
    DECLARE @event_id INT;
    DECLARE @category_id INT;
    
    -- Get enrolment details
    SELECT 
        @participant_id = participant_id,
        @event_id = event_id,
        @category_id = category_id
    FROM Enrolments 
    WHERE enrolment_id = @enrolment_id;
    
    IF @participant_id IS NULL
    BEGIN
        RAISERROR('Enrolment not found', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    -- Insert result
    INSERT INTO Results (
        enrolment_id,
        participant_id,
        event_id,
        category_id,
        finish_time,
        overall_rank,
        category_rank,
        is_verified,
        verified_by,
        verified_at
    )
    VALUES (
        @enrolment_id,
        @participant_id,
        @event_id,
        @category_id,
        @finish_time,
        @overall_rank,
        @category_rank,
        CASE WHEN @verified_by IS NOT NULL THEN 1 ELSE 0 END,
        @verified_by,
        CASE WHEN @verified_by IS NOT NULL THEN GETDATE() ELSE NULL END
    );
    
    -- Update enrolment status
    UPDATE Enrolments 
    SET status = 'Confirmed' 
    WHERE enrolment_id = @enrolment_id;
    
    COMMIT TRANSACTION;
    
    SELECT 'Result recorded successfully' AS Message;
END;
GO

-- Stored Procedure: Get Participant Results
CREATE PROCEDURE sp_GetParticipantResults
    @participant_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        e.event_name,
        e.event_date,
        c.category_name,
        c.distance_km,
        r.finish_time,
        r.overall_rank,
        r.category_rank,
        r.is_verified,
        r.verified_at
    FROM Results r
    JOIN Events e ON r.event_id = e.event_id
    JOIN Categories c ON r.category_id = c.category_id
    WHERE r.participant_id = @participant_id
    ORDER BY e.event_date DESC;
END;
GO

-- Stored Procedure: Get Event Results
CREATE PROCEDURE sp_GetEventResults
    @event_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.full_name AS participant_name,
        c.category_name,
        r.finish_time,
        r.overall_rank,
        r.category_rank,
        r.is_verified
    FROM Results r
    JOIN Participants p ON r.participant_id = p.participant_id
    JOIN Users u ON p.user_id = u.user_id
    JOIN Categories c ON r.category_id = c.category_id
    WHERE r.event_id = @event_id
    ORDER BY r.overall_rank;
END;
GO

-- ============================================
-- FINAL OUTPUT
-- ============================================
PRINT '============================================';
PRINT 'RaceDay Database Created Successfully!';
PRINT '============================================';
PRINT 'Tables Created:';
PRINT '  - Users';
PRINT '  - Organisers';
PRINT '  - Participants';
PRINT '  - Events';
PRINT '  - Categories';
PRINT '  - Enrolments';
PRINT '  - Results';
PRINT '  - Weather_Info';
PRINT '  - Route_Info';
PRINT '';
PRINT 'Sample Data Inserted:';
PRINT '  - 2 Organisers';
PRINT '  - 4 Participants';
PRINT '  - 4 Events';
PRINT '  - 16 Categories';
PRINT '  - 8 Enrolments';
PRINT '  - 5 Results';
PRINT '  - 4 Weather Records';
PRINT '  - 4 Route Records';
PRINT '';
PRINT 'Views Created:';
PRINT '  - vw_EventParticipants';
PRINT '  - vw_EventResults';
PRINT '  - vw_OrganiserDashboard';
PRINT '  - vw_ParticipantPerformance';
PRINT '  - vw_EventAnalytics';
PRINT '';
PRINT 'Stored Procedures Created:';
PRINT '  - sp_EnrolParticipant';
PRINT '  - sp_RecordResult';
PRINT '  - sp_GetParticipantResults';
PRINT '  - sp_GetEventResults';
PRINT '============================================';
GO