-- 1) abntextendido – Recebendo um nome retorna ele no formato ABNT Nome inteiro
drop function if exists abntextendido;

DELIMITER $$
CREATE function abntextendido (nome varchar(100)) returns varchar(100)
deterministic
BEGIN
	declare nomeAux varchar(100);
    
    set nome = upper(nome);
    set nomeAux = substring(reverse(nome), 1, locate(' ', reverse(nome)));
    set nome = substring(nome, 1, length(nome) - length(nomeAux));
    set nomeAux = concat(reverse(nomeAux), ', ', nome);
    
    
    return nomeAux;
    
END $$
DELIMITER ;

select abntextendido("Pedro Lucas Calvo Baschoni");
select abntextendido("Abigail Baratela do Carmo");

-- 2) abnt – Recebendo um nome retorna ele no formato ABNT nome abreviado
drop function if exists abnt;

DELIMITER $$
CREATE function abnt (nome varchar(100)) returns varchar(100)
deterministic
BEGIN
	declare nomeAux varchar(100);
    declare i int default 1;
    
    set nome = abntextendido(nome);
    set nomeAux = substring(nome, 1, locate(', ', nome));
    set nomeAux = concat(nomeAux, ' ');
    
    set i = locate(', ', nome);
    while i <= length(nome) do
    
		if substring(nome, i, 4) = ' de ' or substring(nome, i, 4) = ' de' or substring(nome, i, 4) = ' da ' or
        substring(nome, i, 4) = ' da' or substring(nome, i, 4) = ' do ' or substring(nome, i, 4) = ' do' then
			set nomeAux = concat(nomeAux, substring(nome, i+1, 2));
            set nomeAux = concat(nomeAux, '. ');
            
		else if substring(nome, i, 5) = ' des ' or substring(nome, i, 5) = ' des' or 
        substring(nome, i, 5) = ' das ' or substring(nome, i, 5) = ' das' then
			set nomeAux = concat(nomeAux, substring(nome, i+1, 3));
            set nomeAux = concat(nomeAux, '. ');
			
		else if substring(nome, i, 1) = ' ' then
			set nomeAux = concat(nomeAux, substring(nome, i+1, 1));
            set nomeAux = concat(nomeAux, '. ');
            
        end if;
        end if;
        end if;

		set i = i +1;
    end while;
    
    return nomeAux;
    
END $$
DELIMITER ;

select abnt("Pedro Lucas Calvo Baschoni");
select abnt("Abigail Baratela do Carmo");

-- 3) abrevia – Recebendo um nome retorna o nome abreviado
drop function if exists abrevia;

DELIMITER $$
CREATE function abrevia (nome varchar(100)) returns varchar(100)
deterministic
BEGIN
	declare nomePrimeiro varchar(100);
	declare nomeMeio varchar(100) default ' ';
	declare nomeFim varchar(100);
    declare i int default 1;
    
    set nome = upper(nome);
    set nomePrimeiro = substring(nome, 1, locate(' ', nome));
    set nomePrimeiro = trim(nomePrimeiro);
    set nomeFim = substring(reverse(nome), 1, locate(' ', reverse(nome)));
    set nome = substring(nome, 1, length(nome) - length(nomeFim));
    set nome = substring(nome, locate(' ', nome), length(nome));
    set nomeFim = trim(nomeFim);
    
    
    while i <= length(nome) do
		if substring(nome, i, 4) = ' de ' or substring(nome, i, 4) = ' de' or substring(nome, i, 4) = ' da ' or
        substring(nome, i, 4) = ' da' or substring(nome, i, 4) = ' do ' or substring(nome, i, 4) = ' do' then
			set nomeMeio = concat(nomeMeio, substring(nome, i+1, 2));
            set nomeMeio = concat(nomeMeio, '. ');
            
		else if substring(nome, i, 5) = ' des ' or substring(nome, i, 5) = ' des' or 
        substring(nome, i, 5) = ' das ' or substring(nome, i, 5) = ' das' then
			set nomeMeio = concat(nomeMeio, substring(nome, i+1, 3));
            set nomeMeio = concat(nomeMeio, '. ');
			
		else if substring(nome, i, 1) = ' ' then
			set nomeMeio = concat(nomeMeio, substring(nome, i+1, 1));
            set nomeMeio = concat(nomeMeio, '. ');
            
        end if;
        end if;
        end if;
        
		set i = i + 1;
    end while;
    
    set nome = concat(nomePrimeiro, nomeMeio, reverse(nomeFim));
    
    return nome;
    
END $$
DELIMITER ;

select abrevia("Pedro Lucas Calvo Baschoni");
select abrevia("Abigail Baratela do Carmo");

-- 4) retornanome – Recebendo uma posição e um nome, retorne a palavra correspondente a posição informada
drop function if exists retornaNome;

DELIMITER $$
CREATE function retornaNome (posicao int, nome varchar(100)) returns varchar(100)
deterministic
BEGIN
	declare nomeAux varchar(100);
    declare contaEspaco int default 1;
    declare inicio int default 1;
    declare aux int default 1;
    declare fim int default 1;
    
    set nome = upper(nome);
    
    if contaEspaco = posicao then
		return substring(nome, 1, locate(' ', nome));
    end if;
    
    while inicio <= length(nome) and contaEspaco < posicao do
		
        if substring(nome, inicio, 1) = ' ' then
			set contaEspaco = contaEspaco + 1;
		end if;
			
		set inicio = inicio + 1;
    end while;
    
    set aux = inicio;
    
    while aux <= length(nome) and contaEspaco < posicao + 1 do
    
		if substring(nome, aux, 1) = ' ' then
			set contaEspaco = contaEspaco + 1;
		end if;
    
		set aux = aux + 1; 
		set fim = fim + 1; 
    end while;
    
    set nomeAux = substring(nome, inicio, fim - 1);
    set nomeAux = trim(nomeAux);
    return nomeAux;
    
END $$
DELIMITER ;

select retornaNome(2, "Pedro Lucas Calvo Baschoni");
select retornaNome(3, "Abigail Baratela do Carmo");

-- 5) contvogais – Recebendo um texto retorne a quantidade de vogais no texto
drop function if exists contvogais;

DELIMITER $$
CREATE function contvogais(nome varchar(100)) returns varchar(100) 
deterministic 
BEGIN
	
	declare i int default 1;
    declare contadorVogal int default 0;
        
	while i <= length(nome) do
    
		if substring(nome, i, 1) = 'a' or substring(nome, i, 1) = 'e' or substring(nome, i, 1) = 'i'
        or substring(nome, i, 1) = 'o' or substring(nome, i, 1) = 'u' then
			set contadorVogal = contadorVogal + 1;
        end if;
        
		set i = i + 1;
    end while;
        
    return contadorVogal;
END $$
DELIMITER ;

select contvogais("Pedro Lucas Calvo Baschoni");
select contvogais("Abigail Baratela do Carmo");

-- 6) autores – Uma função no banco de dados CD que ao receber o codigo de uma musica mostre todos os autores dela em formato de uma STRING em letra MAIUSCULA
drop function if exists autores;

DELIMITER $$
CREATE function autores(codigo int)
returns varchar(255)
deterministic
BEGIN
	declare nome varchar(255);
	
    select GROUP_CONCAT(' ',UPPER(nomeaut)) into nome from autor a
	join musicaautor ma on (ma.codaut = a.codaut)
	join musica m on (ma.codmus = m.codmus)
	where m.codmus = codigo;
        
        return nome;
        
END $$
DELIMITER ;

select autores(3);