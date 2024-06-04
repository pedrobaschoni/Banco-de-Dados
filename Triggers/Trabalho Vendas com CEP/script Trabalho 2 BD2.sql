create schema trabalho2;
set search_path to trabalho2;


create table cliente (
    idcliente           integer,
    nome                varchar(100),
    telefone            varchar(14),
    cep                 integer,
    numero              varchar(20),
    nomecidade          varchar(100),
    nomebairro          varchar(100),
    estado              varchar(100),
    local               varchar(100),
    codigoIBGE          int,
    quantidadevendas    int,
    totalcomprado       numeric(10,2),
    status              varchar(1),
    limitecomprafiado   numeric(10,2),

    primary key (idcliente)
);

create table venda (
    idvenda         serial,
    idcliente       integer,
    cep             integer,
    numero          varchar(8),
    valortotal      double precision,
    datavenda       date,
    datapagamento   date,

    primary key (idvenda),
    foreign key (idcliente) references cliente (idcliente)
);

create table produto (
    idproduto           integer,
    qtdeestoque         integer,
    precocusto          double precision,
    percentuallucro     double precision,
    precovenda          double precision,

    primary key (idproduto)
);

create table itemvenda (
    idvenda         integer,
    idproduto       integer,
    quantidade      integer,
    valor           double precision,

    primary key (idvenda, idproduto),
    foreign key (idvenda) references venda (idvenda),
    foreign key (idproduto) references produto (idproduto)
);

create table resumodiario (
    ano                 integer,
    lancamento          integer,
    datapagamento       date,
    numerovenda         integer,
    valorrecebido       double precision,
    saldododia          double precision,

    primary key (ano, lancamento)
);

select * from cidade;
select * from estado;
select * from endereco;
select * from bairro;
select * from faixa_bairros;
select * from faixa_cidades;
select * from geo;
select * from tabela_integrada;
select * from tabela_integrada_bairro;




alter table cidade add primary key (id_cidade);
alter table estado add primary key (uf);
alter table cidade add foreign key (uf) references estado (uf);

alter table endereco add primary key (cep);
alter table bairro add primary key (id_bairro, id_cidade);

update endereco set id_bairro = null where id_bairro=0;
delete from bairro where id_cidade=0;

alter table bairro add foreign key (id_cidade) references cidade (id_cidade);

alter table endereco add foreign key (id_cidade, id_bairro) references bairro (id_cidade, id_bairro);

alter table cliente add foreign key (cep) references endereco (cep);

alter table geo add primary key (cep);
alter table geo add foreign key (cep) references endereco (cep);

create or replace function checarcep() returns trigger
    language plpgsql
as
$$
    declare ceptrigger integer;
begin
    if TG_OP = 'INSERT' then
        select cep from endereco where new.cep = endereco.cep into ceptrigger;

        if ceptrigger is not null then
            raise notice 'CEP Existe';
            return new;
        else
            raise notice 'CEP incorreto';
            return null;
        end if;
    end if;

    return null;
end;
$$;

create or replace trigger tg_checarcep
before insert on cliente
for each row
WHEN (pg_trigger_depth() < 1)
execute function checarcep();



create or replace function completarcliente() returns trigger
    language plpgsql
as
$$
    declare nomecidadetrigger varchar(100);
    declare nomebairrotrigger varchar(100);
    declare estadotrigger varchar(100);
    declare localtrigger varchar(100);
    declare codigoIBGEtrigger varchar(100);

begin
    if(TG_OP = 'INSERT') then
        select c.cidade from endereco e join cidade c on e.id_cidade = c.id_cidade where e.cep = new.cep into nomecidadetrigger;
        select es.estado from cidade c join estado es on c.uf = es.uf join endereco e on c.id_cidade = e.id_cidade where e.cep = new.cep into estadotrigger;
        select b.bairro from endereco e join bairro b on e.id_bairro = b.id_bairro where e.cep = new.cep into nomebairrotrigger;
        select e.local from endereco e where e.cep=new.cep into localtrigger;
        select c.cod_ibge from endereco e join cidade c on e.id_cidade = c.id_cidade where e.cep = new.cep into codigoIBGEtrigger;

        new.quantidadevendas := 0;
        new.totalcomprado := 0;
        new.status := null;
        new.nomecidade := nomecidadetrigger;
        new.estado := estadotrigger;
        new.nomebairro := nomebairrotrigger;
        new.local := localtrigger;
        new.codigoibge := codigoIBGEtrigger;

        return new;
    end if;

end;
$$;

create or replace trigger tg_completarcliente
before insert on cliente
for each row
WHEN (pg_trigger_depth() < 1)
execute function completarcliente();

create or replace function adicionarquantidadevendas() returns trigger
    language plpgsql
as
$$

begin
    if(TG_OP = 'INSERT') then
        update cliente set quantidadevendas = quantidadevendas + 1 where new.idcliente=cliente.idcliente;
        return new;
    end if;

    if(TG_OP = 'DELETE') then
        update cliente set quantidadevendas = quantidadevendas - 1 where cliente.idcliente = old.idcliente;
        return old;
    end if;

end;
$$;

create or replace trigger tg_adicionarquantidadevendas
    after insert or delete
    on venda
    for each row
    WHEN (pg_trigger_depth() < 1)
execute procedure adicionarquantidadevendas();





create or replace function totalcompradocliente() returns trigger
    language plpgsql
as
$$
    declare valortotaltrigger double precision;
begin

    if(TG_OP = 'UPDATE') then
        select sum(valortotal) from venda where new.idcliente=venda.idcliente into valortotaltrigger;
        update cliente set totalcomprado = valortotaltrigger where new.idcliente=idcliente;
        return new;
    end if;

end;
$$;

create or replace trigger tg_totalcompradocliente
    after update
    on venda
    for each row
execute procedure totalcompradocliente();




create or replace function checarcepvendaEdataauto() returns trigger
    language plpgsql
as
$$
    declare ceptrigger integer;
begin
    if TG_OP = 'INSERT' then
        select cep from endereco where new.cep = endereco.cep into ceptrigger;
        new.datapagamento = null;
        new.datavenda = current_date;
        new.valortotal = 0;

        if ceptrigger is not null then
            raise notice 'CEP Existe';
            return new;
        else
            raise notice 'CEP incorreto, não é possivel realizar a venda';
            return null;
        end if;
    end if;

    return null;
end;
$$;

create or replace trigger tg_checarcepvendaEdataauto
before insert on venda
for each row
WHEN (pg_trigger_depth() < 1)
execute function checarcepvendaEdataauto();

create or replace function checarstatuscliente() returns trigger
    language plpgsql
as
$$
    declare statustrigger varchar(1);
begin
    if TG_OP = 'INSERT' then
        select status from cliente where new.idcliente = cliente.idcliente into statustrigger;

        if statustrigger = 'B' then
            raise notice 'Cliente não está autorizado a realizar a compra, conta bloqueada';
            return null;
        else
            raise notice 'Cliente está autorizado a realizar a compra, conta não bloqueada';
            return new;
        end if;
    end if;

    return null;
end;
$$;

create or replace trigger tg_checarstatuscliente
before insert on venda
for each row
WHEN (pg_trigger_depth() < 1)
execute function checarstatuscliente();


create or replace function atualizarprecoitemvenda() returns trigger
    language plpgsql
as
$$
    declare aux double precision;
    declare aux2 double precision;
begin
    if(TG_OP = 'INSERT') then
        select precovenda from produto where new.idproduto=produto.idproduto into aux;
        update itemvenda set valor = valor - valor + ((aux)*new.quantidade) where idvenda=new.idvenda and new.idproduto=idproduto;
        return new;
    end if;

    if(TG_OP = 'UPDATE') then
        select precovenda from produto where old.idproduto=produto.idproduto into aux;
        select precovenda from produto where new.idproduto=produto.idproduto into aux2;
        update itemvenda set valor = valor - ((aux)*old.quantidade) +
                                ((aux2)*new.quantidade) where idvenda=new.idvenda and idproduto=new.idproduto;
        return new;
    end if;

    if(TG_OP = 'DELETE') then
        select precovenda from produto where old.idproduto=produto.idproduto into aux;
        update itemvenda set valor = valor - ((aux)*old.quantidade) where idvenda=old.idvenda and idproduto=old.idproduto;
        return old;
    end if;

end;
$$;

create or replace trigger tg_atualizarprecoitemvenda
    after insert or update or delete
    on itemvenda
    for each row
    WHEN (pg_trigger_depth() < 1) -- MUITO IMPORTANTE
execute function atualizarprecoitemvenda();

create or replace function atualizarestoquevenda() returns trigger
    language 'plpgsql'
as
$$
begin

    if(TG_OP = 'INSERT') then
        update produto set qtdeestoque = qtdeestoque - new.quantidade where idproduto=new.idproduto;
        return new;
    end if;

    if(TG_OP = 'UPDATE') then
        update produto set qtdeestoque = qtdeestoque + old.quantidade - new.quantidade
            WHERE idproduto = new.idproduto;
        return new;
    end if;

    if(TG_OP = 'DELETE') then
        update produto set qtdeestoque = qtdeestoque + old.quantidade
            WHERE idproduto = old.idproduto;
        return old;
    end if;

    return null;
end;
$$;

create or replace trigger tg_atualizarestoquevenda
    after insert or update or delete
    on itemvenda
    for each row
    WHEN (pg_trigger_depth() < 1)
execute function atualizarestoquevenda();

create or replace function iniciarvaloritemvenda() returns trigger
    language 'plpgsql'
as
$$
begin

    if(TG_OP = 'INSERT') then
        new.valor = 0;
        return new;
    end if;

    return null;
end;
$$;

create or replace trigger tg_iniciarvaloritemvenda
    before insert
    on itemvenda
    for each row
    WHEN (pg_trigger_depth() < 1)
execute function iniciarvaloritemvenda();


create or replace function atualizarvalortotalvenda() returns trigger
    language 'plpgsql'
as
$$
begin

    if(TG_OP = 'INSERT') then
        update venda set valortotal = (select sum(valor) from itemvenda where new.idvenda=idvenda) where new.idvenda=idvenda;
        return new;
    end if;

    if(TG_OP = 'UPDATE') then
        update venda set valortotal = (select sum(valor) from itemvenda where new.idvenda=idvenda) where new.idvenda=idvenda;
        return new;
    end if;

    if(TG_OP = 'DELETE') then
        update venda set valortotal = (select sum(valor) from itemvenda where old.idvenda=idvenda) where old.idvenda=idvenda;
        return old;
    end if;
    return null;
end
$$;

create or replace trigger tg_atualizarvalortotalvenda
after insert or update or delete on itemvenda
for each row
execute function atualizarvalortotalvenda();


create function verificarlimitecliente() returns trigger
    language plpgsql
as
$$
    declare limitefiadotrigger double precision;
    declare totalcompradotrigger double precision;
begin

    if(TG_OP = 'INSERT') then
        select cliente.limitecomprafiado from cliente where new.idcliente=idcliente into limitefiadotrigger;
        select cliente.totalcomprado from cliente where new.idcliente=idcliente into totalcompradotrigger;

        if totalcompradotrigger >= limitefiadotrigger then
            raise notice 'A venda não pode ser realizada. Limite fiado insuficiente';
            return null;
        else
            raise notice 'A venda pode ser realizada. Limite fiado suficiente';
            return new;
        end if;
    end if;
    return null;
end
$$;

create or replace trigger tg_verificarlimitecliente
before insert on venda
for each row
WHEN (pg_trigger_depth() < 1)
execute function verificarlimitecliente();


create or replace function verificarlimitecliente() returns trigger
    language plpgsql
as
$$
    declare limitefiadotrigger double precision;
    declare totalcompradotrigger double precision;
begin

    if(TG_OP = 'INSERT') then
        select cliente.limitecomprafiado from cliente where new.idcliente=idcliente into limitefiadotrigger;
        select sum(valortotal) from venda where new.idcliente=venda.idcliente and datapagamento is null into totalcompradotrigger;


        if totalcompradotrigger >= limitefiadotrigger then
            raise notice 'A venda não pode ser realizada. Limite fiado insuficiente';
            return null;
        else
            raise notice 'A venda pode ser realizada. Limite fiado suficiente';
            return new;
        end if;
    end if;
    return null;
end
$$;

create or replace trigger tg_verificarlimitecliente
before insert on venda
for each row
WHEN (pg_trigger_depth() < 1)
execute function verificarlimitecliente();



create or replace function atualizarprecovendaproduto() returns trigger
    language 'plpgsql'
as
$$
    declare precocustotrigger double precision;
    declare percentuallucrotrigger double precision;
begin

    if(TG_OP = 'INSERT') then
        select precocusto from produto where new.idproduto=idproduto into precocustotrigger;
        select percentuallucro from produto where new.idproduto=idproduto into percentuallucrotrigger;
        update produto set precovenda = precocustotrigger + (precocustotrigger * percentuallucrotrigger / 100) where new.idproduto=idproduto;
        return new;
    end if;

    if(TG_OP = 'UPDATE') then
        select precocusto from produto where new.idproduto=idproduto into precocustotrigger;
        select percentuallucro from produto where new.idproduto=idproduto into percentuallucrotrigger;
        update produto set precovenda = precocustotrigger + (precocustotrigger * percentuallucrotrigger / 100) where new.idproduto=idproduto;
        return new;
    end if;

    return null;
end
$$;

create or replace trigger tg_atualizarprecovendaproduto
after insert or update on produto
for each row
WHEN (pg_trigger_depth() < 1)
execute function atualizarprecovenda(produto);



create or replace function realizarresumodiario() returns trigger
    language plpgsql
as
$$
    declare anoatualtrigger integer default 0;
    declare anonovotrigger boolean;
    declare numerovendatrigger integer default 0;
    declare valorrecebidotrigger double precision default 0;
    declare saldododiatrigger double precision default 0;
    declare qtdelancamento integer default 0;
begin

    if(TG_OP = 'UPDATE') then
        anoatualtrigger := extract(year from new.datapagamento);
        numerovendatrigger := new.numero;
        valorrecebidotrigger := new.valortotal;
        select sum(valortotal) from venda where datapagamento = new.datapagamento into saldododiatrigger;

        select coalesce(max(lancamento), 0) from resumodiario where ano = anoatualtrigger into qtdelancamento;
        qtdelancamento := qtdelancamento + 1;

        if (anoatualtrigger <> (select extract(year from max(datapagamento)) from resumodiario)) then
            anonovotrigger := true;
        else
            anonovotrigger := false;
        end if;

        if anonovotrigger is true then
            qtdelancamento := 0;
            qtdelancamento := qtdelancamento + 1;
        end if;

        insert into resumodiario (ano, lancamento, datapagamento, numerovenda, valorrecebido, saldododia) values (anoatualtrigger, qtdelancamento, new.datapagamento, numerovendatrigger, valorrecebidotrigger, saldododiatrigger);
        return new;
    end if;
    return null;
end
$$;

create or replace trigger tg_realizarresumodiario
after update on venda
for each row
WHEN (pg_trigger_depth() < 1)
execute function realizarresumodiario();




-- Funções ====================================================================================================================================================

create or replace function quantidadecidadesestado(estadofuncao varchar(100)) returns integer
    language plpgsql
as
$$
    declare quantidadeCidadeFuncao integer;
begin
    select count(*) from cidade c join estado e on c.uf = e.uf where e.estado = estadofuncao into quantidadeCidadeFuncao;

    return quantidadeCidadeFuncao;
end;
$$;

select quantidadecidadesestado('São Paulo');
select quantidadecidadesestado('Rio de Janeiro');

select * from faixa_cidades;


create or replace function quantidadecepdisponivel(cepfuncao integer) returns table (cidade varchar(100), quantidade_cep integer)
    language plpgsql
as
$$
begin
    return query
    select fa.cidade, (fa.cep_final - fa.cep_inicial) as quantidade_cep from faixa_cidades fa where cepfuncao=cep_inicial;
end;
$$;

select * from quantidadecepdisponivel(1029901);
select * from quantidadecepdisponivel(6503115);
select * from faixa_cidades;



-- Procedures ================================================================================================================================================

create procedure gerarcliente(IN idclienteP integer, nomeP varchar(100), telefoneP varchar(14), cepP integer, numeroP integer, limitecomprafiadoP double precision)
    language plpgsql
as
$$
begin
    insert into cliente (idcliente, nome, telefone, cep, numero, limitecomprafiado) values (idclienteP, nomeP, telefoneP, cepP, numeroP, limitecomprafiadoP);
end;
$$;

call gerarcliente(3, 'Hope Baschoni', '14997837918', 87535970, '999', 5000);
select * from cliente;


create procedure gerarvenda(IN idclienteP integer, cepP integer, numeroP integer)
    language plpgsql
as
$$
begin
    insert into venda (idcliente, cep, numero) values (idclienteP, cepP, numeroP);
end;
$$;

call gerarvenda(3, 87535970, '888');
select * from venda;


create procedure geraritemvenda(IN idvendaP integer, idprodutoP integer, quantidadeP integer)
    language plpgsql
as
$$
begin
    insert into itemvenda (idvenda, idproduto, quantidade) values (idvendaP, idprodutoP, quantidadeP);
end;
$$;

call geraritemvenda(9, 2, 4);
select * from venda;
select * from itemvenda;
select * from produto;


create procedure gerarproduto(IN idprodutoP integer, qtdeestoqueP integer, precocusto double precision, percentuallucroP double precision)
    language plpgsql
as
$$
begin
    insert into produto (idproduto, qtdeestoque, precocusto, percentuallucro) values (idprodutoP, qtdeestoqueP, precocusto, percentuallucroP);
end;
$$;

call gerarproduto(4, 200, 300, 50);
select * from produto;


create procedure gerarendereco(IN cepP integer, logradouroP varchar(100), tipo_logradouroP varchar(100), complementoP varchar(100), localP varchar(100), id_cidadeP integer, id_bairroP integer)
    language plpgsql
as
$$
begin
    insert into endereco (cep, logradouro, tipo_logradouro, complemento, local, id_cidade, id_bairro) values (cepP, logradouroP, tipo_logradouroP, complementoP, localP, id_cidadeP, id_bairroP);
end;
$$;

call gerarendereco(11111, 'SLA', 'SLA', 'SLA', 'SLA', 9668, 25279);
select * from endereco where cep=11111;


create procedure gerargeo(IN cepP integer, latitudeP double precision, longitudeP double precision)
    language plpgsql
as
$$
begin
    insert into geo (cep, latitude, longitude) values (cepP, latitudeP, longitudeP);
end;
$$;

call gerargeo(11111, 4234234, 234234);
select * from geo where cep=11111;


create procedure gerarbairro(IN idbairroP integer, bairroP varchar(100), idcidadeP integer)
    language plpgsql
as
$$
begin
    insert into bairro (id_bairro, bairro, id_cidade) values (idbairroP, bairroP, idcidadeP);
end;
$$;

call gerarbairro(1000, 'LA NA CASA DO KRL', 9668);
select * from bairro where id_bairro=1000;


create procedure gerarcidade(IN idcidadeP integer, cidadeP varchar(100), ufP varchar(2), cod_ibgeP integer, areaP double precision)
    language plpgsql
as
$$
begin
    insert into cidade (id_cidade, cidade, uf, cod_ibge, area) values (idcidadeP, cidadeP, ufP, cod_ibgeP, areaP);
end;
$$;

call gerarcidade(1000, 'DISNEYLANDIA', 'SP', 32423, 234234234);
select * from cidade where id_cidade=1000;


create procedure gerarestado(IN ufP varchar(100), estadoP varchar(100), cod_ibgeP integer)
    language plpgsql
as
$$
begin
    insert into estado (uf, estado, cod_ibge) values (ufP, estadoP, cod_ibgeP);
end;
$$;

call gerarestado('SL', 'SEI LA', 232323);
select * from estado where uf='SL';

-- Testes =====================================================================================================================================================

insert into cliente (idcliente, nome, telefone, cep, numero, quantidadevendas, totalcomprado, limitecomprafiado)
                    values (1, 'Pedro Baschoni', '14998598202', 1029901, '1212', 0, 0, 2000);

insert into cliente (idcliente, nome, telefone, cep, numero, quantidadevendas, totalcomprado, limitecomprafiado)
                    values (2, 'Abigail Baratela', '11995687415', 31270978, '2121', 100, 0, 3000);

insert into cliente (idcliente, nome, telefone, cep, numero, quantidadevendas, totalcomprado, limitecomprafiado)
                    values (2, 'Adryan Luis', '11995687415', 121212, '2121', 0, 0, 3000);

select * from endereco;
select * from cliente;

-- conferir se a trigger pegou as informações corretas
select c.cidade from endereco e join cidade c on e.id_cidade = c.id_cidade where e.cep =1029901;
select * from cidade where cidade = 'São Paulo';
select * from endereco where id_cidade=9668 and cep=1029901;
select e.local from endereco e where e.cep=1029901;
select b.bairro from endereco e join bairro b on e.id_bairro = b.id_bairro where e.cep =1029901;

-- 3550308
select c.cod_ibge from endereco e join cidade c on e.id_cidade = c.id_cidade where e.cep =1029901;

select * from cliente;

-- conferir se a trigger pegou as informações corretas
select c.cidade from endereco e join cidade c on e.id_cidade = c.id_cidade where e.cep =31270978;
select * from cidade where cidade = 'Belo Horizonte';
select * from endereco where id_cidade=2754 and cep=31270978;
select e.local from endereco e where e.cep=31270978;
select b.bairro from endereco e join bairro b on e.id_bairro = b.id_bairro where e.cep =31270978;

-- 3106200
select c.cod_ibge from endereco e join cidade c on e.id_cidade = c.id_cidade where e.cep =31270978;

select * from cliente;


update cliente set status = 'B' where idcliente=2;
update cliente set status = null where idcliente=2;
select * from cliente where idcliente=2;

insert into venda (idcliente, cep, numero, valortotal, datavenda) values (2, 31270978, '1212', 5000, current_date);
select * from venda;
select * from cliente;



insert into venda (idcliente, cep, numero, valortotal, datapagamento) values (1, 1029901, '1212', 100, current_date);
select * from cliente;
select * from venda;



insert into venda (idcliente, cep, numero, valortotal, datapagamento) values (1, 222, '1212', 0, current_date);
insert into venda (idcliente, cep, numero, valortotal, datavenda) values (1, 1029901, '111', 0, current_date);
insert into venda (idcliente, cep, numero, valortotal, datavenda) values (1, 1029901, '123', 0, current_date);
insert into venda (idcliente, cep, numero, valortotal, datavenda) values (3, 1029901, '222', 0, current_date);
insert into venda (idcliente, cep, numero, valortotal, datavenda) values (3, 1029901, '11113', 0, current_date);
insert into venda (idcliente, cep, numero, valortotal, datavenda) values (3, 87535970, '6767', 0, current_date);
select * from venda;
select * from cliente;

insert into produto (idproduto, qtdeestoque, precocusto, percentuallucro, precovenda) values (1, 10, 100, 10, 1000);
insert into produto (idproduto, qtdeestoque, precocusto, percentuallucro, precovenda) values (2, 20, 200, 10, 110);
insert into produto (idproduto, qtdeestoque, precocusto, percentuallucro) values (3, 20, 1000, 10);
select * from produto;

insert into itemvenda (idvenda, idproduto, quantidade, valor) values (7, 1, 5, 0);
insert into itemvenda (idvenda, idproduto, quantidade, valor) values (8, 3, 2, 0);
insert into itemvenda (idvenda, idproduto, quantidade, valor) values (10, 2, 2, 0);
insert into itemvenda (idvenda, idproduto, quantidade, valor) values (11, 2, 2, 0);
insert into itemvenda (idvenda, idproduto, quantidade, valor) values (13, 3, 2, 0);
select * from itemvenda;

insert into produto (idproduto, qtdeestoque, precocusto, percentuallucro, precovenda) values (4, 200, 200, 10, 0);
select * from produto;


select sum(valortotal) from venda where idcliente=venda.idcliente;

select limitecomprafiado from cliente where idcliente = 1;


insert into venda (idcliente, cep, numero, valortotal, datavenda) values (1, 1029901, '888', 0, current_date);
insert into venda (idcliente, cep, numero, valortotal, datavenda) values (2, 1029901, '222', 0, current_date);
insert into venda (idcliente, cep, numero, valortotal, datavenda) values (2, 1029901, '333', 0, current_date);
insert into itemvenda (idvenda, idproduto, quantidade, valor) values (12, 1, 2, 0);
insert into itemvenda (idvenda, idproduto, quantidade, valor) values (31, 4, 2, 0);
insert into itemvenda (idvenda, idproduto, quantidade, valor) values (32, 4, 2, 0);

update venda set datapagamento = current_date where idvenda=7 and idcliente=1;
update venda set datapagamento = current_date where idvenda=8 and idcliente=1;
update venda set datapagamento = '2025-05-30' where idvenda=10 and idcliente=3;
update venda set datapagamento = '2025-05-30' where idvenda=11 and idcliente=3;
update venda set datapagamento = '2025-05-30' where idvenda=13 and idcliente=3;
select * from venda;
select * from resumodiario;

alter sequence venda_idvenda_seq RESTART with 1;


create view vendas_view as
select v.idvenda, v.cep, v.numero, v.valortotal, v.datavenda, v.datapagamento, c.nome as nomeDoCliente, e.local, b.bairro, ci.cidade, es.estado from venda v
    join cliente c on v.idcliente = c.idcliente
    join endereco e on v.cep = e.cep
    join bairro b on e.id_bairro = b.id_bairro AND e.id_cidade = b.id_cidade
    join cidade ci on e.id_cidade = ci.id_cidade
    join estado es on ci.uf = es.uf;

SELECT * FROM vendas_view;






-- Permissões =====================================================================================================================================================

-- ustabelascriadas:
create user ustabelascriadas password '123';

grant connect on database pe3008819 to ustabelascriadas;
grant usage on schema cidades to ustabelascriadas;

grant insert, update, select on table cliente, venda, itemvenda, produto
    to ustabelascriadas;


-- ustabelasimportadas:
create user ustabelasimportadas password '321';

grant connect on database pe3008819 to ustabelasimportadas;
grant usage on schema cidades to ustabelasimportadas;

grant insert, update, select on table bairro, cidade, endereco, estado, faixa_bairros, faixa_cidades, geo, tabela_integrada, tabela_integrada_bairro
    to ustabelasimportadas;


-- usdeletegeral:
create user usdeletegeral password '333';

grant connect on database pe3008819 to usdeletegeral;
grant usage on schema cidades to usdeletegeral;

grant delete, select on table cliente, venda, itemvenda, produto, bairro, cidade, endereco, estado,
                              faixa_bairros, faixa_cidades, geo, tabela_integrada, tabela_integrada_bairro
    to usdeletegeral;

