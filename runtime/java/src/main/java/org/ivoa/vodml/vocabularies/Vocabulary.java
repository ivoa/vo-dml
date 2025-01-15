package org.ivoa.vodml.vocabularies;
/*
 * Created on 10/09/2024 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.URL;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * an IVOA vocabulary as described in https://www.ivoa.net/documents/Vocabularies.
 */
public class Vocabulary {

    /**
     * The terms in the vocabulary.
     */
    Map<String,Term> terms = new HashMap<>();

    /**
     * Create a vocabulary for the given URI.
     * @param url the identifier for the vocabulary.
     */
    public Vocabulary(String url) {
        this.url = url;
    }


    /**
     * The base URL that defines the vocabulary.
     */
    private String url;
    
    private boolean loadSuccessful;


    /**
     * gets the vocabulary id.
     * @return the URL that is the identifier for the vocabulary.
     */
    public String getUrl() {
        return url;
    }

    /**
     * has the vocabulary loaded successfully.
     * @return true if successful.
     */
    public boolean isLoadSuccessful() {
        return loadSuccessful;
    }
    /**
     * Load a vocabulary from remote. Note that this is implemented by requesting the "desise" format for ease.
     * @TODO should probably be reimplemented to read RDF
     * @param url the location of the vocabulary
     * @return the vocabulary
     */
    public static Vocabulary loadRemote(String url)  {

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

            loadInternal(response.body(), vocabulary);
        } catch (IOException | InterruptedException e) {
            //throw new RuntimeException("cannot load vocabulary",e);
            System.err.println("cannot load vocabulary "+url+" "+e.getMessage());//TODO decide on logging
        }



        return vocabulary;
    }

    /**
     * Load a vocabulary from local resource. Note that this is implemented by requesting the "desise" format for ease.
     * @TODO should probably be reimplemented to read RDF
     * @param url the location of the vocabulary
     * @return the vocabulary
     */
    public static Vocabulary loadLocal(String url)  {
        Vocabulary vocabulary = new Vocabulary(url);
        ClassLoader classLoader = Vocabulary.class.getClassLoader();
        try (InputStream is = classLoader.getResourceAsStream(URLEncoder.encode(url, StandardCharsets.UTF_8))) {
            if (is == null) {
                System.err.println("cannot load vocabulary " + url);//TODO decide on logging
                return vocabulary;
            }
            try (InputStreamReader isr = new InputStreamReader(is);
                 BufferedReader reader = new BufferedReader(isr)) {
                loadInternal(reader.lines().collect(Collectors.joining(System.lineSeparator())), vocabulary);
            } catch (IOException e) {
                throw new RuntimeException("cannot load vocabulary " + url,e);
            }
        } catch (IOException e) {
           throw new RuntimeException("cannot load vocabulary " + url,e);
        }

       return vocabulary;

    }

    private static void loadInternal(String desise, Vocabulary vocabulary) throws JsonProcessingException {
        // Parse the JSON using Jackson
        ObjectMapper objectMapper = new ObjectMapper().configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        JsonNode rootNode = objectMapper.readTree(desise);
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
        vocabulary.loadSuccessful = true;
    }

    /**
     * Does the term exist in the vocabulary.
     * @param term expressed as a string.
     * @return true if the term is in the vocabulary.
     */
    public boolean hasTerm(String term)
    {
        return loadSuccessful? terms.containsKey(term):true; //TODO might want to warn that not testing....
    }

    /**
     * Fetch a term definition from the vocabulary.
     * @param term the term value.
     * @return the definition.
     */
    public Optional<Term> getTerm(String term) {
        return Optional.ofNullable(terms.get(term));
    }
    
    
}
