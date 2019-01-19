PRAGMA foreign_keys = ON;

CREATE TABLE tag_RFID (
  ID INTEGER PRIMARY KEY NOT NULL
);

/* Produtos usados na lubrificação de pontos de máquinas. */

CREATE TABLE produto (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  nome TEXT NOT NULL,
  densidade REAL NOT NULL,
  rfid INT NOT NULL,
  FOREIGN KEY (rfid) REFERENCES tag_RFID (ID) ON DELETE CASCADE
);

CREATE INDEX produto_rfid ON produto (rfid);

/* Justificações que podem ser dadas por não se lubrificar um ponto. */

CREATE TABLE justificacao (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  descricao TEXT NOT NULL
);

/* Máquinas têm pontos de lubrificação,
 * e cada ponto precisa de uma determinada massa de lubrificação.
 * Pode haver pontos de lubrificação que não têm um RFID devido
 * à geometria do ponto. */

CREATE TABLE maquina (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  nome TEXT NOT NULL,
  rfid INT,
  FOREIGN KEY (rfid) REFERENCES tag_RFID (ID) ON DELETE CASCADE
);

CREATE INDEX maquina_rfid ON maquina (rfid);

CREATE TABLE ponto (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  nome TEXT NOT NULL,
  rfid INT,
  maquina_ID INT NOT NULL,
  produto_ID INT NOT NULL,
  quantidade REAL NOT NULL,
  tempo_lubrificar INT NOT NULL,
  FOREIGN KEY (rfid) REFERENCES tag_RFID (ID) ON DELETE CASCADE,
  FOREIGN KEY (maquina_ID) REFERENCES maquina (ID) ON DELETE CASCADE,
  FOREIGN KEY (produto_ID) REFERENCES produto (ID) ON DELETE CASCADE
);

CREATE INDEX ponto_rfid ON ponto (rfid);

CREATE INDEX ponto_maquina ON ponto (maquina_ID);

CREATE INDEX ponto_produto ON ponto (produto_ID);

CREATE VIEW detalhe_equipamento (nome_maquina, nome_ponto, rfid_maquina, rfid_ponto, nome_produto) AS
   SELECT
      maquina.nome,
      ponto.nome,
      maquina.rfid,
      ponto.rfid,
      produto.nome
   FROM ponto
      INNER JOIN maquina ON maquina.ID = ponto.maquina_ID
      INNER JOIN produto ON produto.ID = ponto.produto_ID
   ORDER BY
      maquina.nome ASC,
      ponto.nome ASC;

/* Operadores que levam os equipamentos de lubrificação */

CREATE TABLE operador (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  nome TEXT NOT NULL,
  rfid INT NOT NULL,
  FOREIGN KEY (rfid) REFERENCES tag_RFID (ID) ON DELETE CASCADE
);

CREATE INDEX operador_rfid ON operador (rfid);

/* Percursos que os operadores têm que fazer na fábrica.
 * Cada percurso tem uma sequência de paragens em pontos de lubrificação
 * ou em máquinas (cujos pontos não têm RFID). */

CREATE TABLE percurso (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  nome TEXT NOT NULL,
  operador_ID INT NOT NULL,
  FOREIGN KEY (operador_ID) REFERENCES operador (ID) ON DELETE CASCADE
);

CREATE INDEX percurso_operador ON percurso (operador_ID);

CREATE TABLE paragem (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  percurso_ID INT NOT NULL,
  ordem INT NOT NULL,
  FOREIGN KEY (percurso_ID) REFERENCES percurso (ID) ON DELETE CASCADE,
  UNIQUE (percurso_ID, ordem) ON CONFLICT ROLLBACK
);

CREATE INDEX paragem_percurso ON paragem (percurso_ID);

CREATE TABLE paragem_ponto (
  paragem_ID INTEGER PRIMARY KEY NOT NULL,
  ponto_ID  INT NOT NULL,
  FOREIGN KEY (paragem_ID) REFERENCES paragem (ID) ON DELETE CASCADE,
  FOREIGN KEY (ponto_ID) REFERENCES ponto (ID) ON DELETE CASCADE
);

CREATE INDEX paragem_ponto_pp ON paragem_ponto (paragem_ID, ponto_ID);

CREATE VIEW detalhe_paragem_ponto (ID, percurso_ID, ordem, ponto_ID) AS
	SELECT
		paragem.ID,
		paragem.percurso_ID,
		paragem.ordem,
		paragem_ponto.ponto_ID
	FROM paragem
		INNER JOIN paragem_ponto ON paragem.ID = paragem_ponto.paragem_ID;

CREATE TABLE paragem_maquina (
  paragem_ID INTEGER PRIMARY KEY NOT NULL,
  maquina_ID INT NOT NULL,
  FOREIGN KEY (paragem_ID) REFERENCES paragem (ID) ON DELETE CASCADE,
  FOREIGN KEY (maquina_ID) REFERENCES ponto (ID) ON DELETE CASCADE
);

CREATE VIEW detalhe_paragem_maquina (ID, percurso_ID, ordem, maquina_ID) AS
	SELECT
		paragem.ID,
		paragem.percurso_ID,
		paragem.ordem,
		paragem_maquina.maquina_ID
	FROM paragem
		INNER JOIN paragem_maquina ON paragem.ID = paragem_maquina.paragem_ID;

CREATE INDEX paragem_maquina_pm ON paragem_maquina (paragem_ID, maquina_ID);

CREATE VIEW paragens_percurso_operador (operador_ID, percurso_ID, paragem_ID, nome_operador, nome_percurso, ordem) AS
  SELECT
    operador.ID,
    percurso.ID,
    paragem.ID,
    operador.nome,
    percurso.nome,
    paragem.ordem
  FROM percurso
    INNER JOIN paragem ON paragem.percurso_ID = percurso.ID
    INNER JOIN operador ON operador.ID = percurso.operador_ID
  ORDER BY operador.nome, percurso.nome, paragem.ordem;

CREATE VIEW detalhe_paragem (paragem_ID, tipo_paragem, nome_paragem) AS
  SELECT
    paragem_maquina.paragem_ID,
    'máquina' AS tipo_paragem,
    maquina.nome AS nome_paragem
  FROM paragem_maquina
    INNER JOIN maquina ON maquina.ID = paragem_maquina.maquina_ID
  UNION
  SELECT
    paragem_ponto.paragem_ID,
    'ponto' AS tipo_paragem,
    ponto.nome AS nome_paragem
  FROM paragem_ponto
    INNER JOIN ponto ON ponto.ID = paragem_ponto.ponto_ID;

CREATE VIEW detalhe_percurso (operador, nome, ordem, tipo_paragem, nome_paragem) AS
  SELECT
    nome_operador,
    nome_percurso,
    ordem,
    tipo_paragem,
    nome_paragem
  FROM paragens_percurso_operador
    INNER JOIN detalhe_paragem ON detalhe_paragem.paragem_ID = paragens_percurso_operador.paragem_ID;

/* Execução de um percurso por parte de um operador.
 * O operador leva um equipamento com um produto.
 * Uma execução tem várias acções que podem ser lubrificações
 * ou justificações por não ter lubrificado um ponto ou uma máquina numa paragem. */

CREATE TABLE execucao (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  percurso_ID INT NOT NULL,
  operador_ID INT NOT NULL,
  produto_ID INT NOT NULL,
  data_hora TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (percurso_ID) REFERENCES percurso (ID) ON DELETE CASCADE,
  FOREIGN KEY (operador_ID) REFERENCES operador (ID) ON DELETE CASCADE
);

CREATE INDEX execucao_percurso ON execucao (percurso_ID);
CREATE INDEX execucao_operador ON execucao (operador_ID);

CREATE TABLE accao (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  execucao_ID INT NOT NULL,
  paragem_ID INT NOT NULL,
  data_hora TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (execucao_ID) REFERENCES execucao (ID) ON DELETE CASCADE
  FOREIGN KEY (paragem_ID) REFERENCES paragem (ID) ON DELETE CASCADE
);

CREATE INDEX accao_execucao ON accao (execucao_ID);
CREATE INDEX accao_paragem ON accao (paragem_ID);

CREATE TABLE lubrificacao (
  accao_ID INTEGER PRIMARY KEY NOT NULL,
  quantidade REAL NOT NULL,
  FOREIGN KEY (accao_ID) REFERENCES accao (ID) ON DELETE CASCADE
);

CREATE TABLE nao_lubrificado (
  accao_ID INTEGER PRIMARY KEY NOT NULL,
  justificacao_ID INT NOT NULL,
  FOREIGN KEY (accao_ID) REFERENCES accao (ID) ON DELETE CASCADE,
  FOREIGN KEY (justificacao_ID) REFERENCES justificacao (ID) ON DELETE CASCADE
);

CREATE INDEX nao_lubrificado_justificacao ON nao_lubrificado (justificacao_ID);

CREATE VIEW detalhe_execucao (nome, operador_escalonado, ordem, tipo_paragem, nome_paragem, data_hora_arranque, data_hora_accao) AS
/*  SELECT
    percurso.nome,
    operador.nome,
    paragem.ordem,
    'máquina',
    maquina.nome
  FROM percurso
    INNER JOIN paragem ON paragem.percurso_ID = percurso.ID
    INNER JOIN operador ON operador.ID = percurso.operador_ID
    INNER JOIN paragem_maquina ON paragem_maquina.paragem_ID = paragem.ID
    INNER JOIN maquina ON maquina.ID = paragem_maquina.maquina_ID
  UNION*/
  SELECT
    percurso.nome,
    operador.nome,
    paragem.ordem,
    'ponto',
    ponto.nome,
    execucao.data_hora,
    accao.data_hora
  FROM percurso
    INNER JOIN paragem ON paragem.percurso_ID = percurso.ID
    INNER JOIN operador ON operador.ID = percurso.operador_ID
    INNER JOIN paragem_ponto ON paragem_ponto.paragem_ID = paragem.ID
    INNER JOIN ponto ON ponto.ID = paragem_ponto.ponto_ID
    LEFT JOIN execucao ON execucao.percurso_ID = percurso.ID
    LEFT JOIN accao ON accao.execucao_ID = execucao.ID AND accao.paragem_ID = paragem.ID
  ;
