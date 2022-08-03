#!/bin/sh

echo "Starting payments application"
java -jar /bin/spring-boot-payments.jar > /tmp/payments.log 2>&1 &

echo "Starting Product API"
export CONFIG_FILE="/home/app/conf.json"
/bin/product-api > /tmp/product_api.log 2>&1 &

echo "Starting Public API"
export BIND_ADDRESS=":8081"
export PRODUCT_API_URI="http://localhost:9090"
export PAYMENT_API_URI="http://localhost:8080"
/bin/public-api > /tmp/public_api.log 2>&1 &

