pipeline {
    agent any

    environment {
        PROJECT_NAME = "Practica-CI-CD"
    }

    stages {

        stage('Inicio') {
            steps {
                echo "Iniciando pipeline de ${PROJECT_NAME}"
            }
        }
        stage('Clonar repositorio') {
            steps {
                checkout scm
            }
        }

        stage('Mostrar informacion') {
            steps {
                sh 'echo "Usuario actual:"'
                sh 'whoami'

                sh 'echo "Contenido del directorio:"'
                sh 'ls -la'
            }
        }

        stage('Compilacion') {
            steps {
                echo 'Compilando proyecto...'
                sh 'echo "Compilacion completada correctamente"'
            }
        }

        stage('Tests') {
            steps {
                echo 'Ejecutando tests...'
                sh 'echo "Tests ejecutados correctamente"'
            }
        }

        stage('Despliegue') {
            steps {
                echo 'Simulando despliegue...'
                sh 'echo "Despliegue completado"'
            }
        }
    }

    post {

        success {
            echo 'Pipeline ejecutado correctamente'
        }

        failure {
            echo 'El pipeline ha fallado'
        }

        always {
            echo 'Fin de la ejecucion del pipeline'
        }
    }
}