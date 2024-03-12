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
        insert into musicadocd values (musicas_faixa.codmus, musicas_faixa.codcd, musicas_faixa.nomemus, adicionaautor(musicas_faixa.codmus));
        raise notice '% %', musicas_faixa.codcd,musicas_faixa.nomemus;
    end loop;
end;
$$;

call gravemusica(3);
select * from musicadocd;

drop table cliente;

create table cliente(
    idcliente serial primary key,
    nome varchar(60),
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
		insert into cliente (nome, cidade, uf, cep) values (concat('Cliente ', i), 'Presidente Epitácio', 'SP', concat('19470-', i));
		i := i + 1;
    end loop;
end;
$$;


call gerarcliente(100);

select * from cliente;