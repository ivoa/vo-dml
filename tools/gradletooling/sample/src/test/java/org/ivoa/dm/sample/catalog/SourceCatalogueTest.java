package org.ivoa.dm.sample.catalog;
import static org.junit.jupiter.api.Assertions.*;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.List;
import java.util.stream.Collectors;

import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.JAXBException;
import jakarta.xml.bind.Marshaller;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.stream.StreamSource;

import com.fasterxml.jackson.core.JsonProcessingException;

import org.ivoa.dm.sample.SampleModel;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;
import org.ivoa.vodml.VodmlModel;
import org.ivoa.vodml.validation.ModelValidator;
import org.ivoa.vodml.validation.ModelValidator.ValidationResult;

/*
 * Created on 20/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
class SourceCatalogueTest extends BaseSourceCatalogueTest {

    /** logger for this class */
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(SourceCatalogueTest.class);
    @org.junit.jupiter.api.Test
    void sourceCatJaxBTest() throws JAXBException, ParserConfigurationException, TransformerException, IOException {

        logger.debug("starting JAXB test");
 
        JAXBContext jc = SampleModel.contextFactory();

        SampleModel model = new SampleModel();
        model.addContent(sc);
        model.addContent(ps);
        model.processReferences();

        SampleModel modelin = modelRoundTripXMLwithTest(model); 
        checkModel(modelin.getContent(SourceCatalogue.class));
        System.out.println("generating schema");
        SampleModel.writeXMLSchema();
    }

    @org.junit.jupiter.api.Test
    void sourceCatJPATest() {
       jakarta.persistence.EntityManager em = setupH2Db(SampleModel.pu_name());
        em.getTransaction().begin();
        sc.persistRefs(em);
        em.persist(sc); // TODO need to test whether Photometric system is saved....
        em.getTransaction().commit();
        Long id = sc.getId();

        //flush any existing entities
        em.clear();
        em.getEntityManagerFactory().getCache().evictAll();

        // now read back
        em.getTransaction().begin();
        List<SourceCatalogue> cats = em.createNamedQuery("SourceCatalogue.findById", SourceCatalogue.class)
                .setParameter("id", id).getResultList();
        checkModel(cats);


        // now try to add into a new model
       SampleModel model = new SampleModel();
       for(SourceCatalogue c :cats) {
          c.forceLoad();//force any lazy loading to happen
          model.addContent(c);
       }


        em.getTransaction().commit();
       dumpDbData(em, "test_dump.sql");
        

    }

    @org.junit.jupiter.api.Test
   void sourceCatJSONTest() throws JsonProcessingException {
      SampleModel model = new SampleModel();
      model.addContent(sc);
      model.processReferences();
      SampleModel modelin = modelRoundTripJSONwithTest(model);
      checkModel(modelin.getContent(SourceCatalogue.class));
     
   }

   @org.junit.jupiter.api.Test
   void sourceCatDeleteTest() throws JsonProcessingException {
      SampleModel model = new SampleModel();
      model.addContent(sc);
      model.processReferences();
      model.deleteContent(sc); //
      SampleModel modelin = modelRoundTripJSONwithTest(model); // FIXME need to test that the refenences are gone

   }

   @org.junit.jupiter.api.Test
   void sourceCatJPACloneTest() throws JsonProcessingException {
       SampleModel model = new SampleModel();
       jakarta.persistence.EntityManager em = setupH2Db(SampleModel.pu_name());
       em.getTransaction().begin();
       sc.persistRefs(em);
       em.persist(sc);
       em.getTransaction().commit();
       model.addContent(sc);
       
       em.getTransaction().begin();
       sc.jpaClone(em);   
       sc.setName("cloned catalogue");
       sc.getEntry().get(0).setName("cloned source");
       em.merge(sc);
       em.getTransaction().commit(); 
       model.addContent(sc);
       // note that sc gets updated by the clone - so would appear twice in the following
//       SampleModel modelin = roundTripJSON(model.management());

       List<SourceCatalogue> cats = em.createQuery("select s from SourceCatalogue s", SourceCatalogue.class).getResultList();
       model = new SampleModel();
       for (SourceCatalogue s : cats) {
           model.addContent(s); 
       }

       SampleModel modelin = modelRoundTripJSONwithTest(model);
       assertNotNull(modelin);
       long ncat = (long) em.createQuery("select count(o) from SourceCatalogue o").getSingleResult();
       assertEquals(2, ncat,"number of catalogues");
       long nsrc = (long) em.createQuery("select count(o) from SDSSSource o").getSingleResult();
       assertEquals(2, nsrc,"number of sources");
       
   }
   
   @org.junit.jupiter.api.Test
   void sourceCatCopyTest() throws JsonProcessingException
   {
       SourceCatalogue newsc = new SourceCatalogue(sc);
       assertNotNull(newsc);
       assertNotNull(newsc.getEntry().get(0).position);
       sc.setName("sillytest");
       assertEquals("testCat", newsc.getName());
       SampleModel model = new SampleModel();
       model.addContent(sc);
       model.addContent(newsc);
       model.processReferences();
       SampleModel modelin = modelRoundTripJSONwithTest(model);
       assertNotNull(modelin);
   }

    @org.junit.jupiter.api.Test
   void listManipulationTest()
   {
       jakarta.persistence.EntityManager em = setupH2Db(SampleModel.pu_name());
       em.getTransaction().begin();
       sc.persistRefs(em);
       em.persist(sc);
       em.getTransaction().commit();
       List<AbstractSource> ls = sc.getEntry();
       List<LuminosityMeasurement> lms = ls.get(0).getLuminosity();
       //copy constructor creates an object not
       LuminosityMeasurement lumnew = new LuminosityMeasurement(lms.get(0));
       lumnew.setDescription("this is new");
       // merge in changes to the existing db 
       lms.get(0).updateUsing(lumnew);
       em.getTransaction().begin();
       em.merge(lms.get(0));
       em.getTransaction().commit();
       em.clear();
       
       // read back from db
        List<SourceCatalogue> cats = em.createQuery("select s from SourceCatalogue s", SourceCatalogue.class).getResultList();
       assertEquals("this is new", cats.get(0).getEntry().get(0).getLuminosity().get(0).getDescription());

       lumnew.setDescription("another way to update");
       lumnew._id = lms.get(0)._id; //NB this setting of IDs directly not available in end DM API - only possible because of shared package
       
       ls.get(0).replaceInLuminosity(lumnew);
       
       em.getTransaction().begin();
       em.merge(lms.get(0));
       em.getTransaction().commit();
       em.clear();

       List<SourceCatalogue> cats2 = em.createQuery("select s from SourceCatalogue s", SourceCatalogue.class).getResultList();
       assertEquals("another way to update", cats2.get(0).getEntry().get(0).getLuminosity().get(0).getDescription());

       
   }
    @org.junit.jupiter.api.Test
    void externalXMLSchemaTest() throws JAXBException, IOException {
        
       
        SampleModel model = new SampleModel();
        model.addContent(sc);
        model.addContent(ps);
        model.processReferences();
        
        String topschema = model.descriptor().schemaMap().get(model.descriptor().xmlNamespace());
        System.out.println(topschema);
        assertNotNull(topschema);
        InputStream schemastream = this.getClass().getResourceAsStream("/"+topschema);
        assertNotNull(schemastream);
        
        ModelValidator validator = new ModelValidator(model);
        Marshaller jaxbMarshaller = model.management().contextFactory().createMarshaller();
        jaxbMarshaller.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, true);
        File fout = File.createTempFile("samplemod", ".tmp"); 
        FileWriter fw = new FileWriter(fout);
        jaxbMarshaller.marshal(model, fw);
        ValidationResult result = validator.validate(fout);
        if(!result.isOk)
        {
            System.err.println("File "+ fout.getAbsolutePath());
            result.printValidationErrors(System.err);
        }
        assertTrue(result.isOk, "validation with external schema");

    }

}
