package org.ivoa.vodml.validation;


/*
 * Created on 17/12/2024 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import com.networknt.schema.*;
import com.networknt.schema.output.OutputUnit;
import org.ivoa.vodml.ModelManagement;

import java.util.Set;

/**
 * Validate JSON against the generated schema.
 */
public class JSONValidator {

   private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
         .getLogger(JSONValidator.class);
   private final ModelManagement<?> modelManagement;
   private final SchemaValidatorsConfig config;
   private JsonSchemaFactory jsonSchemaFactory;

   /**
    *  create a validator for a particular model.
    * @param modelManagement the model against which the validator should be created.
    */
   public JSONValidator(ModelManagement<?> modelManagement) {

      this.modelManagement = modelManagement;
      // This creates a schema factory that will use Draft 2020-12 as the default if $schema is not specified
// in the schema data. If $schema is specified in the schema data then that schema dialect will be used
// instead and this version is ignored.

      jsonSchemaFactory = JsonSchemaFactory.getInstance(SpecVersion.VersionFlag.V202012, builder ->
            // This creates a mapping from $id which starts with https://www.example.org/ to the retrieval URI classpath:
            builder.schemaMappers(schemaMappers -> schemaMappers.mapPrefix("https://ivoa.net/dm/", "classpath:"))
      );

      SchemaValidatorsConfig.Builder builder = SchemaValidatorsConfig.builder();
// By default the JDK regular expression implementation which is not ECMA 262 compliant is used
// Note that setting this requires including optional dependencies
// builder.regularExpressionFactory(GraalJSRegularExpressionFactory.getInstance());
// builder.regularExpressionFactory(JoniRegularExpressionFactory.getInstance());
      config = builder.build();

   }

   /**
    * validate some JSON against the model schema.
    * @param json the input JSON as a string.
    * @return the validation result.
    */
   public OutputUnit validate(String json) {
      JsonSchema schema = jsonSchemaFactory.getSchema(SchemaLocation.of(modelManagement.description().jsonSchema()), config);

      OutputUnit ou = schema.validate(json, InputFormat.JSON, OutputFormat.HIERARCHICAL, executionContext -> {
         // By default since Draft 2019-09 the format keyword only generates annotations and not assertions
         executionContext.getExecutionConfig().setFormatAssertionsEnabled(true);
      });
      return ou;
   }
}

