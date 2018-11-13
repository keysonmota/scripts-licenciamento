drop function if exists diretorio.atualizar_dados_ativo(json);
create or replace function diretorio.atualizar_dados_ativo(ativo json) 
returns void as
$$
declare

OP_NOVO constant text = 'INSERT';

OP_ALTERAR constant text = 'UPDATE';

OP_REMOVER constant text = 'DELETE'; 

r_cliente diretorio.clientes%rowtype;
r_licenca diretorio.licencas%rowtype;

t_licenca_nova diretorio.tlicencanova ;

t_modulo_habilitar diretorio.tmodulohabilitar;
t_modulo_desabilitar   diretorio.tmodulodesabilitar;
t_usuario_modulo_alterar  diretorio.tmoduloalterarusuarios;

t_api_resultado json;

t_cliente_contrato_ativo boolean;
t_lic_bloquear  diretorio.tlicencabloquear;
t_lic_desbloquear diretorio.tlicencadesbloquear;

t_sistemas text[][];

CP_SIS constant integer = 1;
CP_QTD constant integer = 2;
CP_COD constant integer = 3;

t_modulo_ativo_contrato boolean;
t_modulo_usuarios_contrato integer;
t_modulo_ativo_licenca boolean;
t_modulo_usuarios_licenca integer;

t_usuario json;
begin    
  if not cast(ativo->>'contratosql' as boolean) then
	return;
  end if;
  
  if (ativo->>'operacao' = OP_REMOVER) then
    select a.serial, b.codigo into r_licenca from diretorio.licencas a join diretorio.clientes b on (a.cliente_id = b.id) where contrato_id = cast(ativo->>'contrato' as uuid);
	if (not r_licenca.id isnull) then
		raise exception 'Ainda não é possível remover a licenças "%" do cliente "%"',r_licenca.serial, r_licenca.codigo;
	else return;-- não é necessário efetuar a remoção de uma licença que não tem vínculo com o contrato
	end if;
  end if;
  
  --Cliente
  select * into r_cliente from diretorio.clientes where cliente_erp_id = cast(ativo->>'participante' as uuid);  
  if ( (r_cliente.id isnull) ) then
	raise exception 'Não foi possível recuperar o Cliente "%" do ativo, referente ao contrato "%".',cast(ativo->>'pessoa' as text),cast(ativo->>'codigo' as text);
  end if;

  --Licença
  select * into r_licenca from diretorio.licencas where contrato_id = cast(ativo->>'contrato' as uuid);
  if (ativo->>'operacao' = OP_NOVO)  then
  
    if not (r_licenca.id is null) then
		if  (r_cliente.id <> r_licenca.cliente_id) then
			raise exception 
				'O contrato "%" do cliente "%" já está atrelado a uma licença de titularidade diferente, cliente "%".',
				cast(ativo->>'codigo' as text),
				r_cliente.codigo,
				(select codigo from diretorio.clientes where id = r_licenca.cliente_id);
		end if;
    else 
		t_licenca_nova.cliente_id = r_cliente.id;  
		t_api_resultado = (diretorio.api_licencanova(t_licenca_nova)).mensagem;    
		
		if (t_api_resultado->>'codigo' = 'OK')  then    
		  select * into r_licenca from diretorio.licencas where id = cast(t_api_resultado->>'mensagem' as uuid);                
		  update diretorio.licencas set contrato_id = cast(ativo->>'contrato' as uuid) where id = r_licenca.id;      
		else
		  raise exception '%',t_api_resultado->>'mensagem';
		end if;         	
	end if;
	
  elsif (ativo->>'operacao' = OP_ALTERAR) then 
	
	if (r_licenca.id isnull ) then
		raise exception ' Não foi possível recuperar a Licença do contrato "%" para o cliente "%".',cast(ativo->>'codigo' as text), cast(ativo->>'pessoa' as text);
	end if;
	
	--atualiza a titularidade caso tenha mudado
	if (r_licenca.cliente_id <> r_cliente.id) then
		update diretorio.licencas set cliente_id = r_cliente.id where id = r_licenca.id;
		select * into r_licenca from diretorio.licencas where id = cast(t_api_resultado->>'mensagem' as uuid);                      
		if (r_licenca.id isnull ) then
			raise exception ' Não foi possível recuperar a Licença do contrato "%" para o cliente "%".',cast(ativo->>'codigo' as text), cast(ativo->>'pessoa' as text);
	  end if;		
	end if;	 

  end if;
  
  t_cliente_contrato_ativo = (cast(ativo->>'clienteadimplente' as boolean)) and (not cast(ativo->>'contratocancelado' as boolean));

  t_usuario = '{"email":"devops@nasajon.com.br"}'::json;
  
  if ( r_licenca.ativa <> t_cliente_contrato_ativo ) then
    if t_cliente_contrato_ativo then

      t_lic_desbloquear.licenca = r_licenca.id;
      t_lic_desbloquear.logged_user = t_usuario;     
      t_api_resultado = (diretorio.api_licencadesbloquear(t_lic_desbloquear)).mensagem;
      if not (t_api_resultado->>'codigo' = 'OK')  then              
        raise exception '%',t_api_resultado->>'mensagem';
      end if;   
      
    else
    
      t_lic_bloquear.licenca = r_licenca.id;    
      t_lic_bloquear.logged_user = t_usuario;
      t_api_resultado = (diretorio.api_licencabloquear(t_lic_bloquear)).mensagem;
      if not (t_api_resultado->>'codigo' = 'OK')  then              
        raise exception '%',t_api_resultado->>'mensagem';
      end if;         
      
    end if;
  end if;
    
  --Módulos
  t_sistemas = array[
    array[
      'compras'    ,'contador'    ,'contabil'    ,'crm'    ,'estoque'    ,'familyoffice'    ,'financas'    ,'investimento',
      'pdv'        ,'persona'     ,'scritta'     ,'servicos'
    ], 
    array[
      'qtd_compras','qtd_contador','qtd_contabil','qtd_crm','qtd_estoque','qtd_familyoffice','qtd_financas','qtd_investimento',
      'qtd_pdv'    ,'qtd_persona' ,'qtd_scritta' ,'qtd_servicos'    
    ],
    array[
      'nsjCompras', 'nsjContador' ,'nsjContabil' ,'nsjCRM' ,'nsjEstoque' ,'nsjFamilyOffice' ,'nsjFinancas' ,'nsjInvestimento',
      'nsjPDV'    ,'nsjPersona'   ,'nsjScritta'  ,'nsjServicos'
    ]
  ];  

  for i in array_lower(t_sistemas,2) .. array_upper(t_sistemas,2) loop  
    --ativa/desativa modulos  
    t_modulo_ativo_contrato = cast(ativo->>t_sistemas[CP_SIS][I] as boolean);   
    t_modulo_usuarios_contrato = cast(coalesce(ativo->>t_sistemas[CP_QTD][I],'0') as integer);
    
    t_modulo_ativo_licenca = exists(
      SELECT 1 FROM diretorio.modulos
      WHERE aplicacao_id = (SELECT id FROM diretorio.aplicacoes WHERE codigo = t_sistemas[CP_COD][I])
      AND licenca_id = r_licenca.id LIMIT 1
    );

    t_modulo_usuarios_licenca = (SELECT qtdusuarios FROM diretorio.modulos
      WHERE aplicacao_id = (SELECT id FROM diretorio.aplicacoes WHERE codigo = t_sistemas[CP_COD][I])
      AND licenca_id = r_licenca.id LIMIT 1);
             
  
    if (not t_modulo_ativo_contrato AND t_modulo_ativo_licenca) then          

      t_modulo_desabilitar.codigo = t_sistemas[CP_COD][I];
      t_modulo_desabilitar.licenca_id = r_licenca.id;
      t_modulo_desabilitar.logged_user = t_usuario;
      raise notice '%',t_modulo_desabilitar;
      raise notice 'aaaa';
      t_api_resultado = (diretorio.api_modulodesabilitar(t_modulo_desabilitar)).mensagem;

      if not (t_api_resultado->>'codigo' = 'OK')  then              
        raise exception '%',t_api_resultado->>'mensagem';
      end if;       
      
    elsif (t_modulo_ativo_contrato AND not t_modulo_ativo_licenca) then    

      t_modulo_habilitar.codigo = t_sistemas[CP_COD][I];
      t_modulo_habilitar.licenca_id = r_licenca.id;
      t_modulo_habilitar.logged_user = t_usuario;      
      t_api_resultado = (diretorio.api_modulohabilitar(t_modulo_habilitar)).mensagem;

      if not (t_api_resultado->>'codigo' = 'OK')  then              
        raise exception '%',t_api_resultado->>'mensagem';
      end if; 
      
    end if;

    if ( t_modulo_ativo_contrato and (t_modulo_usuarios_contrato <> t_modulo_usuarios_licenca) ) then    

      raise notice '% % %',t_sistemas[CP_COD][I],t_modulo_usuarios_contrato,t_modulo_usuarios_licenca;

      t_usuario_modulo_alterar.codigo = t_sistemas[CP_COD][I];
      t_usuario_modulo_alterar.licenca_id = r_licenca.id;
      t_usuario_modulo_alterar.qtdusuarios = t_modulo_usuarios_contrato;     
      t_usuario_modulo_alterar.logged_user = t_usuario;
      t_api_resultado = (diretorio.api_moduloalterarusuarios(t_usuario_modulo_alterar)).mensagem;

      if not (t_api_resultado->>'codigo' = 'OK')  then              
        raise exception '%',t_api_resultado->>'mensagem';
      end if;               
      
    end if;    
    
  end loop; 
  
end;
$$
language plpgsql;