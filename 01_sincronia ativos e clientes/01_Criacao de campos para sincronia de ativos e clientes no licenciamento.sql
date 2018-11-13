alter table diretorio.clientes add cliente_erp_id uuid;
COMMENT ON COLUMN diretorio.clientes.cliente_erp_id IS 'Guid do participante na base da Nasajon';

alter table diretorio.licencas add contrato_id uuid;
COMMENT ON COLUMN diretorio.licencas.contrato_id IS 'Guid do contrato na base da Nasajon';