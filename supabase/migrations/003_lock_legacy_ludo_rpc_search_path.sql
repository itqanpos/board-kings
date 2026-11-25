begin;

alter function public.make_ludo_move(uuid, text, text, integer)
  set search_path = '';

commit;
