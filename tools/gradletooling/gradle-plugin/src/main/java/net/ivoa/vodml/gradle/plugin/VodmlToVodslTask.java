package net.ivoa.vodml.gradle.plugin;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.options.Option;

import java.io.File;

public class VodmlToVodslTask extends DefaultTask {

   private File dml, dsl;


   @Option(option = "dml", description = "The VO-DML input file")
   public void setDml(String dml) {
       this.dml = new File(getProject().getProjectDir(), dml);
       getLogger().info("transforming {} {}", this.dml.getAbsolutePath(), this.dml.exists()
       );
   }

   @Option(option = "dsl", description = "The VODSL output file")
   public void setDsl(String dsl){
      this.dsl =  new File(getProject().getProjectDir(), dsl);
   }


   @TaskAction
   void doVodmlToVodsl(){
       Vodml2Vodsl.INSTANCE.doTransform(dml, dsl);
   }
}