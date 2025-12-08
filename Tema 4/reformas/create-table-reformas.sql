CREATE SCHEMA reformas
  DEFAULT CHARACTER SET utf8
  COLLATE utf8_spanish2_ci;

CREATE TABLE reformas.proyectos (
  codP VARCHAR(3) UNIQUE NOT NULL,
  descripcion VARCHAR(20) NOT NULL,
  localidad VARCHAR(20) NOT NULL,
  cliente VARCHAR(40) NOT NULL,
  telefono INTEGER,
  PRIMARY KEY (codP)
);

CREATE TABLE reformas.conductores (
  codC VARCHAR(3) UNIQUE NOT NULL,
  nombre VARCHAR(40) NOT NULL,
  localidad VARCHAR(20) NOT NULL,
  categoria INTEGER NOT NULL,
  PRIMARY KEY (codC)
);

CREATE TABLE reformas.maquinas (
  codM VARCHAR(3) UNIQUE NOT NULL,
  nombre VARCHAR(30) NOT NULL,
  precioHora INTEGER NOT NULL,
  PRIMARY KEY (codM)
);

CREATE TABLE reformas.trabajos (
  codC VARCHAR(3) NOT NULL,
  codM VARCHAR(3) NOT NULL,
  codP VARCHAR(3) NOT NULL,
  fecha DATETIME NOT NULL,
  tiempo INTEGER,
  PRIMARY KEY (codC, codM, codP, fecha),
  CONSTRAINT
    FOREIGN KEY (codC)
    REFERENCES reformas.conductores (codC),
  CONSTRAINT
    FOREIGN KEY (codM)
    REFERENCES reformas.maquinas (codM),
  CONSTRAINT
    FOREIGN KEY (codP)
    REFERENCES reformas.proyectos (codP)
);
