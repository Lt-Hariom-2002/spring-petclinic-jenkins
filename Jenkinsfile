pipeline {
    agent any
    
    tools {
        terraform 'terra'
        ansible 'ansible'
        maven 'maven'
    }

    environment {
        AWS_ACCESS_KEY = credentials('AWS_KEY')
        AWS_SECRET_KEY = credentials('AWS_SECRET')
        SSH_PRIVATE_KEY_PATH = "~/.ssh/mujahed.pem"
    }

    stages {

        stage('Clone App Repo') {
            steps {
                git branch: 'master', url: 'https://github.com/NEMCO-Projects/spring-petclinic-jenkins.git'
            }
        }

        stage('Provision Infrastructure with Terraform') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Generate Dynamic Ansible Inventory') {
            steps {
                script {
                    sh """
                        echo "[mysql_server]" > inventory
                        echo "\$(cd terraform && terraform output -raw mysql_server_ip) ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory

                        echo "[tomcat_server]" >> inventory
                        echo "\$(cd terraform && terraform output -raw tomcat_server_ip) ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory

                        echo "[maven_server]" >> inventory
                        echo "\$(cd terraform && terraform output -raw maven_server_ip) ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory
                    """
                }
            }
        }

        stage('Run Ansible Setup (Install Packages)') {
            steps {
                sh "ansible-playbook -i inventory setup.yml"
            }
        }

        stage('Update MySQL IP in application.properties') {
            steps {
                script {
                    def mysqlIp = sh(script: "cd terraform && terraform output -raw mysql_server_ip", returnStdout: true).trim()

                    sh """
                        sed -i 's|jdbc:mysql://youip/petclinic|jdbc:mysql://${mysqlIp}/petclinic|' spring-petclinic-jenkins/src/main/resources/application.properties
                    """
                }
            }
        }

        stage('Build WAR using Maven') {
            steps {
                dir('spring-petclinic-jenkins') {
                    sh "mvn clean package"
                }
            }
        }

        stage('Copy Jar to Tomcat Server') {
            steps {
                script {
                    def tomcatIp = sh(script: "cd terraform && terraform output -raw tomcat_server_ip", returnStdout: true).trim()

                    sh """
                        scp -i ${SSH_PRIVATE_KEY_PATH} -o StrictHostKeyChecking=no spring-petclinic-jenkins/target/*.jar ubuntu@${tomcatIp}:/home/ubuntu/app.war
                    """
                }
            }
        }

        stage('Deploy WAR on Tomcat Server') {
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
            echo "❌ Something failed. Please check the logs."
        }
    }
}
