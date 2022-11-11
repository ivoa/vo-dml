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
    /**
     * The VODML reference
     * @return a string with the VODML reference
     */
    String id();
    
    /**
     * the VODML role
     * @return the role
     */
    VodmlRole role();
    
    /**
     * The type. not needed if the role is such that the id is the same as the type.
     * @return the type as a vodml reference
     */
    String type() default "";
    

    /**
     * the VODML role or the declared type. Only useful for attributes.
     * @return the role
     */
    VodmlRole typeRole() default VodmlRole.unknown ;
  
}
