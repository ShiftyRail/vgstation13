/*

	The TENSIONER, with antag datums

	Q: What is this ?
	A: The tensioner is a gamemode which reads the situation of the station as best as it can, and then picks a ruleset which will give the crew something to do.

	Q: How does this work ?
	A: There is a list of tensioner events whose role is to monitor many aspects of the round. 
	These events report a given tension value, as well as certain specific, unique flags.

	With this data (tension and flags) in hands, the tensioner will chose a ruleset to execute.

	Here is a list of existing "round monitors" :

	I. Mechanical modifications independant of round progression
	- Tension slowly decreases over time

	II. Count antagonists
	- Increases tension if there are active antags, depending on type, how long they've been here, where they are, etc.

	III. Job counters
	- Counts how many people there are on station who belong to a given departement.
	- Retruns tension if there's not enough jobs for a given thing

	IV. Prisonners
	- Increases tension if the brig cells are full

	V. Shootouts
	- Increases tension if people are shooting each other

	VI. Dead players count
	- Decreases tension if there's plenty of people in deadchat

	VII. Admin intervention
	- Periodically asks admins if there's not enoguh or too much tension

*/