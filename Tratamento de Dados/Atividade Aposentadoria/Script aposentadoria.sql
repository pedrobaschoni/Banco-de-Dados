create table aposentadoria(
	nome			varchar(60),
	cpf				varchar(14),
	situacao 		varchar(15),
	matricula 		varchar(8),
	uorg 			varchar(10),
	orgao 			varchar(255),
	classe 			varchar(10),
	padrao 			varchar(3),
	regime 			varchar(3),
	fundamentacao 	varchar(10),
	dataocorrencia 	date,
	datadou 		date,
	ato 			varchar(10),
	doclegal 		varchar(10),
	numerodoc 		varchar(10),
	datapublicacao 	varchar(10)
);

COPY aposentadoria from 'Q:/dados/aposentadoria.csv' DELIMITER ';'
	CSV HEADER encoding 'ISO-8859-1'

select * from aposentadoria;

create table APOSBACKUP AS SELECT * FROM aposentadoria;

create or replace function atualizarcpf(entrada varchar(14)) returns varchar(14)
    language plpgsql
as
$$
    declare saida varchar default '';
BEGIN
    saida := '';
    saida := substring(entrada, 5, 3) ||'.'||
             substring(entrada, 5, 3) ||'.'||
             substring(entrada, 9, 3) ||'-'||
             substring(entrada, 10, 2);
    return saida;
end;
$$;

select atualizarcpf('***.888.977-**');

select * from aposentadoria;

update aposentadoria set cpf = atualizarcpf(cpf);

select * from aposentadoria limit 5;
select atualizarcpf(cpf) from aposentadoria;
select cpf, substring(cpf, 5, 3) || '.' || substring(cpf, 5, 3) from aposentadoria;

create or replace function atualizarmatricula(entrada1 varchar(14), entrada2 varchar(8)) returns varchar(8)
    language plpgsql
as
$$
    declare saida varchar default '';
BEGIN
    saida := '';
    saida := substring(entrada2, 1, 3) ||
             substring(entrada1, 5, 3) ||
             substring(entrada1, 10, 2);

    return saida;
end;
$$;

select atualizarmatricula('974.974.107-07', '138*****');
update aposentadoria set matricula = atualizarmatricula(cpf, matricula);
select * from aposentadoria;

create table orgao as select distinct (uorg), ORGAO from aposentadoria;

update APOSBACKUP set uorg='250206' where orgao='ELETROBRAS';

create table orgao as
select uorg as iduorg,
       count(*) as qtdeapos,
       (select  orgao from APOSBACKUP where uorg=ap.uorg limit 1) as orgao from APOSBACKUP ap
            group by  iduorg;

alter table aposentadoria rename column uorg to iduorg;

select * from orgao;

alter table orgao add primary key (iduorg);
alter table aposentadoria drop column orgao;
alter table aposentadoria
    add foreign key (iduorg) references orgao (iduorg);

select * from aposentadoria;

create  table classes as
select distinct (classe), padrao from APOSBACKUP
    order by  classe, padrao;

alter table classes add column idclasse serial primary key ;
select * from classes;

alter table aposentadoria add column idclasse int;
update aposentadoria ap set idclasse = (select  idclasse from classes where classe=ap.classe and ap.padrao=padrao)
    where ap.idclasse is null;

select  * from aposentadoria;

alter table aposentadoria drop column classe;

select extract(day from datadou) from aposentadoria;
select datadou, doclegal from aposentadoria where extract(month  from datadou) = 6 -- testes do extract
order by doclegal;

CREATE OR REPLACE PROCEDURE numdocumento() as $$

DECLARE
    vetor integer[];
    meses varchar[];
    mes integer;
    valor int;
    numdoc varchar;
    dados record;
BEGIN
    vetor := ARRAY[0,0,0,0,0,0,0,0,0,0,0,0];
    meses := array['JA','FE','MA','AB','MA','JN','JL','AG','SE','OU','NV','DE'];
    for dados in select iddados,extract(month from datadou) as nmes from aposentadoria loop
        vetor[dados.nmes]:=vetor[dados.nmes]+1;
        valor:=100000+vetor[dados.nmes];
        numdoc=meses[dados.nmes]||substring(cast(valor as varchar),2,5);
        RAISE NOTICE '%',numdoc;
        update aposentadoria set doclegal = numdoc where iddados=dados.iddados;
    end loop;
END;
$$ LANGUAGE plpgsql;

select doclegal from aposentadoria where iddados =5385;

alter table aposentadoria add column iddados serial primary key;

call numdocumento();

select * from aposentadoria;
select * from orgao;

create table aposentadoria(
	nome			varchar(60),
	cpf				varchar(14),
	situacao 		varchar(15),
	matricula 		varchar(8),
	uorg 			varchar(10)
	    references orgao,
	padrao 			varchar(3),
	regime 			varchar(3),
	fundamentacao 	varchar(10),
	dataocorrencia 	date,
	datadou 		date,
	ato 			varchar(10),
	doclegal 		varchar(10),
	numerodoc 		varchar(10),
	datapublicacao 	varchar(10),
	idclasse        integer
        references classes,
    iddados         serial
        primary key
);