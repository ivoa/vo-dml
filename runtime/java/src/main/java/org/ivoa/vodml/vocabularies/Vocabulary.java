package org.ivoa.vodml.vocabularies;
/*
 * Created on 10/09/2024 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.io.IOException;
import java.net.URI;
import java.net.URL;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * an IVOA vocabulary as described in https://www.ivoa.net/documents/Vocabularies.
 */
public class Vocabulary {

   /**
    * The terms in the vocabulary.
    */
   Map<String,Term> terms = new HashMap<>();

   public Vocabulary(String url) {
      this.url = url;
   }

   /**
    * The base URL that defines the vocabulary.
    */
   private String url;

   /**
    * Load a vocabulary. Note that this is implemented by requesting the "desise" format for ease.
    * @TODO should probably be reimplemented to read RDF
    * @param url the location of the vocabulary
    * @return the vocabulary
    */
   public static Vocabulary load(String url)  {

      Vocabulary vocabulary = new Vocabulary(url);
      try {
         HttpClient client = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NORMAL).build();

         // read the vocabulary in the 'desise' format
         HttpRequest request = HttpRequest.newBuilder()
               .uri(URI.create(url))
               .header("Accept", "application/x-desise+json")
               .GET()
               .build();
         HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

         // Check if the response is OK (status code 200)
         if (response.statusCode() != 200) {
            throw new RuntimeException("cannot load vocabulary : " + response.statusCode());
         }

         // Parse the JSON using Jackson
         ObjectMapper objectMapper = new ObjectMapper().configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
         JsonNode rootNode = objectMapper.readTree(response.body());
         // read the initial terms
         for ( var entry : rootNode.get("terms").properties()) {

            ObjectNode term = (ObjectNode) entry.getValue();
            term.put("term", entry.getKey());
            vocabulary.terms.put(entry.getKey(),objectMapper.treeToValue(term, Term.class)); //FIXME the deprecated and preliminary JSON are not being actually written as boolean in desise
         }
         //connect the wider and narrower.
         for ( var entry : rootNode.get("terms").properties()) {
            ObjectNode term = (ObjectNode) entry.getValue();
            Term voterm = vocabulary.terms.get(entry.getKey());
            if(term.has("wider")) {
               term.get("wider").spliterator().forEachRemaining(e -> voterm.addWider(vocabulary.terms.get(e.textValue())));
            }
            if(term.has("narrower")) {
               term.get("narrower").spliterator().forEachRemaining(e -> voterm.addNarrower(vocabulary.terms.get(e.textValue())));
            }
            if(term.has("parent")) { //FIXME desise does not show parent
               voterm.addParent(vocabulary.terms.get(term.get("parent").textValue()));
            }
         }
      } catch (IOException | InterruptedException e) {
         throw new RuntimeException("cannot load vocabulary",e);
      }



      return vocabulary;
   }
}
