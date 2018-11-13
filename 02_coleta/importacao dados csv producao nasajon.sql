/*
Ultima importação 11/10
*/

do
$$
begin

raise notice 'limpa os dados';
truncate itenscontratos,contratos, servicos;

raise notice 'servicos';
copy servicos from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\servicos.servicos.csv' with csv  HEADER delimiter '~';
copy servicos from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\servicos.servicos2.csv' with csv  HEADER delimiter '~';
update servicos set id_grupodeservico = '1d1f3055-8682-4de1-8d48-fa93091ab9ba' where upper(descricao) like '%SQL%';
raise notice 'contratos';
copy contratos from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\financas.contratos.csv' with csv  HEADER delimiter '~';
raise notice 'itenscontratos';
copy itenscontratos from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\financas.itenscontratos.csv' with csv  HEADER delimiter '~';


--apaga contratos nao sql
with marcar as (
select distinct contrato from itenscontratos ic
join servicos s on (s.id = ic.servico) 
where id_grupodeservico  = '1d1f3055-8682-4de1-8d48-fa93091ab9ba' and not cancelado and recorrente
)
update contratos set participante = '00000000-0000-0000-0000-000000000000'::uuid where not contrato in (select contrato from marcar);
end;
$$;

select * from itenscontratos where contrato = (
select * from contratos where codigo = '2008-10856' and participante <>  '00000000-0000-0000-0000-000000000000'
)
--SELECT * FROM  DIRETORIO.instalacoes LIMIT 1

select 
