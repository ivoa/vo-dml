/*
 * Created on 3 May 2023 
 * Copyright 2023 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.validation;

import java.io.*;
import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.XMLConstants;
import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.JAXBException;
import jakarta.xml.bind.util.JAXBSource;

import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import org.ivoa.vodml.ModelManagement;
import org.ivoa.vodml.VodmlModel;
import org.xml.sax.ErrorHandler;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xmlresolver.ResolverFeature;
import org.xmlresolver.XMLResolverConfiguration;
import org.xmlresolver.XMLResolver;
import org.xmlresolver.catalog.entry.EntryCatalog;

/**
 * A Model Validator.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 3 May 2023
 */
public class XMLValidator {
    // TODO would really like this to be a xsd 1.1 validator.
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(XMLValidator.class);

    private final String schemaCat;
    private JAXBContext jc;

    private final Source[] schemaFiles;


    /**
     * Create modelValidator from XML Schema.
     * @param modelManagement the model description.
     */
    public XMLValidator(ModelManagement<?> modelManagement) {
        schemaFiles = modelManagement.description().schemaMap().entrySet().stream()
                .map(s -> new StreamSource(this.getClass().getResourceAsStream("/"+s.getValue()),s.getKey()))
                .toArray(Source[]::new);
        schemaCat = makeCatalogue( modelManagement.description().schemaMap());
        try {
            this.jc = modelManagement.contextFactory();
        } catch (JAXBException e) {
            this.jc = null;
            logger.error("unable to create a model validator", e);
        }
    }

    /**
     * create a validator that will validate VO-DML model definitions themselves.
     */
    public XMLValidator() {
         schemaFiles = new Source[]{new StreamSource(this.getClass().getResourceAsStream("/xsd/vo-dml-v1.0.xsd"))};
        StringWriter writer = new StringWriter();
        writer.write("<catalog xmlns=\"urn:oasis:names:tc:entity:xmlns:xml:catalog\">\n");
        writer.write("</catalog>");
         schemaCat = writer.toString();

    }


    static private String makeCatalogue(Map<String, String> schemaMap) {
        StringWriter writer = new StringWriter();

        writer.write("<catalog xmlns=\"urn:oasis:names:tc:entity:xmlns:xml:catalog\">\n");
        schemaMap.forEach((k,v) -> {
            writer.append("<uri name=\"");
            writer.append(k);
            writer.append("\" uri=\"classpath:/");
            writer.append(v);
            writer.append("\"/>\n");
        });

        writer.write("</catalog>");


        return writer.toString();
    }


    /**
     * the model validation kind.
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     * 
     */
    public enum ErrorKind {
        /** Unknown.
         */
        Unknown,
        /** Warning.
         */
        Warning,
        /** Error.
         */
        Error,
        /** FatalError.
         */
        FatalError,
        /** Sax.
         */
        Sax
    }

    /** the map of validation errors.
     */
    protected Map<ErrorKind, List<ErrorDescription>> errorMap;

    /**
     * Represents the validation resulf. .
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     */
    public static class ValidationResult {
        /** is the result valid.
         */
        public final boolean isOk;
        private final  Map<ErrorKind, List<ErrorDescription>> errorMap;
        ValidationResult(boolean isOk,
                Map<ErrorKind, List<ErrorDescription>> errorMap) {
            this.isOk = isOk;
            this.errorMap = new HashMap<>(errorMap);
        }
        /**
         * print the validation result.
         * @param printStream the printstream to which the result is printed.
         */
        public void printValidationErrors(PrintStream printStream) {
            errorMap.forEach((kind, errors) -> {
                errors.stream().forEach(printStream::println);
            });
        }

        /**
         * print the validation errors to a writer.
         * @param writer the writer to print to.
         */
        public void printValidationErrors(Writer writer) {
            errorMap.forEach((kind, errors) -> {
                errors.stream().forEach(errorDescription -> {
                   try {
                      writer.write(errorDescription.toString());
                      writer.write(System.lineSeparator());
                   } catch (IOException e) {
                      throw new RuntimeException(e);
                   }
                });
            });
        }
    }
    private class ErrorDescription {
        String desc;
        ErrorKind kind;
        int line;
        int column;


        ErrorDescription(ErrorKind kind, SAXParseException e) {
            this.desc = e.getMessage();
            this.kind = kind;
            this.line = e.getLineNumber();
            this.column = e.getColumnNumber();
        }

        ErrorDescription(SAXException e) {
            this.desc = e.getMessage();
            this.kind = ErrorKind.Sax;
            this.line = 0;
            this.column = 0;
        }



        ErrorDescription(RuntimeException e) {
            this.desc = e.getCause().getMessage();
            this.kind = ErrorKind.Unknown;
            this.line = 0;
            this.column = 0;

        }
        /**
         * {@inheritDoc}
         * overrides @see java.lang.Object#toString()
         */
        @Override
        public String toString() {
            StringBuilder builder = new StringBuilder();
            builder.append("Validation ");
            builder.append(kind);
            builder.append(" ").append(desc);
            if(line> 0) {
                builder.append(" line=");
                builder.append(line);
                if (column > 0) {
                    builder.append(", column=");
                    builder.append(column);
                }
            }
            return builder.toString();
        }
    }
    private class SimpleErrorHandler implements ErrorHandler
    {

        /**
         * {@inheritDoc}
         * overrides @see org.xml.sax.ErrorHandler#warning(org.xml.sax.SAXParseException)
         */
        @Override
        public void warning(SAXParseException exception) throws SAXException {
            final ErrorKind kind = ErrorKind.Warning;
            final  ErrorDescription err = new ErrorDescription(kind, exception);
            logger.trace(err.toString());
            put(errorMap,kind, err);

        }

        /**
         * {@inheritDoc}
         * overrides @see org.xml.sax.ErrorHandler#error(org.xml.sax.SAXParseException)
         */
        @Override
        public void error(SAXParseException exception) throws SAXException {
            final ErrorKind kind = ErrorKind.Warning;
            final  ErrorDescription err = new ErrorDescription(kind, exception);
            logger.trace(err.toString());
            put(errorMap,kind, err);

        }

        /**
         * {@inheritDoc}
         * overrides @see org.xml.sax.ErrorHandler#fatalError(org.xml.sax.SAXParseException)
         */
        @Override
        public void fatalError(SAXParseException exception)
                throws SAXException {
            final ErrorKind kind = ErrorKind.Warning;
            final  ErrorDescription err = new ErrorDescription(kind, exception);
            logger.trace(err.toString());
            put(errorMap,kind, err);
        }


    }


    /**
     * validate an object from the model.
     * @param <T> The type of the object
     * @param p The type to be validated.
     * @return the result of the validation.
     */
    public  <T> ValidationResult validateObject(T p) {
        try {
            JAXBSource source = new JAXBSource(jc, p);
            validateJAXB(source);
        } catch (JAXBException e) {
            ErrorDescription d = new ErrorDescription(new RuntimeException(e));
            put(errorMap, d.kind, d);;
        } 
        return new ValidationResult(errorMap.isEmpty(), errorMap);
    }

    /**
     * Validate the file content against the model.
     * @param file containing xml instance of the model.
     * @return the validation
     */
    public ValidationResult validate(File file) {
        return validate(new StreamSource(file));
    }

    /**
     * Validate the string content against the model.
     * @param s string containing a model instance.
     * @return the validation.
     */
    public ValidationResult validate(String s) {
        return validate(new StreamSource(new StringReader(s)));
    }

    /**
     * Validate a source.
     * @param source the source to be validated.
     * @return the validation result.
     */
    public ValidationResult validate(Source source) {
        try {

            Validator validator = initValidator();

            validator.validate(source);


        } catch (SAXException e) {
            ErrorDescription d = new ErrorDescription(e);
            put(errorMap, d.kind, d);

        } catch (IOException e) {
            ErrorDescription d = new ErrorDescription(new RuntimeException(e));
            put(errorMap, d.kind, d);;
        }

        return new ValidationResult(errorMap.isEmpty(), errorMap);

    }


    ValidationResult validateJAXB (JAXBSource source) {
        return validate(source);
    }



    private Validator initValidator() throws SAXException {
        errorMap = new HashMap<>();
        SchemaFactory schemaFactory = SchemaFactory
                .newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
        schemaFactory.setResourceResolver(makeXMLResolver().getLSResourceResolver());
        Schema schema = schemaFactory.newSchema(schemaFiles);
        Validator validator = schema.newValidator();
        validator.setErrorHandler(new SimpleErrorHandler());
        return validator;
    }

    XMLResolver makeXMLResolver() {
        XMLResolverConfiguration config = new XMLResolverConfiguration();
        config.setFeature(ResolverFeature.DEFAULT_LOGGER_LOG_LEVEL, "info");
        config.setFeature(ResolverFeature.ACCESS_EXTERNAL_DOCUMENT, "all");// it would be nice if this actually did stop external lookups as suggested
        config.setFeature(ResolverFeature.THROW_URI_EXCEPTIONS, true);
        config.setFeature(ResolverFeature.ALWAYS_RESOLVE, true);
        config.setFeature(ResolverFeature.PREFER_PUBLIC, false);
        config.setFeature(ResolverFeature.CLASSPATH_CATALOGS, true);
        config.setFeature(ResolverFeature.CLASSLOADER, ClassLoader.getSystemClassLoader());//trying to get a classloader that will load resources from inside jar...

        org.xmlresolver.CatalogManager manager = config
                .getFeature(ResolverFeature.CATALOG_MANAGER);
        URI caturi = URI.create("https://ivoa.net/vodml/catalog.xml");//IMPL - not sure is this should be more obviously false.
        config.addCatalog(caturi.toString());
        EntryCatalog cat = manager.loadCatalog(caturi, new InputSource(new StringReader(schemaCat)));

        XMLResolver resolver = new XMLResolver(config);
        return resolver;
    }


    private static  <KEY, VALUE > void put (Map<KEY, List<VALUE>> map, KEY key, VALUE value) {
        map.computeIfAbsent(key, k -> new ArrayList<>()).add(value);
    }

}
