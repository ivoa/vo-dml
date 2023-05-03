package org.ivoa.vodml.validation;
/*
 * Created on 03/05/2023 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.ivoa.vodml.ModelManagement;
import org.ivoa.vodml.validation.ModelValidator.ValidationResult;

import javax.persistence.EntityManager;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.bind.PropertyException;
import javax.xml.bind.Unmarshaller;
import javax.xml.bind.ValidationEvent;
import javax.xml.bind.util.ValidationEventCollector;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import java.io.File;
import java.io.StringReader;
import java.io.StringWriter;
import java.util.HashMap;
import java.util.Map;

public abstract class BaseValidationTest {
    protected  <T> RoundTripResult<T> roundTripJSON(ModelManagement<T> m) throws JsonProcessingException {
        T model = m.theModel();
        @SuppressWarnings("unchecked")
        Class<T> clazz =  (Class<T>) model.getClass();
        ObjectMapper mapper = m.jsonMapper();
        String json = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(model);
        System.out.println("JSON output");
        System.out.println(json);
        T retval = mapper.readValue(json, clazz);
        return new RoundTripResult<T>(true, retval);

    }

    public static class RoundTripResult <T>  {
        public final boolean isValid;
        public final T retval;
        RoundTripResult(boolean isValid, T retval) {
            this.isValid = isValid;
            this.retval = retval;
        }
    }

    protected <T> RoundTripResult<T> roundtripXML(ModelManagement<T> modelManagement) throws ParserConfigurationException, JAXBException,
    PropertyException, TransformerFactoryConfigurationError,
    TransformerConfigurationException, TransformerException {
        T model = modelManagement.theModel();
        @SuppressWarnings("unchecked")
        Class<T> clazz =  (Class<T>) model.getClass();
        JAXBContext jc = modelManagement.contextFactory();
        StringWriter sw = new StringWriter();
        Marshaller m = jc.createMarshaller();

        m.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
        m.marshal(model, sw);
        // Actually pretty Print - as the above formatting instruction does not seem to work
        // Set up the output transformer
        TransformerFactory transfac = TransformerFactory.newInstance();
        Transformer trans = transfac.newTransformer();
        trans.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
        trans.setOutputProperty(OutputKeys.INDENT, "yes"); 

        StringWriter sw2 = new StringWriter();
        StreamResult result = new StreamResult(sw2);

        trans.transform(new StreamSource(new StringReader(sw.toString())), result);
        System.out.println(sw2.toString());

        //try to read in again
        Unmarshaller um = jc.createUnmarshaller();
        ValidationEventCollector vc = new javax.xml.bind.util.ValidationEventCollector();
        um.setEventHandler(vc);
        JAXBElement<T> el = um.unmarshal(new StreamSource(new StringReader(sw2.toString())),clazz);
        if (vc.hasEvents()) {
            for (ValidationEvent err : vc.getEvents()) {
                System.err.println(err.getMessage());
            }
        }           
        T modelin = el.getValue();
        return new RoundTripResult<T>(!vc.hasEvents(), modelin);
    }
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
    
    protected <T> ValidationResult validate(ModelManagement<T> mm, File schema) throws JAXBException {
        ModelValidator v = new ModelValidator(schema, mm.contextFactory());
        return v.validate(mm.theModel());
        
    }

}
