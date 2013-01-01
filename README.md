Gideros_Spriter
===============

An implementation of Spriter Animation in Gideros: 
+ See: http://www.brashmonkey.com/spriter.htm
+ See: http://www.giderosmobile.com/

NOTE: bone animation has not been supported yet !

This stuff consists two parts: 

+ Export script using python, which export spriter file format ".scml" to ".lua" script (build_spriter.py)
	
	Requirement:
		- Python 2.7 http://www.python.org/download/releases/2.7.3/
		- PIL 1.1.7 http://www.pythonware.com/products/pil/

	Usage:
		
		build_spriter.py input.scml output_path
	Example:
	
		build_spriter.py .\sample\spriter_demo.scml .\sample\output

+ And lua source files written in Gideros style, includes:
	+ CSprite.lua, ResourceManagement.lua, CAnimation.lua: need for playing animation, CAnimation.lua is main script
	+ spriter_demo.lua, spriter_demo.png : animation data

Youtube demo: http://youtu.be/hD0rnQOQLLI
