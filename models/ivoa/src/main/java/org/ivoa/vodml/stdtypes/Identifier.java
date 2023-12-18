
package org.ivoa.vodml.stdtypes;
        


      /**
      *  something that an identifier that can be used as a key for lookup of an entity that is *outside this datamodel*.
      *  PrimitiveType identifier :
      *
      *  @author generated by https://github.com/ivoa/vo-dml tools
      */
      
@org.ivoa.vodml.annotation.VoDml(id="ivoa:identifier", role=org.ivoa.vodml.annotation.VodmlRole.primitiveType)
          

    @org.eclipse.microprofile.openapi.annotations.media.Schema(description="something that an identifier that can be used as a key for lookup of an entity that is *outside this datamodel*")
    @jakarta.persistence.Embeddable

    @jakarta.xml.bind.annotation.XmlType( name = "identifier")
  
      public abstract class Identifier  implements java.io.Serializable {

        private static final long serialVersionUID = 1L;


          /**
      * no arg constructor.
      */
      protected Identifier() {}

      }
  