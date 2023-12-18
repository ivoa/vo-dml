
package org.ivoa.vodml.stdtypes;
        


      /**
      *  an integer identifier.
      *  PrimitiveType intIdentifier :
      *
      *  @author generated by https://github.com/ivoa/vo-dml tools
      */
      
@org.ivoa.vodml.annotation.VoDml(id="ivoa:intIdentifier", role=org.ivoa.vodml.annotation.VodmlRole.primitiveType)
          

        @org.eclipse.microprofile.openapi.annotations.media.Schema(description="an integer identifier")
    @jakarta.persistence.Embeddable

    @jakarta.xml.bind.annotation.XmlType( name = "intIdentifier")
  
      public class IntIdentifier  implements java.io.Serializable {

        private static final long serialVersionUID = 1L;

        /**  representation */
        @jakarta.xml.bind.annotation.XmlValue
        @jakarta.persistence.Column(name="val")
        protected int value;

        /**
         * Creates a new intIdentifier Primitive Type instance, wrapping a base type.
         *
         * @param v the value
         */
        public IntIdentifier(final int v) {
            this.value = v;
        }
      /**
      * no arg constructor.
      */
      protected IntIdentifier() {}

      /**
      * copy constructor.
       * @param c the other to copy
      */
      public IntIdentifier(IntIdentifier c)
      {
         this(c.value);
      }

      /**
         * Return the representation of this primitive (value)
         * @return string representation of this primitive( value)
         */
        public final int value() {
            return this.value;
        }

        /**
         * Return the string representation of this primitive value
         * @see #value()
         * @return string representation of this primitive
         */
        @Override
        public final String toString() {
            return Integer.toString(value);
        }
              

      }
  