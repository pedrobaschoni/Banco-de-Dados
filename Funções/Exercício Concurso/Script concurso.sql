create database concurso;
use concurso;

create table concurso(
  nome varchar(100)

);

insert into concurso values("1 HENRIQUE MARTINS DOS SANTOS COSTA 617.003.103-48 APROVADO 758,16");
insert into concurso values("2 ANTONIO EVERALDO COSTA DE LIRA NETO 146.032.834-58 APROVADO 737,46");
insert into concurso values("3 ELLEN GOMES LUNA 061.883.923-22 APROVADO 728,54");
insert into concurso values("4 LARISSA ALANA CHERQUE ROCCON 142.787.877-31 APROVADO 723,54");
insert into concurso values("5 ANA BEATRIZ FERREIRA MODESTO 074.135.984-77 APROVADO 722,48");
insert into concurso values("6 HIAM PINHEIRO LANDIM 051.405.243-09 APROVADO 718,36");
insert into concurso values("7 LÍVIA ANDRADE BARROS 062.555.063-39 APROVADO 713,42");
insert into concurso values("8 CARLOS ALBERTO ZATTI ARAPONGA 033.842.935-25 APROVADO 711,16");
insert into concurso values("9 LAÍZA CLÁUDIA BARBOSA DE MACEDO 086.612.524-82 APROVADO 708,52");
insert into concurso values("10 MATHEUS BATISTA DE ALBUQUERQUE 711.740.544-92 APROVADO 705,66");
insert into concurso values("11 JUDÁ MACHADO TORQUATO 071.713.993-03 APROVADO 701,88");
insert into concurso values("12 CICERO FERRUCIO PONTES TERCEIRO 075.520.293-74 APROVADO 698,06");
insert into concurso values("13 WIZILLANY ELLEN BARBOSA DE ALMEIDA 058.694.484-25 APROVADO 695,92");
insert into concurso values("14 ROBERTO BRAYNER DE FARIAS XAVIER 109.555.124-84 APROVADO 693,12");
insert into concurso values("15 VICTORIA MARIA FONTENELE COSTA 056.041.283-50 APROVADO 690,68");
insert into concurso values("16 CARLOS RODOLFO SIA DE QUEIROZ BRAGA 048.861.994-70 APROVADO 689,42");
insert into concurso values("17 LARA QUINTINO DE MACÊDO 087.777.413-74 APROVADO 686,40");
insert into concurso values("18 LIVIA FERREIRA LIMA 705.203.624-03 APROVADO 686,24");
insert into concurso values("19 VINÍCIUS VICTOR DA SILVA MORAIS 108.374.094-62 APROVADO 685,46");
insert into concurso values("20 FRANCIMAR RODRIGUES DE OLIVEIRA JUNIOR 069.692.954-60 APROVADO 685,16");
insert into concurso values("21 LUCIANO RODRIGUES PACHECO FILHO 080.551.394-90 APROVADO 684,60");
insert into concurso values("22 ANA LUÍZA INGELBERT SILVA 071.329.374-80 APROVADO 683,78");
insert into concurso values("23 NICOLE SILVA FLOR 051.719.132-69 APROVADO 683,36");
insert into concurso values("24 JOSE OTAVIO DELMONDES DE ALENCAR MELO 126.751.984-39 APROVADO 682,94");
insert into concurso values("25 MARIA LOREN GOMES LUCENA DE MÉLLO 080.253.764-27 APROVADO 682,32");
insert into concurso values("26 LUCIA VITÓRIA FIGUEROA DIAS 116.024.684-00 APROVADO 682,12");
insert into concurso values("27 MARCELA DE GODOY CARVALHO DUQUE 114.771.784-22 APROVADO 682,02");
insert into concurso values("28 MARIA CLARA DA SILVA ROCHA 071.526.534-29 APROVADO 681,62");
insert into concurso values("29 VICTOR FRANCISO VITORIA BRENHA 131.686.364-60 APROVADO 679,14");
insert into concurso values("30 ISLARA RODRIGUES CAVALCANTE 058.375.743-01 APROVADO 677,92");
insert into concurso values("31 THAINA AYMAR RIBEIRO 711.025.514-06 APROVADO 677,78");
insert into concurso values("32 FRANCISCO VIANA ARRUDA JUNIOR 065.455.123-58 APROVADO 677,38");
insert into concurso values("33 ABIDENEGO JUSTINO RAMOS NETO 122.298.764-30 APROVADO 677,08");
insert into concurso values("34 WALDEMAR DE BRITO CAVALCANTI NETO 120.345.274-88 APROVADO 675,84");
insert into concurso values("35 ALICE GABRIELLY CAVALCANTE OLIVEIRA MORAIS 705.126.864-32 APROVADO 675,44");
insert into concurso values("36 TIAGO MUNIZ VIEIRA DE MELO 108.022.984-19 APROVADO 675,10");
insert into concurso values("37 ALICE JOANA SOUZA VIEIRA DA SILVA 124.217.624-13 APROVADO 674,36");
insert into concurso values("38 JOSÉ ZITO DE OLIVEIRA NETO 075.370.803-56 APROVADO 674,04"); 

-- Adicionando todos atributos na tabela concurso
alter table concurso 
    add column posicao int,
    add column nomeCandidato varchar(100),
    add column situacao varchar(15),
    add column cpf varchar(14),
    add column nota double;

-- Comando para desabilitar a segurança e poder dar UPDATE sem WHERE
set sql_safe_updates = 1;

alter table concurso
	add primary key (nome);

-- Posição (Pega da primeira posição até o primeiro espaço)
select substring(nome,1,locate(' ',nome)) from concurso;
update concurso set posicao = substring(nome,1,locate(' ',nome)) where nome<>''; -- Posso dar update usando o WHERE com a condição da minha chave primaria (nome) sendo diferente de null (nome<>'')
select posicao from concurso; 

-- Nome Candidato
select substring(nome,locate(' ',nome), length(nome)) from concurso;
update concurso set nomeCandidato = substring(nome, locate(' ', nome) + 1, length(nome)); 

-- Nota
select (replace(right(trim(nome),6),',','.')) from concurso;
update concurso set nota = (replace(right(trim(nome),6),',','.')) where posicao<>'';

-- Aprovado
update concurso set situacao = 'APROVADO' where nome like '%APROVADO%' and posicao>0;

-- Tirando tudo menos o cpf do nome Candidato
select substring(nome,1,locate('APROVADO',nome)-1) from concurso;
update concurso set nomeCandidato = LEFT(nomeCandidato,locate('APROVADO',nomeCandidato)-1) where posicao>0;

-- CPF
update concurso set cpf = right(trim(nomeCandidato),14);
update concurso set cpf = right(trim(nomeCandidato),14) where posicao>0; -- Com o where

-- Remove o cpf do nome candidato
update concurso set nomeCandidato = substring(trim(nomeCandidato),1,length(trim(nomeCandidato)) - 15);

-- Atualizando o nome
update concurso set nome = nomeCandidato;

-- Colocando a situacao de ELIMINADO para todo mundo com sobrenome SILVA
update concurso set situacao = 'ELIMINADO' where nome like '%SILVA%';
select * from concurso where nome LIKE '%SILVA%';

-- Removendo a coluna 'nomeCandidato' que era apenas uma segurança no caso de cometer um erro ao atualizar o banco
alter table concurso
	drop column nomeCandidato;
    
-- Dropa a primary key nome que estava utilizando para o WHERE
alter table concurso
	drop primary key;

-- Posição é uma chave primaria
alter table concurso
	add primary key (posicao);
    
alter table concurso
	add column cpfCandidato varchar(14);

update concurso set cpfCandidato = cpf;
select concat('***.',substring(cpfCandidato, 5, 3),'.***',substring(cpfCandidato, 12)) as cpfFormatado from concurso;

drop function ALTERARCPF;

DELIMITER $$
CREATE function ALTERARCPF (cpf varchar(14)) returns varchar(14)
deterministic
BEGIN
	declare cpfFormatado varchar(14);
	select concat('***.',substring(cpf, 5, 3),'.***',substring(cpf, 12)) into cpfFormatado;
    return cpfFormatado;
END $$
DELIMITER ;

update concurso set cpfCandidato = ALTERARCPF(cpfCandidato) where posicao > 0;

update concurso set cpf = cpfCandidato;
alter table concurso
	drop column cpfCandidato;

select * from concurso;