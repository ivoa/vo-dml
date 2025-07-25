package org.ivoa.vodml.validation;
/*
 * Created on 03/05/2023 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import java.io.StringReader;
import java.io.StringWriter;
import java.net.URL;
import java.sql.PreparedStatement;
import java.util.*;

import com.networknt.schema.output.OutputUnit;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.SharedCacheMode;
import jakarta.persistence.ValidationMode;
import jakarta.persistence.spi.ClassTransformer;
import jakarta.persistence.spi.PersistenceUnitInfo;
import jakarta.persistence.spi.PersistenceUnitTransactionType;
import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.JAXBElement;
import jakarta.xml.bind.JAXBException;
import jakarta.xml.bind.Marshaller;
import jakarta.xml.bind.PropertyException;
import jakarta.xml.bind.Unmarshaller;
import jakarta.xml.bind.ValidationEvent;
import jakarta.xml.bind.util.ValidationEventCollector;

import javax.sql.DataSource;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.hibernate.Session;
import org.hibernate.jpa.boot.internal.EntityManagerFactoryBuilderImpl;
import org.hibernate.jpa.boot.internal.PersistenceUnitInfoDescriptor;
import org.ivoa.vodml.ModelDescription;
import org.ivoa.vodml.ModelManagement;
import org.ivoa.vodml.VodmlModel;
import org.ivoa.vodml.jpa.JPAManipulationsForObjectType;
import org.ivoa.vodml.validation.XMLValidator.ValidationResult;

/**
 * Base Class for doing validating tests.
 */
public abstract class AbstractBaseValidation {
    /**
     * Do a JSON round trip of a model instance.
     * @param m A model instance.
     * @return The result of the round trip test.
     * @param <T> The Model class .
     * @throws JsonProcessingException if there is a problem with the JSON processing
     */
    protected  <T> RoundTripResult<T> roundTripJSON(VodmlModel<T> m) throws JsonProcessingException {
        T model = m.management().theModel();
        if(m.management().hasReferences())
        {
           m.processReferences();
        }
        @SuppressWarnings("unchecked")
        Class<T> clazz =  (Class<T>) model.getClass();
        ObjectMapper mapper = m.management().jsonMapper();
        String json = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(model);
        System.out.println("JSON output");
        System.out.println(json);
        JSONValidator jsonValidator = new JSONValidator(m.management());
        OutputUnit vresult = jsonValidator.validate(json);
        if (!vresult.isValid()) {
            System.err.println(vresult.toString());
        }
        T retval = mapper.readValue(json, clazz);
        return new RoundTripResult<T>(vresult.isValid(), retval);

    }

    /**
     * The result of doing a round trip test.
     * @param <T> the model class.
     */
    public static class RoundTripResult <T>  {
        /** if the result passes validity tests.
         */
        public final boolean isValid;
        /** The returned value from the round trip.
         */
        public final T retval;
        RoundTripResult(boolean isValid, T retval) {
            this.isValid = isValid;
            this.retval = retval;
        }
    }

    /**
     * Do a XML round trip of a model instance.
     * @param vodmlModel a model instance.
     * @return the result of doing a round trip.
     * @param <T> The model class.
     * @throws ParserConfigurationException if there is a parser problem.
     * @throws JAXBException if there is a JAX problem.
     * @throws PropertyException if the property is problematic.
     * @throws TransformerFactoryConfigurationError if there is an error in the setup of the transformer.
     * @throws TransformerConfigurationException if there is an error in the setup of the transformer.
     * @throws TransformerException if there is an error in the setup of the transformer.
     */
    protected <T extends VodmlModel<T>> RoundTripResult<T> roundtripXML(VodmlModel<T> vodmlModel) throws ParserConfigurationException, JAXBException,
    PropertyException, TransformerFactoryConfigurationError,
    TransformerConfigurationException, TransformerException {
        T model = vodmlModel.management().theModel();
        if(vodmlModel.management().hasReferences())
        {
           vodmlModel.processReferences();
        }
        @SuppressWarnings("unchecked")
        Class<T> clazz =  (Class<T>) model.getClass();
        JAXBContext jc = vodmlModel.management().contextFactory();
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
        final String xmlOutput = sw2.toString();
        System.out.println(xmlOutput);
        XMLValidator xmlValidator = new XMLValidator(vodmlModel.management());
        ValidationResult validation = xmlValidator.validate(xmlOutput);
        if(!validation.isOk)
        {
           validation.printValidationErrors(System.err); 
        }

        //try to read in again
        Unmarshaller um = jc.createUnmarshaller();
        ValidationEventCollector vc = new jakarta.xml.bind.util.ValidationEventCollector();
        um.setEventHandler(vc);
        JAXBElement<T> el = um.unmarshal(new StreamSource(new StringReader(xmlOutput)),clazz);
        if (vc.hasEvents()) {
            for (ValidationEvent err : vc.getEvents()) {
                System.err.println(err.getMessage());
            }
        }           
        T modelin = el.getValue();
        return new RoundTripResult<T>(!vc.hasEvents() & validation.isOk, modelin);
    }

    /**
     * Do an RDB round trip of a model instance.
     * @param modelManagement Then model management
     * @param entity The entity to round trip.
     * @return the entity retrieved from the database after it has been stored.
     * @param <M> the model class.
     * @param <I> The type of the identifier for the entity.
     * @param <T> The type of the entity.
     */
    protected <M, I, T extends JPAManipulationsForObjectType<I>> RoundTripResult<T> roundtripRDB(ModelManagement<M> modelManagement, T  entity)
    {
       
        jakarta.persistence.EntityManager em = setupH2Db(modelManagement.pu_name(), modelManagement.description().allClassNames());
        em.getTransaction().begin();
        modelManagement.persistRefs(em);
        em.persist(entity);
        em.getTransaction().commit();
        I id = entity.getId();
        String dumpfile = setDbDumpFile();
        if(dumpfile!= null) dumpDbData(em, dumpfile);
        //flush any existing entities
        em.clear();
        em.getEntityManagerFactory().getCache().evictAll();

        // now read back
        @SuppressWarnings("unchecked")
        T r = (T) em.createNamedQuery(entity.getClass().getSimpleName()+".findById", entity.getClass())
                .setParameter("id", id).getSingleResult();
        
        return new RoundTripResult<T>(true, r);

    }

    /**
     * Create an Entity manager for a memory-based test database;
     * @param puname the persistence unit name of the JPA DB.
     * @param classNames the list of classes managed by the persistence unit.
     * @return the EntityManager for the database.
     */
    protected EntityManager setupH2Db(String puname, List<String> classNames) {


        PersistenceUnitInfo persistenceUnitInfo = new HibernatePersistenceUnitInfo(puname, classNames);
        Map<String, Object> configuration = new HashMap<>();
        return new EntityManagerFactoryBuilderImpl(
              new PersistenceUnitInfoDescriptor(persistenceUnitInfo), configuration)
              .build().createEntityManager();
    }



    /**
     * Validate a model instance. This is done via JAXB.
     * @param m the model instance.
     * @return result of the validation.
     * @param <T> the model class.
     * @throws JAXBException exception when there is a JAXB problem.
     */
    protected <T> ValidationResult validateModel(VodmlModel<T> m) throws JAXBException {

        XMLValidator v = new XMLValidator(m.management());
        return v.validateObject(m.management().theModel());
        
    }

    /**
     * Write the contents of the database to a file.
     * @param em the entity manager for the database.
     * @param filename The name of the file to write the DDL to.
     */
    protected void dumpDbData(jakarta.persistence.EntityManager em, String filename) {
        //IMPL hibernate specific way of getting connection... generally dirty, see  https://stackoverflow.com/questions/3493495/getting-database-connection-in-pure-jpa-setup
            Session sess = em.unwrap(Session.class);
            sess.doWork(conn -> {
                PreparedStatement ps = conn.prepareStatement("SCRIPT TO ?"); // this is H2db specific
                ps.setString(1, filename);
                ps.execute();
            });
    }

    /**
     * set the name of the file to which the dbDump is written. The default is null so that no file is written.
     * @return the filename.
     */
    protected String setDbDumpFile() {
        return  null;
    }


    private static class HibernatePersistenceUnitInfo implements PersistenceUnitInfo {

        public static String JPA_VERSION = "2.1";
        private String persistenceUnitName;
        private PersistenceUnitTransactionType transactionType
              = PersistenceUnitTransactionType.RESOURCE_LOCAL;
        private List<String> managedClassNames;
        private List<String> mappingFileNames = new ArrayList<>();
        private Properties properties;
        private DataSource jtaDataSource;
        private DataSource nonjtaDataSource;
        private List<ClassTransformer> transformers = new ArrayList<>();

        public HibernatePersistenceUnitInfo(
              String persistenceUnitName, List<String> managedClassNames) {
            this.persistenceUnitName = persistenceUnitName;
            this.managedClassNames = managedClassNames;
            this.properties = new Properties();
            //derby
            //      properties.put("jakarta.persistence.jdbc.url", "jdbc:derby:memory:"+puname+";create=true");//IMPL differenrt DB for each PU to stop interactions
            //        properties.put(PersistenceUnitProperties.JDBC_URL, "jdbc:derby:emerlindb;create=true;traceFile=derbytrace.out;traceLevel=-1;traceDirectory=/tmp");
            //      properties.put("jakarta.persistence.jdbc.driver", "org.apache.derby.jdbc.EmbeddedDriver");
            // properties.put(PersistenceUnitProperties.TARGET_DATABASE, "org.eclipse.persistence.platform.database.DerbyPlatform");

            //        //h2
            properties.put("jakarta.persistence.jdbc.url", "jdbc:h2:mem:"+persistenceUnitName+";DB_CLOSE_DELAY=-1");//IMPL differenrt DB for each PU to stop interactions
            properties.put("jakarta.persistence.jdbc.driver", "org.h2.Driver");
            properties.put("hibernate.dialect", "org.hibernate.dialect.H2Dialect");
            //        properties.put(PersistenceUnitProperties.TARGET_DATABASE, "org.eclipse.persistence.platform.database.H2Platform");
            //
            //        //hsqldb
            //        properties.put(PersistenceUnitProperties.JDBC_URL, "jdbc:hsqldb:mem:"+puname+";");//IMPL differenrt DB for each PU to stop interactions
            //        properties.put(PersistenceUnitProperties.JDBC_DRIVER, "org.hsqldb.jdbcDriver");
            //        properties.put(PersistenceUnitProperties.TARGET_DATABASE, "org.eclipse.persistence.platform.database.HSQLPlatform");


            // properties.put(PersistenceUnitProperties.DDL_GENERATION_MODE, PersistenceUnitProperties.DDL_BOTH_GENERATION);
            properties.put("jakarta.persistence.schema-generation.scripts.create-target", "test.sql");
            properties.put("jakarta.persistence.schema-generation.scripts.drop-target", "test-drop.sql");
            properties.put("hibernate.hbm2ddl.schema-generation.script.append", "false");
            properties.put("jakarta.persistence.create-database-schemas", "true");

            properties.put("jakarta.persistence.schema-generation.create-source", "metadata");
            properties.put("jakarta.persistence.schema-generation.database.action", "drop-and-create");
            properties.put("jakarta.persistence.schema-generation.scripts.action", "drop-and-create");
            properties.put("jakarta.persistence.jdbc.user", "");
            //        properties.put(PersistenceUnitProperties.CACHE_SHARED_, "false");

        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getPersistenceUnitName()
         */
        @Override
        public String getPersistenceUnitName() {
            return persistenceUnitName;
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getPersistenceProviderClassName()
         */
        @Override
        public String getPersistenceProviderClassName() {
            return "org.hibernate.jpa.HibernatePersistenceProvider";
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getTransactionType()
         */
        @Override
        public PersistenceUnitTransactionType getTransactionType() {
            return  transactionType;     
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getJtaDataSource()
         */
        @Override
        public DataSource getJtaDataSource() {
           return null;
            
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getNonJtaDataSource()
         */
        @Override
        public DataSource getNonJtaDataSource() {
            return null;
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getMappingFileNames()
         */
        @Override
        public List<String> getMappingFileNames() {
            return mappingFileNames;
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getJarFileUrls()
         */
        @Override
        public List<URL> getJarFileUrls() {
           return Collections.emptyList();
            
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getPersistenceUnitRootUrl()
         */
        @Override
        public URL getPersistenceUnitRootUrl() {
           return null;
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getManagedClassNames()
         */
        @Override
        public List<String> getManagedClassNames() {
            return managedClassNames;            
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#excludeUnlistedClasses()
         */
        @Override
        public boolean excludeUnlistedClasses() {
            return true;           
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getSharedCacheMode()
         */
        @Override
        public SharedCacheMode getSharedCacheMode() {
            return SharedCacheMode.ALL;//IMPL is this good?
            
        }
        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getValidationMode()
         */
        @Override
        public ValidationMode getValidationMode() {
            return ValidationMode.AUTO;
                
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getProperties()
         */
        @Override
        public Properties getProperties() {
            return properties;
            
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getPersistenceXMLSchemaVersion()
         */
        @Override
        public String getPersistenceXMLSchemaVersion() {
            return JPA_VERSION;
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getClassLoader()
         */
        @Override
        public ClassLoader getClassLoader() {
          return Thread.currentThread().getContextClassLoader(); //IMPL ??
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#addTransformer(jakarta.persistence.spi.ClassTransformer)
         */
        @Override
        public void addTransformer(ClassTransformer transformer) {
            // TODO Auto-generated method stub
            throw new  UnsupportedOperationException("PersistenceUnitInfo.addTransformer() not implemented");
            
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.spi.PersistenceUnitInfo#getNewTempClassLoader()
         */
        @Override
        public ClassLoader getNewTempClassLoader() {
            return null;// return Thread.currentThread().getContextClassLoader(); //IMPL or null

        }
   }
}
