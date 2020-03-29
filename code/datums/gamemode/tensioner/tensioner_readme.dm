/*

	The TENSIONER, with antag datums

	Q: What is this ?
	A: The tensioner is a gamemode which reads the situation of the station as best as it can, and then picks a ruleset which will give the crew something to do.

	Q: How does this work ?
	A: There is a list of tensioner events whose role is to monitor many aspects of the round. 
	These events report a given tension value, as well as certain specific, unique flags.

	With this data (tension and flags) in hands, the tensioner will chose a ruleset to execute.

	Here is a list of existing "round monitors" :

		- ...

*/