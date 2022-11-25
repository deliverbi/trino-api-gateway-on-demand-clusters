#!/bin/bash
cd "$(dirname "$0")"
/usr/local/bin/waitress-serve --port=5000 trino_app:app
