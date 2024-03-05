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

-- =======================================================================================================================================

-- Função para mostrar a quantidade de musicas de um autor
DELIMITER $$
CREATE function qtdeMusicaAutor (codigoAut int) returns int
deterministic
BEGIN
	declare qtde int default 0;
    select count(*) from MusicaAutor where codaut=codigoAut into qtde;
    return qtde;
END $$
DELIMITER ;

select codaut, qtdeMusicaAutor(codaut) from autor;

-- =======================================================================================================================================

-- Procedure para alterar o preço
DELIMITER $$
CREATE procedure alterarPreco (in valor double)  
deterministic
BEGIN
	update cd set preco = preco + preco*(valor/100);
END $$
DELIMITER ;

call alterarPreco(100);
select * from cd;

drop procedure insereAutor;

-- =======================================================================================================================================

-- Procedure para inserir um autor
DELIMITER $$
CREATE procedure insereAutor (in nome varchar(100))  
deterministic
BEGIN
	declare ultimoCodigo int default 0;
    select max(codaut) from autor into ultimoCodigo;
    set ultimoCodigo = ultimoCodigo + 1;
    insert into autor values (ultimoCodigo, nome);
END $$
DELIMITER ;

call insereAutor('Pedro Baschoni');
select * from autor;

-- =======================================================================================================================================

-- Procedure para apagar um autor
DELIMITER $$
CREATE procedure apagarAutor (in codigoAutor int)  
deterministic
BEGIN
    delete from autor where codigoAutor=codaut;
END $$
DELIMITER ;

call apagarAutor(62);
select * from autor;

-- =======================================================================================================================================

-- Procedure para alterar um autor
DELIMITER $$
CREATE procedure alterarAutor (in codigoAutor int, nomeAutor varchar(100))  
deterministic
BEGIN
    update autor set nomeaut = nomeAutor where codigoAutor=codaut;
END $$
DELIMITER ;

call alterarAutor(62, 'Abigail baratela do Carmo');
select * from autor where codaut = 62;

-- =======================================================================================================================================

-- Função para pesquisar um autor
DELIMITER $$
CREATE function pesquisarAutor (nomeAutor varchar(100)) returns varchar(100) 
deterministic
BEGIN
    declare autorEncontrado varchar(100);
    select nomeaut from autor where nomeaut like concat('%', nomeAutor, '%') into autorEncontrado;
    return autorEncontrado;
END $$
DELIMITER ;

select pesquisarAutor('Abigail');

-- =======================================================================================================================================
drop function abntextendido;
DELIMITER $$
CREATE function abntextendido (nomeAutor varchar(100)) returns varchar(100) 
deterministic
BEGIN
    declare nomeAux varchar(100);
    
    set nomeAutor = upper(nomeAutor);
    set nomeAux = substring(reverse(nomeAutor), 1, locate(' ', reverse(nomeAutor)));
    set nomeAutor = substring(nomeAutor, 1, length(nomeAutor) - length(nomeAux));
    set nomeAux = concat(reverse(nomeAux), ', ', nomeAutor);
    
    return nomeAux;
END $$
DELIMITER ;

select abntextendido('Abigail Baratela do Carmo');