#!/usr/bin/python

import sys
import httplib
import urllib

def doit():
    params = urllib.urlencode({'field1': sys.argv[1], 'field2': sys.argv[2], 'field3': sys.argv[3], 'field4': sys.argv[4],'field5': sys.argv[5], 'key':'1VM2S9Z7RJRH8M6A'})
    headers = {"Content-type": "application/x-www-form-urlencoded","Accept":"text/plain"}
    conn = httplib.HTTPConnection("api.thingspeak.com")
    conn.request("POST","/update",params,headers)
    response = conn.getresponse()
    print response.status, response.reason
    data = response.read()
    conn.close()

if __name__ == "__main__":
    doit()
