-- OPTIONAL: run only if you want sample companies. Does not create auth users.
insert into public.shipping_companies(name, code, phone, website)
values
 ('Amana','AMANA',null,'https://www.poste.ma'),
 ('Chronopost Maroc','CHRONOPOST',null,'https://www.chronopost.ma')
on conflict (name) do nothing;
