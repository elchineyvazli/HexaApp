allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val sharedBuildDirectory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.set(sharedBuildDirectory)

subprojects {
    project.layout.buildDirectory.set(
        sharedBuildDirectory.dir(project.name),
    )
}

subprojects {
    // Flutter pluginlerinin uygulama yapılandırmasını doğru sırada
    // görebilmesi için mevcut davranışı koruyoruz.
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}