CREATE UNIQUE INDEX clientes_cpf_idx  ON diretorio.clientes USING btree  (cpf);
CREATE UNIQUE INDEX clientes_cnpj_idx ON diretorio.clientes USING btree  (cnpj);