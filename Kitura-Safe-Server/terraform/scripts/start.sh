#! /usr/bin/env bash

pkill swift
cd .build/release
./Kitura-Safe-Server
cd -
