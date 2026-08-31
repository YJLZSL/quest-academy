allprojects {
    repositories {
        google()
        mavenCentral()
    }
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
// 统一子模块 compileSdk：部分插件（如 flutter_native_splash）仍锁定 android-31，
// 而其依赖的 androidx 库要求 compileSdk >= 33，会导致构建失败。
// 这里统一提升到 36，与 Flutter 3.44 的 flutter.compileSdkVersion 对齐。
// 注意：必须注册在下面的 evaluationDependsOn 之前，否则子项目已被求值，
// afterEvaluate 会抛 "Cannot run Project.afterEvaluate ... already evaluated"。
subprojects {
    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt is com.android.build.gradle.BaseExtension) {
            androidExt.compileSdkVersion(36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
