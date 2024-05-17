package net.ivoa.vodml.gradle.plugin;
/*
 * Created on 21/10/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.options.Option;

import java.io.File;

/**
 * converts an XML schema to VODSL.
 */
public class XsdToVodslTask extends DefaultTask {
   private File xsd, dsl;

   /**
    * Set the input XSD file.
    * @param xsd the input xsd file.
    */
   @Option(option = "xsd", description = "The XML schema file to be converted (path to)")
   public void setXsd(String xsd) {
      this.xsd = new File(xsd);
      getLogger().info("transforming XSD {} {}", this.xsd.getAbsolutePath(), this.xsd.exists()
      );
   }

   /**
    * Set the output VODSL file
    * @param dsl the output filename.
    */
   @Option(option = "dsl", description = "The VODSL output file")
   public void setDsl(String dsl){
      this.dsl =  new File( dsl);
   }


   @TaskAction
   void doXsdToVodsl(){
      Xsd2Vodsl.INSTANCE.doTransform(xsd, dsl);
   }
}
