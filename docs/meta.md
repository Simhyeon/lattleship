### TODO

* [x] Docs

### DONE

* [x] Simple body parser
* [x] Find a way to create uuid : copy pastad

* [x] Make Basic workflow
	* [x] Index.html 
	* [x] Game start (id creation)
	* [x] Pick choice (pick POST)
		* [x] Send information
* [x] Make index.html
	* [x] Can send game start request and create
	* [x] Can pick block and get server response
	* [x] Can detect game victory or win
	* [x] Make it aesthecially workable
		* [x] Distinctively split each field
		* [x] Set block size rationally
		* [x] Set start button for plausible place
		* [x] Make it flexible for mobile

* [x] Make Stateful connection map ( at least global )
	* [x] FieldState object
		* [x] Generate_map
		- This kinda works? but needs some serious testing because dynamic programming...
		* [x] Randomseed is very time dependent almost 1 second is same map wihch is not ideal
		- Solution was to call randomseed only once
		* [x] Complete attack method
	* [x] Name can collide with each other - Made table not a hashmap but object array
	* [x] GameState object

* [x] Automation script (Makefile)
- Not yet tested though

* [x] Understand the concept of oop mimicking
	* [x] self.__index = self
