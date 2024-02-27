-- pe3009271
-- pe3016226
-- pe3008819

create schema padaria;
set search_path to padaria;

-- Table funcionario
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS funcionario (
  idfuncionario INT NOT NULL,
  nome VARCHAR(45) NOT NULL,
  tipo VARCHAR(1) NOT NULL,
  cpf VARCHAR(14) NOT NULL,
  login VARCHAR(20) NOT NULL,
  senha VARCHAR(20) NOT NULL,
  statusfuncionario VARCHAR(1) NOT NULL,
  email VARCHAR(20) ,
  telefone VARCHAR(20) ,
  PRIMARY KEY (idfuncionario)
);
-- -----------------------------------------------------
-- Table caixa
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS caixa (
  idcaixa TIMESTAMP NOT NULL,
  saida TIME ,
  saldo DECIMAL(10,2) NOT NULL,
  situacao VARCHAR(1) NOT NULL,
  idfuncionario INT NOT NULL,
  saldofinal DECIMAL(10,2) ,
  PRIMARY KEY (idcaixa),
  FOREIGN KEY (idfuncionario)
    REFERENCES funcionario (idfuncionario)
);
-- -----------------------------------------------------
-- Table fornecedor
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS fornecedor (
  idfornecedor INT NOT NULL,
  nome VARCHAR(45) NOT NULL,
  valortotalcomprado DECIMAL(10,2) ,
  email VARCHAR(20) NOT NULL,
  telefone VARCHAR(20) NOT NULL,
  valortotalpago DECIMAL(10,2) ,
  statusfornecedor VARCHAR(1) NOT NULL,
  PRIMARY KEY (idfornecedor)
);
-- -----------------------------------------------------
-- Table compra
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS compra (
  idcompra INT NOT NULL,
  valortotal DECIMAL(10,2) ,
  idfornecedor INT NOT NULL,
  qtdeparcelas INT NOT NULL,
  idcaixa TIMESTAMP NOT NULL,
  PRIMARY KEY (idcompra),
  FOREIGN KEY (idfornecedor) REFERENCES fornecedor (idfornecedor),
  FOREIGN KEY (idcaixa) REFERENCES caixa (idcaixa)
);

-- -----------------------------------------------------
-- Table venda
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS venda (
  idvenda INT NOT NULL,
  datavenda DATE NOT NULL,
  valortotal DECIMAL(10,2) ,
  idcaixa TIMESTAMP NOT NULL,
  PRIMARY KEY (idvenda),
  FOREIGN KEY (idcaixa) REFERENCES caixa (idcaixa)
);
-- -----------------------------------------------------
-- Table produto
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS produto (
  idproduto INT NOT NULL,
  descricao VARCHAR(60) ,
  qtde INT NOT NULL,
  preco DECIMAL(10,2) NOT NULL,
  nome VARCHAR(45) NOT NULL,
  tipo VARCHAR(1) NOT NULL,
  PRIMARY KEY (idproduto)
);
-- -----------------------------------------------------
-- Table itempedido
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS itempedido (
  idvenda INT NOT NULL,
  idproduto INT NOT NULL,
  preco DECIMAL(10,2),
  qtde INT NOT NULL,
  PRIMARY KEY (idvenda, idproduto),
  FOREIGN KEY (idvenda) REFERENCES venda (idvenda),
  FOREIGN KEY (idproduto) REFERENCES produto (idproduto)
);
-- -----------------------------------------------------
-- Table parcela
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS parcela (
  idparcela INT NOT NULL,
  datapagamento DATE ,
  datavencimento DATE NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  idcompra INT NOT NULL,
  PRIMARY KEY (idparcela, idcompra),
  FOREIGN KEY (idcompra) REFERENCES compra (idcompra)
);

-- -----------------------------------------------------
-- Table compra_produto
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS compraproduto (
  idproduto INT NOT NULL,
  idcompra INT NOT NULL,
  valor DECIMAL(10,2) NULL,
  qtde INT NOT NULL,
  PRIMARY KEY (idproduto, idcompra),
  FOREIGN KEY (idcompra) REFERENCES compra (idcompra),
  FOREIGN KEY (idproduto) REFERENCES produto (idproduto)
);

--------------------------------------------------------
-- Table sangria
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS sangria (
  idsangria INT NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  motivo VARCHAR(60) NOT NULL,
  idcaixa TIMESTAMP NOT NULL,
  PRIMARY KEY (idsangria),
  FOREIGN KEY (idcaixa) REFERENCES caixa (idcaixa)
);
------------------------------------------------------------------------------
insert into funcionario values (1,'Adryan','C','123','Adryan.com','123','A','saaluis@',123);
------------------------------------------------------------------------------
create or replace function alterarValorTotalVenda()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	
		
begin
	if(TG_OP = 'INSERT') then

 		new.valortotal := 0; 	
		
		return new;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_alterarValorTotalVenda
before insert  on venda 
for each row execute procedure alterarValorTotalVenda();

------------------------------------------------------------------------------
create or replace function alterarValorTotalCompra()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	
		
begin
	if(TG_OP = 'INSERT') then

 		new.valortotal := 0; 	
		
		return new;
	end if;
	
	if(TG_OP = 'UPDATE') then

 		new.qtdeparcelas := old.qtdeparcelas;	
		
		return new;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_alterarValorTotalCompra
before insert or update on compra 
for each row execute procedure alterarValorTotalCompra();

------------------------------------------------------------------------------
create or replace function alterarPrecoCompraProduto()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	
		
begin
	if(TG_OP = 'INSERT') then

 		new.valor := new.qtde * (select preco from produto where idproduto = new.idproduto);
 	
		return new;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_alterarPrecoCompraProduto
before insert on compraproduto 
for each row execute procedure alterarPrecoCompraProduto();

------------------------------------------------------------------------------
create or replace function alterarCaixaVenda()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	
		
begin
	if(TG_OP = 'INSERT') then

		update caixa set saldo = saldo + new.valortotal  where new.idcaixa = caixa.idcaixa;
		
		return new;
	end if;
	
	if(TG_OP = 'UPDATE') then
		
		update caixa set saldo = saldo - old.valortotal + new.valortotal where idcaixa = new.idcaixa;
		
		return new;
	end if;
	
	if(TG_OP = 'DELETE') then
		
		update caixa set saldo = saldo - old.valortotal where idcaixa = old.idcaixa; 
		
		return old;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_alterarCaixaVenda
after insert or update or delete on venda 
for each row execute procedure alterarCaixaVenda();

------------------------------------------------------------------------------
create or replace function alterarDataPagamento()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	
		
begin
	if(TG_OP = 'INSERT') then

 		new.datapagamento := null; 	
		
		return new;
	end if;
	
	if(TG_OP = 'UPDATE') then

 		if new.datapagamento is not null and 
       		(select saldo from caixa where caixa.idcaixa 
				= (select idcaixa from compra where idcompra = new.idcompra)) 
					> (select caixa.saldo from caixa where caixa.idcaixa 
					   	= (select idcaixa from compra
							where idcompra = new.idcompra)) then
							
			NEW.datapagamento := null;
		
		end if; 	
		
		return new;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_alterarDataPagamento
before insert or update on parcela 
for each row execute procedure alterarDataPagamento();

------------------------------------------------------------------------------
create or replace function alterarCaixaParcela()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	declare idcaixa2 TIMESTAMP;
    declare idfornecedor2 int;
		
begin
	
	if(TG_OP = 'UPDATE') then
		
		
    select idfornecedor into idfornecedor2 from compra where idcompra = new.idcompra;
	select idcaixa into idcaixa2 from compra where idcompra = old.idcompra;
	
    if(new.datapagamento is not null and old.datapagamento is null) then
		update caixa set saldo = saldo - new.valor where idcaixa = idcaixa2;
        update fornecedor set valortotalpago = valortotalpago + new.valor where idfornecedor2 
			= idfornecedor;
	end if;
		
		return new;
	end if;
	
	if(TG_OP = 'DELETE') then
		
	select idcaixa into idcaixa2 from compra where idcompra = old.idcompra;
	
    if(old.datapagamento is not null) then
    	update caixa set saldo = saldo + old.valor where caixa.idcaixa = idcaixa2;
    end if; 
		
		return old;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_alterarCaixaParcela
after update or delete on parcela 
for each row execute procedure alterarCaixaParcela();

------------------------------------------------------------------------------
create or replace function alterarItemPedidoVenda()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	declare idcaixa2 date;
    declare idfornecedor2 int;
		
begin

	if(TG_OP = 'INSERT') then
	
		if(new.qtde > (select produto.qtde from produto where produto.idproduto = new.idproduto) ) then
			RAISE EXCEPTION 'A condição não foi atendida. ItemPedido cancelado.';
		end if;
		
		new.preco := new.qtde * (select preco from produto where idproduto = new.idproduto);
    	update produto set qtde = qtde - new.qtde where idproduto = new.idproduto;
   		update venda set valortotal = valortotal + new.preco where idvenda = new.idvenda;
		
		return new;
		
	end if;
	
	if(TG_OP = 'UPDATE') then
		
		if((select sum(old.qtde+produto.qtde-new.qtde) from caixa where idprdouto = new.idproduto) < 0) then
			new.qtde := old.qtde;
   		 end if;

		return new;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_alterarItemPedidoVenda
before insert or update on itempedido 
for each row execute procedure alterarItemPedidoVenda();

------------------------------------------------------------------------------
create or replace function alterarProdutoVenda()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	declare idcaixa2 date;
    declare idfornecedor2 int;
		
begin

	if(TG_OP = 'INSERT') then
		
	
		
		return new;
	end if;
	
	if(TG_OP = 'UPDATE') then
		
		update produto set qtde = qtde + old.qtde - new.qtde where idproduto = new.idproduto;
		
		update venda set valortotal = valortotal + new.preco - old.preco where idvenda = new.idvenda;
		return new;
	end if;
	
	if(TG_OP = 'DELETE') then
		
		update produto set qtde = qtde + old.qtde where idproduto = old.idproduto;
		
   		update venda set valortotal = valortotal - old.preco  where idvenda = old.idvenda;
		
		return old;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_alterarProdutoVenda
after update or delete on itempedido
for each row execute procedure alterarProdutoVenda();

------------------------------------------------------------------------------
create or replace function triggerCompra()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	DECLARE i INT DEFAULT 1;
    declare vencimento date default current_date;
		
begin

	if(TG_OP = 'INSERT') then
		
		FOR i IN 1..new.qtdeparcelas LOOP
		
        insert into parcela values(i,null,vencimento,new.valortotal/new.qtdeparcelas,new.idcompra);
		vencimento := vencimento + INTERVAL '30 days';
		
        i := i + 1;
    END LOOP;
    
	update fornecedor set valortotalcomprado = valortotalcomprado + new.valortotal where idfornecedor = new.idfornecedor;
		
		return new;
	end if;
	
	if(TG_OP = 'UPDATE') then
		
		update fornecedor set valortotalcomprado = valortotalcomprado - old.valortotal + new.valortotal where idfornecedor = new.idfornecedor;
    
    	update parcela set valor = new.valortotal/new.qtdeparcelas where idcompra = new.idcompra;
		return new;
	end if;
	
	if(TG_OP = 'DELETE') then
		
		update fornecedor set valortotalcomprado = valortotalcomprado - old.valortotal 
			where idfornecedor = old.idfornecedor; 
			
		return old;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_triggerCompra
after insert or update or delete on compra
for each row execute procedure triggerCompra();

------------------------------------------------------------------------------
create or replace function triggerCompra()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	DECLARE i INT DEFAULT 1;
    declare vencimento date default current_date;
		
begin

	if(TG_OP = 'INSERT') then
		
		FOR i IN 1..new.qtdeparcelas LOOP
		
        insert into parcela values(i,null,vencimento,new.valortotal/new.qtdeparcelas,new.idcompra);
		vencimento := vencimento + INTERVAL '30 days';
		
        i := i + 1;
    END LOOP;
    
	update fornecedor set valortotalcomprado = valortotalcomprado + new.valortotal where idfornecedor = new.idfornecedor;
		
		return new;
	end if;
	
	if(TG_OP = 'UPDATE') then
		
		update fornecedor set valortotalcomprado = valortotalcomprado - old.valortotal + new.valortotal where idfornecedor = new.idfornecedor;
    
    	update parcela set valor = new.valortotal/new.qtdeparcelas where idcompra = new.idcompra;
		return new;
	end if;
	
	if(TG_OP = 'DELETE') then
		
		update fornecedor set valortotalcomprado = valortotalcomprado - old.valortotal 
			where idfornecedor = old.idfornecedor; 
			
		return old;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_triggerCompra
after insert or update or delete on compra
for each row execute procedure triggerCompra();

------------------------------------------------------------------------------
create or replace function triggerCompraProduto()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	DECLARE i INT DEFAULT 1;
    declare vencimento date default current_date;
		
begin

	if(TG_OP = 'INSERT') then
		
		if(new.qtde <= (select produto.qtde from produto where produto.idproduto = new.idproduto)) then
			update produto set qtde = qtde + new.qtde where idproduto = new.idproduto;
		end if;
    
    update compra set valortotal = valortotal + new.valor where idcompra = new.idcompra;
		
		return new;
	end if;
	
	if(TG_OP = 'UPDATE') then
		
		update produto set qtde = qtde - old.qtde + new.qtde where idproduto = new.idproduto;
    	update compra set valortotal = valortotal - old.valor + new.valor where idcompra = new.idcompra;
		return new;
	end if;
	
	if(TG_OP = 'DELETE') then
		
		update produto set qtde = qtde - old.qtde where idproduto = old.idproduto;
    	update compra set valortotal = valortotal - old.valor where idcompra = old.idcompra;
			
		return old;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_triggerCompraProduto
after insert or update or delete on compraproduto
for each row execute procedure triggerCompraProduto();

------------------------------------------------------------------------------
create or replace function triggerSangria()
	returns trigger
	language 'plpgsql' cost 100 volatile not leakproof 
as $BODY$

	DECLARE i INT DEFAULT 1;
    declare vencimento date default current_date;
		
begin

	if(TG_OP = 'INSERT') then
		
		if ((select saldo from caixa where idcaixa = new.idcaixa) - new.valor) < 100 then
			RAISE EXCEPTION 'A condição não foi atendida. Sangria cancelada.';
   		end if;
		
		update caixa set saldo = saldo - new.valor where idcaixa = new.idcaixa;
		return new;
	end if;
	
end;
$BODY$;

create or replace TRIGGER tg_triggerSangria
before insert on sangria
for each row execute procedure triggerSangria();

------------------------------------------------------------------------------
insert into produto values (1,'Queijo','30',30,'Queijo Cheddar','F');
insert into fornecedor values (1,'Andre',0,'Andre@','123',0,'A');
insert into caixa values (current_timestamp,current_time,300,'A',1,0);
insert into sangria values (1,100,'cara',current_timestamp);
insert into venda values (1, current_date, 20.00, current_timestamp);
insert into compra values (1,213,1,6,current_timestamp);
insert into itempedido values (1,1,0,6);
insert into compraproduto values (1,1,0,6);


select * from caixa;
select * from venda;
select * from fornecedor;
select * from compra;
select * from produto;
select * from itempedido;
select * from parcela;
select * from compraproduto;
select * from sangria;