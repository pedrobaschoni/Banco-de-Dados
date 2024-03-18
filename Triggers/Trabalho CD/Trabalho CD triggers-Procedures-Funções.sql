set search_path to cd;

create schema cd;
set search_path  to cd;

create or replace function qtdemusicacd(entrada_cd int)
    returns int
language 'plpgsql'
as
$$
declare  qtde int default 0;
begin
    select count(*) from faixa where codcd=entrada_cd into qtde;
    return qtde;
end;

$$;

select qtdemusicacd(1);

create or replace function qtdeautor(entrada_aut int)
    returns int
language 'plpgsql'
as
$$
declare  qtde int default 0;
begin
    select count(*) from musicaautor where codaut=entrada_aut into qtde;
    return qtde;
end;

$$;

select qtdeautor(2);

create or replace function contacd(entrada_grav int)
    returns int
language 'plpgsql'
as
$$
declare  qtde int default 0;
begin
    select count(*) from cd where codgrav=entrada_grav into qtde;
    return qtde;
end;

$$;

select gravadora.nomegrav, contacd(codgrav) from gravadora;

alter table cd add column precovenda float;

create procedure atualizavenda(valor float)
language 'plpgsql'
as
$$

begin
    update cd set precovenda = preco + preco*(valor/100) where codcd>=1;
end;

$$;

call atualizavenda(100);
select * from cd;

alter table gravadora add column aumento decimal(10,2);

create procedure mostragravadora()
language 'plpgsql'
as
$$
    declare DADOS record;
begin
    for DADOS in select * from gravadora loop
        raise notice '%' ,DADOS.nomegrav,DADOS.aumento;
    end loop;
end;
$$;

call mostragravadora();

select nomegrav, aumento from gravadora;

update gravadora set aumento = 10 where codgrav = 1;
update gravadora set aumento = 10 where codgrav = 2;
update gravadora set aumento = 15 where codgrav = 3;
update gravadora set aumento = 5 where codgrav = 4;

create procedure vendaporaumento()
language 'plpgsql'
as
$$
    declare DADOS record;
begin
    for DADOS in select * from gravadora loop
        update cd set precovenda = preco + preco*(DADOS.aumento/100) where DADOS.codgrav=cd.codgrav;
    end loop;
end;
$$;

call vendaporaumento();
select codgrav, precovenda from cd;


create table musicadocd(
    codmus int,
    codcd int,
    nomemusica varchar(60),
    primary key(codmus, codcd)
);

alter table musicadocd add column autor varchar(60);

create function adicionaautor(codigo_mus int) returns varchar
language 'plpgsql'
as
$$
    declare nomeAutor varchar(60);
begin
    select nomeaut from autor a join musicaautor m on (a.codaut=m.codaut) where codmus=codigo_mus limit 1 into nomeAutor;
    return nomeAutor;
end;
$$;

create or replace procedure gravemusica(codigo_cd int)
language 'plpgsql'
as
$$
    declare musicas_faixa record;
begin
    delete from musicadocd where codcd<>0;
    for musicas_faixa in select f.codcd, f.codmus, m.nomemus
                         from faixa f join musica m on (m.codmus = f.codmus)
                         where codcd=codigo_cd loop
        insert into musicadocd values (musicas_faixa.codmus, musicas_faixa.codcd, musicas_faixa.nomemus, adicionaautor(musicas_faixa.codmus)); -- Ou faz automatico com a trigger
        raise notice '% %', musicas_faixa.codcd,musicas_faixa.nomemus;
    end loop;
end;
$$;

call gravemusica(3);
select * from musicadocd;

drop table cliente;

create table cliente(
    codcli serial primary key,
    nome varchar(60),
    endereco varchar(60),
    cidade varchar(50),
    uf varchar(2),
    cep varchar(10)
);

drop procedure gerarcliente;

create procedure gerarcliente(quant int)
language 'plpgsql'
as
$$
    declare i int default 1;
begin
    while i <= quant loop
		insert into cliente (nome, endereco, cidade, uf, cep) values (concat('Cliente ', i), 'Rio Branco', 'Presidente Epitácio', 'SP', concat('19470-', i));
		i := i + 1;
    end loop;
end;
$$;


call gerarcliente(100);

select * from cliente;

create function buscanome() returns trigger
    language 'plpgsql'
as
$$
    declare codigo int default 0;
    declare nome varchar(60) default '';
begin
    select codaut from musicaautor where codmus=new.codmus into codigo;
    select nomeaut into nome from autor where codaut=codigo;
    new.autor := nome;
    return new;
end;
$$;

create trigger tg_buscanome
    before insert
    on musicadocd
    for each row
execute procedure buscanome();

call gravemusica(1);
select * from musicadocd;

create table venda(
    idvenda int primary key,
    datavenda date,
    codcli int,
    Parcelas int,
    foreign key (codcli) references cliente (codcli)
);

drop table venda;
drop table itemvenda;

create table itemvenda (
    idvenda integer,
    codcd integer,
    qtde integer,
    primary key (idvenda, codcd),
    foreign key (codcd) references cd (codcd),
    foreign key (idvenda) references venda(idvenda)
);

create procedure gerarvenda(qtde int)
    language 'plpgsql'
as
$$
    declare i int default 1;
    declare parcelas int default 1;
    declare contador int default 1;
begin
    while i <= qtde loop
        insert into venda values (i, current_date, contador, parcelas);
        contador = contador + 1;
        parcelas = parcelas + 1;

        if contador > 100 then
            contador = 1;
        end if;

        if parcelas > 12 then
            parcelas = 1;
        end if;

        i := i + 1;
    end loop;
end;
$$;

call gerarvenda(1000);

select * from venda;

alter table itemvenda add column preco numeric;

update itemvenda iv set preco = (select preco from cd c where codcd=iv.codcd);

select * from itemvenda;

select sum(qtde*preco) from itemvenda where idvenda=1;

alter table venda add column valortotal numeric;

update venda set valorTotal =
	(select sum(preco*qtde) from itemvenda where idvenda=venda.idvenda)
where idvenda>0;

select * from venda;

create or replace function atualizarvalor() returns trigger
    language 'plpgsql'
as
$$
begin
    if(TG_OP = 'INSERT') then
        update venda set valortotal = valortotal + (new.preco*new.qtde) where idvenda=new.idvenda;
        return new;
    end if;

    if(TG_OP = 'UPDATE') then
        update venda set valortotal = valortotal - (old.preco*old.qtde) + (new.preco*new.qtde) where idvenda=new.idvenda;
        return new;
    end if;

    if(TG_OP = 'DELETE') then
        update venda set valortotal = valortotal - (old.preco*old.qtde) where idvenda=old.idvenda;
        return old;
    end if;

end;
$$;

create trigger tg_atualizarvalor
    after insert or update or delete
    on itemvenda
    for each row
execute function atualizarvalor();

update itemvenda set preco=10 where codcd=1 and idvenda=1;
update itemvenda set preco=15 where codcd=1 and idvenda=1;
select valortotal from venda where idvenda=1;

select * from venda where idvenda = 1;
select * from itemvenda where idvenda = 1 and idvenda = 1;

update itemvenda set preco=15 where codcd =1;

insert into itemvenda values (1, 2, 1, 10);

delete from itemvenda where idvenda = 1 and codcd = 2;

alter table cliente add column valorcomprado numeric;

update cliente set valorcomprado =
	(select sum(valortotal) from venda where codcli=cliente.codcli)
where codcli>0;

select * from cliente;

create or replace function retornatotalcliente(codigo int) returns numeric
    language 'plpgsql'
as
$$
    declare total numeric default 0;
begin
    select sum(valortotal) from venda where codcli=codigo into total;
    return total;
end;
$$;

select retornatotalcliente(1);

create or replace function atualizavalorcomprado() returns trigger
    language 'plpgsql'
as
$$
begin
    if(TG_OP = 'INSERT') then
        update cliente set valorcomprado = retornatotalcliente(new.codcli) where codcli=new.codcli;
        return new;
    end if;

    if(TG_OP = 'UPDATE') then
        update cliente set valorcomprado = retornatotalcliente(new.codcli) where codcli=new.codcli;
        return new;
    end if;

    if(TG_OP = 'DELETE') then
        update cliente set valorcomprado = retornatotalcliente(old.codcli) where codcli=old.codcli;
        return new;
    end if;

end;
$$;

create trigger tg_atualizavalorcomprado
    after insert or update or delete
    on venda
    for each row
execute function atualizavalorcomprado();

insert into cliente values (101, 'Pedro Lucas',	'Rio Branco', 'Presidente Epitácio', 'SP', 19470-000, 0);
insert into venda(idvenda, datavenda, codcli, parcelas, valorTotal) values (1003, current_date, 101, 1, 0);
insert into itemvenda  values (1003, 1, 1, 3.00);
select * from venda where idvenda = '1003';
select * from cliente where codcli = '101';
update itemvenda set qtde = 4 where idvenda = '1003' and codcd = 1;
delete from cliente where codcli=101;
delete from venda where idvenda=1003;
delete from itemvenda where idvenda=1003;


