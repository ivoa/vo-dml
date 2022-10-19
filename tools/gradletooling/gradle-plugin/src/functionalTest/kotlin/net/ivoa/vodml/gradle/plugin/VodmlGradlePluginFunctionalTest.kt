package net.ivoa.vodml.gradle.plugin

import java.io.File
import org.gradle.testkit.runner.GradleRunner
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * A simple functional test for the 'net.ivoa.vodml.plugin' plugin.
 */
class VodmlGradlePluginFunctionalTest {
    @Test fun `can run task`() {
        // Setup the test build
        val projectDir = File("build/functionalTest")
        projectDir.mkdirs()
        projectDir.resolve("settings.gradle").writeText("")
        projectDir.resolve("build.gradle").writeText("""
            plugins {
                id('net.ivoa.vo-dml.vodmltools"')
            }
        """)

        // Run the build
        val runner = GradleRunner.create()
        runner.forwardOutput()
        runner.withPluginClasspath()
        runner.withArguments("greeting")
        runner.withProjectDir(projectDir)
        val result = runner.build()

        // Verify the result
        assertTrue(result.output.contains("Hello from plugin 'vodml'"))
    }
}
