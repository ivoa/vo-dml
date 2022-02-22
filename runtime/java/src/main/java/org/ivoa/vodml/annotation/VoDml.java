package org.ivoa.vodml.annotation;

import java.lang.annotation.Documented;
import java.lang.annotation.Retention;
import java.lang.annotation.Target;

import static java.lang.annotation.ElementType.*;
import static java.lang.annotation.RetentionPolicy.RUNTIME;

/*
 * Created on 11/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
@Documented
@Retention(RUNTIME) @Target({TYPE,FIELD})
public @interface VoDml {
   String ref();
   VodmlType type();
}
