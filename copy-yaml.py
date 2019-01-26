import sys

def createYaml(roleArn):
    inputData = """\
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: %s
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes""" % roleArn

    yamlFile = open("aws-auth-cm.yaml", "w")
    yamlFile.write(inputData)
    yamlFile.close()

if (len(sys.argv) > 1 ):
    outYaml = sys.argv[1]
    createYaml(outYaml)
else:
    print("No argument passed.")
    createYaml("null")     

