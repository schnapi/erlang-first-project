#!/bin/bash

actordb stop;
sudo rm /var/lib/actordb/lmdb;
actordb start;
actordb_console -f /etc/actordb/init.example.sql;
