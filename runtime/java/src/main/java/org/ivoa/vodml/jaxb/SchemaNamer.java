package org.ivoa.vodml.jaxb;
/*
 * Created on 26/09/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
import org.ivoa.vodml.nav.ModelInstanceTraverser;

import javax.xml.bind.SchemaOutputResolver;
import javax.xml.transform.Result;
import javax.xml.transform.stream.StreamResult;
import java.io.IOException;
import java.util.Arrays;
import java.util.Map;

/**
 *
 */
public class SchemaNamer  extends  SchemaOutputResolver {
   /** logger for this class */
   private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
         .getLogger(SchemaOutputResolver.class);
   private final Map<String,String> names;

   public SchemaNamer(Map<String,String> n) {
      this.names = n;
   }

   @Override
   public Result createOutput(String namespaceUri, String suggestedFileName) throws IOException {
      String n;
      if(names.containsKey(namespaceUri) && !names.get(namespaceUri).isEmpty()) {
         n = names.get(namespaceUri);
      }
      else {
         n = Arrays.stream(namespaceUri.split("/+")).filter(s -> s.length() > 0).map(s -> s+".xsd").reduce((first, second) -> second).orElse(suggestedFileName);
      }
      logger.info("schema namespace {} written to {}",namespaceUri,n);
      return new StreamResult(n);
   }
}
