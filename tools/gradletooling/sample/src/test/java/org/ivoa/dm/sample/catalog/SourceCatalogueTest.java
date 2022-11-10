package org.ivoa.dm.sample.catalog;

import static org.ivoa.dm.filter.PhotometryFilter.createPhotometryFilter;
import static org.ivoa.dm.sample.catalog.LuminosityMeasurement.createLuminosityMeasurement;
import static org.ivoa.dm.sample.catalog.SDSSSource.createSDSSSource;
import static org.ivoa.dm.sample.catalog.SkyCoordinate.createSkyCoordinate;
import static org.ivoa.dm.sample.catalog.inner.SourceCatalogue.createSourceCatalogue;
import static org.junit.jupiter.api.Assertions.*;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.Arrays;
import java.util.Date;
import java.util.List;

import javax.persistence.Query;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.SchemaOutputResolver;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;

import com.fasterxml.jackson.core.JsonProcessingException;

import org.hibernate.Session;
import org.ivoa.dm.AbstractTest;
import org.ivoa.dm.ivoa.RealQuantity;
import org.ivoa.dm.ivoa.Unit;
import org.ivoa.dm.sample.SampleModel;
import org.ivoa.dm.sample.SampleModel.References;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;
import org.ivoa.vodml.ModelManagement;

/*
 * Created on 20/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
class SourceCatalogueTest extends AbstractTest {

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

        sc = createSourceCatalogue(c -> {
            c.name = "testCat";
            c.entry = Arrays.asList(createSDSSSource(s -> {
                s.name = "testSource";
                s.classification = SourceClassification.AGN;
                s.position = createSkyCoordinate(co -> {
                    co.frame = frame;
                    co.latitude = new RealQuantity(52.5, degree );
                    co.longitude = new RealQuantity(2.5, degree );
                });
                s.positionError = ellipseError;//note subsetting forces compile need AlignedEllipse

                s.luminosity = Arrays.asList(
                        createLuminosityMeasurement(l ->{
                            l.description = "lummeas";
                            l.type = LuminosityType.FLUX;                         
                            l.value = new RealQuantity(2.5, jansky );
                            l.error = new RealQuantity(.25, jansky );
                            l.filter = createPhotometryFilter(fl -> {
                                fl.bandName ="C-Band";
                                fl.spectralLocation = new RealQuantity(5.0,GHz);
                                fl.dataValidityFrom = new Date();
                                fl.dataValidityTo = new Date();
                                fl.description = "radio band";
                                fl.name = fl.bandName;
                            });
                            
                        })
                        ,createLuminosityMeasurement(l ->{
                            l.description = "lummeas2";
                            l.filter = createPhotometryFilter(fl -> {
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

    private void checkModel(List<SourceCatalogue> lin) {
        assertEquals(1, lin.size());
        SourceCatalogue scin = lin.get(0);
        System.out.println(lin.get(0).getName());
        SDSSSource src = (SDSSSource) scin.getEntry().get(0);
        AlignedEllipse perr = src.getPositionError();
        assertEquals(0.2, perr.longError);
        assertTrue(!src.getLuminosity().get(0).getFilter().getBandName().equals(
        src.getLuminosity().get(1).getFilter().getBandName()),"failure to distinguish references");
        SkyCoordinateFrame fr = src.getPosition().getFrame();
        assertNotNull(fr);
        assertEquals("J2000", fr.getName());
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
            PreparedStatement ps = conn.prepareStatement("SCRIPT TO ?"); // this is H2db specifid
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

}
