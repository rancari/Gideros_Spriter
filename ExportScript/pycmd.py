import sys
import os
import shutil
import os.path
import fnmatch
import re
import subprocess
import time
import urllib 
import socket
import random
import distutils
import distutils.dir_util
import threading
import ctypes
import commands
import urllib
import json
import hashlib
import base64
import getpass

re_spaces = re.compile("\s+")

gPathStack = []
gHasError = False
gPreProcessorDefines=""
gPreProcessorDict= {}
#----------------------------------------------------------
# System function
#----------------------------------------------------------
STD_OUTPUT_HANDLE = -11
gTextColor = {'black': 0, 'blue': 1, 'green': 2, 'aqua': 3, 'red': 4, 'purple': 5, 'yellow': 6, 'white': 7, 'grey': 8, 'light blue': 9, 'light green': 10, 'light aqua': 11, 'light red': 12, 'light purple': 13, 'light yellow': 14, 'bright white': 15}
gTextColorMAC = {'black': "30;49m", 'red': "31;49m", 'green': "32;49m", 'yellow': "33;49m", 'blue': "34;49m", 'purple': "35;49m", 'aqua': "36;49m", 'white': "37;49m", 'grey': "30;49m", 'light red': "31;49m", 'light green': "32;49m", 'light yellow': "33;49m", 'light blue': "34;49m", 'light purple': "35;49m", 'light aqua': "36;49m", 'bright white': "37;49m"}
def get_csbi_attributes(handle):
	# Based on IPython's winconsole.py, written by Alexander Belchenko
	import struct
	csbi = ctypes.create_string_buffer(22)
	res = ctypes.windll.kernel32.GetConsoleScreenBufferInfo(handle, csbi)
	assert res

	(bufx, bufy, curx, cury, wattr,
	left, top, right, bottom, maxx, maxy) = struct.unpack("hhhhHhhhhhh", csbi.raw)
	return wattr

def echoc(text, color):
	if os.name=="nt": 
		if gTextColor.has_key(color):
			color = gTextColor[color]
			handle = ctypes.windll.kernel32.GetStdHandle(STD_OUTPUT_HANDLE)
			reset = get_csbi_attributes(handle)
			ctypes.windll.kernel32.SetConsoleTextAttribute(handle, color)
			print(text)
			ctypes.windll.kernel32.SetConsoleTextAttribute(handle, reset)
		else:
			print(text)
	else:
		if gTextColorMAC.has_key(color):
			color = gTextColorMAC[color]
			CSI="\x1B[1;"
			print CSI + color + text + CSI + "0m"
		else:
			print text

def echowarn(text):
	echoc(text, "light yellow")
	
def echoerror(text):
	Error()
	echoc(text, "light red")

def echo(str):
	print str

def md(dir):
	ExistDir = exist(dir)
	notIsFile = os.path.isfile(dir)
	if (not ExistDir) or (ExistDir and notIsFile):
		try:
			os.makedirs(dir)
		except OSError, e:
			echoerror("[ERROR] [md] fail when execute with dir [%s]" %(dir))
			Error()

def rd(dir):
	if exist(dir):
		try:
			shutil.rmtree(dir)
		except:
			echoerror("[ERROR] [rd] fail when execute with dir [%s]" %(dir))
			Error()
	else:
		echowarn("[WARNING] [rd] %s not found" %(dir))

def exist(path):
	return os.path.exists(path)
	
	
def cd(path):
	if exist(path):
		os.chdir(path)
	else:
		echoerror("[ERROR] [cd] fail when execute with dir [%s]" %(path))
		Error()

def pushd(path):
	global gPathStack
	if exist(path):
		gPathStack.append(CurrentDir())
		cd(path)
	else:
		echoerror("[ERROR] [pushd] fail when execute with dir [%s]" %(path))
		Error()
		
def popd():
	global gPathStack
	empty = (len(gPathStack) == 0)
	if not empty:
		cd(gPathStack.pop())
	
def goto(lable):
	lable()
	
def xcopy(src, dst):
    try:
        distutils.dir_util.copy_tree(src, dst)
    except OSError as exc:
		echoerror("[ERROR] [xcopy] fail to execute with files [%s] [%s]" %(src, dst))
		Error()
		
def copy(src, dst):
	if exist(src):
		try:
			shutil.copy(src, dst)
		except ValueError:
			echoerror("[ERROR] [copy] fail to execute with files [%s] [%s]: [%s]" %(src, dst, ValueError))
	else:
		echoerror("[ERROR] [copy] fail. [%s] not found" %(src))
		Error()
		
def move(src, dst):
	if exist(src):
		try:
			shutil.move(src, dst)
		except:
			echoerror("[ERROR] [move] fail to execute with files [%s] [%s]" %(src, dst))
	else:
		echoerror("[ERROR] [move] fail. [%s] not found" %(src))
		Error()
		
def delete(file):
	if exist(file):
		try: 
			os.remove(file)
		except:
			echoerror("[ERROR] [delete] fail to execute with file [%s]" %(file))
			Error()
		
def pause(message):
	raw_input(message)	

def cls():
	if os.name=="nt":
		run("cls", True)
	else:
		run("clear", True)
#----------------------------------------------------------
# additional function
#----------------------------------------------------------
def run(cmd, IsShell = True):
	# return os.system(cmd)
	try:
		retcode = subprocess.call(cmd, shell=IsShell)
		return retcode
	except OSError, e:
		Error()
		echoerror("[ERROR] [delete] fail to execute run %s)" %(cmd))
		return -1

def Error():
	global gHasError
	gHasError = True

def CurrentDir():
	return os.getcwd()
	
def HasError():
	global gHasError
	return gHasError
	
def IsFileExist(path):
	return os.path.exists(path) and os.path.isfile(path)

def ListFileNoRecursive(path, filters):
	list = []
	params = filters.split(",")
	for filter in params:
		filter = filter.strip()
		for filename in os.listdir(path):
			if fnmatch.fnmatch(filename, filter):
				fn = os.path.basename(filename)
				if not fn.startswith("@"):
					list.append(os.path.join(path, filename))
	return list
	
def ListFile(path, filters):
	list = []
	params = filters.split(",")
	for filter in params:
		filter = filter.strip()
		# echo(filter);
		for root, dirnames, filenames in os.walk(path):
			for filename in fnmatch.filter(filenames, filter):
				fn = os.path.basename(filename)
				if not fn.startswith("@"):
					list.append(os.path.join(root, filename))
	return list

def GetFileNX(long_file_path):
	return os.path.basename(long_file_path)


def GetFileN(long_file_path):
	filename = GetFileNX(long_file_path)
	return os.path.splitext(filename)[0]
	
def GetFileX(long_file_path):
	filename = GetFileNX(long_file_path)
	return os.path.splitext(filename)[1]
	
def GetFileLastModified(file):
	if exist(file):
		return time.ctime(os.path.getmtime(file))
	else:
		return 0

def GetFileSize(file):
	if exist(file):
		return os.path.getsize(file)
	else:
		return 0
			

def WriteFile(file, content):
	f = open(file, "a")
	f.write(content)
	f.close()
		
def WriteNewFile(file, content):
	f = open(file, "w")
	f.write(content)
	f.close()

def GetPath(file):
	if exist(file):
		return os.path.dirname(os.path.realpath(file))
	else:
		echoerror("[ERROR] [GetPath] file not found [%s]" %(file))
		Error()
		
def GetFileAbsolutePath(file):
	return GetPath(file) + "/" + GetFileNX(file)

def SetEnv(env, value):
	os.putenv(env, value)

def CloneFileWithVerifing(src, dst):
	out = ""
	if IsFileExist(dst):
		out = GetFileNX(dst)
		dst = GetPath(dst)
		# print("aaaaa")
	else:
		if not exist(dst):
			out = GetFileNX(dst)
			dst = os.path.dirname(dst)
			
	# print(dst, out)
	if exist(dst):
		if IsFileExist(src):
			try:
				lastModifiedSrc = GetFileLastModified(src)
				lastModifiedDest = ""
				lastSizeDest = ""
				
				if out == "":
					fname = GetFileNX(src)
				else:
					fname = out
					
				timeStampFile = "%s/%s.o.d"%(dst, fname)
				desFile = "%s/%s" % (dst, fname)
				if not IsFileExist(timeStampFile): 
					copy(src, desFile)
					lastModifiedDest = GetFileLastModified(desFile)
					WriteNewFile(timeStampFile, "%s\n%s"%(lastModifiedSrc, lastModifiedDest))
					# echo ("Copy .. %s"%(fname)) 
				else:
					if IsFileExist(desFile):
						lastModifiedDest = GetFileLastModified(desFile)
						if os.path.getsize(desFile) != os.path.getsize(src):
							copy(src, desFile)	
							WriteNewFile(timeStampFile, "%s\n%s"%(lastModifiedSrc, lastModifiedDest))
							# echo ("[Overwrite] %s"%(fname))
						else:
							data_file = open(timeStampFile, 'r')
							data = data_file.readlines()
							data_file.close()
							
							lines = []
							for line in data:
								line = line.strip()
								lines.append(line)
							
							if lastModifiedSrc != lines[0] or lastModifiedDest != line[1]:
								copy(src, desFile)
								lastModifiedDest = GetFileLastModified(desFile)
								WriteNewFile(timeStampFile, "%s\n%s"%(lastModifiedSrc, lastModifiedDest))
								# echo ("[Overwrite2] %s"%(fname)) 
					else:
						copy(src, desFile)
						lastModifiedDest = GetFileLastModified(desFile)
						WriteNewFile(timeStampFile, "%s\n%s"%(lastModifiedSrc, lastModifiedDest))
			except ValueError:
				#echo(ValueError)
				echoerror("[ERROR] [CloneFileWithVerifing] fail to execute with [%s] [%s]" %(src, dst))
				Error()
		else:
			echoerror("[ERROR] [CloneFileWithVerifing] fail. [%s] not found" %(src))
			Error()
	else:
		echoerror("[ERROR] [CloneFileWithVerifing] fail. [%s] not found" %(dst))
		Error()
#----------------------------------------------------------
# additional function
#----------------------------------------------------------
def Isset(var):
	try:
		var
		return True
	except NameError:
		return False

def GetHomeDir():
	return os.getenv('USERPROFILE') or os.getenv('HOME')


def GetSVNRev():
	# fName =""
	# return os.popen('svn info %s | grep "Last Changed Rev" ' % fName, "r").readline().replace("Last Changed Rev:","").strip()
	rev = "0"
	for line in os.popen('svn info', "r").readlines():
		if line.startswith("Last Changed Rev"):
			rev = line.replace("Last Changed Rev:","").strip()
	return rev
	


def GetMAC(iface):
	if os.name=="nt": 
		try:
			for line in os.popen("ipconfig /all"): 
				if line.lstrip().startswith('Physical Address'): 
					return line.split(':')[1].strip().replace('-',':') 
		except:
			return '00:00:00:00:00:00'
	else:
		words = commands.getoutput("ifconfig " + iface).split()
		if "HWaddr" in words:
			return words[ words.index("HWaddr") + 1 ]
		else:
			return '00:00:00:00:00:00'

def GetDefaultMAC():
	return GetMAC('eth0')

# list item format : {'name':reg_name, 'x': x, 'y': y, 'w': w, 'h': h, 'size': w*h, 'rearrangeX': x, 'rearrangeY': y}
def Rearrange(list, width, height):
	# echo("======width x height = %s %s======="%(width, height))
	x = 0
	y = 0
	liney = 0
	isAdd = False
	isNewLine = False
	
	items = []
	for obj in list:
		items.append(obj)

	if items[0]['w'] > width or items[0]['h'] > height:
		return [-1, -1]

	regions = []
	reg = {'x':0, 'y':0, 'w':width, 'h':height, 'size':width*height}
	regions.append(reg)
	max_height = -1
	max_width = -1
	while len(items) > 0 and len(regions) > 0:
		reg = regions.pop()
		mix_dif = 99999999
		select_item = -1
		for obj in items:
			if obj['w'] <= reg['w'] and obj['h'] <= reg['h']:
				dif = (reg['w'] - obj['w']) + (reg['h'] - obj['h'])
				if dif < mix_dif:
					mix_dif = dif
					select_item = obj
					break
		if not select_item == -1:
			obj['rearrangeX'] = reg['x']
			obj['rearrangeY'] = reg['y']
			if max_height < obj['rearrangeY'] + obj['h']:
				max_height = obj['rearrangeY'] + obj['h']
			if max_width < obj['rearrangeX'] + obj['w']:
				max_width = obj['rearrangeX'] + obj['w']
			items.remove(obj)

			regUp 		= {'x':reg['x'], 'y':reg['y'] + obj['h'], 'w':reg['w'], 'h':reg['h'] - obj['h'], 'size':reg['w']*(reg['h'] - obj['h'])}
			regRight 	= {'x':reg['x'] + obj['w'], 'y':reg['y'], 'w':reg['w'] - obj['w'], 'h':obj['h'], 'size':(reg['w'] - obj['w'])*obj['h']}
					
			regions.append(regUp)
			regions.append(regRight)
			# break
		# regions = sorted(regions, key=lambda k: k['size']) 
	if (len(items) == 0):
		# print (max_width, max_height, max_width*max_height)
		return [max_width, max_height]
	else:
		return [-1, -1]
	
#----------------------------------------------------------
# threading
#----------------------------------------------------------
gThreads = []

class FuncThread(threading.Thread):
    def __init__(self, target, *args):
        self._target = target
        self._args = args
        threading.Thread.__init__(self)
		
    def run(self):
		self._target(*self._args)

def Thread_ResetPool():
	global gThreads
	gThreads = []

def Thread_Add(target, *args):
	if os.name == "nt":
		global gThreads
		thread = FuncThread(target, *args)
		gThreads.append(thread)
		thread.start()
	else:
		target(*args)
	
def Thread_Join():
	global gThreads
	for thread in gThreads:
		thread.join()
		
# HTTP request

def HTTPRequest(url, params, method):
	try:
		params = urllib.urlencode(params)
		if method=='POST':
			f = urllib.urlopen(url, params)
		else:
			f = urllib.urlopen(url+'?'+params)
		return (f.read(), f.code)
	except:
		return ("", -1)
