-- 01 TOTAL DE CIDADES DO ESTADO DE SANTA CATARINA
select count(*) as total_cidade from Cidades where Estado = 'SC';

-- 02 TOTAL DE CIDADES POR ESTADO EM ORDEM ESTADO
select Estado, count(*) as total_por_estado from Cidades
group by Estado
order by Estado;

-- 03 AS 5 CIDADES MAIS POPULOSAS
select Municipio, Populacao from Cidades order by Populacao desc limit 5;

-- 04 OS 5 ESTADOS COM MAIS CIDADES ORDEM DESCRECENTE 
select Estado, count(Municipio) as total_cidades from Cidades group by Estado order by total_cidades desc limit 5;

-- 05 OS 5 ESTADOS MAIS POPULOSOS
select Estado, sum(Populacao) as total_populacao from Cidades group by Estado order by total_populacao desc limit 5;

-- 06 MEDIA DA POPULAÇÃO DE HOMEM E MULHERES POR ESTADO
select Estado, avg(pctHomem) as media_homem, avg(pctMulher) as media_mulher from Cidades group by Estado order by Estado;

-- 07 SOMA DA POPULACAO, SOMA DE HOMENS E MULHERES POR ESTADO PARA OS 10 PRIMEIROS REGISTROS
select Estado, sum(Populacao) as soma_populacao, round(sum(Populacao * (pctHomem / 100)), 0) as quant_homem, round(sum(Populacao * (pctMulher / 100)), 0) as quant_mulher from Cidades group by Estado limit 10;

-- 08 TODOS OS ESTADOS EM QUE A MEDIA DA POPULACAO DE MULHERES E ACIMA DE 50%
select Estado, round(avg(pctMulher), 2) as media_mulheres from Cidades group by estado having media_mulheres >= 50 order by Estado;

-- BONUS = QUAL A CIDADE COM MENOR POPULAÇÃO INICIANDO COM A LETRA A
select Municipio, min(Populacao) as menor_populacao from Cidades where left(upper(Municipio), 1) = 'A' group by Municipio order by menor_populacao limit 1;

-- 09 OS ESTADOS EM QUE A POPULAÇÃO DE MULHERES É MAIOR QUE A DE HOMEM
select Estado, round(sum(Populacao * (pctHomem / 100)), 0) as quant_homem, round(sum(Populacao * (pctMulher / 100)), 0) as quant_mulher from Cidades group by Estado having quant_homem < quant_mulher order by Estado;

-- 10 AS CIDADES COM MAIOR PERCENTUAL DE MULHERES
select count(Municipio) from Cidades where pctMulher > pctHomem;

-- 11 A CIDADE COM MENOR PERCENTUAL DE MULHERES E A DIFERENÇA DE PERCENTUAL EM RELAÇÃO AOS HOMENS
select Municipio, abs(pctmulher-pcthomem) as diferenca from Cidades where pctMulher = (select min(pctMulher) from Cidades);

-- 12 A CIDADE COM A MENOR POPULAÇÃO POR ESTADO
with dados as (
	select distinct(estado) as uf,
					min(populacao) as minimo,
                    max(populacao) as maximo
	from cidades
    group by estado
    order by estado
)
select uf, minimo, (select municipio from cidades
						where estado = uf and populacao = minimo) as menor,
					(select municipio from cidades
                    where estado = uf and populacao = maximo) as maior
from dados;

-- 13 AS CINCO MAIORES CIDADES SENDO UMA DE CADA ESTADO COM A MAIOR POUPULACAO
select estado, municipio, populacao from cidades where (estado, populacao) in (select estado, max(populacao) as max_populacao from cidades group by estado) order by populacao desc limit 5;

-- 14 A QUANTIDADE DE HOMENS E MULHERES POR ESTADO
select estado, sum(populacao) as total_populacao, round(sum(pctHomem * populacao / 100), 0) as total_homem, round(sum(pctMulher * populacao / 100), 0) as total_mulher from cidades group by estado order by total_populacao;

-- 15 A SOMATORIA DA POPULAÇÃO PELA INICIAL DA CIDADE A,B,C,D ...
select left(municipio, 1), sum(populacao) as total_populacao from cidades group by left(municipio, 1);

-- 16 A SOMATORIA DA POPULACAO POR ESTADO, SOMENTE PARA AS CIDADES ONDE PERCENTUAL DE HOMENS É MAIOR QUE O PERCENTUAL DE MULHERES
select estado, sum(populacao) as populacao from cidades where pcthomem > pctmulher group by estado;

-- 17 A CIDADE E ESTADO DA MAIOR DIFERENÇA DA POPULACAO DE HOMEM E MULHER
select estado, municipio, abs(pcthomem - pctmulher) from cidades where abs(pcthomem - pctmulher) = (select max(abs(pcthomem - pctmulher)) from cidades);
