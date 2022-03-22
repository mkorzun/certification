pipeline {
    environment {
        AWS_ACCESS_KEY_ID     = credentials('jenkins-aws-secret-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws-secret-access-key')
        docker_hub_login = credentials('docker_hub_login')
        docker_hub_password = credentials('docker_hub_password')
    }

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        string(name: 'version', defaultValue: '', description: 'Assign a version')
    }

    agent  any
        options {
                timestamps ()
            }
    stages {
        stage('Copy source with configs') {
            steps {
                git 'https://github.com/snuffles765/certification.git'
            }
        }

        stage('TF Init&Plan Build instance') {
            steps {
                dir('build/terraform') {
                  sh 'terraform init -input=false'
                  sh 'terraform plan -input=false -out tfplan'
                  sh 'terraform show -no-color tfplan > tfplan.txt'
                }
            }
        }

        stage('Approval? (build)') {
           when {
               not {
                   equals expected: true, actual: params.autoApprov
               }
           }

            steps {
                script {
                    def plan = readFile 'build/terraform/tfplan.txt'
                    input message: "Do you want to apply the plan?",
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
               }
           }
        }

        stage('TF Apply Build instance') {
            steps {
                dir('build/terraform') {
                  sh 'terraform apply -input=false tfplan'
                }
            }
        }

        stage('TF Init&Plan Stage instance') {
            steps {
                dir('stage/terraform') {
                  sh 'terraform init -input=false'
                  sh 'terraform plan -input=false -out tfplan'
                  sh 'terraform show -no-color tfplan > tfplan.txt'
                }
            }
        }

        stage('Approval? (stage)') {
           when {
               not {
                   equals expected: true, actual: params.autoApprov
               }
           }

            steps {
                script {
                    def plan = readFile 'stage/terraform/tfplan.txt'
                    input message: "Do you want to apply the plan?",
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
               }
           }
        }

        stage('TF Apply Stage instance') {
            steps {
                dir('stage/terraform') {
                  sh 'terraform apply -input=false tfplan'
                }
            }
        }

        stage ('Waiting for ssh connection..') {
            steps {
                sh 'ansible-playbook global/ansible/wait_aws_infrastructure.yml -i build/terraform/inventory.yaml -i stage/terraform/inventory.yaml'
            }
        }

        stage('Ansible Deploy in Build ') {

            steps {
                sh 'ansible-playbook build/ansible/main.yml -i build/terraform/inventory.yaml -e docker_hub_login=${docker_hub_login} -e docker_hub_password=${docker_hub_password} -e version=${version}'
            }
        }
        stage('Ansible Deploy in Stage ') {

            steps {
                sh 'ansible-playbook stage/ansible/main.yml -i stage/terraform/inventory.yaml -e docker_hub_login=${docker_hub_login} -e docker_hub_password=${docker_hub_password} -e version=${version}'
            }
        }
    }
}


