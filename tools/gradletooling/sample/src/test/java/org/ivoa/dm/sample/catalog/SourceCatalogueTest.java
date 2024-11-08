package org.ivoa.dm.sample.catalog;

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.networknt.schema.*;
import com.networknt.schema.output.OutputUnit;
import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.JAXBException;
import jakarta.xml.bind.Marshaller;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.util.List;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;
import org.ivoa.dm.sample.SampleModel;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;
import org.ivoa.vodml.validation.XMLValidator;
import org.ivoa.vodml.validation.XMLValidator.ValidationResult;

/*
 * Created on 20/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
class SourceCatalogueTest extends BaseSourceCatalogueTest {

  /** logger for this class */
  private static final org.slf4j.Logger logger =
      org.slf4j.LoggerFactory.getLogger(SourceCatalogueTest.class);

  @org.junit.jupiter.api.Test
  void sourceCatJaxBTest()
      throws JAXBException, ParserConfigurationException, TransformerException, IOException {

    logger.debug("starting JAXB test");

    JAXBContext jc = SampleModel.contextFactory();

    SampleModel model = new SampleModel();
    model.addContent(ps);
    model.addContent(sc);

    model.processReferences();

    SampleModel modelin = modelRoundTripXMLwithTest(model);
    checkModel(modelin.getContent(SourceCatalogue.class));
   
  }

  @org.junit.jupiter.api.Test
  void sourceCatJPATest() {
    jakarta.persistence.EntityManager em = setupH2Db(SampleModel.pu_name());
    SampleModel omodel = new SampleModel();
    omodel.addContent(sc);
    omodel.addContent(ps);
    em.getTransaction().begin();
    omodel.management().persistRefs(em);
    em.persist(ps);
    em.persist(sc); // TODO need to test whether Photometric system is saved....
    em.getTransaction().commit();
    Long id = sc.getId();

    // flush any existing entities
    em.clear();
    em.getEntityManagerFactory().getCache().evictAll();

    // now read back
    em.getTransaction().begin();
    List<SourceCatalogue> cats =
        em.createNamedQuery("SourceCatalogue.findById", SourceCatalogue.class)
            .setParameter("id", id)
            .getResultList();
    checkModel(cats);

    // now try to add into a new model
    SampleModel model = new SampleModel();
    for (SourceCatalogue c : cats) {
      c.forceLoad(); // force any lazy loading to happen
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
    SampleModel modelin =
        modelRoundTripJSONwithTest(model); // FIXME need to test that the refenences are gone
  }

 
  @org.junit.jupiter.api.Test
  void sourceCatCopyTest() throws JsonProcessingException {
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
  void listManipulationTest() {
    jakarta.persistence.EntityManager em = setupH2Db(SampleModel.pu_name());
    em.getTransaction().begin();
    sc.persistRefs(em);
    em.persist(sc);
    em.getTransaction().commit();
    List<AbstractSource> ls = sc.getEntry();
    List<LuminosityMeasurement> lms = ls.get(0).getLuminosity();
    // copy constructor creates an object not
    LuminosityMeasurement lumnew = new LuminosityMeasurement(lms.get(0));
    lumnew.setDescription("this is new");
    // merge in changes to the existing db
    lms.get(0).updateUsing(lumnew);
    em.getTransaction().begin();
    em.merge(lms.get(0));
    em.getTransaction().commit();
    em.clear();

    // read back from db
    List<SourceCatalogue> cats =
        em.createQuery("select s from SourceCatalogue s", SourceCatalogue.class).getResultList();
    assertEquals(
        "this is new", cats.get(0).getEntry().get(0).getLuminosity().get(0).getDescription());

    lumnew.setDescription("another way to update");
    lumnew._id =
        lms.get(0)._id; // NB this setting of IDs directly not available in end DM API - only
    // possible because of shared package

    ls.get(0).replaceInLuminosity(lumnew);

    em.getTransaction().begin();
    em.merge(lms.get(0));
    em.getTransaction().commit();
    em.clear();

    List<SourceCatalogue> cats2 =
        em.createQuery("select s from SourceCatalogue s", SourceCatalogue.class).getResultList();
    assertEquals(
        "another way to update",
        cats2.get(0).getEntry().get(0).getLuminosity().get(0).getDescription());
  }

  @org.junit.jupiter.api.Test
  void externalXMLSchemaTest() throws JAXBException, IOException {

    SampleModel model = new SampleModel();
    model.addContent(sc);
    model.addContent(ps);
    model.processReferences();

    String topschema = model.modelDescription.schemaMap().get(model.modelDescription.xmlNamespace());
    System.out.println(topschema);
    assertNotNull(topschema);
    InputStream schemastream = this.getClass().getResourceAsStream("/" + topschema);
    assertNotNull(schemastream);

    XMLValidator validator = new XMLValidator(model.management());
    Marshaller jaxbMarshaller = model.management().contextFactory().createMarshaller();
    jaxbMarshaller.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, true);
    File fout = File.createTempFile("samplemod", ".tmp");
    FileWriter fw = new FileWriter(fout);
    jaxbMarshaller.marshal(model, fw);
    ValidationResult result = validator.validate(fout);
    if (!result.isOk) {
      System.err.println("File " + fout.getAbsolutePath());
      result.printValidationErrors(System.err);
    }
    assertTrue(result.isOk, "validation with external schema");
  }

  @org.junit.jupiter.api.Test
  void externalJSONSchemaTest() throws JAXBException, IOException {

    SampleModel model = new SampleModel();
    model.addContent(
        ps); // IMPL N.B add the photometric system first, as it has sc used it in contained
    // references - it does work the other way round, but looks strange....
    model.addContent(sc);
    model.processReferences();

    ObjectMapper mapper = model.management().jsonMapper();
    StringWriter fw = new StringWriter();
    mapper.writerWithDefaultPrettyPrinter().writeValue(fw, model);
    System.out.println(fw.toString());
    JsonSchemaFactory jsonSchemaFactory =
        JsonSchemaFactory.getInstance(
            SpecVersion.VersionFlag.V202012,
            builder ->
                // This creates a mapping from $id which starts with
                // https://www.example.org/ to the retrieval URI classpath:schema/
                builder.schemaMappers(
                    schemaMappers ->
                        schemaMappers.mapPrefix("https://ivoa.net/dm/", "classpath:/")));
    SchemaValidatorsConfig config = new SchemaValidatorsConfig();
    // By default JSON Path is used for reporting the instance location and evaluation path
    config.setPathType(PathType.JSON_POINTER);

    // Due to the mapping the schema will be retrieved from the classpath at
    // classpath:schema/example-main.json.
    // If the schema data does not specify an $id the absolute IRI of the schema location will
    // be used as the $id.
    JsonSchema schema =
        jsonSchemaFactory.getSchema(
            SchemaLocation.of("https://ivoa.net/dm/Sample.vo-dml.json"), config);
    OutputUnit outputUnit =
        schema.validate(
            fw.toString(),
            InputFormat.JSON,
            OutputFormat.HIERARCHICAL,
            executionContext -> {
              // By default since Draft 2019-09 the format keyword only generates
              // annotations and not assertions
              executionContext.getExecutionConfig().setFormatAssertionsEnabled(true);
            });

    if (!outputUnit.isValid()) {
      System.err.println(outputUnit.toString());
    }

    assertTrue(outputUnit.isValid());
  }
}
