/*
A Star pathfinding algorithm
Returns a list of tiles forming a path from A to B, taking dense objects as well as walls, and the orientation of
windows along the route into account.
Use:
your_list = AStar(start location, end location, adjacent turf proc, distance proc)
For the adjacent turf proc i wrote:
/turf/proc/AdjacentTurfs
And for the distance one i wrote:
/turf/proc/Distance
So an example use might be:

src.path_list = AStar(src.loc, target.loc, /turf/proc/AdjacentTurfs, /turf/proc/Distance)

Then to start on the path, all you need to do it:
Step_to(src, src.path_list[1])
src.path_list -= src.path_list[1] or equivilent to remove that node from the list.

Optional extras to add on (in order):
MaxNodes: The maximum number of nodes the returned path can be (0 = infinite)
Maxnodedepth: The maximum number of nodes to search (default: 30, 0 = infinite)
Mintargetdist: Minimum distance to the target before path returns, could be used to get
near a target, but not right to it - for an AI mob with a gun, for example.
Minnodedist: Minimum number of nodes to return in the path, could be used to give a path a minimum
length to avoid portals or something i guess?? Not that they're counted right now but w/e.
*/

// Modified to provide ID argument - supplied to 'adjacent' proc, defaults to null
// Used for checking if route exists through a door which can be opened

// Also added 'exclude' turf to avoid travelling over; defaults to null

//Currently, there's four main ways to call AStar
//
// 1) adjacent = "/turf/proc/AdjacentTurfsWithAccess" and distance = "/turf/proc/Distance"
//	Seeks a path moving in all directions (including diagonal) and checking for the correct id to get through doors
//
// 2) adjacent = "/turf/proc/CardinalTurfsWithAccess" and distance = "/turf/proc/Distance_cardinal"
//  Seeks a path moving only in cardinal directions and checking if for the correct id to get through doors
//  Used by most bots, including Beepsky
//
// 3) adjacent = "/turf/proc/AdjacentTurfs" and distance = "/turf/proc/Distance"
//  Same as 1), but don't check for ID. Can get only get through open doors
//
// 4) adjacent = "/turf/proc/AdjacentTurfsSpace" and distance = "/turf/proc/Distance"
//  Same as 1), but check all turf, including unsimulated

//////////////////////
//PriorityQueue object
//////////////////////

//an ordered list, using the cmp proc to weight the list elements
/PriorityQueue
	var/list/L //the actual queue
	var/cmp //the weight function used to order the queue

/PriorityQueue/New(compare)
	L = new()
	cmp = compare

/PriorityQueue/proc/IsEmpty()
	return !L.len

//add an element in the list,
//immediatly ordering it to its position using Insertion sort
/PriorityQueue/proc/Enqueue(var/atom/A)
	var/i
	L.Add(A)
	i = L.len -1
	while(i > 0 &&  call(cmp)(L[i],A) >= 0) //place the element at it's right position using the compare proc
		L.Swap(i,i+1) 						//last inserted element being first in case of ties (optimization)
		i--

//removes and returns the first element in the queue
/PriorityQueue/proc/Dequeue()
	if(!L.len)
		return 0
	. = L[1]
	Remove(.)
	return .

//removes an element
/PriorityQueue/proc/Remove(var/atom/A)
	return L.Remove(A)

//returns a copy of the elements list
/PriorityQueue/proc/List()
	var/list/ret = L.Copy()
	return ret

//return the position of an element or 0 if not found
/PriorityQueue/proc/Seek(var/atom/A)
	return L.Find(A)

//return the element at the i_th position
/PriorityQueue/proc/Get(var/i)
	if(i > L.len || i < 1)
		return 0
	return L[i]

//replace the passed element at it's right position using the cmp proc
/PriorityQueue/proc/ReSort(var/atom/A)
	var/i = Seek(A)
	if(i == 0)
		return
	while(i < L.len && call(cmp)(L[i],L[i+1]) > 0)
		L.Swap(i,i+1)
		i++
	while(i > 1 && call(cmp)(L[i],L[i-1]) <= 0) //last inserted element being first in case of ties (optimization)
		L.Swap(i,i-1)
		i--

//////////////////////
//PathNode object
//////////////////////

//A* nodes variables
/PathNode
	var/turf/source //turf associated with the PathNode
	var/PathNode/prevNode //link to the parent PathNode
	var/total_node_cost		//A* Node weight (f = g + h)
	var/distance_from_end		//A* movement cost variable, how far it is from the end
	var/distance_from_start		//A* heuristic variable
	var/nodecount		//count the number of Nodes traversed

/PathNode/New(s,p,ndistance_from_start,ndistance_from_end,pnt)
	source = s
	prevNode = p
	distance_from_start = ndistance_from_start
	distance_from_end = ndistance_from_end
	total_node_cost = distance_from_start + distance_from_end
	source.PNode = src
	nodecount = pnt

/PathNode/proc/calc_f()
	total_node_cost = distance_from_start + distance_from_end

//////////////////////
//A* procs
//////////////////////

//the weighting function, used in the A* algorithm
proc/PathWeightCompare(PathNode/a, PathNode/b)
	return a.total_node_cost - b.total_node_cost

//search if there's a PathNode that points to turf T in the Priority Queue
proc/SeekTurf(var/PriorityQueue/Queue, var/turf/T)
	var/i = 1
	var/PathNode/PN
	while(i < Queue.L.len + 1)
		PN = Queue.L[i]
		if(PN.source == T)
			return i
		i++
	return 0

//the actual algorithm
proc/AStar(start,end,adjacent,dist,maxnodes,maxnodedepth = 30,mintargetdist,minnodedist,id=null, var/turf/exclude=null)
	ASSERT(!istype(end,/area)) //Because yeah some things might be doing this and we want to know what
	var/PriorityQueue/open = new /PriorityQueue(/proc/PathWeightCompare) //the open list, ordered using the PathWeightCompare proc, from lower f to higher
	var/list/closed = new() //the closed list
	var/list/path = null //the returned path, if any
	var/PathNode/cur //current processed turf

	//sanitation
	start = get_turf(start)
	if(!start)
		return 0

	//initialization
	open.Enqueue(new /PathNode(start,null,0,call(start,dist)(end),0))

	//then run the main loop
	while(!open.IsEmpty() && !path)
	{
			//get the lower f node on the open list
		cur = open.Dequeue() //get the lowest node cost turf in the open list
		closed.Add(cur.source) //and tell we've processed it

		//if we only want to get near the target, check if we're close enough
		var/closeenough
		if(mintargetdist)
			closeenough = call(cur.source,dist)(end) <= mintargetdist

		//if too many steps, abandon that path
		to_chat(world, "maxnodedepth:[maxnodedepth] cur.nodecount [cur.nodecount]")
		if(maxnodedepth && (cur.nodecount > maxnodedepth))
			continue

		//found the target turf (or close enough), let's create the path to it
		if(cur.source == end || closeenough)
			path = new()
			path.Add(cur.source)
			while(cur.prevNode)
				cur = cur.prevNode
				path.Add(cur.source)
			break

		//IMPLEMENTATION TO FINISH
		//do we really need this minnodedist ???
		/*if(minnodedist && maxnodedepth)
			if(call(cur.source,minnodedist)(end) + cur.nt >= maxnodedepth)
				continue
		*/

		//get adjacents turfs using the adjacent proc, checking for access with id
		var/list/L = call(cur.source,adjacent)(id,closed)

		for(var/turf/T in L)
			if(T.color != "#00ff00")
				T.color = "#FFA500" //orange
			if(T == exclude)
				if(T.color != "#00ff00")
					T.color = "#FF0000" //red
				continue

			var/newenddist = call(T,dist)(end)
			to_chat(world, "[T.x] [T.y] [T.z], val:[newenddist]")
			if(!T.PNode) //is not already in open list, so add it
				open.Enqueue(new /PathNode(T,cur,call(cur.source,dist)(T),newenddist,cur.nodecount+1))
				if(T.color != "#00ff00")
					T.color = "#0000ff" //blue
			else //is already in open list, check if it's a better way from the current turf
				if(newenddist < T.PNode.distance_from_end)
					T.color = "#00ff00" //green
					T.PNode.prevNode = cur
					T.PNode.distance_from_start = newenddist
					T.PNode.calc_f()
					open.ReSort(T.PNode)//reorder the changed element in the list
		sleep(5)

	}

	//cleaning after us
	for(var/PathNode/PN in open.L)
		PN.source.PNode = null
	for(var/turf/T in closed)
		T.PNode = null

	//if the path is longer than maxnodes, then don't return it
	if(path && maxnodes && path.len > (maxnodes + 1))
		return 0

	//reverse the path to get it from start to finish
	if(path)
		for(var/i = 1; i <= path.len/2; i++)
			path.Swap(i,path.len-i+1)

	return path






///////////////////
//A* helpers procs
///////////////////

// Returns true if a link between A and B is blocked
// Movement through doors allowed if ID has access
/proc/LinkBlockedWithAccess(turf/A, turf/B, obj/item/weapon/card/id/ID)


	if(A == null || B == null)
		return 1
	var/adir = get_dir(A,B)
	var/rdir = get_dir(B,A)
	if(adir & (adir-1))	//	diagonal
		var/turf/iStep = get_step(A,adir&(NORTH|SOUTH))
		if(!iStep.density && !LinkBlockedWithAccess(A,iStep, ID) && !LinkBlockedWithAccess(iStep,B,ID))
			return 0

		var/turf/pStep = get_step(A,adir&(EAST|WEST))
		if(!pStep.density && !LinkBlockedWithAccess(A,pStep,ID) && !LinkBlockedWithAccess(pStep,B,ID))
			return 0

		return 1

	if(DirBlockedWithAccess(A,adir, ID))
		return 1

	if(DirBlockedWithAccess(B,rdir, ID))
		return 1

	for(var/obj/O in B)
		if(O.density && !istype(O, /obj/machinery/door) && !(O.flow_flags & ON_BORDER))
			return 1

	return 0

// Returns true if direction is blocked from loc
// Checks doors against access with given ID
/proc/DirBlockedWithAccess(turf/loc,var/dir,var/obj/item/weapon/card/id/ID)
	for(var/obj/structure/window/D in loc)
		if(!D.density)
			continue
		if(D.dir == SOUTHWEST)
			return 1 //full-tile window
		if(D.dir == dir)
			return 1 //matching border window

	for(var/obj/machinery/door/D in loc)
		if(!D.CanAStarPass(ID,dir))
			return 1
	return 0

// Returns true if a link between A and B is blocked
// Movement through doors allowed if door is open
/proc/LinkBlocked(turf/A, turf/B)
	if(A == null || B == null)
		return 1
	var/adir = get_dir(A,B)
	var/rdir = get_dir(B,A)
	if(adir & (adir-1)) //diagonal
		var/turf/iStep = get_step(A,adir & (NORTH|SOUTH)) //check the north/south component
		if(!iStep.density && !LinkBlocked(A,iStep) && !LinkBlocked(iStep,B))
			return 0

		var/turf/pStep = get_step(A,adir & (EAST|WEST)) //check the east/west component
		if(!pStep.density && !LinkBlocked(A,pStep) && !LinkBlocked(pStep,B))
			return 0

		return 1

	if(DirBlocked(A,adir))
		return 1
	if(DirBlocked(B,rdir))
		return 1

	for(var/obj/O in B)
		if(O.density && !istype(O, /obj/machinery/door) && !(O.flow_flags & ON_BORDER))
			return 1

	return 0

// Returns true if direction is blocked from loc
// Checks if doors are open
/proc/DirBlocked(turf/loc,var/dir)
	for(var/obj/structure/window/D in loc)
		if(!D.density)
			continue
		if(D.dir == SOUTHWEST)
			return 1 //full-tile window
		if(D.dir == dir)
			return 1 //matching border window

	for(var/obj/machinery/door/D in loc)
		if(!D.density)//if the door is open
			continue
		else
			return 1	// if closed, it's a real, air blocking door
	return 0

/////////////////////////////////////////////////////////////////////////

/atom/proc/make_astar_path(var/atom/target)
	var/list/L = AStar(get_turf(src), get_turf(target), /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, 30, 30)
	if(L)
		to_chat(world, "make astar path succeeded")
		pathfinders.Add(src)
		return L
	to_chat(world, "make astar path failed.")
	return FALSE

/atom/proc/process_astar_path()
	return FALSE

/atom/proc/drop_astar_path()
	pathfinders.Remove(src)