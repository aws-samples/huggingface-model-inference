### Instructions to build the the Huggingface model inference container with Neuron SDK

#### Step1: Launch an EC2 instance to build and run the container:

Launch https://console.aws.amazon.com/ec2/v2/home
Select "Launch instance"

In "Choose an Amazon Machine Image (AMI) - search for DLAMI

Select images "in AWS Marketplace"

Select AWS Deep Learning AMI (Amazon Linux 2)

In "Choose an instance type" choose "inf1.2xlarge" and select "Review and Launch" and then "Launch" to launch the instance

It may take 2-10 mins for instance to launch. once instance in is in "Running" state follow the instructions in Connect to your instance to connect to the instance

#### Step2:

Download and unzip file with contents to local folder (e.g. "Huggingface_Transformers")


#### Step 3:

Open dockerfile, edit and replace code as below

1: replace <model_store> - with location of model_store folder (e.g. ./model_store) in step 2
oftorchserve/model_store

2: replace <config.properties> with location of config.properties
from folder (e.g. ./) in step 2

3: replace dockerd-entrypoint.sh with location of dockerd-entrypoint.sh location from step 2 (./)

4: to build: docker

docker build . -f Dockerfile -t torch-neuron-rtd

Prior to running the container, make sure that the Neuron runtime on the instance is turned off, by running the command:
```
sudo service neuron-rtd stop
```

Docker Run :


```
docker run --device=/dev/neuron0 -p 8443:8443 -p 8081:8081 -p 8082:8082 --cap-add IPC_LOCK -it torch-neuron-rtd

```

Test torchserve health

```
curl http://127.0.0.1:8443/ping
```

Output should be "Healthy"

```
{
  "status": "Healthy"
}
```

Load model

```
MAX_LENGTH=$(jq '.max_length' config.json)

BATCH_SIZE=$(jq '.batch_size' config.json)

MODEL_NAME=bert-max_length$MAX_LENGTH-batch_size$BATCH_SIZE

MAX_BATCH_DELAY=5000 # ms timeout before a partial batch is processed

INITIAL_WORKERS=4 # number of models that will be loaded at launch

curl -X POST "http://127.0.0.1:8081/models?url=$MODEL_NAME.mar&batch_size=$BATCH_SIZE&initial_workers=$INITIAL_WORKERS&max_batch_delay=$MAX_BATCH_DELAY"

```
output will be similar to below

```
{
  "status": "Model \"bert-max_length128-batch_size6\" Version: 1.0 registered with 4 initial workers"
}

```
Test inference using infer_bert.py included in the zip
```
python3 infer_bert.py

```
Output :

```
0 ['paraphrase']
2 ['paraphrase']
3 ['not paraphrase']
5 ['not paraphrase']
4 ['not paraphrase']
1 ['paraphrase']
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

