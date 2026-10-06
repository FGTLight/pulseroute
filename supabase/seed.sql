-- PulseRoute · Demo data
--
-- Sample incidents around two popular running/cycling spots in
-- Porto Alegre, Brazil: the Orla do Guaíba waterfront and Parque Farroupilha
-- (Redenção). Run after the migrations (the CLI does it on `supabase db reset`;
-- on a hosted project paste it in the SQL Editor).
--
-- Seed rows have no reporter (reporter_id is null) and bypass RLS because the
-- SQL Editor runs as the database owner.

insert into public.incidents
  (category, severity, description, location, radius_m, confirmations, created_at, expires_at)
values
  -- Orla do Guaíba (Trecho 1, from Usina do Gasômetro southwards)
  ('dark_area', 3, 'Waterfront path has no working lights after 8 pm.',
    'SRID=4326;POINT(-51.2405 -30.0391)', 180, 6, now() - interval '3 days', now() + interval '11 days'),
  ('pothole', 2, 'Deep pothole on the bike lane, hard to see at night.',
    'SRID=4326;POINT(-51.2398 -30.0447)', null, 3, now() - interval '1 day', now() + interval '13 days'),
  ('dangerous_crossing', 3, 'Cars run the red light at this crossing.',
    'SRID=4326;POINT(-51.2372 -30.0336)', null, 8, now() - interval '6 days', now() + interval '8 days'),
  ('closed_street', 2, 'Path closed for construction, detour through the park.',
    'SRID=4326;POINT(-51.2389 -30.0502)', null, 2, now() - interval '2 days', now() + interval '12 days'),
  ('no_sidewalk', 2, 'Sidewalk ends, runners have to use the road.',
    'SRID=4326;POINT(-51.2366 -30.0558)', null, 1, now() - interval '5 hours', now() + interval '14 days'),
  ('other', 1, 'Broken glass on the path near the kiosk.',
    'SRID=4326;POINT(-51.2414 -30.0369)', null, 0, now() - interval '2 hours', now() + interval '14 days'),

  -- Parque Farroupilha (Redenção) and surroundings
  ('dark_area', 2, 'Inner trail is very dark, avoid after sunset.',
    'SRID=4326;POINT(-51.2139 -30.0381)', 120, 4, now() - interval '4 days', now() + interval '10 days'),
  ('pothole', 3, 'Large hole in the asphalt, risk for cyclists.',
    'SRID=4326;POINT(-51.2118 -30.0352)', null, 5, now() - interval '1 day', now() + interval '13 days'),
  ('dangerous_crossing', 2, 'No crosswalk and fast traffic on Av. Osvaldo Aranha.',
    'SRID=4326;POINT(-51.2160 -30.0340)', null, 2, now() - interval '7 days', now() + interval '7 days'),
  ('closed_street', 1, 'Street fair on Sunday mornings, street closed to bikes.',
    'SRID=4326;POINT(-51.2097 -30.0393)', null, 1, now() - interval '3 hours', now() + interval '14 days'),
  ('no_sidewalk', 2, 'Sidewalk blocked by parked cars.',
    'SRID=4326;POINT(-51.2181 -30.0412)', null, 0, now() - interval '30 minutes', now() + interval '14 days'),
  ('other', 1, 'Loose dogs near the playground in the early morning.',
    'SRID=4326;POINT(-51.2125 -30.0405)', null, 2, now() - interval '9 days', now() + interval '5 days');
