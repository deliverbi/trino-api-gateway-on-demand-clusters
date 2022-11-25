# Creating a Basic Trino Service to Start On Demand Clusters for ADHOC Large ETL Jobs on GCP Google Cloud Platform using Python Flask.
Creating a Basic Trino Service to Start On Demand Clusters for ADHOC Large ETL Jobs on GCP Google Cloud Platform using Python Flask.


Creating a Basic Trino Service to Start On Demand Clusters for ADHOC Large ETL Jobs on GCP Google Cloud Platform using Python Flask.


We were working on a client site where a customer of ours wanted to have a set of trino clusters that would be used for specific high memory ETL/ ELT jobs. They wanted to send a signal to a http server and in the background it will start a Trino Cluster up. The main purpose is to overcome the static user query memory limits on a static cluster that is being used 24x7.

 

The Main components required from the GCP side are as follows.
1.	Trino Master Machine VM
2.	Dynamic Instance Group that can be scaled with a trino worker image. (You can contact DELIVERBI for this if not already in place.

So lets Assume you have a cluster that can Start and Stop from a command line. Our cluster we can start and stop as-well as state the number of workers we require at any time with graceful shutdowns and quick startups.

Lets Have a look at the Service itself . Very basic idea but works a treat. They can invoke the starting and stopping from any ETL or Orchestration tool such as Apache Airflow.

Lets put together a small vm with the following components

#Installations required
apt get-install python3-pip
apt-get install jq
pip3 install --upgrade pip
pip3 install flask flask_shell2http
pip3 install waitress


Shell script to START a server

trino-start-cluster , trino-stop-cluser these can be found under files here.

Now lets move onto creating a small python flask program. Nothing difficult , This will execute shell scripts as per the URL we use . Lets call it trino_app.py

````
```
from flask import Flask
from flask_executor import Executor
from flask_shell2http import Shell2HTTP

# Flask application instance
app = Flask(__name__)

executor = Executor(app)
shell2http = Shell2HTTP(app=app, executor=executor, base_url_prefix="/commands/")

def my_callback_fn(context, future):
  # optional user-defined callback function
  print(context, future.result())
  return  

#shell2http.register_command(endpoint="saythis", command_name="echo", callback_fn=my_callback_fn, decorators=[])
shell2http.register_command(endpoint="m1start", command_name="bash /trinoapp/trino-start-cluster.sh 1 5", callback_fn=my_callback_fn, decorators=[])
shell2http.register_command(endpoint="m1stop", command_name="bash /trinoapp/trino-stop-cluster.sh 1 5", callback_fn=my_callback_fn, decorators=[])
shell2http.register_command(endpoint="m2start", command_name="bash /trinoapp/trino-start-cluster.sh 2 3", callback_fn=my_callback_fn, decorators=[])
shell2http.register_command(endpoint="m2stop", command_name="bash /trinoapp/trino-stop-cluster.sh 2 3", callback_fn=my_callback_fn, decorators=[])
```
````

Start the Webserver to host the flask script. Create a script called : run_trino_app.sh
````
```
#!/bin/bash
cd "$(dirname "$0")"
/usr/local/bin/waitress-serve --port=5000 trino_app:app
```
````

We can setup a systemd service for this so it will be easier to start and stop the flask application.

````
```
# /etc/systemd/system/trino_app.service
[Unit]
Description=My Trino API APP
After=network.target

[Service]
Type=simple
User=nanodano
WorkingDirectory=/root/trinoapp
ExecStart=/root/trinoapp/run_trino_app.sh
Restart=always

[Install]
WantedBy=multi-user.target

```
````

#Start and Stop the Trino App - Background process is waitress.
systemctl start trino_app
systemctl stop trino_app
systemctl status trino_app


Check Service is up and you can invoke a cluster manually here are some sample commands. Here is a start command – just use m1stop to stop once or whatever you have used for your url path.

#Make a Call - initiate shell script.

````
```
curl -X POST http://ip:5000/commands/m1start

#Check Result - You cant make another call to same api unless result comes back.Use the key from the above call

curl http://ip:5000/commands/m1stop?key=864d8355
```
````


The the main server for taking the incoming http api calls is all done above.

Now lets move onto the client side or airflow. We want the the call to the API to hold whilst the server is coming up as a first step in the ETL process. 
So for this we introduced a client side script. This will wait until the Trino Cluster is fully up and then the ETL process can begin Once the ETL process has completed as a last step we can invoke the cluster to be shutdown.


The following Shell script can be run on the client side airflow server or orchestration server.
````
```

#for shell program apt-get install jq -- client side
#------------------------Shell program to loop
v_url=$1

#m1stop m1start m2start m2stop etc

key_id=`curl -X POST http://DELIVERBI-trino-analyzer:5000/commands/$v_url | jq -r '.key'`

#echo "$key_id" > key.name

while true ; do

#key_value=`cat ~/key.name`

#echo "$key_value"

isnodeactive=`curl -s http://DELIVERBI-trino-analyzer:5000/commands/$v_url?key=$key_id`

#echo "Curl Response is : $isnodeactive"

#If response is null then shut it down as systemctl service has been shutdown completely
#string='$isnodeactive'
if [[ $isnodeactive == *"running"* ]]; then
  echo "Running $key_id"
  sleep 10s
elif [ $isnodeactive == *"ServerUP"* ] || [ $isnodeactive == *"ServerDOWN"* ]; then
  echo "Complete $key_id"
  break
else echo "ERROR"
break
fi
 
done

```
````
