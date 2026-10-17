buildscript {
    println("Tasks=${gradle.startParameter.taskNames}")
}

plugins {
    alias(libs.plugins.reproducible.builds)
}

val javaCompilerArgs = listOf("-Xlint:unchecked", "-Xlint:deprecation")
allprojects {
    apply(plugin = "org.gradlex.reproducible-builds")

    gradle.projectsEvaluated {
        println("Configure $project JavaCompile tasks with compilerArgs=$javaCompilerArgs")
        tasks.withType<JavaCompile> {
            options.compilerArgs.addAll(javaCompilerArgs)
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
