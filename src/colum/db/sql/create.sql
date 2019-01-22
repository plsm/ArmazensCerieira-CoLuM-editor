PRAGMA foreign_keys = ON;

CREATE TABLE tag_RFID (
  ID INTEGER PRIMARY KEY NOT NULL
);

CREATE TABLE produto (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  nome TEXT NOT NULL,
  densidade REAL NOT NULL,
  rfid INT NOT NULL,
  FOREIGN KEY (rfid) REFERENCES tag_RFID (ID) ON DELETE CASCADE
);

CREATE INDEX produto_rfid ON produto (rfid);

CREATE TABLE justificacao (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  descricao TEXT NOT NULL
);

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

CREATE TABLE operador (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  nome TEXT NOT NULL,
  rfid INT NOT NULL,
  FOREIGN KEY (rfid) REFERENCES tag_RFID (ID) ON DELETE CASCADE
);

CREATE INDEX operador_rfid ON operador (rfid);

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

CREATE TABLE accao_escalonada (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  execucao_ID INT NOT NULL,
  paragem_ID INT NOT NULL,
  data_hora TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (execucao_ID) REFERENCES execucao (ID) ON DELETE CASCADE
  FOREIGN KEY (paragem_ID) REFERENCES paragem (ID) ON DELETE CASCADE
);

CREATE INDEX accao_execucao ON accao_escalonada (execucao_ID);

CREATE INDEX accao_paragem ON accao_escalonada (paragem_ID);

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

CREATE TABLE accao_nao_prevista (
  ID INTEGER PRIMARY KEY ASC NOT NULL,
  execucao_ID INT NOT NULL,
  data_hora TEXT DEFAULT CURRENT_TIMESTAMP,
  quantidade REAL NOT NULL,
  FOREIGN KEY (execucao_ID) REFERENCES execucao (ID) ON DELETE CASCADE
);

CREATE TABLE accao_nao_prevista_ponto (
  accao_nao_prevista_ID INTEGER PRIMARY KEY NOT NULL,
  ponto_ID  INT NOT NULL,
  FOREIGN KEY (accao_nao_prevista_ID) REFERENCES accao_nao_prevista (ID) ON DELETE CASCADE,
  FOREIGN KEY (ponto_ID) REFERENCES ponto (ID) ON DELETE CASCADE
);

CREATE TABLE accao_nao_prevista_maquina (
  accao_nao_prevista_ID INTEGER PRIMARY KEY NOT NULL,
  maquina_ID INT NOT NULL,
  FOREIGN KEY (accao_nao_prevista_ID) REFERENCES accao_nao_prevista (ID) ON DELETE CASCADE,
  FOREIGN KEY (maquina_ID) REFERENCES ponto (ID) ON DELETE CASCADE
);

CREATE VIEW detalhe_execucao (nome, operador_escalonado, ordem, tipo_paragem, nome_paragem, data_hora_arranque, data_hora_accao) AS
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
