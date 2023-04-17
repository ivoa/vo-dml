package net.ivoa.vodml.gradle.plugin

import org.gradle.api.DefaultTask
import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.tasks.*
import javax.inject.Inject


/*
 * Created on 14/02/2022 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */
/**
 * Task to generate VO-DML from vodsl.
 */
open class VodslTask  @Inject constructor(@Internal protected val ao: ArchiveOperations) : DefaultTask() {
    @get:[InputDirectory PathSensitive(PathSensitivity.RELATIVE)] @Optional
    val vodslDir: DirectoryProperty = project.objects.directoryProperty()

    @get:InputFiles
    val vodslFiles: ConfigurableFileCollection = project.objects.fileCollection()

    @get:[OutputDirectory]
    val vodmlDir: DirectoryProperty = project.objects.directoryProperty()

    private val parser = net.ivoa.vodsl.standalone.ParserRunner()

    @TaskAction
    fun doVodslToVodml(){
        val eh = ExternalModelHelper(project, ao, logger)
        eh.convertExternalToVODSL()
        vodslFiles.forEach{
            logger.info("Generating VO-DML from vodsl ${ it.name } to ${vodmlDir.get().asFile.absolutePath}")
            parser.parse(arrayOf(it.absolutePath),vodmlDir.get().asFile.absolutePath)
        }

    }


}

