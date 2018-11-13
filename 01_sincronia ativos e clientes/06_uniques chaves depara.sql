alter table diretorio.clientes add constraint "UK_clientes_cliente_erp_id" unique(cliente_erp_id);

alter table diretorio.licencas add constraint "UK_licencas_contrato_id" unique(contrato_id);