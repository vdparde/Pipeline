def app
def docker_repo_url = 'docker-repo.skillnetinc.com:8502'
def docker_repo_cred = 'docker.skillnet'
def docker_image_name = 'xstore_base_linux'
def xstore_container_name = "anode-1"
def db_container_name = "anode-db-1"
def project_name = "XSTORE-BASE"
def project_env = "DEV"
def xunit_tags = "XUNITDEMO"
def docker_file_directory = '/home/docker/docker'
def xcenter_container_name = "xcenter-node-1"
def docker_xcenterrepo_url = 'docker-repo.skillnetinc.com:8504'
def docker_xcenterimage_name = 'xcenterfull'
def xcenterip = "xcenter.host "


pipeline {

    agent {
        label 'master'
    }


    stages {
        
        stage('Copy Installers') {
            steps {
        		checkout scm
                copyArtifacts filter: 'workspace/distro-full/OracleRetailXstorePointofService*.zip', fingerprintArtifacts: true, flatten: true, projectName: 'OMC_V16_Test', selector: lastSuccessful(), target: ''
             }
            when {
                expression {
                    return "${params.PIPELINE_ACTIVITY}" == 'deploy';
                }
            }
        }
        
        stage('Build-Push Docker Image') {
            steps {
        		
        		withEnv(["docker_file_directory=$docker_file_directory","docker_xcenterrepo_url=$docker_xcenterrepo_url","docker_xcenterimage_name=$docker_xcenterimage_name","xcenter_container_name=$xcenter_container_name","xstore_container_name=$xstore_container_name","db_container_name=$db_container_name","docker_repo_url=$docker_repo_url","docker_image_name=$docker_image_name","project_name=$project_name","project_env=$project_env","xunit_tags=$xunit_tags"]) {
		      	sh '''
						DOCKERFILE_DIR=$docker_file_directory
						BASEDIR=$(pwd)
						XSTORE_CONTAINER_NAME=$xstore_container_name
						XCENTER_CONTAINER_NAME=$xcenter_container_name
						
						DB_CONTAINER_NAME=$db_container_name
						
						mv OracleRetailXstorePointofService*.zip xstore.zip 
						rm -rf $BASEDIR/ant.install.properties.mssql
						cp $DOCKERFILE_DIR/ant.install.properties.mssql $BASEDIR/ant.install.properties.mssql
						rm -rf $BASEDIR/xunit.properties
						cp $DOCKERFILE_DIR/xunit.properties $BASEDIR/xunit.properties
						rm -rf ModifedDatabaseScripts
						cp -R $DOCKERFILE_DIR/ModifedDatabaseScripts $BASEDIR/ModifedDatabaseScripts
						
						PRE_CLUSTER_IP=$(cat ant.install.properties.mssql | grep -oh 192.168.* | tail -1)
						PRE_XCENTER_IP=$xcenterip					
						
						
						echo "#########################Starting Kube-xstore process#######################"
						echo "########## Clean Up: Removing existing Kube PODS ###########################"
						
						kubectl delete deployments/$XCENTER_CONTAINER_NAME --ignore-not-found
						kubectl delete services/$XCENTER_CONTAINER_NAME --ignore-not-found
						kubectl delete deployments/$XSTORE_CONTAINER_NAME --ignore-not-found
						kubectl delete deployments/$DB_CONTAINER_NAME --ignore-not-found
						kubectl delete services/$DB_CONTAINER_NAME --ignore-not-found
						sleep 60
						
						
						echo "########## Starting xcenter container with name:$XCENTER_CONTAINER_NAME ##############"
						kubectl run $XCENTER_CONTAINER_NAME --image=$docker_xcenterrepo_url/$docker_xcenterimage_name:latest --image-pull-policy=Always 
						kubectl expose deployment $XCENTER_CONTAINER_NAME --type=NodePort --name=$XCENTER_CONTAINER_NAME --port=80 --target-port=8443                     
						
						echo "########## Checking xcenter POD status ###########################"
						XCENTER_POD_STATUS=""
						while [ "$XCENTER_POD_STATUS" != "Running" ]
						do
						  XCENTER_POD_STATUS=$(kubectl get pod -l run=$XCENTER_CONTAINER_NAME -o jsonpath="{.items[0].status.phase}")
						  echo "Current Status:"$XCENTER_POD_STATUS
							sleep 5
						done
						echo "########## Xcenter container is running, trying to get cluster IP for xcenter image"
						XCENTER_CLUSTER_IP=$(kubectl get services -l run=$XCENTER_CONTAINER_NAME -o jsonpath="{.items[0].spec.clusterIP}")
						echo "########## Found cluster IP: $XCENTER_CLUSTER_IP #############"						
						echo "########## Updating Xcenter Cluster IP to installer files"
						sed -i "s/$PRE_XCENTER_IP/$XCENTER_CLUSTER_IP/g" ant.install.properties.mssql	
						
						
						
						echo "########## Starting Database container with name:$DB_CONTAINER_NAME ##############"
						kubectl run $DB_CONTAINER_NAME --image=microsoft/mssql-server-linux:latest --image-pull-policy=IfNotPresent --env=\'SA_PASSWORD=$Killnet123\' --env="ACCEPT_EULA=Y"
						kubectl expose deployment $DB_CONTAINER_NAME --type=NodePort --name=$DB_CONTAINER_NAME --port=1433 --target-port=1433                     
						
						echo "########## Checking db POD status ###########################"
						DB_POD_STATUS=""
						while [ "$DB_POD_STATUS" != "Running" ]
						do
						  DB_POD_STATUS=$(kubectl get pod -l run=$DB_CONTAINER_NAME -o jsonpath="{.items[0].status.phase}")
						  echo "Current Status:"$DB_POD_STATUS
							sleep 5
						done
						echo "########## Database container is running, trying to get cluster IP"
						CLUSTER_IP=$(kubectl get services -l run=$DB_CONTAINER_NAME -o jsonpath="{.items[0].spec.clusterIP}")
						echo "########## Found cluster IP: $CLUSTER_IP #############"
						
						echo "########## Updating Cluster IP to installer files"
						sed -i "s/$PRE_CLUSTER_IP/$CLUSTER_IP/g" ModifedDatabaseScripts/mssql/make-database.sh
						sed -i "s/$PRE_CLUSTER_IP/$CLUSTER_IP/g" ant.install.properties.mssql
						
						echo "########## Creating temp directory for installer files"
						TDIR=$BASEDIR/installertmp
						mkdir -p $TDIR && rm -rf xstore-mssqlserver.tar
						echo "########## Inflating installer ####################"
						unzip -o $BASEDIR/xstore.zip -d $TDIR
						cd $TDIR
						POSDIR=$(dirname "$(find $(pwd) -type d -name *pos*)")
						echo "########## Going to $POSDIR####################"
						cd $POSDIR
						rm -rf resources && mkdir -p resources/db/mssql
						cp $BASEDIR/ModifedDatabaseScripts/mssql/make-database.sh resources/db/mssql
						cp $BASEDIR/ModifedDatabaseScripts/mssql/db-update.sql resources/db/mssql
						zip pos/**install.jar -r resources
						cp $DOCKERFILE_DIR/xstore.install.properties xstore.install.properties
						zip -u pos/**install.jar xstore.install.properties
						rm -rf xstore.install.properties
						tar -cvf $BASEDIR/xstore-mssqlserver.tar pos/
						cd $BASEDIR
						rm -rf $TDIR
						
							
		       		'''
       			}
       		
			 script {
           			 app = docker.build("${docker_image_name}")

           			 docker.withRegistry("https://${docker_repo_url}", "${docker_repo_cred}") {
               		 app.push("${env.BUILD_NUMBER}")
                	 app.push("latest")
            	     }
       		     }
             }
            when {
                expression {
                    return "${params.PIPELINE_ACTIVITY}" == 'deploy';
                }
            }
        }
 		stage('Deploy On Kubernetes') {
            steps {
        		withEnv(["docker_file_directory=$docker_file_directory","xstore_container_name=$xstore_container_name","docker_repo_url=$docker_repo_url","docker_image_name=$docker_image_name","project_name=$project_name","project_env=$project_env","xunit_tags=$xunit_tags"]) {
			   
			   /*
			    run without nfs echo exit | kubectl run -it $xstore_container_name --image=$docker_repo_url/$docker_image_name:latest --image-pull-policy=Always --env=\"JAVA_HOME=/usr/orps/java/jdk1.8.0_144\" --env=\"DISPLAY=:1\" -- /bin/bash
			   */
			    sh '''
						echo "########## Staring XStore Container: $xstore_container_name ##############################"
						
						echo exit | kubectl run -it $xstore_container_name --overrides='{"kind":"Deployment","apiVersion":"extensions/v1beta1","spec":{"template":{"spec":{"containers":[{"name": "anode-1","image": "'"$docker_repo_url/$docker_image_name:latest"'","args":["/bin/bash"],"stdin":true,"tty": true,"volumeMounts":[{"mountPath":"/home/store","name":"store"}]}],"volumes":[{"name":"store","nfs":{"server":"192.168.2.112","path":"/home/oracle/basetestcases"}}]}}}}' --image=$docker_repo_url/$docker_image_name:latest --image-pull-policy=Always --env="JAVA_HOME=/usr/orps/java/jdk1.8.0_144" --env="DISPLAY=:1" -- /bin/bash
						
						sleep 10
				'''
	
	   			 }
 		
             }
            when {
                expression {
                    return "${params.PIPELINE_ACTIVITY}" == 'deploy';
                }
            }
        }
        stage('Dev Test On Kubernetes') {
            steps {
        		withEnv(["docker_file_directory=$docker_file_directory","xstore_container_name=$xstore_container_name","docker_repo_url=$docker_repo_url","docker_image_name=$docker_image_name","project_name=$project_name","project_env=$project_env","xunit_tags=$xunit_tags"]) {
				  
				  /*
				  echo "########## Copy test cases"
							echo h|kubectl cp $docker_file_directory/test $POD:/home/oracle/xstore/config/
							echo "########## Copy encryption keys"
							echo h|kubectl cp $docker_file_directory/keys $POD:/home/oracle/xstore/res/
							echo "########## Copy query config"
							echo h|kubectl cp $docker_file_directory/query $POD:/home/oracle/xstore/config/test/
							
							we chose nfs to put required files into container and not the kubectl cp command, because cp command sometimes freezes, defect has been opened on account of same(https://github.com/kubernetes/kubernetes/issues/61589), until the fix is available we can use this method.
							
				  */
				    sh '''
							XSTORE_POD_STATUS=""
							echo "Wait until POD status is: Running"
							while [ "$XSTORE_POD_STATUS" != "Running" ]
							do
						  		XSTORE_POD_STATUS=$(kubectl get pod -l run=$xstore_container_name -o jsonpath="{.items[0].status.phase}")
						  		echo "Current XStore POD Status:"$XSTORE_POD_STATUS
								sleep 5
							done
							echo "########## XStore kube container is running now, copying required files##############################"
							POD=$(kubectl get pod -l run=$xstore_container_name -o jsonpath="{.items[0].metadata.name}")
							echo "########## XStore POD NAME:$POD#####################"
							sleep 5
							POD=$(kubectl get pod -l run=$xstore_container_name -o jsonpath="{.items[0].metadata.name}")
							
							echo "######### Copying required files #################"
							kubectl exec $POD -- /bin/bash -c "mkdir -p  /home/oracle/xstore/config/test && mkdir -p  /home/oracle/xstore/config/dtv/res/config && cp -rf /home/store/test /home/oracle/xstore/config"
							kubectl exec $POD -- /bin/bash -c "cp -rf /home/store/keys /home/oracle/xstore/res/"
					        kubectl exec $POD -- /bin/bash -c "cp -rf /home/store/query /home/oracle/xstore/config/test/query"
					        kubectl exec $POD -- /bin/bash -c "cp -rf /home/store/DtxReplicationConfig.xml /home/oracle/xstore/config/dtv/res/config/DtxReplicationConfig.xml"
							
							
							
							echo "########## Removing vncserver lock files"
							kubectl exec $POD -- /bin/bash -c "vncserver -kill :1 | :"
							kubectl exec $POD -- /bin/bash -c "rm -rf /tmp/.X11-unix | :"
							kubectl exec $POD -- /bin/bash -c "find /tmp -type f -name .*X*lock -exec rm -rf {} \\; | :"
							
							kubectl exec $POD -- /bin/bash -c "vncserver" 
							echo "########## Starting xunit #################"
							kubectl exec $POD -- /bin/bash -c "export DISPLAY=:1 && export JAVA_HOME=/usr/orps/java/jdk1.8.0_144 && cd /home/oracle/Skillnet-XUnit && chmod +x xunit.sh && ./xunit.sh XFORE FORE XUNITDEMO"
							kubectl exec $POD -- /bin/bash -c "vncserver -kill :1 | :"
					'''
            	 }
           	
        	}
        	 
    	}
	}
    parameters {
        string(defaultValue: 'dev', description: '*Comma separated A) dev - Development environment </br> B) sit - SIT environment </br> C) uat - UAT environment', name: 'ENVIRONMENT')
        string(defaultValue: 'test', description: '*Comma separated A) deploy - Deploy & execute test cases </br> B) test - Do not deploy only execute test cases </br>this is applicable for all environment', name: 'PIPELINE_ACTIVITY')
        string(defaultValue: 'dhananjay.patade@skillnetinc.com', description: 'Email id of manager(s) who will approve pipeline stages (Comma separated values)', name: 'MANAGER_EMAIL_ID')
        string(defaultValue: '33', description: 'Build no of XStore installer to be installed', name: 'XSTORE_BUILD_NUMBER')
        string(defaultValue: '192.168.2.83', description: 'IP of puppet master', name: 'PUPPET_MASTER_IP')
        string(defaultValue: 'XUNITDEMO', description: 'XUNIT tags to be tested', name: 'ENABLED_TAGS')
    }

}
