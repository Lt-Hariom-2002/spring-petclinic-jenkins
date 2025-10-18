pipeline {
    agent any
    
    tools {
        terraform 'ttff'
        ansible 'aann'
        maven 'mmvvnn'
    }

    environment {
        AWS_ACCESS_KEY = credentials('AWS_KEY')
        AWS_SECRET_KEY = credentials('AWS_SECRET')
        SSH_PRIVATE_KEY_PATH = "${WORKSPACE}/hariom.pem"
    }

    stages {

        stage('Clone App Repo') {
            steps {
                git branch: 'main', url: 'https://github.com/Lt-Hariom-2002/spring-petclinic-jenkins.git'
            }
        }

        stage('Prepare SSH Key') {
            steps {
                sh """
                    cp /var/lib/jenkins/.ssh/hariom.pem ${WORKSPACE}/hariom.pem
                    chmod 600 ${WORKSPACE}/hariom.pem
                """
            }
        }

        stage('Provision Infrastructure') {
            steps {
                sh """
                    terraform init
                    terraform apply -auto-approve \
                        -var AWS_ACCESS_KEY=${AWS_ACCESS_KEY} \
                        -var AWS_SECRET_KEY=${AWS_SECRET_KEY}
                """
            }
        }

        stage('Generate Dynamic Ansible Inventory') {
            steps {
                script {
                    def mysqlDns = sh(script: "terraform output -raw mysql_server_dns", returnStdout: true).trim()
                    def mavenDns = sh(script: "terraform output -raw maven_server_dns", returnStdout: true).trim()

                    writeFile file: 'inventory', text: """
[mysql_server]
${mysqlDns} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[maven_server]
${mavenDns} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
"""
                    sh "cat inventory"
                }
            }
        }

        stage('Run Ansible Setup') {
            steps {
                sh "ansible-playbook -i inventory setup.yml"
            }
        }

        stage('Update MySQL IP') {
            steps {
                script {
                    def mysqlIp = sh(script: "terraform output -raw mysql_server_ip", returnStdout: true).trim()
                    sh """
                        sed -i 's|jdbc:mysql://youip/petclinic|jdbc:mysql://${mysqlIp}/petclinic|' spring-petclinic-jenkins/src/main/resources/application.properties
                    """
                }
            }
        }

        stage('Build WAR') {
            steps {
                dir('spring-petclinic-jenkins') {
                    sh "mvn clean package -DskipTests"
                }
            }
        }

        stage('Copy WAR to Maven/App Server') {
            steps {
                script {
                    def appDns = sh(script: "terraform output -raw maven_server_dns", returnStdout: true).trim()
                    sh """
                        scp -i ${SSH_PRIVATE_KEY_PATH} -o StrictHostKeyChecking=no \
                        spring-petclinic-jenkins/target/*.war ubuntu@${appDns}:/home/ubuntu/app.war
                    """
                }
            }
        }

        stage('Deploy Application') {
            steps {
                sh "ansible-playbook -i inventory deploy.yml"
            }
        }
    }

    post {
        success {
            echo "✅ Application deployed successfully!"
        }
        failure {
            echo "❌ Deployment failed. Check logs!"
        }
    }
}
