drop function if exists diretorio.atualizar_dados_cliente(json);
create or replace function diretorio.atualizar_dados_cliente(cliente json) 
returns void as
$$
declare
r_cliente diretorio.clientes%rowtype;
r_licenca diretorio.licencas%rowtype;

existe_por_documento boolean;

t_cliente_novo diretorio.tclientenovo ;
t_cliente_alterar diretorio.tclientealterar ;
t_cliente_excluir diretorio.tclienteexcluir ;

t_api_resultado json;

OP_NOVO constant text = 'INSERT';

OP_ALTERAR constant text = 'UPDATE';

OP_REMOVER constant text = 'DELETE'; 

begin      

  if ( cast(cliente->>'operacao' as text) in ( OP_NOVO, OP_ALTERAR )) and (cast(cliente->>'pessoa' as text) is null) then
	return;
  end if;    
  
  if exists(select 1 from diretorio.clientes where codigo = cliente->>'pessoa' and id <> r_cliente.id  ) then
	raise exception 'Já existe um cliente com o código "%".',cliente->>'pessoa';
  end if;  
  
  select * into r_cliente from diretorio.clientes where cliente_erp_id = cast(cliente->>'id' as uuid);	
	 
  if (cliente->>'operacao' = OP_ALTERAR and (not r_cliente.id isnull)) or ( (cliente->>'operacao' = OP_NOVO) and (not r_cliente.id isnull)  ) then
      
    if exists(select 1 from diretorio.clientes where codigo = cliente->>'pessoa' and id <> r_cliente.id  ) then
      raise exception 'Já existe um cliente com o código "%".',cliente->>'pessoa';
    end if;   
    
	t_cliente_alterar.id = r_cliente.id;
    t_cliente_alterar.codigo = cliente->>'pessoa';
    t_cliente_alterar.razaosocial = cliente->>'nome';
    t_cliente_alterar.nomefantasia = cliente->>'nomefantasia';
    t_cliente_alterar.cnpj = cliente->>'cnpj';
    t_cliente_alterar.cpf = cliente->>'cpf';     
    t_api_resultado = (diretorio.api_clientealterar(t_cliente_alterar)).mensagem;
    if not (t_api_resultado->>'codigo' = 'OK')  then              
      raise exception '%',t_api_resultado->>'mensagem';
    end if;  
	
	update diretorio.clientes 
	set 
		r1 = cast(cliente->>'restricaocobranca1' as uuid), r2 = cast(cliente->>'restricaocobranca2' as uuid)
	where id = r_cliente.id;
	
  elsif (cliente->>'operacao' = OP_NOVO) or ( (cliente->>'operacao' = OP_ALTERAR) and (r_cliente.id isnull) ) then    
  
    if exists(select 1 from diretorio.clientes where codigo = cast(cliente->>'pessoa' as text)  ) then
      raise exception 'Já existe um cliente com o código "%".',cast(cliente->>'pessoa' as text);
    end if; 
  
    t_cliente_novo.codigo = cliente->>'pessoa';
    t_cliente_novo.razaosocial = cliente->>'nome';
    t_cliente_novo.nomefantasia = cliente->>'nomefantasia';
    t_cliente_novo.cnpj = cliente->>'cnpj';
	t_cliente_novo.cpf = cliente->>'cpf'; 
    t_api_resultado = (diretorio.api_clientenovo(t_cliente_novo)).mensagem;
    if (t_api_resultado->>'codigo' = 'OK')  then      
      
	  select * into r_cliente from diretorio.clientes where id = cast(t_api_resultado->>'mensagem' as uuid);           
	  
	  if (r_cliente.id isnull) then
	    raise exception 'Não foi possível carregar o cliente novo "%".',cast(cliente->>'pessoa' as text)||'-'||cast(cliente->>'nome' as text);		
	  end if;
	  
	  update diretorio.clientes 
	  set 
		cliente_erp_id = cast(cliente->>'id' as uuid), r1 = cast(cliente->>'restricaocobranca1' as uuid), r2 = cast(cliente->>'restricaocobranca2' as uuid)
		where id = r_cliente.id; 
		
    else
      raise exception '%',t_api_resultado->>'mensagem';
    end if;  	
	
  elsif cliente->>'operacao' = OP_REMOVER then
  
	select * into r_cliente from diretorio.clientes where cliente_erp_id = cast(cliente->>'id' as uuid);
	if (r_cliente.id isnull) then
	    --Não remove o que não existe 
		return;		
	end if;
	
	t_cliente_excluir.id = r_cliente.id;
	t_api_resultado = (diretorio.api_clienteexcluir(t_cliente_excluir)).mensagem;
    if not (t_api_resultado->>'codigo' = 'OK')  then              
      raise exception '%',t_api_resultado->>'mensagem';
    end if;  
	
  else 
	raise exception 'Operação inválida para atualização cliente: "%".',json;
  end if;
  
end;
$$
language plpgsql;