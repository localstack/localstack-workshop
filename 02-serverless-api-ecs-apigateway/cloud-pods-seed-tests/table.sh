#!/bin/bash

awslocal dynamodb create-table --cli-input-json file://food.json

awslocal dynamodb create-table --cli-input-json file://pet.json

awslocal dynamodb put-item \
    --table-name TablePetstorePets \
    --item '{
        "petId": {"S": "1"},
        "petName": {"S": "Dog"} 
      }' \
    --return-consumed-capacity TOTAL


awslocal dynamodb put-item \
    --table-name TablePetstoreFood \
    --item '{
        "foodId": {"S": "1"},
        "foodName": {"S": "Cat food"} 
      }' \
    --return-consumed-capacity TOTAL


