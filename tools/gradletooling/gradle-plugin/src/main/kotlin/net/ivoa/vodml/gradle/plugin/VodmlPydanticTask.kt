package net.ivoa.vodml.gradle.plugin

import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.tasks.*
import javax.inject.Inject


/**
 * Generates Pydantic model code from the VO-DML models.
 * Uses pydantic-xml for XML/JSON serialisation support.
 */
open class VodmlPydanticTask @Inject constructor(ao1: ArchiveOperations) : VodmlBaseTask(ao1) {

    @get:OutputDirectory
    val pythonGenDir: DirectoryProperty = project.objects.directoryProperty()

    @TaskAction
    fun doGeneration() {
        logger.info("Generating Pydantic for VO-DML files ${vodmlFiles.files.joinToString { it.name }}")
        logger.info("Looked in ${vodmlDir.get()}")
        val eh = ExternalModelHelper(project, ao, logger)
        val actualCatalog = eh.makeCatalog(vodmlFiles, catalogFile)

        val allBinding = bindingFiles.files.plus(eh.externalBinding())

        var index = 0
        vodmlFiles.forEach { v ->
            val shortname = v.nameWithoutExtension
            val outfile = pythonGenDir.file("$shortname.pydantictrans.txt")
            Vodml2Pydantic.doTransform(
                v.absoluteFile, mapOf(
                    "binding" to allBinding.joinToString(separator = ",") { it.toURI().toURL().toString() },
                    "output_root" to pythonGenDir.get().asFile.toURI().toURL().toString(),
                    "isMain" to (if (index++ == 0) "True" else "False")
                ),
                actualCatalog, outfile.get().asFile
            )
        }
    }
}
