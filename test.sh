#!/bin/bash

echo -e "[ CREATE ]\n"
./bdsh -f file.json create database
./bdsh -f file.json create table user id,firstname,lastname
./bdsh -f file.json create table age id,age

rep=""
while [ "$rep" == "" ]; do
    read -p "Étape suivante ? (o/n/q) " rep; [ "$rep" = "o" ]
    if [ "$rep" == "q" ]; then
       exit 0
    fi
done

echo -e "\n [ INSERT ]\n"
./bdsh -f file.json insert user id=1,firstname=John,lastname=SMITH
./bdsh -f file.json insert user id=4,firstname=Robert\ John,lastname=WILLIAMS
./bdsh -f file.json insert user id=2,firstname=Lisa,lastname=SIMPSON
./bdsh -f file.json insert user id=10,lastname=SMITH
./bdsh -f file.json insert user firstname=Laura,lastname=SMITH
./bdsh -f file.json insert user id=9
./bdsh -f file.json insert age id=1,age=42

rep=""
while [ "$rep" == "" ]; do
    read -p "Étape suivante ? (o/n/q) " rep; [ "$rep" = "o" ]
    if [ "$rep" == "q" ]; then
       exit 0
    fi
done

echo -e "\n [ DESCRIBE ]\n"
./bdsh -f file.json describe user


rep=""
while [ "$rep" == "" ]; do
    read -p "Étape suivante ? (o/n/q) " rep; [ "$rep" = "o" ]
    if [ "$rep" == "q" ]; then
       exit 0
    fi
done

echo -e "\n [ SELECT ]\n"

./bdsh -f file.json select user firstname,lastname
echo -e '\n'
./bdsh -f file.json select user lastname,firstname order
