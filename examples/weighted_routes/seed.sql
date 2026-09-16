INSERT INTO routes.locations (name)
VALUES ('Depot'), ('A'), ('B'), ('C'), ('Store')
ON CONFLICT (name) DO NOTHING;

INSERT INTO routes.connections (
    from_location_id, to_location_id, distance_km, travel_minutes
)
SELECT source.id, destination.id, seeded.distance_km, seeded.travel_minutes
FROM (
    VALUES
        ('Depot', 'A', 2.0, 4),
        ('A', 'Store', 8.0, 8),
        ('Depot', 'B', 3.0, 3),
        ('B', 'C', 3.0, 3),
        ('C', 'Store', 3.0, 3),
        ('A', 'C', 2.0, 5),
        ('B', 'Store', 9.0, 7)
) AS seeded(source_name, destination_name, distance_km, travel_minutes)
JOIN routes.locations AS source ON source.name = seeded.source_name
JOIN routes.locations AS destination ON destination.name = seeded.destination_name
ON CONFLICT (from_location_id, to_location_id) DO UPDATE
SET distance_km = EXCLUDED.distance_km,
    travel_minutes = EXCLUDED.travel_minutes;
