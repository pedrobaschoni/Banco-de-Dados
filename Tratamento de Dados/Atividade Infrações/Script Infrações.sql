create schema infracoes;

set search_path to infracoes;

create table dadosinfracao (
	
	DatGeracaoConjuntoDados date,
	SigAgenteFiscalizador varchar(45),
	NumAutoInfracao varchar(30),
	DatLavraturaAutoInfracao date,
	NomNaturezaFiscalizacao varchar(200),
	DscObjetoFiscalizado varchar(3200),
	CodObjetoFiscalizado varchar(1200),
	NomAgenteFiscalizado varchar(200),
	NumCPFCNPJAgenteFiscalizado varchar(30),
	NumProcessoPunitivo varchar(200),
	NumProcessoPunitivoANEEL varchar(40),
	DatRecebimentoAutoInfracao date,
	DscTipoPenalidade varchar(200),
	VlrPenalidade NUMERIC(10, 2),
	DtRecebimentoRecurso date,
	DatDecisaoJuizo date,
	DscDecisaoCompletaJuizo varchar(200),
	DscAtoJuizo varchar(40),
	VlrMultaAposJuizo numeric(10,2),
	DatDecisaoDiretoria varchar(30),
	DscDecisaoCompletaDiretoria varchar(200),
	DscAtoDiretoria varchar(70),
	VlrMultaAposDiretoria numeric(10,2),
	NumTermoEncerramento varchar(50),
	DatLavraturaTE varchar(20),
	DscEnquadramentoAI varchar(250),
	NumTermoNotificacao varchar(100),
	NumProcessoFiscalizacao varchar(100)
	
);

COPY dadosinfracao FROM 'c:/BD2/autoinfracao.CSV' DELIMITER ';'
    CSV HEADER encoding 'ISO-8859-1';

create table agenteFiscalizados(
	idagenteFiscalizados serial primary key,
	sigla varchar(45)
);

INSERT INTO agenteFiscalizados (sigla)
SELECT DISTINCT SigAgenteFiscalizador FROM dadosinfracao;

alter table dadosinfracao add idagenteFiscalizados int;
 
update dadosinfracao set idagenteFiscalizados = af.idagenteFiscalizados 
	from agenteFiscalizados af
		where af.sigla = SigAgenteFiscalizador;

alter table dadosinfracao drop column SigAgenteFiscalizador;

alter table dadosinfracao add foreign key (idagenteFiscalizados)
	references agenteFiscalizados (idagenteFiscalizados);
 
create table AgenteFiscalizado(
	idAgenteFiscalizado serial primary key,
	descricao varchar(150),
	cnpf varchar(16),
	agentefiscalizadocol varchar(45),
	valortotalmultas decimal(15,2)
);

INSERT INTO AgenteFiscalizado (descricao,cnpf,agentefiscalizadocol)
SELECT DISTINCT NomAgenteFiscalizado,NumCPFCNPJAgenteFiscalizado,DscTipoPenalidade
	FROM dadosinfracao;

update AgenteFiscalizado set valortotalmultas = (select sum(di.vlrpenalidade) 
	from dadosinfracao di where (cnpf = di.NumCPFCNPJAgenteFiscalizado) 
		and (DscTipoPenalidade = 'multa' or DscTipoPenalidade =' Advertência / Multa'))
			from dadosinfracao di
	where cnpf = di.NumCPFCNPJAgenteFiscalizado;
	
alter table dadosinfracao add idAgenteFiscalizado int;
 
update dadosinfracao set idAgenteFiscalizado = af.idagenteFiscalizado from AgenteFiscalizado af
	where af.cnpf = NumCPFCNPJAgenteFiscalizado;

alter table dadosinfracao drop column NomAgenteFiscalizado;
alter table dadosinfracao drop column NumCPFCNPJAgenteFiscalizado;
alter table dadosinfracao drop column DscTipoPenalidade;

alter table dadosinfracao add foreign key (idAgenteFiscalizado) references AgenteFiscalizado
 (idAgenteFiscalizado);

create table naturezafiscalizacao(
	idnaturezafiscalizacao serial primary key,
	descricao varchar(150)
);

INSERT INTO naturezafiscalizacao (descricao)
SELECT DISTINCT NomNaturezaFiscalizacao FROM dadosinfracao;

alter table dadosinfracao add idnaturezafiscalizacao int;
 
update dadosinfracao set idnaturezafiscalizacao = nf.idnaturezafiscalizacao 
	from naturezafiscalizacao nf where  nf.descricao = NomNaturezaFiscalizacao;	
	
alter table dadosinfracao add foreign key (idnaturezafiscalizacao) 
	references naturezafiscalizacao (idnaturezafiscalizacao);
 
alter table dadosinfracao drop column NomNaturezaFiscalizacao;

alter table dadosinfracao add column iddadosinfracao serial primary key;


