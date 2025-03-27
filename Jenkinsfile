pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-registry.com'
        DOCKER_IMAGE = 'dbt-ui'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DBT_PROJECTS_DIR = 'pk'
        DOCKER_COMPOSE_FILE = 'docker-compose.yml'
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Checkout main repository
                checkout scm
                
                // The repository already contains the dbt projects in the pk directory
                // No need for additional checkouts
            }
        }
        
        stage('Merge dbt Manifests') {
            steps {
                script {
                    // Create a Python script to merge manifests
                    writeFile file: 'merge_manifests.py', text: '''
import json
import os
from pathlib import Path

def merge_manifests(projects_dir):
    merged_manifest = {
        "nodes": {},
        "sources": {},
        "metadata": {
            "project_name": "merged_projects",
            "version": "1.0.0"
        }
    }
    
    # Process each project
    for project_dir in os.listdir(projects_dir):
        manifest_path = os.path.join(projects_dir, project_dir, 'target', 'manifest.json')
        if os.path.exists(manifest_path):
            with open(manifest_path, 'r') as f:
                manifest = json.load(f)
                
                # Merge nodes
                for node_id, node in manifest.get('nodes', {}).items():
                    # Prefix node_id with project name to avoid conflicts
                    new_node_id = f"{project_dir}_{node_id}"
                    merged_manifest['nodes'][new_node_id] = node
                
                # Merge sources
                for source_id, source in manifest.get('sources', {}).items():
                    new_source_id = f"{project_dir}_{source_id}"
                    merged_manifest['sources'][new_source_id] = source
    
    # Save merged manifest
    output_dir = Path('merged_manifest')
    output_dir.mkdir(exist_ok=True)
    
    with open(output_dir / 'manifest.json', 'w') as f:
        json.dump(merged_manifest, f, indent=2)

if __name__ == "__main__":
    merge_manifests("pk")
'''
                    // Run the merge script
                    sh 'python merge_manifests.py'
                }
            }
        }
        
        stage('Build dbt Projects') {
            steps {
                dir('pk') {
                    // Build each dbt project
                    sh '''
                        for project in */dbt_project.yml; do
                            project_dir=$(dirname "$project")
                            cd "$project_dir"
                            dbt compile
                            dbt run
                            cd ..
                        done
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image
                    sh """
                        docker build -t ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    // Push to Docker registry
                    sh """
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
    }
    
    post {
        always {
            // Clean up workspace
            cleanWs()
        }
    }
} 