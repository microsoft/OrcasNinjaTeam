#!/usr/bin/python
import psycopg2
import os
import threading
import time
import sys

print(sys.argv)
#source info
source_url = sys.argv[1]
source_table = sys.argv[2]

#dest info
dest_url = sys.argv[3]
dest_table = sys.argv[4]

#others
total_threads=int(sys.argv[5]);
size=int(sys.argv[6]);


interval=size/total_threads;
start=0;
end=start+interval;


for i in range(0,total_threads):
        if(i!=total_threads-1):
                select_query = '\"\COPY (SELECT * from ' + source_table + ' WHERE id>='+str(start)+' AND id<'+str(end)+") TO STDOUT\"";
                read_query = "psql \"" + source_url + "\" -c " + select_query
                write_query = "psql \"" + dest_url + "\" -c \"\COPY " + dest_table +" FROM STDIN\""
                os.system(read_query+'|'+write_query + ' &')
        else:
                select_query = '\"\COPY (SELECT * from '+ source_table +' WHERE id>='+str(start)+") TO STDOUT\"";
                read_query = "psql \"" + source_url + "\" -c " + select_query
                write_query = "psql \"" + dest_url + "\" -c \"\COPY " + dest_table +" FROM STDIN\""
                os.system(read_query+'|'+write_query)
        start=end;
        end=start+interval;
