/*
Ultima importação 11/10
*/

do
$$
begin

raise notice 'limpa os dados';
truncate 
DIRETORIO.licencasmetadados,diretorio.modulos,diretorio.atualizacoes,diretorio.historicos_validacoes,
diretorio.instalacoes,diretorio.licencas_servidores,diretorio.licencas,diretorio.provisoes ,
diretorio.tenants_administradores,diretorio.tenants_contas,diretorio.tenants_sistemas,diretorio.tenants_contas,
diretorio.grupos_permissoes,diretorio.grupos_entidades,diretorio.grupos,
diretorio.nasajon_sync,diretorio.tenants,diretorio.clientes,diretorio.servidores,
diretorio.aplicacoes;

truncate query_124;
truncate query_125;


raise notice 'apaga colunas novas';
begin
alter table diretorio.clientes drop cliente_erp_id;
alter table diretorio.licencas drop contrato_id;
exception
when others then
end;


raise notice 'reinsere os dados';
raise notice 'clientes';
copy diretorio.clientes from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\clientes.csv' with csv  HEADER delimiter ',';
raise notice 'consultas';
insert into query_124 select codigo,razaosocial,nomefantasia,regexp_replace(cpf, '[^0-9]', '', 'g') cpf,regexp_replace(cnpj, '[^0-9]', '', 'g') cnpj,id from diretorio.clientes;
copy query_125 from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\Licenciamento_- Clientes Nasajon_2018_10_31.csv' with csv  HEADER delimiter ',';
update query_125 set chavecnpj = coalesce(cnpj,cpf) where not cnpj isnull or not cpf isnull;
raise notice 'servidores';
alter table diretorio.servidores alter column metadados type text;
copy diretorio.servidores from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\servidores.csv' with csv  HEADER delimiter ',';
raise notice 'aplicações';
copy diretorio.aplicacoes from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\aplicacoes.csv' with csv  HEADER delimiter ',';
raise notice 'licencas';
truncate tmp_licencas;
copy tmp_licencas from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\licencas.csv' with csv  HEADER delimiter ',';
delete from diretorio.modulos;
delete from diretorio.atualizacoes;
delete from diretorio.instalacoes;
delete from diretorio.licencas;
insert into diretorio.licencas select * from tmp_licencas where cliente_id in (
select id from diretorio.clientes
);
raise notice 'modulos';
truncate tmp_modulos;
copy tmp_modulos from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\modulos.csv' with csv  HEADER delimiter ',';
insert into diretorio.modulos select * from tmp_modulos where licenca_id in (
select id from diretorio.licencas
);

raise notice 'instalações';
truncate tmp_instalacoes;
copy tmp_instalacoes(id,cliente_id,versao,datacriacao,nome,licenca_id,hash,ativa,servidor_id,ipinstalacao,ipultimaverificacao,dataultimaverificacao,ultimostatus,ultimamensagem) from 'C:\SPRINTS\36\dados diretorio\tarefas diretorio\02_coleta\instalacoes.csv' with csv  HEADER delimiter ',';
insert into diretorio.instalacoes select * from tmp_instalacoes where cliente_id in (
  select id from diretorio.clientes
)

--copy diretorio.historicos_validacoes from 'C:\SPRINTS\36\dados diretorio\historicos_validacoes.csv' with csv  HEADER delimiter ',';

update diretorio.clientes set cpf = cnpj where cpf is null and cnpj is not null;
update diretorio.clientes set cnpj = cpf where cnpj is null and cpf is not null;

alter table diretorio.clientes add cliente_erp_id uuid;
COMMENT ON COLUMN diretorio.clientes.cliente_erp_id IS 'Guid do participante na base da Nasajon';

alter table diretorio.licencas add contrato_id uuid;
COMMENT ON COLUMN diretorio.licencas.contrato_id IS 'Guid do contrato na base da Nasajon';


end;
$$;


--SELECT * FROM  DIRETORIO.instalacoes LIMIT 1


