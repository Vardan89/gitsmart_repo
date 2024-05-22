pipeline {
	agent {label "linux"}
	options {
      		buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '5', days
ToKeepStr: '', numToKeepStr: '5')
	disableConcurrentBuilds()
	}
	stages {
		stage('Hello'){
			steps {
				echo "hello"
			}
		}
	}
}
