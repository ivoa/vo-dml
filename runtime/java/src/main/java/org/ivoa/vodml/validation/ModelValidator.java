/*
 * Created on 3 May 2023 
 * Copyright 2023 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.validation;

import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.XMLConstants;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.util.JAXBSource;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 * A Model Validator.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 3 May 2023
 */
public class ModelValidator {
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(ModelValidator.class);

    private final Source[] schemaFiles;
    private final JAXBContext jc;

    
    /**
     * Create modelValidator from XML Schema.
     * @param schemaFile the XML schema for the model
     * @param jc the J
     */
    public  ModelValidator(File schemaFile, JAXBContext jc) {
        schemaFiles = new Source[] {new StreamSource(schemaFile)};
        this.jc = jc;
    }

    
    public enum ErrorKind {
        Unknown,
        Warning,
        Error,
        FatalError,
        Sax
    }

    protected Map<ErrorKind, List<ErrorDescription>> errorMap;

    public static class ValidationResult {
        public final boolean isOk;
        private final  Map<ErrorKind, List<ErrorDescription>> errorMap;
        ValidationResult(boolean isOk,
                Map<ErrorKind, List<ErrorDescription>> errorMap) {
            this.isOk = isOk;
            this.errorMap = new HashMap<>(errorMap);
        }
        public void printValidationErrors(PrintStream printStream) {
            errorMap.forEach((kind, errors) -> {
                errors.stream().forEach(printStream::println);
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

    
    <T> ValidationResult validate (T p) {

        try {
            errorMap = new HashMap<>();
            SchemaFactory schemaFactory = SchemaFactory
                    .newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
            Schema schema = schemaFactory.newSchema(schemaFiles);
            Validator validator = schema.newValidator();
            validator.setErrorHandler(new SimpleErrorHandler());
            JAXBSource source = new JAXBSource(jc, p);   validator.validate(source);;


        } catch (SAXException e) {
            ErrorDescription d = new ErrorDescription(e);
            put(errorMap, d.kind, d);

        } catch (IOException | JAXBException e) {
            ErrorDescription d = new ErrorDescription(new RuntimeException(e));
            put(errorMap, d.kind, d);;
        }
      
        return new ValidationResult(errorMap.isEmpty(), errorMap);
    }

    private static  <KEY, VALUE > void put (Map<KEY, List<VALUE>> map, KEY key, VALUE value) {
        map.computeIfAbsent(key, k -> new ArrayList<>()).add(value);
    }

}
