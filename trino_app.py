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
