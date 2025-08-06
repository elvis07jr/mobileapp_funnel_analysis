-- Drop the table if it already exists to allow for a clean re-creation.
DROP TABLE IF EXISTS events;

-- Create the main events table to store all user-generated events.
CREATE TABLE events (
    user_id INT NOT NULL,
    event_name VARCHAR(255) NOT NULL,
    event_timestamp DATETIME NOT NULL,
    platform VARCHAR(50)
);

-- Add indexes to improve query performance.
-- Index on (user_id, event_timestamp) is crucial for time-series analysis and user journey tracking.
CREATE INDEX idx_user_timestamp ON events (user_id, event_timestamp);

-- Index on event_name is useful for quickly filtering by specific event types.
CREATE INDEX idx_event_name ON events (event_name);
