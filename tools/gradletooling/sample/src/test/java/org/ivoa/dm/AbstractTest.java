/*
 * Created on 5 Nov 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.dm;

import static org.junit.jupiter.api.Assertions.*;

import java.util.HashMap;
import java.util.Map;

import javax.persistence.EntityManager;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.ivoa.vodml.ModelManagement;

/**
 * Base Class for the test classes .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 5 Nov 2021
 */
public abstract class AbstractTest extends org.javastro.ivoa.tests.AbstractJAXBJPATest {

     protected EntityManager setupH2Db(String puname){
           Map<String, String> props = new HashMap<>();
          
          //
            
          //derby
    //      props.put("javax.persistence.jdbc.url", "jdbc:derby:memory:"+puname+";create=true");//IMPL differenrt DB for each PU to stop interactions
    //        props.put(PersistenceUnitProperties.JDBC_URL, "jdbc:derby:emerlindb;create=true;traceFile=derbytrace.out;traceLevel=-1;traceDirectory=/tmp");
    //      props.put("javax.persistence.jdbc.driver", "org.apache.derby.jdbc.EmbeddedDriver");
          // props.put(PersistenceUnitProperties.TARGET_DATABASE, "org.eclipse.persistence.platform.database.DerbyPlatform");
    
    //        //h2
            props.put("javax.persistence.jdbc.url", "jdbc:h2:mem:"+puname+";DB_CLOSE_DELAY=-1");//IMPL differenrt DB for each PU to stop interactions
            props.put("javax.persistence.jdbc.driver", "org.h2.Driver");
            props.put("hibernate.dialect", "org.hibernate.dialect.H2Dialect");
    //        props.put(PersistenceUnitProperties.TARGET_DATABASE, "org.eclipse.persistence.platform.database.H2Platform");
    //        
    //        //hsqldb
    //        props.put(PersistenceUnitProperties.JDBC_URL, "jdbc:hsqldb:mem:"+puname+";");//IMPL differenrt DB for each PU to stop interactions
    //        props.put(PersistenceUnitProperties.JDBC_DRIVER, "org.hsqldb.jdbcDriver");
    //        props.put(PersistenceUnitProperties.TARGET_DATABASE, "org.eclipse.persistence.platform.database.HSQLPlatform");
          
          
          // props.put(PersistenceUnitProperties.DDL_GENERATION_MODE, PersistenceUnitProperties.DDL_BOTH_GENERATION);
          props.put("javax.persistence.schema-generation.scripts.create-target", "test.sql");
          props.put("javax.persistence.schema-generation.scripts.drop-target", "test-drop.sql");
          props.put("hibernate.hbm2ddl.schema-generation.script.append", "false");
          
          props.put("javax.persistence.schema-generation.create-source", "metadata");
          props.put("javax.persistence.schema-generation.database.action", "drop-and-create");
          props.put("javax.persistence.schema-generation.scripts.action", "drop-and-create");
          props.put("javax.persistence.jdbc.user", "");
    //        props.put(PersistenceUnitProperties.CACHE_SHARED_, "false");
          
        // Configure logging. FINE ensures all SQL is shown
          //props.put(PersistenceUnitProperties.LOGGING_LEVEL, "FINEST");
           
     
          javax.persistence.EntityManagerFactory emf = javax.persistence.Persistence.createEntityManagerFactory(puname, props);
          
          javax.persistence.EntityManager em = emf.createEntityManager();
            return em;
        
    }

    protected  <T> T roundTripJSON(ModelManagement<T> m) throws JsonProcessingException {
        T model = m.theModel();
        @SuppressWarnings("unchecked")
        Class<T> clazz =  (Class<T>) model.getClass();
        ObjectMapper mapper = m.jsonMapper();
        String json = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(model);
        System.out.println("JSON output"); 
        System.out.println(json);
        T retval = mapper.readValue(json, clazz);
        assertNotNull(retval);
        return retval;

    }

}


