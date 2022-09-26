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

import java.io.File;
import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.util.HashMap;
import java.util.Map;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.bind.PropertyException;
import javax.xml.bind.SchemaOutputResolver;
import javax.xml.bind.Unmarshaller;
import javax.xml.bind.ValidationEvent;
import javax.xml.bind.util.ValidationEventCollector;
import javax.xml.namespace.QName;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Result;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.w3c.dom.Document;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 5 Nov 2021
 */
public class AbstractTest {


    protected javax.persistence.EntityManager setupDB(String puname) {
            Map<String, String> props = new HashMap<>();
          
          //
            
          //derby
          props.put("javax.persistence.jdbc.url", "jdbc:derby:memory:"+puname+";create=true;traceFile=derbytrace.out;traceLevel=-1;");//IMPL differenrt DB for each PU to stop interactions
    //        props.put(PersistenceUnitProperties.JDBC_URL, "jdbc:derby:emerlindb;create=true;traceFile=derbytrace.out;traceLevel=-1;traceDirectory=/tmp");
          props.put("javax.persistence.jdbc.driver", "org.apache.derby.jdbc.EmbeddedDriver");
          // props.put(PersistenceUnitProperties.TARGET_DATABASE, "org.eclipse.persistence.platform.database.DerbyPlatform");
    
    //        //h2
    //        props.put(PersistenceUnitProperties.JDBC_URL, "jdbc:h2:mem:"+puname+";DB_CLOSE_DELAY=-1");//IMPL differenrt DB for each PU to stop interactions
    //        props.put(PersistenceUnitProperties.JDBC_DRIVER, "org.h2.Driver");
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
          props.put("javax.persistence.schema-generation.database.action", "create");
          props.put("javax.persistence.schema-generation.scripts.action", "drop-and-create");
          props.put("javax.persistence.jdbc.user", "");
    //        props.put(PersistenceUnitProperties.CACHE_SHARED_, "false");
          
        // Configure logging. FINE ensures all SQL is shown
          //props.put(PersistenceUnitProperties.LOGGING_LEVEL, "FINEST");
           
     
          javax.persistence.EntityManagerFactory emf = javax.persistence.Persistence.createEntityManagerFactory(puname, props);
          
          javax.persistence.EntityManager em = emf.createEntityManager();
            return em;
        }

    protected <T> T roundtripXML(JAXBContext jc, T model, Class<T> clazz) throws ParserConfigurationException, JAXBException,
            PropertyException, TransformerFactoryConfigurationError,
            TransformerConfigurationException, TransformerException {
                DocumentBuilderFactory dbf = DocumentBuilderFactory
                        .newInstance();
                dbf.setNamespaceAware(true);
                Document doc = dbf.newDocumentBuilder().newDocument();
                Marshaller m = jc.createMarshaller();
                m.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
                m.marshal(model, doc);
                // Set up the output transformer
                TransformerFactory transfac = TransformerFactory.newInstance();
                Transformer trans = transfac.newTransformer();
                trans.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
                trans.setOutputProperty(OutputKeys.INDENT, "yes");
            
                // Print the DOM node
                StringWriter sw = new StringWriter();
                StreamResult result = new StreamResult(sw);
                DOMSource source = new DOMSource(doc);
                trans.transform(source, result);
                System.out.println(sw.toString());
            
                //try to read in again
                Unmarshaller um = jc.createUnmarshaller();
                ValidationEventCollector vc = new javax.xml.bind.util.ValidationEventCollector();
                um.setEventHandler(vc);
                JAXBElement<T> el = um.unmarshal(new StreamSource(new StringReader(sw.toString())),clazz);
                if (vc.hasEvents()) {
                    for (ValidationEvent err : vc.getEvents()) {
                        System.err.println(err.getMessage());
                    }
                }
                assertTrue(!vc.hasEvents(), "reading xml back had errors");
                T modelin = el.getValue();
                assertNotNull(modelin);
                return modelin;
            }

}


