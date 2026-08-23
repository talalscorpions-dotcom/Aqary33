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
    implementation("org.codehaus.groovy:groovy:3.0.21")
    implementation("org.codehaus.groovy:groovy-xml:3.0.21")
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
