-- H2 2.1.214; 
SET DB_CLOSE_DELAY -1;         
;              
CREATE USER IF NOT EXISTS "" SALT '' HASH '' ADMIN;            
CREATE SEQUENCE "PUBLIC"."ANOBJECT_SEQ" START WITH 1 INCREMENT BY 50;          
CREATE SEQUENCE "PUBLIC"."ASTROOBJECT_SEQ" START WITH 1 INCREMENT BY 50;       
CREATE SEQUENCE "PUBLIC"."ATEST2_SEQ" START WITH 1 INCREMENT BY 50;            
CREATE SEQUENCE "PUBLIC"."ATEST3_SEQ" START WITH 1 INCREMENT BY 50;            
CREATE SEQUENCE "PUBLIC"."ATEST4_SEQ" START WITH 1 INCREMENT BY 50;            
CREATE SEQUENCE "PUBLIC"."ATEST_SEQ" START WITH 1 INCREMENT BY 50;             
CREATE SEQUENCE "PUBLIC"."AXIS_SEQ" START WITH 1 INCREMENT BY 50;              
CREATE SEQUENCE "PUBLIC"."BASEC_SEQ" START WITH 1 RESTART WITH 101 INCREMENT BY 50;            
CREATE SEQUENCE "PUBLIC"."CHILD_SEQ" START WITH 1 INCREMENT BY 50;             
CREATE SEQUENCE "PUBLIC"."CONTAINED_SEQ" START WITH 1 INCREMENT BY 50;         
CREATE SEQUENCE "PUBLIC"."COORDFRAME_SEQ" START WITH 1 INCREMENT BY 50;        
CREATE SEQUENCE "PUBLIC"."COORDSPACE_SEQ" START WITH 1 INCREMENT BY 50;        
CREATE SEQUENCE "PUBLIC"."COORDSYS_SEQ" START WITH 1 INCREMENT BY 50;          
CREATE SEQUENCE "PUBLIC"."LCHILD_SEQ" START WITH 1 INCREMENT BY 50;            
CREATE SEQUENCE "PUBLIC"."LUMINOSITYMEASUREMENT_SEQ" START WITH 1 INCREMENT BY 50;             
CREATE SEQUENCE "PUBLIC"."PARENT_SEQ" START WITH 1 INCREMENT BY 50;            
CREATE SEQUENCE "PUBLIC"."PHOTOMETRICSYSTEM_SEQ" START WITH 1 INCREMENT BY 50; 
CREATE SEQUENCE "PUBLIC"."PHOTOMETRYFILTER_SEQ" START WITH 1 INCREMENT BY 50;  
CREATE SEQUENCE "PUBLIC"."REFA_SEQ" START WITH 1 RESTART WITH 51 INCREMENT BY 50;              
CREATE SEQUENCE "PUBLIC"."REFERREDLIFECYCLE_SEQ" START WITH 1 INCREMENT BY 50; 
CREATE SEQUENCE "PUBLIC"."REFERREDTO1_SEQ" START WITH 1 INCREMENT BY 50;       
CREATE SEQUENCE "PUBLIC"."REFERREDTO2_SEQ" START WITH 1 INCREMENT BY 50;       
CREATE SEQUENCE "PUBLIC"."REFERREDTO3_SEQ" START WITH 1 INCREMENT BY 50;       
CREATE SEQUENCE "PUBLIC"."REFERREDTO_SEQ" START WITH 1 INCREMENT BY 50;        
CREATE SEQUENCE "PUBLIC"."SOMECONTENT_SEQ" START WITH 1 RESTART WITH 51 INCREMENT BY 50;       
CREATE SEQUENCE "PUBLIC"."SOURCECATALOGUE_SEQ" START WITH 1 INCREMENT BY 50;   
CREATE SEQUENCE "PUBLIC"."TESTING_SEQ" START WITH 1 INCREMENT BY 50;           
CREATE MEMORY TABLE "PUBLIC"."ANOBJECT"(
    "POSITION_DIST_VALUE" FLOAT(53) NOT NULL,
    "POSITION_LAT_VALUE" FLOAT(53) NOT NULL,
    "POSITION_LON_VALUE" FLOAT(53) NOT NULL,
    "ID" BIGINT NOT NULL,
    "COORDSYS_ID" BIGINT,
    "POSITION_DIST_UNIT_VALUE" CHARACTER VARYING(255) NOT NULL,
    "POSITION_LAT_UNIT_VALUE" CHARACTER VARYING(255) NOT NULL,
    "POSITION_LON_UNIT_VALUE" CHARACTER VARYING(255) NOT NULL
);           
ALTER TABLE "PUBLIC"."ANOBJECT" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_8" PRIMARY KEY("ID");      
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.ANOBJECT; 
CREATE MEMORY TABLE "PUBLIC"."ASTROCOORDSYSTEM"(
    "ID" BIGINT NOT NULL
);   
ALTER TABLE "PUBLIC"."ASTROCOORDSYSTEM" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_4" PRIMARY KEY("ID");              
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.ASTROCOORDSYSTEM;         
CREATE MEMORY TABLE "PUBLIC"."ASTROOBJECT"(
    "POSITIONERROR_LATERROR" FLOAT(53),
    "POSITIONERROR_LONGERROR" FLOAT(53),
    "POSITIONERROR_MAJOR" FLOAT(53),
    "POSITIONERROR_MINOR" FLOAT(53),
    "POSITIONERROR_PA" FLOAT(53),
    "POSITIONERROR_RADIUS" FLOAT(53),
    "POSITION_LATITUDE_VALUE" FLOAT(53),
    "POSITION_LONGITUDE_VALUE" FLOAT(53),
    "ID" BIGINT NOT NULL,
    "SOURCECATALOGUE_ID" BIGINT,
    "FRAME_NAME" CHARACTER VARYING(32),
    "DTYPE" CHARACTER VARYING(64) NOT NULL,
    "DESCRIPTION" CHARACTER VARYING(255),
    "LABEL" CHARACTER VARYING(255),
    "NAME" CHARACTER VARYING(255),
    "POSITION_LATITUDE_UNIT_VALUE" CHARACTER VARYING(255),
    "POSITION_LONGITUDE_UNIT_VALUE" CHARACTER VARYING(255),
    "CLASSIFICATION" ENUM('AGN', 'GALAXY', 'PLANET', 'STAR', 'UNKNOWN')
);            
ALTER TABLE "PUBLIC"."ASTROOBJECT" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_C" PRIMARY KEY("ID");   
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.ASTROOBJECT;              
CREATE MEMORY TABLE "PUBLIC"."ATEST"(
    "ID" BIGINT NOT NULL,
    "CONTAINED2_ID" BIGINT,
    "REF1_ID" BIGINT NOT NULL
);   
ALTER TABLE "PUBLIC"."ATEST" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_3B" PRIMARY KEY("ID");        
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.ATEST;    
CREATE MEMORY TABLE "PUBLIC"."ATEST2"(
    "ID" BIGINT NOT NULL,
    "ATEST_ID" BIGINT,
    "REFCONT_ID" BIGINT NOT NULL
);    
ALTER TABLE "PUBLIC"."ATEST2" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_73" PRIMARY KEY("ID");       
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.ATEST2;   
CREATE MEMORY TABLE "PUBLIC"."ATEST2_REFERREDTO"(
    "ATEST2_ID" BIGINT NOT NULL,
    "REFAGG_ID" BIGINT NOT NULL
);          
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.ATEST2_REFERREDTO;        
CREATE MEMORY TABLE "PUBLIC"."ATEST3"(
    "ID" BIGINT NOT NULL,
    "REFBAD_ID" BIGINT NOT NULL
);            
ALTER TABLE "PUBLIC"."ATEST3" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_73A" PRIMARY KEY("ID");      
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.ATEST3;   
CREATE MEMORY TABLE "PUBLIC"."ATEST4"(
    "ID" BIGINT NOT NULL,
    "LOWR_ID" BIGINT NOT NULL
);              
ALTER TABLE "PUBLIC"."ATEST4" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_73AB" PRIMARY KEY("ID");     
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.ATEST4;   
CREATE MEMORY TABLE "PUBLIC"."AXIS"(
    "COORDSPACE_ID" BIGINT,
    "ID" BIGINT NOT NULL,
    "DTYPE" CHARACTER VARYING(32) NOT NULL,
    "NAME" CHARACTER VARYING(255)
);    
ALTER TABLE "PUBLIC"."AXIS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_1" PRIMARY KEY("ID");          
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.AXIS;     
CREATE MEMORY TABLE "PUBLIC"."BASEC"(
    "ID" BIGINT NOT NULL,
    "SOMECONTENT_ID" BIGINT,
    "DTYPE" CHARACTER VARYING(64) NOT NULL,
    "BNAME" CHARACTER VARYING(255) NOT NULL,
    "DVAL" CHARACTER VARYING(255),
    "EVALUE" CHARACTER VARYING(255)
);
ALTER TABLE "PUBLIC"."BASEC" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_3C" PRIMARY KEY("ID");        
-- 2 +/- SELECT COUNT(*) FROM PUBLIC.BASEC;    
INSERT INTO "PUBLIC"."BASEC" VALUES
(1, 1, 'MyModel:Dcont', 'dval', 'a D', NULL),
(2, 1, 'MyModel:Econt', 'eval', NULL, 'cube');               
CREATE MEMORY TABLE "PUBLIC"."BINNEDAXIS"(
    "LENGTH" INTEGER NOT NULL,
    "ID" BIGINT NOT NULL
);          
ALTER TABLE "PUBLIC"."BINNEDAXIS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_80" PRIMARY KEY("ID");   
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.BINNEDAXIS;               
CREATE MEMORY TABLE "PUBLIC"."CARTESIANCOORDSPACE"(
    "ID" BIGINT NOT NULL
);
ALTER TABLE "PUBLIC"."CARTESIANCOORDSPACE" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_88" PRIMARY KEY("ID");          
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.CARTESIANCOORDSPACE;      
CREATE MEMORY TABLE "PUBLIC"."CHILD"(
    "ID" BIGINT NOT NULL,
    "RVAL_ID" BIGINT NOT NULL
);               
ALTER TABLE "PUBLIC"."CHILD" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_3D" PRIMARY KEY("ID");        
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.CHILD;    
CREATE MEMORY TABLE "PUBLIC"."CONTAINED"(
    "ATEST3_ID" BIGINT,
    "ATEST_ID" BIGINT,
    "ID" BIGINT NOT NULL,
    "REFBAD2_ID" BIGINT NOT NULL,
    "TEST2" CHARACTER VARYING(255) NOT NULL
);            
ALTER TABLE "PUBLIC"."CONTAINED" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_8D" PRIMARY KEY("ID");    
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.CONTAINED;
CREATE MEMORY TABLE "PUBLIC"."CONTINUOUSAXIS"(
    "CYCLIC" BOOLEAN,
    "DOMAINMAX_VALUE" FLOAT(53),
    "DOMAINMIN_VALUE" FLOAT(53),
    "ID" BIGINT NOT NULL,
    "DOMAINMAX_UNIT_VALUE" CHARACTER VARYING(255),
    "DOMAINMIN_UNIT_VALUE" CHARACTER VARYING(255)
);       
ALTER TABLE "PUBLIC"."CONTINUOUSAXIS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_2" PRIMARY KEY("ID");
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.CONTINUOUSAXIS;           
CREATE MEMORY TABLE "PUBLIC"."COORDFRAME"(
    "ID" BIGINT NOT NULL,
    "DTYPE" CHARACTER VARYING(32) NOT NULL
);             
ALTER TABLE "PUBLIC"."COORDFRAME" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_28" PRIMARY KEY("ID");   
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.COORDFRAME;               
CREATE MEMORY TABLE "PUBLIC"."COORDSPACE"(
    "ID" BIGINT NOT NULL,
    "DTYPE" CHARACTER VARYING(32) NOT NULL
);             
ALTER TABLE "PUBLIC"."COORDSPACE" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_29" PRIMARY KEY("ID");   
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.COORDSPACE;               
CREATE MEMORY TABLE "PUBLIC"."COORDSYS"(
    "ID" BIGINT NOT NULL,
    "DTYPE" CHARACTER VARYING(32) NOT NULL
);               
ALTER TABLE "PUBLIC"."COORDSYS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_E" PRIMARY KEY("ID");      
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.COORDSYS; 
CREATE MEMORY TABLE "PUBLIC"."DISCRETESETAXIS"(
    "ID" BIGINT NOT NULL
);    
ALTER TABLE "PUBLIC"."DISCRETESETAXIS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_6" PRIMARY KEY("ID");               
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.DISCRETESETAXIS;          
CREATE MEMORY TABLE "PUBLIC"."GENERICCOORDSPACE"(
    "ID" BIGINT NOT NULL
);  
ALTER TABLE "PUBLIC"."GENERICCOORDSPACE" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_25" PRIMARY KEY("ID");            
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.GENERICCOORDSPACE;        
CREATE MEMORY TABLE "PUBLIC"."GENERICFRAME"(
    "ID" BIGINT NOT NULL,
    "PLANETARYEPHEM" CHARACTER VARYING(255)
);          
ALTER TABLE "PUBLIC"."GENERICFRAME" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_7A" PRIMARY KEY("ID"); 
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.GENERICFRAME;             
CREATE MEMORY TABLE "PUBLIC"."GENERICSYS"(
    "ID" BIGINT NOT NULL
);         
ALTER TABLE "PUBLIC"."GENERICSYS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_2F" PRIMARY KEY("ID");   
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.GENERICSYS;               
CREATE MEMORY TABLE "PUBLIC"."LCHILD"(
    "IVAL" INTEGER NOT NULL,
    "LVAL_ORDER" INTEGER,
    "ID" BIGINT NOT NULL,
    "PARENT_ID" BIGINT,
    "SVAL" CHARACTER VARYING(255) NOT NULL
);  
ALTER TABLE "PUBLIC"."LCHILD" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_85" PRIMARY KEY("ID");       
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.LCHILD;   
CREATE MEMORY TABLE "PUBLIC"."LUMINOSITYMEASUREMENT"(
    "ERROR_VALUE" FLOAT(53),
    "VALUE_VALUE" FLOAT(53),
    "ABSTRACTSOURCE_ID" BIGINT,
    "ID" BIGINT NOT NULL,
    "FILTER_ID" BIGINT NOT NULL,
    "DESCRIPTION" CHARACTER VARYING(255),
    "ERROR_UNIT_VALUE" CHARACTER VARYING(255),
    "VALUE_UNIT_VALUE" CHARACTER VARYING(255),
    "TYPE" ENUM('FLUX', 'MAGNITUDE') NOT NULL
);            
ALTER TABLE "PUBLIC"."LUMINOSITYMEASUREMENT" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_4E" PRIMARY KEY("ID");        
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.LUMINOSITYMEASUREMENT;    
CREATE MEMORY TABLE "PUBLIC"."PARENT"(
    "DVAL_DVALR" FLOAT(53),
    "ID" BIGINT NOT NULL,
    "CVAL_ID" BIGINT,
    "DREF_ID" BIGINT,
    "RVAL_ID" BIGINT NOT NULL,
    "DVAL_BASESTR" CHARACTER VARYING(255),
    "DVAL_DVALS" CHARACTER VARYING(255),
    "DVAL_INTATT" CHARACTER VARYING(255)
);        
ALTER TABLE "PUBLIC"."PARENT" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_8C3" PRIMARY KEY("ID");      
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.PARENT;   
CREATE MEMORY TABLE "PUBLIC"."PHOTOMETRICSYSTEM"(
    "DETECTORTYPE" INTEGER NOT NULL,
    "ID" BIGINT NOT NULL,
    "DESCRIPTION" CHARACTER VARYING(255)
);   
ALTER TABLE "PUBLIC"."PHOTOMETRICSYSTEM" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_3A" PRIMARY KEY("ID");            
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.PHOTOMETRICSYSTEM;        
CREATE MEMORY TABLE "PUBLIC"."PHOTOMETRYFILTER"(
    "SPECTRALLOCATION_VALUE" FLOAT(53) NOT NULL,
    "ID" BIGINT NOT NULL,
    "PHOTOMETRICSYSTEM_ID" BIGINT,
    "DATAVALIDITYFROM" TIMESTAMP(6) NOT NULL,
    "DATAVALIDITYTO" TIMESTAMP(6) NOT NULL,
    "BANDNAME" CHARACTER VARYING(255) NOT NULL,
    "DESCRIPTION" CHARACTER VARYING(255) NOT NULL,
    "FPSIDENTIFIER" CHARACTER VARYING(255),
    "NAME" CHARACTER VARYING(255) NOT NULL,
    "SPECTRALLOCATION_UNIT_VALUE" CHARACTER VARYING(255) NOT NULL
);       
ALTER TABLE "PUBLIC"."PHOTOMETRYFILTER" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_86" PRIMARY KEY("ID");             
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.PHOTOMETRYFILTER;         
CREATE MEMORY TABLE "PUBLIC"."PHYSICALCOORDSPACE"(
    "ID" BIGINT NOT NULL
); 
ALTER TABLE "PUBLIC"."PHYSICALCOORDSPACE" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_D" PRIMARY KEY("ID");            
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.PHYSICALCOORDSPACE;       
CREATE MEMORY TABLE "PUBLIC"."PHYSICALCOORDSYS"(
    "ASTROCOORDSYSTEM_ID" BIGINT,
    "ID" BIGINT NOT NULL,
    "COORDSPACE_ID" BIGINT,
    "FRAME_ID" BIGINT
);              
ALTER TABLE "PUBLIC"."PHYSICALCOORDSYS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_E0C8" PRIMARY KEY("ID");           
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.PHYSICALCOORDSYS;         
CREATE MEMORY TABLE "PUBLIC"."PIXELCOORDSYSTEM"(
    "ID" BIGINT NOT NULL,
    "PIXELSPACE_ID" BIGINT
);       
ALTER TABLE "PUBLIC"."PIXELCOORDSYSTEM" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_55" PRIMARY KEY("ID");             
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.PIXELCOORDSYSTEM;         
CREATE MEMORY TABLE "PUBLIC"."PIXELSPACE"(
    "ID" BIGINT NOT NULL,
    "HANDEDNESS" ENUM('LEFT', 'RIGHT')
); 
ALTER TABLE "PUBLIC"."PIXELSPACE" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_1C" PRIMARY KEY("ID");   
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.PIXELSPACE;               
CREATE MEMORY TABLE "PUBLIC"."REFA"(
    "ID" BIGINT NOT NULL,
    "VAL" CHARACTER VARYING(255) NOT NULL
);    
ALTER TABLE "PUBLIC"."REFA" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_26" PRIMARY KEY("ID");         
-- 1 +/- SELECT COUNT(*) FROM PUBLIC.REFA;     
INSERT INTO "PUBLIC"."REFA" VALUES
(1, 'a value');             
CREATE MEMORY TABLE "PUBLIC"."REFB"(
    "NAME" CHARACTER VARYING(255) NOT NULL,
    "VAL" CHARACTER VARYING(255) NOT NULL
);  
ALTER TABLE "PUBLIC"."REFB" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_265" PRIMARY KEY("NAME");      
-- 1 +/- SELECT COUNT(*) FROM PUBLIC.REFB;     
INSERT INTO "PUBLIC"."REFB" VALUES
('a name', 'another val');  
CREATE MEMORY TABLE "PUBLIC"."REFERREDLIFECYCLE"(
    "ATEST_ID" BIGINT,
    "ID" BIGINT NOT NULL,
    "TEST3" CHARACTER VARYING(255) NOT NULL
);              
ALTER TABLE "PUBLIC"."REFERREDLIFECYCLE" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_8B" PRIMARY KEY("ID");            
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.REFERREDLIFECYCLE;        
CREATE MEMORY TABLE "PUBLIC"."REFERREDTO"(
    "TEST1" INTEGER NOT NULL,
    "ID" BIGINT NOT NULL
);           
ALTER TABLE "PUBLIC"."REFERREDTO" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_70" PRIMARY KEY("ID");   
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.REFERREDTO;               
CREATE MEMORY TABLE "PUBLIC"."REFERREDTO1"(
    "ID" BIGINT NOT NULL,
    "SVAL" CHARACTER VARYING(255) NOT NULL
);            
ALTER TABLE "PUBLIC"."REFERREDTO1" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_9" PRIMARY KEY("ID");   
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.REFERREDTO1;              
CREATE MEMORY TABLE "PUBLIC"."REFERREDTO2"(
    "ID" BIGINT NOT NULL,
    "SVAL" CHARACTER VARYING(255) NOT NULL
);            
ALTER TABLE "PUBLIC"."REFERREDTO2" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_95" PRIMARY KEY("ID");  
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.REFERREDTO2;              
CREATE MEMORY TABLE "PUBLIC"."REFERREDTO3"(
    "ID" BIGINT NOT NULL,
    "SVAL" CHARACTER VARYING(255) NOT NULL
);            
ALTER TABLE "PUBLIC"."REFERREDTO3" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_950" PRIMARY KEY("ID"); 
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.REFERREDTO3;              
CREATE MEMORY TABLE "PUBLIC"."SKYCOORDINATEFRAME"(
    "NAME" CHARACTER VARYING(32) NOT NULL,
    "DOCUMENTURI" CHARACTER VARYING(255) NOT NULL,
    "EQUINOX" CHARACTER VARYING(255),
    "SYSTEM" CHARACTER VARYING(255)
);  
ALTER TABLE "PUBLIC"."SKYCOORDINATEFRAME" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_A" PRIMARY KEY("NAME");          
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.SKYCOORDINATEFRAME;       
CREATE MEMORY TABLE "PUBLIC"."SOMECONTENT"(
    "ID" BIGINT NOT NULL,
    "REF1_ID" BIGINT NOT NULL,
    "REF2_NAME" CHARACTER VARYING(255) NOT NULL,
    "ZVAL" CHARACTER VARYING(255) NOT NULL
);            
ALTER TABLE "PUBLIC"."SOMECONTENT" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_A4" PRIMARY KEY("ID");  
-- 1 +/- SELECT COUNT(*) FROM PUBLIC.SOMECONTENT;              
INSERT INTO "PUBLIC"."SOMECONTENT" VALUES
(1, 1, 'a name', 'some;z;values');   
CREATE MEMORY TABLE "PUBLIC"."SOURCECATALOGUE"(
    "ID" BIGINT NOT NULL,
    "ATESTMORE_ID" BIGINT,
    "ATEST_ID" BIGINT,
    "NAME" CHARACTER VARYING(255) NOT NULL
);      
ALTER TABLE "PUBLIC"."SOURCECATALOGUE" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_4A82" PRIMARY KEY("ID");            
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.SOURCECATALOGUE;          
CREATE MEMORY TABLE "PUBLIC"."SPACEFRAME"(
    "ID" BIGINT NOT NULL,
    "EQUINOX" CHARACTER VARYING(255),
    "PLANETARYEPHEM" CHARACTER VARYING(255),
    "SPACEREFFRAME" CHARACTER VARYING(255) NOT NULL
); 
ALTER TABLE "PUBLIC"."SPACEFRAME" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_3B5" PRIMARY KEY("ID");  
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.SPACEFRAME;               
CREATE MEMORY TABLE "PUBLIC"."SPACESYS"(
    "ID" BIGINT NOT NULL
);           
ALTER TABLE "PUBLIC"."SPACESYS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_A8" PRIMARY KEY("ID");     
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.SPACESYS; 
CREATE MEMORY TABLE "PUBLIC"."SPHERICALCOORDSPACE"(
    "ID" BIGINT NOT NULL
);
ALTER TABLE "PUBLIC"."SPHERICALCOORDSPACE" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_861" PRIMARY KEY("ID");         
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.SPHERICALCOORDSPACE;      
CREATE MEMORY TABLE "PUBLIC"."TESTING"(
    "ID" BIGINT NOT NULL,
    "PLAIN" CHARACTER VARYING(255) NOT NULL,
    "UNBOUNDED" CHARACTER VARYING(255),
    "ARRAYISH" CHARACTER VARYING(255) ARRAY
);          
ALTER TABLE "PUBLIC"."TESTING" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_D6" PRIMARY KEY("ID");      
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.TESTING;  
CREATE MEMORY TABLE "PUBLIC"."TIMEFRAME"(
    "ID" BIGINT NOT NULL,
    "TIMESCALE" CHARACTER VARYING(255) NOT NULL
);         
ALTER TABLE "PUBLIC"."TIMEFRAME" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_A8A" PRIMARY KEY("ID");   
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.TIMEFRAME;
CREATE MEMORY TABLE "PUBLIC"."TIMESYS"(
    "ID" BIGINT NOT NULL
);            
ALTER TABLE "PUBLIC"."TIMESYS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_DC" PRIMARY KEY("ID");      
-- 0 +/- SELECT COUNT(*) FROM PUBLIC.TIMESYS;  
ALTER TABLE "PUBLIC"."PARENT" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_8C" UNIQUE("CVAL_ID");       
ALTER TABLE "PUBLIC"."ATEST" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_3" UNIQUE("CONTAINED2_ID");   
ALTER TABLE "PUBLIC"."PIXELCOORDSYSTEM" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_5" UNIQUE("PIXELSPACE_ID");        
ALTER TABLE "PUBLIC"."ATEST2" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_7" UNIQUE("ATEST_ID");       
ALTER TABLE "PUBLIC"."PHYSICALCOORDSYS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_E0" UNIQUE("COORDSPACE_ID");       
ALTER TABLE "PUBLIC"."SOURCECATALOGUE" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_4A" UNIQUE("ATESTMORE_ID");         
ALTER TABLE "PUBLIC"."SOURCECATALOGUE" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_4A8" UNIQUE("ATEST_ID");            
ALTER TABLE "PUBLIC"."PHYSICALCOORDSYS" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_E0C" UNIQUE("FRAME_ID");           
ALTER TABLE "PUBLIC"."ATEST4" ADD CONSTRAINT "PUBLIC"."FKS6QHX5UBNMGQ1Y0N3D3E4LAGN" FOREIGN KEY("LOWR_ID") REFERENCES "PUBLIC"."REFERREDLIFECYCLE"("ID") NOCHECK;              
ALTER TABLE "PUBLIC"."ATEST2" ADD CONSTRAINT "PUBLIC"."FKDOQBR66SJ92D51TA0IC44AEGA" FOREIGN KEY("ATEST_ID") REFERENCES "PUBLIC"."ATEST"("ID") NOCHECK;         
ALTER TABLE "PUBLIC"."ATEST" ADD CONSTRAINT "PUBLIC"."FK5OXFJU4451XQXGYMB214330XS" FOREIGN KEY("CONTAINED2_ID") REFERENCES "PUBLIC"."ATEST4"("ID") NOCHECK;    
ALTER TABLE "PUBLIC"."ASTROOBJECT" ADD CONSTRAINT "PUBLIC"."FKGJNJY0VATN6KK881G725MADII" FOREIGN KEY("SOURCECATALOGUE_ID") REFERENCES "PUBLIC"."SOURCECATALOGUE"("ID") NOCHECK;
ALTER TABLE "PUBLIC"."TIMEFRAME" ADD CONSTRAINT "PUBLIC"."FK9G2XJFJ94HUE36RW4T6HPINP9" FOREIGN KEY("ID") REFERENCES "PUBLIC"."COORDFRAME"("ID") NOCHECK;       
ALTER TABLE "PUBLIC"."LUMINOSITYMEASUREMENT" ADD CONSTRAINT "PUBLIC"."FK6WHF47CG1I3JE3YLHGAS69IB7" FOREIGN KEY("FILTER_ID") REFERENCES "PUBLIC"."PHOTOMETRYFILTER"("ID") NOCHECK;              
ALTER TABLE "PUBLIC"."PHYSICALCOORDSYS" ADD CONSTRAINT "PUBLIC"."FKNSVKNFKOHM01PLQRIBL0DCID3" FOREIGN KEY("ASTROCOORDSYSTEM_ID") REFERENCES "PUBLIC"."ASTROCOORDSYSTEM"("ID") NOCHECK;         
ALTER TABLE "PUBLIC"."CONTAINED" ADD CONSTRAINT "PUBLIC"."FK18TN5YK1W5LKNEW30HSRDHQ20" FOREIGN KEY("ATEST3_ID") REFERENCES "PUBLIC"."ATEST3"("ID") NOCHECK;    
ALTER TABLE "PUBLIC"."PIXELCOORDSYSTEM" ADD CONSTRAINT "PUBLIC"."FKSJSB5YRKBX3O0XP2TGE2IJI8X" FOREIGN KEY("ID") REFERENCES "PUBLIC"."COORDSYS"("ID") NOCHECK;  
ALTER TABLE "PUBLIC"."REFERREDLIFECYCLE" ADD CONSTRAINT "PUBLIC"."FKPAXB33S8IU3IW1OMJ9CMYQ73R" FOREIGN KEY("ATEST_ID") REFERENCES "PUBLIC"."ATEST"("ID") NOCHECK;              
ALTER TABLE "PUBLIC"."CONTAINED" ADD CONSTRAINT "PUBLIC"."FKOHMTFEDSG3F3UK98CEJS90UJW" FOREIGN KEY("REFBAD2_ID") REFERENCES "PUBLIC"."REFERREDLIFECYCLE"("ID") NOCHECK;        
ALTER TABLE "PUBLIC"."SPACESYS" ADD CONSTRAINT "PUBLIC"."FK8BD52R7PYC4V2S4UF7DAS38D9" FOREIGN KEY("ID") REFERENCES "PUBLIC"."PHYSICALCOORDSYS"("ID") NOCHECK;  
ALTER TABLE "PUBLIC"."CONTINUOUSAXIS" ADD CONSTRAINT "PUBLIC"."FKGHT0K6JREBRX4NR27ABIGHC34" FOREIGN KEY("ID") REFERENCES "PUBLIC"."AXIS"("ID") NOCHECK;        
ALTER TABLE "PUBLIC"."ATEST3" ADD CONSTRAINT "PUBLIC"."FKPNY1LMHXUPMT2FBOORGCTCHAI" FOREIGN KEY("REFBAD_ID") REFERENCES "PUBLIC"."REFERREDLIFECYCLE"("ID") NOCHECK;            
ALTER TABLE "PUBLIC"."ANOBJECT" ADD CONSTRAINT "PUBLIC"."FK4L6XJNNO9496H6G1FN71XJ9TT" FOREIGN KEY("COORDSYS_ID") REFERENCES "PUBLIC"."COORDSYS"("ID") NOCHECK; 
ALTER TABLE "PUBLIC"."PARENT" ADD CONSTRAINT "PUBLIC"."FKSRL05F1MILT6O6GEN5YEYP9H7" FOREIGN KEY("DREF_ID") REFERENCES "PUBLIC"."REFERREDTO3"("ID") NOCHECK;    
ALTER TABLE "PUBLIC"."PHYSICALCOORDSYS" ADD CONSTRAINT "PUBLIC"."FKA5K2OIRBE77QXK4SQP7H4K3KG" FOREIGN KEY("COORDSPACE_ID") REFERENCES "PUBLIC"."PHYSICALCOORDSPACE"("ID") NOCHECK;             
ALTER TABLE "PUBLIC"."AXIS" ADD CONSTRAINT "PUBLIC"."FKFMVEH3KP7LW6J5DQVWGOGD479" FOREIGN KEY("COORDSPACE_ID") REFERENCES "PUBLIC"."COORDSPACE"("ID") NOCHECK; 
ALTER TABLE "PUBLIC"."ATEST2_REFERREDTO" ADD CONSTRAINT "PUBLIC"."FKIPPTG4KSMH975SV056OOAPTTO" FOREIGN KEY("ATEST2_ID") REFERENCES "PUBLIC"."ATEST2"("ID") NOCHECK;            
ALTER TABLE "PUBLIC"."PHOTOMETRYFILTER" ADD CONSTRAINT "PUBLIC"."FK8WSO70V67T2IGF2VJLINFD9VN" FOREIGN KEY("PHOTOMETRICSYSTEM_ID") REFERENCES "PUBLIC"."PHOTOMETRICSYSTEM"("ID") NOCHECK;       
ALTER TABLE "PUBLIC"."BINNEDAXIS" ADD CONSTRAINT "PUBLIC"."FKBUS8G6HE9ONLNV0SH7K32JYY8" FOREIGN KEY("ID") REFERENCES "PUBLIC"."AXIS"("ID") NOCHECK;            
ALTER TABLE "PUBLIC"."PHYSICALCOORDSPACE" ADD CONSTRAINT "PUBLIC"."FKRUER3897C1HGKBXFKS7B88PLQ" FOREIGN KEY("ID") REFERENCES "PUBLIC"."COORDSPACE"("ID") NOCHECK;              
ALTER TABLE "PUBLIC"."ATEST" ADD CONSTRAINT "PUBLIC"."FKR6QS7YXPYAGPJ0O7PY9SPYK5B" FOREIGN KEY("REF1_ID") REFERENCES "PUBLIC"."REFERREDTO"("ID") NOCHECK;      
ALTER TABLE "PUBLIC"."SPACEFRAME" ADD CONSTRAINT "PUBLIC"."FKJYTCQPD7S0R4E1KNMABBNK9VM" FOREIGN KEY("ID") REFERENCES "PUBLIC"."COORDFRAME"("ID") NOCHECK;      
ALTER TABLE "PUBLIC"."CHILD" ADD CONSTRAINT "PUBLIC"."FKLP052JI9T0DSYPG6LT8P2X9LT" FOREIGN KEY("RVAL_ID") REFERENCES "PUBLIC"."REFERREDTO2"("ID") NOCHECK;     
ALTER TABLE "PUBLIC"."GENERICSYS" ADD CONSTRAINT "PUBLIC"."FKBNUAHWO699RLCYOD2VUQ1E541" FOREIGN KEY("ID") REFERENCES "PUBLIC"."PHYSICALCOORDSYS"("ID") NOCHECK;
ALTER TABLE "PUBLIC"."PIXELSPACE" ADD CONSTRAINT "PUBLIC"."FKTOILBWRRXSHWUOTGVEV57YY2C" FOREIGN KEY("ID") REFERENCES "PUBLIC"."COORDSPACE"("ID") NOCHECK;      
ALTER TABLE "PUBLIC"."ATEST2_REFERREDTO" ADD CONSTRAINT "PUBLIC"."FKSCLCP9LKARKT1MM6FS5PDHJ22" FOREIGN KEY("REFAGG_ID") REFERENCES "PUBLIC"."REFERREDTO"("ID") NOCHECK;        
ALTER TABLE "PUBLIC"."CONTAINED" ADD CONSTRAINT "PUBLIC"."FK17S61RKJMSMU8JNWQ1FEG4NX0" FOREIGN KEY("ATEST_ID") REFERENCES "PUBLIC"."ATEST"("ID") NOCHECK;      
ALTER TABLE "PUBLIC"."SPHERICALCOORDSPACE" ADD CONSTRAINT "PUBLIC"."FKRK9L38XAWUWITGYBTO1BDR3TR" FOREIGN KEY("ID") REFERENCES "PUBLIC"."PHYSICALCOORDSPACE"("ID") NOCHECK;     
ALTER TABLE "PUBLIC"."ASTROCOORDSYSTEM" ADD CONSTRAINT "PUBLIC"."FK28WXMFBHERXIDJGOE6JJRGCEB" FOREIGN KEY("ID") REFERENCES "PUBLIC"."COORDSYS"("ID") NOCHECK;  
ALTER TABLE "PUBLIC"."PIXELCOORDSYSTEM" ADD CONSTRAINT "PUBLIC"."FKH7VDS8PJGR00DU8B3OBDAXURO" FOREIGN KEY("PIXELSPACE_ID") REFERENCES "PUBLIC"."PIXELSPACE"("ID") NOCHECK;     
ALTER TABLE "PUBLIC"."SOURCECATALOGUE" ADD CONSTRAINT "PUBLIC"."FKQ1J3XAC8UIMJILJDAHC96UQT6" FOREIGN KEY("ATEST_ID") REFERENCES "PUBLIC"."TESTING"("ID") NOCHECK;              
ALTER TABLE "PUBLIC"."GENERICFRAME" ADD CONSTRAINT "PUBLIC"."FKMDHTT5YCAIIR737Q6LUPT887Y" FOREIGN KEY("ID") REFERENCES "PUBLIC"."COORDFRAME"("ID") NOCHECK;    
ALTER TABLE "PUBLIC"."GENERICCOORDSPACE" ADD CONSTRAINT "PUBLIC"."FKIJLUVATG728UH2PSOQMX6DAKS" FOREIGN KEY("ID") REFERENCES "PUBLIC"."PHYSICALCOORDSPACE"("ID") NOCHECK;       
ALTER TABLE "PUBLIC"."SOMECONTENT" ADD CONSTRAINT "PUBLIC"."FKG0R291MBS50KA6TNQJI6228TY" FOREIGN KEY("REF1_ID") REFERENCES "PUBLIC"."REFA"("ID") NOCHECK;      
ALTER TABLE "PUBLIC"."PARENT" ADD CONSTRAINT "PUBLIC"."FKNH8FPTUAT5JGXX0E37TEJTMY0" FOREIGN KEY("CVAL_ID") REFERENCES "PUBLIC"."CHILD"("ID") NOCHECK;          
ALTER TABLE "PUBLIC"."PHYSICALCOORDSYS" ADD CONSTRAINT "PUBLIC"."FK356TXW7GAEIHECOA9W50CVKGS" FOREIGN KEY("FRAME_ID") REFERENCES "PUBLIC"."COORDFRAME"("ID") NOCHECK;          
ALTER TABLE "PUBLIC"."CARTESIANCOORDSPACE" ADD CONSTRAINT "PUBLIC"."FK2XY5UVGHIP2J2IYESUDY27V27" FOREIGN KEY("ID") REFERENCES "PUBLIC"."PHYSICALCOORDSPACE"("ID") NOCHECK;     
ALTER TABLE "PUBLIC"."PARENT" ADD CONSTRAINT "PUBLIC"."FK6FCJQQ2KNA6RDQRMQXL8ITTE4" FOREIGN KEY("RVAL_ID") REFERENCES "PUBLIC"."REFERREDTO1"("ID") NOCHECK;    
ALTER TABLE "PUBLIC"."LUMINOSITYMEASUREMENT" ADD CONSTRAINT "PUBLIC"."FKQDST9Y9X0ODS4WPLRT9QW6HY" FOREIGN KEY("ABSTRACTSOURCE_ID") REFERENCES "PUBLIC"."ASTROOBJECT"("ID") NOCHECK;            
ALTER TABLE "PUBLIC"."BASEC" ADD CONSTRAINT "PUBLIC"."FKIMVTFGQD2E8F8TS0QDO5OD8HE" FOREIGN KEY("SOMECONTENT_ID") REFERENCES "PUBLIC"."SOMECONTENT"("ID") NOCHECK;              
ALTER TABLE "PUBLIC"."ATEST2" ADD CONSTRAINT "PUBLIC"."FK6FV3YSH7M6GNUI5EKYBFJ7898" FOREIGN KEY("REFCONT_ID") REFERENCES "PUBLIC"."REFERREDLIFECYCLE"("ID") NOCHECK;           
ALTER TABLE "PUBLIC"."PHYSICALCOORDSYS" ADD CONSTRAINT "PUBLIC"."FKDEVRHVIM7I1DFO48FUP3IW66" FOREIGN KEY("ID") REFERENCES "PUBLIC"."COORDSYS"("ID") NOCHECK;   
ALTER TABLE "PUBLIC"."LCHILD" ADD CONSTRAINT "PUBLIC"."FKBPJI587L8MTJWS0USVCHK5DE0" FOREIGN KEY("PARENT_ID") REFERENCES "PUBLIC"."PARENT"("ID") NOCHECK;       
ALTER TABLE "PUBLIC"."TIMESYS" ADD CONSTRAINT "PUBLIC"."FK8HECWB4S4PQR2KVGSW5NIEP9E" FOREIGN KEY("ID") REFERENCES "PUBLIC"."PHYSICALCOORDSYS"("ID") NOCHECK;   
ALTER TABLE "PUBLIC"."ASTROOBJECT" ADD CONSTRAINT "PUBLIC"."FKRXCSM0YVTD9BYMIJ2YSLEATS4" FOREIGN KEY("FRAME_NAME") REFERENCES "PUBLIC"."SKYCOORDINATEFRAME"("NAME") NOCHECK;   
ALTER TABLE "PUBLIC"."SOURCECATALOGUE" ADD CONSTRAINT "PUBLIC"."FKRQEVPIFGX1WGEYRSCN0VSYUJ4" FOREIGN KEY("ATESTMORE_ID") REFERENCES "PUBLIC"."TESTING"("ID") NOCHECK;          
ALTER TABLE "PUBLIC"."DISCRETESETAXIS" ADD CONSTRAINT "PUBLIC"."FK5QG4WWCJA8EMQCRFW5SCYHFDR" FOREIGN KEY("ID") REFERENCES "PUBLIC"."AXIS"("ID") NOCHECK;       
ALTER TABLE "PUBLIC"."SOMECONTENT" ADD CONSTRAINT "PUBLIC"."FKO7XJPH52AT2M3438D6IA48BY0" FOREIGN KEY("REF2_NAME") REFERENCES "PUBLIC"."REFB"("NAME") NOCHECK;  
