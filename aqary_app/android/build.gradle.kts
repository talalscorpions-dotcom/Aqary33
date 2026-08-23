plugins {
    id("groovy")
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

dependencies {
    // Update Groovy to a version that includes groovy-xml and all required modules
    implementation("org.codehaus.groovy:groovy:4.0.21")
    implementation("org.codehaus.groovy:groovy-xml:4.0.21")
    // Ensure XML parsing support is available
    implementation("org.codehaus.groovy:groovy-all:4.0.21")
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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
