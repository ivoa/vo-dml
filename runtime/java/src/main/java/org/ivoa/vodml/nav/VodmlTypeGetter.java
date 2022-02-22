/*
 * Created on 31 Aug 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.nav;


/**
 * Gets The basic VODML meta model information for a type.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 31 Aug 2021
 */
public interface VodmlTypeGetter {

     /**
      * 
      * @return the VODML type information.
      */
     VodmlTypeInfo vodmlInfo();
}


