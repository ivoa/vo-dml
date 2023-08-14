package org.ivoa.dm.sample.catalog;
import static org.junit.jupiter.api.Assertions.*;


import java.io.IOException;
import java.util.List;

import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.JAXBException;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;

import com.fasterxml.jackson.core.JsonProcessingException;

import org.ivoa.dm.sample.SampleModel;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;
import org.ivoa.vodml.VodmlModel;

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
        em.persist(sc);
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

}
