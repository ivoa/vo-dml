/*
 * Created on 3 May 2023 
 * Copyright 2023 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml;

/**
 *  Marks as a vodml model. Also provides some useful management interfaces.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 3 May 2023
 * IMPL it might be nicer just to inherit all of the interfaces.
 */
public interface VodmlModel <T> extends org.ivoa.vodml.jaxb.JaxbManagement {
    ModelManagement<T> management(); 
    ModelDescription descriptor();
}


