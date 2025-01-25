import json
import copy
import os

from datetime import datetime
from pathlib import Path

today = datetime.today()
formatted_date = today.strftime("%y.%m.%d")

def merge_swagger_files(file_paths, output_path, title, endpoint=None):
    """
    Merge multiple swagger.json files into a single swagger.json file.

    Args:
        file_paths (list): List of file paths to swagger.json files to merge.
        output_path (str): Path to save the merged swagger.json file.
    """
    merged_swagger = {
        "swagger": "2.0",  # Update this to "openapi" if using OpenAPI 3.x
        "info": {
            "title": f"%s API" % title,
            "version": formatted_date,
        },
        "schemes": [
            "http",
            "https"
        ],
        "securityDefinitions": {
            "X-Auth-Token": {
                "type": "apiKey",
                "name": "X-Auth-Token",
                "in": "header",
                "description": "Enter the OpenStack token in the X-Auth-Token header."
            }
          },
          "security": [
                {
                    "X-Auth-Token": []
                }
          ],
        "paths": {},
        "definitions": {},  # For OpenAPI 3.x, replace with `components`
    }

    for file_path in file_paths:
        with open(file_path, 'r') as file:
            swagger = json.load(file)
            # Merge paths
            for path, methods in swagger.get("paths", {}).items():
                if path not in merged_swagger["paths"]:
                    merged_swagger["paths"][path] = methods
                else:
                    for method, details in methods.items():
                        if method not in merged_swagger["paths"][path]:
                            merged_swagger["paths"][path][method] = details

            # Merge definitions (or components in OpenAPI 3.x)
            for definition, schema in swagger.get("definitions", {}).items():
                if definition not in merged_swagger["definitions"]:
                    merged_swagger["definitions"][definition] = schema
                else:
                    print(f"Conflict: Definition {definition} already exists. Skipping.")

    # Save merged Swagger file
    with open(output_path, 'w') as output_file:
        json.dump(merged_swagger, output_file, indent=2)

    print(f"Merged swagger.json saved to {output_path}")

def make_merge(proto_path, output_path, endpoint):
    # List all swagger directories
    directories = [entry for entry in Path(proto_path).iterdir() if entry.is_dir()]

    if not os.path.exists(output_path):
        os.makedirs(output_path)  # Creates the directory (including intermediate directories if needed)
        print(f"Directory created: {output_path}")
    else:
        print(f"Directory already exists: {output_path}")

    # for ENV URLS in Dockerfile
    output = ''
    for directory in directories:
        files = [entry for entry in Path(directory).iterdir() if entry.is_file()]
        directory_name = Path(directory).name
        merge_swagger_files(files, f"%s/%s.json" % (output_path, directory_name), directory_name, endpoint)
        output = output + f'{{"url": "./ktcloud/%s.json", "name": "%s"}},' % (directory_name, directory_name)
    return output

def make_dockerfile(output_path, env):
    """
    Creates a Dockerfile for Swagger UI.
    
    Args:
        output_path (str): Path to the directory where the Dockerfile should be created.
    """
    # Ensure the output directory exists
    if not os.path.exists(output_path):
        os.makedirs(output_path)
        print(f"Created directory: {output_path}")
    else:
        print(f"Directory already exists: {output_path}")
    
    # Define the Dockerfile content
    dockerfile_content = f"""\
# Base image
FROM swaggerapi/swagger-ui:latest

# Set working directory
RUN mkdir -p /usr/share/nginx/html/ktcloud/

# Copy application code
COPY ./*.json /usr/share/nginx/html/ktcloud/

ENV URLS='[%s]'

""" % env

    # Write the Dockerfile
    dockerfile_path = os.path.join(output_path, "Dockerfile")
    with open(dockerfile_path, "w") as dockerfile:
        dockerfile.write(dockerfile_content)
    
    print(f"Dockerfile created at: {dockerfile_path}")

if __name__ == "__main__":
    # export ENDPOINT=http://127.0.0.1 (KONG gateway address)
    endpoint = os.environ.get("ENDPOINT", None)
    output_dir = "/opt/dist/swagger"
    #env = make_merge("./dist/openapi/ktcloud/api", output_dir,  endpoint)
    env = make_merge("/opt/dist/openapi/ktcloud/api", output_dir,  endpoint)
    make_dockerfile(output_dir, env)
