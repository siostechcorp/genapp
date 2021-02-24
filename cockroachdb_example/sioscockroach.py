#!/bin/python
import os
import sys
import subprocess

# functions
def printS(a): 
	print >> sys.stderr, a
 #future   print(a,file=sys.stderr)

def startDB(execCmd,myaddr,myhttp,mystore):
	#cmd=execCmd+" start --insecure --store="+mystore+" --listen-addr="+myaddr+" --http-addr="+myhttp+" --join="+myaddr+" --background"
	cmd=execCmd+" start --insecure --store="+mystore+" --listen-addr="+myaddr+" --http-addr="+myhttp+" --background"
	printS (cmd)
	return_code = subprocess.call(cmd, shell=True)
	printS ("startDB result={}".format(return_code))
	return return_code

def initDB(execCmd,myaddr):
	cmd=execCmd+" init --insecure --host="+myaddr+' >&2'
	printS (cmd)
	return_code = subprocess.call(cmd, shell=True)
	printS ("initDB result={}".format(return_code))
	return return_code

def stopDB(execCmd,myaddr):
	cmd=execCmd+' quit --insecure --host='+myaddr+' >&2'
	printS (cmd)
	return_code = subprocess.call(cmd, shell=True)
	printS ("stopDB result={}".format(return_code))
	return return_code

def statusDB(execCmd,myaddr):
	cmd=execCmd+' sql --insecure --host='+myaddr+' -e \'show users\' >&2'
	printS (cmd)
	return_code = subprocess.call(cmd, shell=True)
	printS ("statusDB result={}".format(return_code))
	return return_code

from subprocess import check_output
def get_pid(name):
	try: 
		pid = check_output(["pidof",name])
		return pid
	except :
		return 0

def flg_create():
	cmd=LKBIN+'/flg_create -f '+flag
	printS (cmd)
	return_code = subprocess.call(cmd, shell=True)
	printS ("flg_create result={}".format(return_code))
	return return_code

def flg_remove(LKBIN):
	cmd=LKBIN+'/flg_remove -f '+flag
	printS (cmd)
	return_code = subprocess.call(cmd, shell=True)
	printS ("flg_remove result={}".format(return_code))
	return return_code

def flg_test(LKBIN):
	cmd=LKBIN+'/flg_test -f '+flag
	printS (cmd)
	return_code = subprocess.call(cmd, shell=True)
	printS ("flg_test result={}".format(return_code))
	return return_code

def flg_list(LKBIN):
	cmd=LKBIN+'/flg_list'
	printS (cmd)
	return_code = subprocess.call(cmd, shell=True)
	printS ("flg_list result={}".format(return_code))
	return return_code

def get_vars(LKBIN,tag):
	cmd=LKBIN+'/getinfo'
	printS (cmd)
	return_code = subprocess.check_output([cmd, tag])
	printS ("info result={}".format(return_code))
	return return_code
