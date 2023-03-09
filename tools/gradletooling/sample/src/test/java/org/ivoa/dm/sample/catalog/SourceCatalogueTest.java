package org.ivoa.dm.sample.catalog;
import static org.junit.jupiter.api.Assertions.*;


import java.io.IOException;
import java.sql.PreparedStatement;
import java.util.List;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;

import com.fasterxml.jackson.core.JsonProcessingException;

import org.hibernate.Session;
import org.ivoa.dm.sample.SampleModel;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;

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


        SampleModel modelin = roundtripXML(jc, model, SampleModel.class); 
        checkModel(modelin.getContent(SourceCatalogue.class));
        


        System.out.println("generating schema");
        SampleModel.writeXMLSchema();
    }

    @org.junit.jupiter.api.Test
    void sourceCatJPATest() {
       javax.persistence.EntityManager em = setupH2Db(SampleModel.pu_name());
        em.getTransaction().begin();
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
          c.walkCollections();//force any lazy loading to happen
          model.addContent(c);
       }


        em.getTransaction().commit();
       //IMPL hibernate specific way of getting connection... generally dirty, see  https://stackoverflow.com/questions/3493495/getting-database-connection-in-pure-jpa-setup
        Session sess = em.unwrap(Session.class);
        sess.doWork(conn -> {
            PreparedStatement ps = conn.prepareStatement("SCRIPT TO ?"); // this is H2db specific
            ps.setString(1, "test_dump.sql");
            ps.execute();
        });
        

    }
   @org.junit.jupiter.api.Test
   void sourceCatJSONTest() throws JsonProcessingException {
      SampleModel model = new SampleModel();
      model.addContent(sc);
      model.makeRefIDsUnique();
      SampleModel modelin = roundTripJSON(model.management());
      checkModel(modelin.getContent(SourceCatalogue.class));
     
   }

   @org.junit.jupiter.api.Test
   void sourceCatDeleteTest() throws JsonProcessingException {
      SampleModel model = new SampleModel();
      model.addContent(sc);
      model.makeRefIDsUnique();
      model.deleteContent(sc); //
      SampleModel modelin = roundTripJSON(model.management()); // FIXME need to test that the refenences are gone

   }

}
