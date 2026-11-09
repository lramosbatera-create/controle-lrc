-- Controle LRC — apagar a tabela antiga `alunos` (08/11/2026)
-- Rodar no SQL Editor do Supabase DO CONTROLE LRC (não no do Programa Nego Batera).
-- Os alunos do INB moram no Programa Nego Batera desde 13/08/2026; esta tabela era uma
-- cópia congelada. Backup: Documents\Projetos\LRC\Backups\controle-lrc-tabela-alunos-antiga-2026-11-08.json (36 linhas).
-- O app já não lê nem grava nela.

drop table if exists alunos;
