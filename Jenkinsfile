pipeline {
    agent any

    environment {
        BROWSER = 'chrome'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/JamilaTak/pfb-homey-automation.git',
                    branch: 'main'
            }
        }

        stage('Install dependencies') {
            steps {
                bat 'pip install -r requirements.txt'
            }
        }

        stage('Run Tests') {
            steps {
                bat 'robot --outputdir results tests/'
            }
            post {
                always {
                    robot outputPath: 'results'
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'results/*.html, results/*.csv, results/*.xml', allowEmptyArchive: true
        }
    }
}
