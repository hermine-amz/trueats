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
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val proj = this
    val configureSubproject = {
        val android = proj.extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val currentNamespace = getNamespace.invoke(android)
                if (currentNamespace == null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    val fallbackNamespace = "com.example.${proj.name.replace('-', '_').replace('.', '_')}"
                    setNamespace.invoke(android, fallbackNamespace)
                    println("Dynamically set namespace to $fallbackNamespace for subproject ${proj.name}")
                }
            } catch (e: Exception) {
                // Ignore
            }

            try {
                val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                val setSource = compileOptions.javaClass.methods.firstOrNull { it.name == "setSourceCompatibility" && it.parameterCount == 1 }
                val setTarget = compileOptions.javaClass.methods.firstOrNull { it.name == "setTargetCompatibility" && it.parameterCount == 1 }
                setSource?.invoke(compileOptions, org.gradle.api.JavaVersion.VERSION_11)
                setTarget?.invoke(compileOptions, org.gradle.api.JavaVersion.VERSION_11)
                println("Dynamically set Java compatibility to 11 for subproject ${proj.name}")
            } catch (e: Exception) {
                // Ignore
            }

            try {
                val kotlinOptions = android.javaClass.getMethod("getKotlinOptions").invoke(android)
                val setJvm = kotlinOptions.javaClass.methods.firstOrNull { it.name == "setJvmTarget" && it.parameterCount == 1 }
                setJvm?.invoke(kotlinOptions, "11")
                println("Dynamically set Kotlin JVM target to 11 for subproject ${proj.name}")
            } catch (e: Exception) {
                // Ignore
            }
        }
        
        proj.tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "11"
            targetCompatibility = "11"
        }

        proj.tasks.configureEach {
            val taskName = this.name
            val className = this.javaClass.name
            if (className.contains("KotlinCompile") || className.contains("KotlinJvmCompile") || className.contains("Kotlin2JsCompile")) {
                try {
                    val kotlinOptions = this.javaClass.getMethod("getKotlinOptions").invoke(this)
                    val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                    setJvmTarget.invoke(kotlinOptions, "11")
                    println("Dynamically set Kotlin JVM target to 11 for task $taskName in subproject ${proj.name}")
                } catch (e: Exception) {
                    try {
                        val compilerOptions = this.javaClass.getMethod("getCompilerOptions").invoke(this)
                        val jvmTargetProp = compilerOptions.javaClass.getMethod("getJvmTarget").invoke(compilerOptions)
                        val jvmTargetClass = Class.forName("org.jetbrains.kotlin.gradle.dsl.JvmTarget")
                        val jvm11 = jvmTargetClass.getField("JVM_11").get(null)
                        val setMethod = jvmTargetProp.javaClass.getMethod("set", Object::class.java)
                        setMethod.invoke(jvmTargetProp, jvm11)
                        println("Dynamically set Kotlin compilerOptions JVM target to 11 for task $taskName in subproject ${proj.name}")
                    } catch (ex: Exception) {
                        // Ignore
                    }
                }
            }
        }
    }

    if (proj.state.executed) {
        configureSubproject()
    } else {
        proj.afterEvaluate {
            configureSubproject()
        }
    }
}





tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
