# This code is MIT licensed, see http://www.opensource.org/licenses/mit-license.php
# (C) 2013 Guava7

import sys
from sys import argv
from xml.dom import minidom
import Image, ImageDraw
import os

def exist(path):
	return os.path.exists(path)
	
def GetFileNX(long_file_path):
	return os.path.basename(long_file_path)


def GetFileN(long_file_path):
	filename = GetFileNX(long_file_path)
	return os.path.splitext(filename)[0]
	
def GetPath(file):
	if exist(file):
		return os.path.dirname(os.path.realpath(file))
	else:
		print("[ERROR] [GetPath] file not found [%s]" %(file))
		
def GetFileAbsolutePath(file):
	return GetPath(file) + "/" + GetFileNX(file)

# list item format : {'name':reg_name, 'x': x, 'y': y, 'w': w, 'h': h, 'size': w*h, 'rearrangeX': x, 'rearrangeY': y}
def Rearrange(list, width, height):
	# print("======width x height = %s %s======="%(width, height))
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
	
	items = sorted(items, key=lambda k: -k['w']*k['h'])  # sort items descending order by size
	
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

			
			#there're two way to split free region into up/right. Choose the best way (given bigger free region)
			regUp1 		= {'x':reg['x'], 'y':reg['y'] + obj['h'], 'w':reg['w'], 'h':reg['h'] - obj['h'], 'size':reg['w']*(reg['h'] - obj['h'])}
			regRight1 	= {'x':reg['x'] + obj['w'], 'y':reg['y'], 'w':reg['w'] - obj['w'], 'h':obj['h'], 'size':(reg['w'] - obj['w'])*obj['h']}
			candidateSize1 = max(regUp1['size'], regRight1['size'])
			
			regUp2 		= {'x':reg['x'], 'y':reg['y'] + obj['h'], 'w':obj['w'], 'h':reg['h'] - obj['h'], 'size':obj['w']*(reg['h'] - obj['h'])}
			regRight2 	= {'x':reg['x'] + obj['w'], 'y':reg['y'], 'w':reg['w'] - obj['w'], 'h':reg['h'], 'size':(reg['w'] - obj['w'])*reg['h']}
			candidateSize2 = max(regUp2['size'], regRight2['size'])
			
			if candidateSize1 > candidateSize2:
				regions.append(regUp1)
				regions.append(regRight1)
			else:
				regions.append(regUp2)
				regions.append(regRight2)
			# break
		regions = sorted(regions, key=lambda k: -k['size'])  # sort regions descending order by size
	if (len(items) == 0):
		return [max_width, max_height]
	else:
		return [-1, -1]

def WriteFile(file, content):
	f = open(file, "a")
	f.write(content)
	f.close()
		
def WriteNewFile(file, content):
	f = open(file, "w")
	f.write(content)
	f.close()
		
def ArrangeSingleImage(data_images):
	list_sizew = [64, 128, 64,  128,  256,  128,  256,  512,  256,  512, 1024, 1024, 2048, 2048]
	list_sizeh = [64, 64,  128, 128,  128,  256,  256,  256,  512,  512, 512,  1024, 1024, 2048]
	isRearrangeSuccess = False
	w = 0
	h = 0
	
	# print(data_images)
	
	for i in range(len(list_sizew)):
		sizew = list_sizew[i]
		sizeh = list_sizeh[i]
		_tmpsize = Rearrange(data_images, sizew, sizeh)
		if _tmpsize[0] > 0:
			isRearrangeSuccess = True
			w = _tmpsize[0]
			h = _tmpsize[1]
			break
	
	if isRearrangeSuccess == False:
		print("[ERROR]  Can not re-arrange. Output image is bigger than %sx%s"%(list_sizew[len(list_sizew)-1], list_sizeh[len(list_sizeh)-1]))
		return None
	return [w, h]

def ExportSingleImage(data_images, size, name):
	w = size[0]
	h = size[1]
	
	isAllIndexImage = True
	for iter in data_images:
		img_src = Image.open(iter['name'])
		if img_src.mode != "P":
			isAllIndexImage = False
			break

	img_des = Image.new('RGBA', (w, h))
	if isAllIndexImage:
		draw = ImageDraw.Draw(img_des) # Create a draw object
		draw.rectangle((0, 0, w, h), fill=(255, 0, 255))
	for iter in data_images:
		img_src = Image.open(iter['name'])
		tmp = img_src.crop((iter['x'], iter['y'], iter['x'] + iter['w'], iter['y'] + iter['h']))
		tmp.load()
		img_des.paste(tmp, (iter['rearrangeX'], iter['rearrangeY']))
	
	img_des.save(name + ".png", optimize=1)
	
def build_spriter(input, output_folder):
	# print(input, output_folder)
	if not exist(output_folder): md(output_folder)
	input_filename = GetFileN(input)
	input_path = GetPath(input)
	
	data_images = []
	data_images_map = {}
	data_anims = {}
	data_anims_count = 0;
	
	doc = minidom.parse(input)
	tag_spriter_data  = doc.getElementsByTagName("spriter_data")[0]
	
	
	#export image data
	tag_folders = tag_spriter_data.getElementsByTagName("folder")
	for folder in tag_folders:
		folder_id = int(folder.getAttribute('id'))
		tag_files = folder.getElementsByTagName("file")
		for file in tag_files:
			file_id = int(file.getAttribute('id'))
			file_name = GetFileAbsolutePath(input_path + "/" + file.getAttribute('name'))
			file_width = int(file.getAttribute('width'))
			file_height = int(file.getAttribute('height'))
			data_images_map['%s:%s'%(folder_id, file_id)] = len(data_images)
			
			if file_width == 0 or file_height == 0:
				tmp_img = Image.open(file_name)
				file_width, file_height = tmp_img.size
			data_images.append({
				'name':file_name, 
				'x': 0,
				'y': 0,
				'w':file_width, 
				'h':file_height,
				'rearrangeX': 0,
				'rearrangeY': 0})
				
	# read animation
	tag_entity  = tag_spriter_data.getElementsByTagName("entity")[0]
	tag_animations = tag_entity.getElementsByTagName("animation")
	for anim in tag_animations:
		anim_id = int(anim.getAttribute('id'))
		anim_name = anim.getAttribute('name')
		anim_dur = int(anim.getAttribute('length'))
		anim_looping = anim.getAttribute('looping') != 'false'
		
		_anim = {'id': anim_id, 'name': anim_name, 'duration': anim_dur, 'loop': anim_looping, 'keyframes': [], 'timelines': []}
		data_anims[anim_name] = _anim
		data_anims_count += 1
		keyframes = _anim['keyframes']
		
		tag_mainline = anim.getElementsByTagName("mainline")[0]
		tag_keys = tag_mainline.getElementsByTagName("key")
		for key in tag_keys:
			key_id = int(key.getAttribute('id'))
			key_time = key.getAttribute('time')
			if key_time != "":
				key_time = int(key_time)
			else:
				key_time = 0
			
			kf = {'id': key_id, 'timestamp': key_time, 'frames': []}
			frames = kf['frames']
			
			tag_objects = key.getElementsByTagName("object_ref")
			for object in tag_objects:
				obj_id = int(object.getAttribute('id'))
				obj_timeline = int(object.getAttribute('timeline'))
				obj_key = int(object.getAttribute('key'))
				obj_zindex = int(object.getAttribute('z_index'))
				frames.append({'timeline':obj_timeline, 'slot': obj_key})
			keyframes.append(kf)
		
		timelines = _anim['timelines']
		tag_timelines = anim.getElementsByTagName("timeline")
		for tl in tag_timelines:
			timeline_id = int(tl.getAttribute('id'))
			tag_keys = tl.getElementsByTagName("key")
			
			timeline = []
			for key in tag_keys:
				key_id = int(key.getAttribute('id'))
				key_time = 0
				if key.getAttribute('time') != "":
					key_time = int(key.getAttribute('time'))
				spin = 1
				if key.getAttribute('spin') != "":
					spin = int(key.getAttribute('spin'))
				obj = key.getElementsByTagName("object")[0]
				folder_id = int(obj.getAttribute('folder'))
				file_id = int(obj.getAttribute('file'))
				x = 0
				y = 0
				scalex = 1
				scaley = 1
				angle = 0
				alpha = 1
				pivot_x = 0
				pivot_y = 1
				if obj.getAttribute('x') != "":
					x = int(float(obj.getAttribute('x')))
				if obj.getAttribute('y') != "":
					y = int(float(obj.getAttribute('y')))
				if obj.getAttribute('scale_x') != "":
					scalex = (float(obj.getAttribute('scale_x')))
				if obj.getAttribute('scale_y') != "":
					scaley = (float(obj.getAttribute('scale_y')))
				if obj.getAttribute('angle') != "":
					angle = int(float(obj.getAttribute('angle')))
				if obj.getAttribute('a') != "":
					alpha = float(obj.getAttribute('a'))
				if obj.getAttribute('pivot_x') != "":
					pivot_x = float(obj.getAttribute('pivot_x'))
				if obj.getAttribute('pivot_y') != "":
					pivot_y = float(obj.getAttribute('pivot_y'))
				
				image_region = data_images[data_images_map["%s:%s"%(folder_id, file_id)]]
	
				timeslot = {'region':image_region, 'x': x, 'y': y, 'sx': scalex, 'sy': scaley, 'angle': angle, 'timestamp': key_time, 'spin':spin, 'alpha':alpha, 'pivot_x':pivot_x, 'pivot_y':pivot_y}
				timeline.append(timeslot)
			timelines.append(timeline)

	#export single image
	size =  ArrangeSingleImage(data_images)
	if size == None: return False
	ExportSingleImage(data_images, size, output_folder + "/" + input_filename)		

	lua = "return {\n"
	
	for anim_key in data_anims:
		lua += "	['%s'] = {\n"%(anim_key)
		anim = data_anims[anim_key]

		lua += "		['%s'] = %s,\n"%('duration', anim['duration'])
		lua += "		['%s'] = %s,\n"%('loop', anim['loop'] == False and 'false' or 'true')
		lua += "		['%s'] = '%s',\n"%('name', anim['name'])
		
		lua += "		['%s'] = {\n"%('keyframes')
		for keyframe in anim['keyframes']:
			lua += "			{\n"
			# lua += "				['%s'] = %s,\n"%('id', keyframe['id'] + 1)
			lua += "				['%s'] = %s,\n"%('timestamp', keyframe['timestamp'])
			lua += "				['%s'] = {\n"%('frames')
			for frame in keyframe['frames']:
				lua += "					{['%s'] = %s, ['%s'] = %s},\n"%('timeline', frame['timeline'] + 1, 'slot', frame['slot'] + 1)
			lua += "				},\n"
			lua += "			},\n"
		lua += "		},\n"
		
		lua += "		['%s'] = {\n"%('timelines')
		for timeline in anim['timelines']:
			lua += "			{\n"
			for slot in timeline:
				region = slot['region']
				lua += "				{['region'] = '%s:%s:%s:%s:%s', ['x'] = %s, ['y'] = %s, ['sx'] = %s, ['sy'] = %s, ['angle'] = %s, ['timestamp'] = %s, ['spin'] = %s, ['alpha'] = %s, ['pivot_x'] = %s, ['pivot_y'] = %s},\n"%(input_filename + '.png', region['rearrangeX'], region['rearrangeY'], region['w'], region['h'], slot['x'], -slot['y'], slot['sx'], slot['sy'], 360 - slot['angle'], slot['timestamp'], slot['spin'], slot['alpha'], slot['pivot_x'], 1 - slot['pivot_y'])
			lua += "			},\n"
		lua += "		},\n"
		
		# for timeline in 
		lua += "	},\n"	
				
				
	lua += "}"
	
	lua = lua.replace('\n', '')
	lua = lua.replace('	', '')
	WriteNewFile(output_folder + "/" + input_filename + ".lua", lua)
				
				
if __name__ == '__main__':
    build_spriter(sys.argv[1], sys.argv[2])
	
	