package net.ivoa.vodml.gradle.plugin

import org.gradle.api.DefaultTask
import org.gradle.api.Project
import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.tasks.*
import java.io.File
import java.nio.file.Paths
import java.util.jar.JarInputStream


/*
 * Created on 21/10/2022 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */
/**
 * base classs with common properties.
 */
abstract class VodmlBaseTask(@Internal protected val ao: ArchiveOperations) : DefaultTask() {

    @get:[InputDirectory PathSensitive(PathSensitivity.RELATIVE)]
    val vodmlDir: DirectoryProperty = project.objects.directoryProperty()

    @get:InputFiles
    val vodmlFiles: ConfigurableFileCollection = project.objects.fileCollection()

    @get:InputFiles
    val bindingFiles: ConfigurableFileCollection = project.objects.fileCollection()

    @get:InputFile
    @Optional
    val catalogFile: RegularFileProperty = project.objects.fileProperty()


}

/**
 * Helper class to process information from external models.
 */
class ExternalModelHelper constructor (private val project: Project, private val ao: ArchiveOperations, private val logger:org.gradle.api.logging.Logger) {
    private val externalModelJars = project.configurations.getByName("runtimeClasspath").files.filter { f: File ->
        val js = JarInputStream(f.inputStream())
        (js.manifest.mainAttributes.getValue("VODML-binding")) != null //IMPL because of weird map of maps no contains
    }
    private val buildDir = project.layout.buildDirectory.asFile.get()

    init {
        logger.info("external models=${externalModelJars.joinToString { f -> f.name }}")
    }
    fun makeCatalog(vodmlFiles:ConfigurableFileCollection, catalogFile:RegularFileProperty): File {

        val tmpdir = project.mkdir(Paths.get(buildDir.absolutePath, "tmp"))
        val actualCatalog = if (catalogFile.isPresent) catalogFile.get().asFile
        else createCatalog(project.file(Paths.get(tmpdir.absolutePath, "catalog.xml")),
            vodmlFiles.files.plus(
                externalModelJars.flatMap { f ->
                    ao.zipTree(f).matching(org.gradle.api.tasks.util.PatternSet().include(vodmlFileName(f))).files
                }
            )
        )
        return  actualCatalog
    }

    fun convertExternalToVODSL()  {
        val tmpdir = project.mkdir(Paths.get(buildDir.absolutePath, "tmp"))
        val toConvert =  externalModelJars.flatMap { f ->
            ao.zipTree(f).matching(org.gradle.api.tasks.util.PatternSet().include(vodmlFileName(f))).files
        }
        toConvert.forEach{
            val outvodsl = project.file(Paths.get(tmpdir.absolutePath, it.name.replace(".vo-dml.xml", ".vodsl")))
            logger.info("writing VODSL for external model to ${outvodsl}")
            Vodml2Vodsl.doTransform(it, outvodsl)
        }
    }

    fun externalBinding(): List<File> {
        return externalModelJars.flatMap { f ->
            ao.zipTree(f).matching(org.gradle.api.tasks.util.PatternSet().include(bindingFileName(f))).files
        }
    }
    private val hasVodml = fun (f: File): Boolean {
        val js = JarInputStream(f.inputStream())
        return (js.manifest.mainAttributes.getValue("VODML-binding") ) != null //IMPL because of weird map of maps no contains
    }

    private val bindingFileName = fun (f: File): String {
        val js = JarInputStream(f.inputStream())
        return (js.manifest.mainAttributes.getValue("VODML-binding") )
    }
    private val vodmlFileName = fun (f: File): String {
        val js = JarInputStream(f.inputStream())
        return (js.manifest.mainAttributes.getValue("VODML-source") )
    }

    private fun createCatalog(cat : File, v: Iterable<File> ): File {
        cat.bufferedWriter().use { out ->
            out.write(
                """
                     <?xml version="1.0"?>
                     <catalog  xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog">
                        <group  prefer="system"  >
                        
                 """.trimIndent()
            )
            v.forEach {
                out.write("   <uri name=\"${it.name}\" uri=\"${it.toURI().toURL()}\"/>\n")
            }
            out.write(
                """
                        </group>
                     </catalog>
                 """.trimIndent()
            )
        }
        return cat;
    }
}