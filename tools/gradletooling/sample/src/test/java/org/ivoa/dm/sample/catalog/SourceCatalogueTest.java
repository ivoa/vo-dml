package org.ivoa.dm.sample.catalog;

import static org.junit.jupiter.api.Assertions.*;

import java.io.File;
import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.util.*;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
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
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.ivoa.dm.filter.PhotometryFilter;
import org.ivoa.dm.ivoa.RealQuantity;
import org.ivoa.dm.ivoa.Unit;
import org.ivoa.dm.sample.SampleModel;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;
//import org.javastro.ivoa.entities.jaxb.DescriptionValidator;
//import org.javastro.ivoa.entities.jaxb.JaxbAnnotationMeta;
import org.w3c.dom.Document;

/*
 * Created on 20/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
class SourceCatalogueTest {

    /** logger for this class */
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(SourceCatalogueTest.class);
    private SourceCatalogue sc;


    @org.junit.jupiter.api.BeforeEach
    void setUp() {
               final Unit jansky = new Unit("Jy");
        final Unit degree = new Unit("degree");
        final Unit GHz= new Unit("GHz");
        final SkyCoordinateFrame frame = new SkyCoordinateFrame().withName("J2000").withEquinox("J2000.0").withDocumentURI("http://coord.net");

        final AlignedEllipse ellipseError = new AlignedEllipse(.2, .1);
        SDSSSource sdss = new SDSSSource().withPositionError(ellipseError);// UNUSED, but just checking position error subsetting.
        sdss.setPositionError(ellipseError);
        AlignedEllipse theError = sdss.getPositionError();

        sc = SourceCatalogue.builder(c -> {
            c.name = "testCat";
            c.entry = Arrays.asList(SDSSSource.builder(s -> {
                s.name = "testSource";
                s.classification = SourceClassification.AGN;
                s.position = SkyCoordinate.builder(co -> {
                    co.frame = frame;
                    co.latitude = new RealQuantity(52.5, degree );
                    co.longitude = new RealQuantity(2.5, degree );
                });
                s.positionError = ellipseError;//note subsetting forces compile need AlignedEllipse

                s.luminosity = Arrays.asList(
                        LuminosityMeasurement.builder(l ->{
                            l.description = "lummeas";
                            l.type = LuminosityType.FLUX;                         
                            l.value = new RealQuantity(2.5, jansky );
                            l.error = new RealQuantity(.25, jansky );
                            l.filter = PhotometryFilter.builder(fl -> {
                                fl.bandName ="C-Band";
                                fl.spectralLocation = new RealQuantity(5.0,GHz);
                                fl.dataValidityFrom = new Date();
                                fl.dataValidityTo = new Date();
                                fl.description = "radio band";
                                fl.name = fl.bandName;
                            });
                            
                        })
                        ,LuminosityMeasurement.builder(l ->{
                            l.description = "lummeas2";
                            l.filter = PhotometryFilter.builder(fl -> {
                                fl.bandName ="L-Band";
                                fl.spectralLocation = new RealQuantity(1.5,GHz);
                                fl.dataValidityFrom = new Date();
                                fl.dataValidityTo = new Date();
                                fl.description = "radio band";
                                fl.name = fl.bandName;
                            });
                            l.type = LuminosityType.FLUX;
                            l.value = new RealQuantity(3.5, jansky );
                            l.error = new RealQuantity(.25, jansky );//TODO should be allowed to be null

   })

                        );
            }));
        }
                );


    }

    private static class MySchemaOutputResolver extends SchemaOutputResolver {
        public Result createOutput(String uri, String suggestedFileName)
                throws IOException {
            String[] parts = uri.split("/");


            File file = new File(suggestedFileName);//new File(parts[parts.length -2]+".xsd");
            StreamResult result = new StreamResult(file);
            System.out.println("uri=" + uri + " " + file.getName());
            result.setSystemId(file.toURI().toURL().toString());
            return result;
        }
    };


    @org.junit.jupiter.api.Test
    void sourceCatJaxBTest() throws JAXBException, ParserConfigurationException, TransformerException, IOException {

        logger.debug("starting test");
 
        JAXBContext jc = SampleModel.contextFactory();
//        JaxbAnnotationMeta<SourceCatalogue> meta = JaxbAnnotationMeta.of(SourceCatalogue.class);
//        DescriptionValidator<SourceCatalogue> validator = new DescriptionValidator<>(jc, meta);
//        DescriptionValidator.Validation validation = validator.validate(sc);
//        if(!validation.valid) {
//            System.err.println(validation.message);
//        }
//        assertTrue(validation.valid);

        SampleModel model = new SampleModel();
        model.addContent(sc);
        model.makeRefIDsUnique();
//        JaxbAnnotationMeta<SampleModel> mmeta = JaxbAnnotationMeta.of(SampleModel.class);
//        DescriptionValidator<SampleModel> mvalidator = new DescriptionValidator<>(jc, mmeta);
//        DescriptionValidator.Validation mvalidation = mvalidator.validate(model);
//        assertTrue(mvalidation.valid, "errors on whole model");


        DocumentBuilderFactory dbf = DocumentBuilderFactory
                .newInstance();
        dbf.setNamespaceAware(true);
        Document doc = dbf.newDocumentBuilder().newDocument();
        Marshaller m = jc.createMarshaller();
        m.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
        JAXBElement<SampleModel> element =  new JAXBElement<SampleModel>(new QName("http://ivoa.net/dm/models/vo-dml/xsd/sample/sample", "SampleModel"),SampleModel.class,model);//mmeta.element(model);
        m.marshal(element, doc);
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
        JAXBElement<SampleModel> el = um.unmarshal(new StreamSource(new StringReader(sw.toString())),SampleModel.class);
        if (vc.hasEvents()) {
            for (ValidationEvent err : vc.getEvents()) {
                System.err.println(err.getMessage());
            }
        }
        assertTrue(!vc.hasEvents(), "reading xml back had errors");
        SampleModel modelin = el.getValue();
        assertNotNull(modelin);
        List<SourceCatalogue> lin = modelin.getContent(SourceCatalogue.class);
        assertEquals(1, lin.size());
        SourceCatalogue scin = lin.get(0);
        System.out.println(lin.get(0).getName());
        SDSSSource src = (SDSSSource) scin.getEntry().get(0);
        AlignedEllipse perr = src.getPositionError();
        assertEquals(0.2, perr.longError);
        assertTrue(!src.getLuminosity().get(0).getFilter().getBandName().equals(
       src.getLuminosity().get(1).getFilter().getBandName()),"failure to distiguish references");
        

        SchemaOutputResolver sor = new MySchemaOutputResolver();
        System.out.println("generating schema");
        jc.generateSchema(sor);
    }
    
    @org.junit.jupiter.api.Test
    void sourceCatJPATest() {
                Map<String, String> props = new HashMap<>();
        
        //
                
               final String puname = "vodml_sample";

        //derby
        props.put("javax.persistence.jdbc.url", "jdbc:derby:memory:"+puname+";create=true");//IMPL differenrt DB for each PU to stop interactions
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
        props.put("javax.persistence.schema-generation.database.action", "drop-and-create");
        props.put("javax.persistence.schema-generation.scripts.action", "drop-and-create");
        props.put("javax.persistence.jdbc.user", "");
//        props.put(PersistenceUnitProperties.CACHE_SHARED_, "false");
        
     // Configure logging. FINE ensures all SQL is shown
        //props.put(PersistenceUnitProperties.LOGGING_LEVEL, "FINEST");
         
 
        javax.persistence.EntityManagerFactory emf = javax.persistence.Persistence.createEntityManagerFactory(puname, props);
        
        javax.persistence.EntityManager em = emf.createEntityManager();
        em.getTransaction().begin();
        em.persist(sc);
        em.getTransaction().commit();
        Long id = sc.getId();
        
        em.getTransaction().begin();
        List<SourceCatalogue> cats = em.createNamedQuery("SourceCatalogue.findById", SourceCatalogue.class)
                .setParameter("id", id).getResultList();
        assertEquals(1, cats.size());
        SourceCatalogue nc = cats.get(0);
        em.getTransaction().commit();
        assertEquals(1, nc.getEntry().size());
        
        SDSSSource src = (SDSSSource) nc.getEntry().get(0);
        AlignedEllipse err = src.getPositionError();
        assertEquals(.2, err.getLongError());

    }
}
