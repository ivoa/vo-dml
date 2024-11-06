BEGIN TRANSACTION;
CREATE TABLE "AbstractSource" (
	id INTEGER NOT NULL, 
	dtype VARCHAR, 
	"AstroObject_ID" INTEGER, 
	name VARCHAR, 
	description VARCHAR, 
	position_longitude_unit VARCHAR, 
	position_longitude_value DOUBLE, 
	position_latitude_unit VARCHAR, 
	position_latitude_value DOUBLE, 
	classification VARCHAR(7), 
	"SOURCECATALOGUE_ID" INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY("AstroObject_ID") REFERENCES "AstroObject" (id), 
	FOREIGN KEY("SOURCECATALOGUE_ID") REFERENCES "SourceCatalogue" (id)
);
INSERT INTO "AbstractSource" VALUES(1,'sample:catalog.SDSSSource',1,'testSource',NULL,'degree',2.5,'degree',52.5,'AGN',1);
CREATE TABLE "AstroObject" (
	id INTEGER NOT NULL, 
	dtype VARCHAR, 
	label VARCHAR, 
	PRIMARY KEY (id)
);
INSERT INTO "AstroObject" VALUES(1,'sample:catalog.SDSSSource',NULL);
CREATE TABLE "LuminosityMeasurement" (
	id INTEGER NOT NULL, 
	value_unit VARCHAR, 
	value_value DOUBLE, 
	error_unit VARCHAR, 
	error_value DOUBLE, 
	description VARCHAR, 
	type VARCHAR(9), 
	"ABSTRACTSOURCE_ID" INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY("ABSTRACTSOURCE_ID") REFERENCES "AbstractSource" (id)
);
INSERT INTO "LuminosityMeasurement" VALUES(1,'Jy',2.5,'Jy',0.25,'lummeas','FLUX',1);
INSERT INTO "LuminosityMeasurement" VALUES(2,'Jy',3.5,'Jy',0.25,'lummeas2','FLUX',1);
CREATE TABLE "PhotometricSystem" (
	id INTEGER NOT NULL, 
	description VARCHAR, 
	"detectorType" INTEGER, 
	PRIMARY KEY (id)
);
CREATE TABLE "PhotometryFilter" (
	id INTEGER NOT NULL, 
	"fpsIdentifier" VARCHAR, 
	name VARCHAR, 
	description VARCHAR, 
	"bandName" VARCHAR, 
	"dataValidityFrom" DATETIME, 
	"dataValidityTo" DATETIME, 
	"spectralLocation_unit" VARCHAR, 
	"spectralLocation_value" DOUBLE, 
	"PHOTOMETRICSYSTEM_ID" INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY("PHOTOMETRICSYSTEM_ID") REFERENCES "PhotometricSystem" (id)
);
CREATE TABLE "SDSSSource" (
	id INTEGER NOT NULL, 
	dtype VARCHAR, 
	"AbstractSource_ID" INTEGER, 
	"positionError_longError" DOUBLE, 
	"positionError_latError" DOUBLE, 
	"SOURCECATALOGUE_ID" INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY("AbstractSource_ID") REFERENCES "AbstractSource" (id), 
	FOREIGN KEY("SOURCECATALOGUE_ID") REFERENCES "SourceCatalogue" (id)
);
INSERT INTO "SDSSSource" VALUES(1,'sample:catalog.SDSSSource',1,NULL,NULL,1);
CREATE TABLE "SkyCoordinateFrame" (
	name VARCHAR NOT NULL, 
	"documentURI" VARCHAR, 
	equinox VARCHAR, 
	system VARCHAR, 
	PRIMARY KEY (name)
);
CREATE TABLE "Source" (
	id INTEGER NOT NULL, 
	dtype VARCHAR, 
	"AbstractSource_ID" INTEGER, 
	"positionError_radius" DOUBLE, 
	"SOURCECATALOGUE_ID" INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY("AbstractSource_ID") REFERENCES "AbstractSource" (id), 
	FOREIGN KEY("SOURCECATALOGUE_ID") REFERENCES "SourceCatalogue" (id)
);
CREATE TABLE "SourceCatalogue" (
	id INTEGER NOT NULL, 
	name VARCHAR, 
	PRIMARY KEY (id)
);
INSERT INTO "SourceCatalogue" VALUES(1,'testCat');
CREATE TABLE "Testing" (
	id INTEGER NOT NULL, 
	plain VARCHAR, 
	"arrayIsh" VARCHAR, 
	unbounded VARCHAR, 
	"SOURCECATALOGUE_ID" INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY("SOURCECATALOGUE_ID") REFERENCES "SourceCatalogue" (id)
);
CREATE TABLE "TwoMassSource" (
	id INTEGER NOT NULL, 
	dtype VARCHAR, 
	"AbstractSource_ID" INTEGER, 
	"positionError_major" DOUBLE, 
	"positionError_minor" DOUBLE, 
	"positionError_pa" DOUBLE, 
	"SOURCECATALOGUE_ID" INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY("AbstractSource_ID") REFERENCES "AbstractSource" (id), 
	FOREIGN KEY("SOURCECATALOGUE_ID") REFERENCES "SourceCatalogue" (id)
);
COMMIT;
