drop database if exists cd;
create database cd;
use cd;

CREATE TABLE Gravadora (
       codgrav              SMALLINT    NOT NULL,
       nomegrav             VARCHAR(60) NULL,
       ender                VARCHAR(60) NULL,
       telefone             VARCHAR(20) NULL,
       contato              VARCHAR(20) NULL,
       url                  VARCHAR(80) NULL,
       PRIMARY KEY (codgrav)
);

CREATE TABLE CD (
       codcd                INTEGER       NOT NULL,
       codgrav              SMALLINT      NULL,
       nomecd               VARCHAR(60)   NULL,
       preco                DECIMAL(14,2) NULL,
       datalanc             DATE          NULL,
       indica               INTEGER       NULL,
       PRIMARY KEY (codcd),
       FOREIGN KEY (codgrav) REFERENCES Gravadora(codgrav),
       FOREIGN KEY (indica)  REFERENCES CD(codcd)
);

CREATE TABLE Musica (
       codmus               INTEGER      NOT NULL,
       nomemus              VARCHAR(60)  NULL,
       duracao              DECIMAL(6,2) NULL,
       PRIMARY KEY (codmus)
);

CREATE TABLE Autor (
       codaut            INTEGER     NOT NULL,
       nomeaut           VARCHAR(60) NULL,
       PRIMARY KEY (codaut) 
);

CREATE TABLE MusicaAutor (
       codmus           INTEGER NOT NULL,
       codaut           INTEGER NOT NULL,
       PRIMARY KEY (codmus, codaut),
       FOREIGN KEY (codaut) REFERENCES Autor (codaut),
       FOREIGN KEY (codmus) REFERENCES Musica(codmus) 
);

CREATE TABLE Faixa (
       codmus           INTEGER  NOT NULL,
       codcd            INTEGER  NOT NULL,
       num              SMALLINT NULL,
       PRIMARY KEY (codmus, codcd),
       FOREIGN KEY (codcd)  REFERENCES CD(codcd),
       FOREIGN KEY (codmus) REFERENCES Musica(codmus)
);

CREATE TABLE CDCategoria(
       codcat       SMALLINT      NOT NULL,
       menor        DECIMAL(14,2) NOT NULL,
       maior        DECIMAL(14,2) NOT NULL
);

-- 1 Os 5 autores com a maior quantidade de musicas (COM JOIN)
SELECT A.nomeaut, COUNT(MA.codmus) AS qtd_musicas
	FROM Autor A
JOIN MusicaAutor MA ON A.codaut = MA.codaut
GROUP BY A.nomeaut
ORDER BY qtd_musicas DESC LIMIT 5;

-- 1 Os 5 autores com a maior quantidade de musicas (SEM JOIN)
SELECT A.nomeaut, 
	(SELECT COUNT(*) FROM MusicaAutor MA WHERE MA.codaut = A.codaut) AS qtd_musicas
	FROM Autor A
ORDER BY qtd_musicas DESC
LIMIT 5;

-- 2 A somatória da duração das musica de cada CD, mostre o nome do CD e a DURACAO (COM JOIN)
SELECT CD.nomecd, SUM(M.duracao) AS duracao_total
	FROM CD
JOIN Faixa F ON CD.codcd = F.codcd
JOIN Musica M ON F.codmus = M.codmus
GROUP BY CD.nomecd;

-- 2 A somatória da duração das musica de cada CD, mostre o nome do CD e a DURACAO (SEM JOIN)
SELECT CD.nomecd, 
	(SELECT SUM(M.duracao) FROM Faixa F, Musica M WHERE F.codcd = CD.codcd AND F.codmus = M.codmus) AS duracao_total
	FROM CD;

-- 3 Mostrar todas as durações que possuem mais de 3 musicas (COM JOIN)
SELECT SUM(M.duracao) AS duracao_total
	FROM CD
JOIN Faixa F ON CD.codcd = F.codcd
JOIN Musica M ON F.codmus = M.codmus
GROUP BY CD.codcd
HAVING COUNT(*) > 3;

-- 3 Mostrar todas as durações que possuem mais de 3 musicas (SEM JOIN)
SELECT 
	(SELECT SUM(M.duracao) FROM Faixa F, Musica M WHERE F.codcd = CD.codcd AND F.codmus = M.codmus) AS duracao_total
FROM CD WHERE (SELECT COUNT(*)FROM Faixa F WHERE F.codcd = CD.codcd) > 3;

-- 1 Crie uma query que mostre o nome do autor, nome da musica e nome do CD ordem nome do autor
SELECT Autor.nomeaut, Musica.nomemus, CD.nomecd
	FROM Autor
JOIN MusicaAutor ON Autor.codaut = MusicaAutor.codaut
JOIN Musica ON MusicaAutor.codmus = Musica.codmus
JOIN Faixa ON Musica.codmus = Faixa.codmus
JOIN CD ON Faixa.codcd = CD.codcd
ORDER BY Autor.nomeaut;

-- 2 Quais CDS e preco deles estão sendo vendido acima da media de preços
SELECT nomecd, preco
	FROM CD WHERE preco > (SELECT AVG(preco) FROM CD);

-- 3 Qual a media de preco por gravadora
SELECT Gravadora.nomegrav, ROUND(AVG(CD.preco), 2) AS media_preco
	FROM Gravadora
JOIN CD ON Gravadora.codgrav = CD.codgrav
GROUP BY Gravadora.nomegrav;

-- 4 Qual gravadora possui os CD mais caro
SELECT Gravadora.nomegrav
	FROM Gravadora
JOIN CD ON Gravadora.codgrav = CD.codgrav
GROUP BY Gravadora.nomegrav
HAVING MAX(CD.preco) = (SELECT MAX(preco) FROM CD);

-- 5 Sabendo-se que cada CD tem um preco e uma quantidade de musica, calcule quanto custa cada musica no CD em seguida verique qual o autor recebeu mais de somando-
--   se as musicas de cada CD que ele aparece. Coloque o nome do autor e o total em ordem decrescente de valor.
SELECT Autor.nomeaut, 
       ROUND(SUM(CD.preco / (SELECT COUNT(Faixa.num) FROM Faixa WHERE Faixa.codcd = CD.codcd)), 2) AS total_recebido
	FROM Autor
JOIN MusicaAutor ON Autor.codaut = MusicaAutor.codaut
JOIN Musica ON MusicaAutor.codmus = Musica.codmus
JOIN Faixa ON Musica.codmus = Faixa.codmus
JOIN CD ON Faixa.codcd = CD.codcd
GROUP BY Autor.nomeaut
ORDER BY total_recebido DESC;
