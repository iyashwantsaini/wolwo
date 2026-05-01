allprojects {
    repositories {
        google()
        mavenCentral()
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

    // Workaround: async_wallpaper plugin ships a `wallpaper.xml` that
    // references `@mipmap/ic_launcher` from the host-app namespace, which
    // breaks the library's own `verifyReleaseResources` task even though
    // the resource resolves fine when the app is assembled. Skip the
    // library-level verification for that plugin only.
    afterEvaluate {
        if (project.name == "async_wallpaper") {
            project.tasks.matching { it.name == "verifyReleaseResources" }
                .configureEach { enabled = false }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
