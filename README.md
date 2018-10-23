# Chord

The implementation of the chord protocol in elixir using the Actor Model


#Group Information

Name: Ashwin Kalyana Kumar, UFID: 13517733
Name: Jinansh Rupesh Patel, UFID: 94318155 

## Installation

There is no need for installation.
To run the project on a machine that has Elixir and Mix, unzip the files and run the following
from the 'chord-master' folder

Sample Input: mix run start_script.exs 3000 10
The first argument is the number of nodes and the next argument is the number of messages sent by every node 

Sample Output: 

adding nodes in the order
[1481, 445, 2857, 2469, 2616, 2119, 2836, 95, 1353, 1009, 2567, 1768, 679, 1486,
 2050, 411, 352, 929, 1502, 482, 515, 1478, 1114, 2063, 1825, 2642, 1924, 1780,
 476, 2630, 2241, 57, 192, 2825, 990, 731, 1542, 2784, 1656, 1018, 174, 2641,
 508, 1824, 1988, 2868, 1850, 2278, 2216, 471, ...]
Average number of hops: 16.7911

This first prints the order in which the nodes are being added to the chord followed by the average number of hops.

## implementation:

for any given N. first the chord will be created with a single node, with all the keys.
Then we are joining the other nodes in the random order(which is printed in the beginning) to 
the chord one by one. Once every node is joined to the chord,
each node will send a message requesting for a key.

Each node will have a successor, a predecessor, a finger table and a list of 5 succcessors. 
The finger table and the list of 5 successors will be updated every 5 seconds for each node. Each node will also
stablize every 5 seconds. 

The hop count is calculated as the total number of hops for a message to be sent, delivered to the node which has the key,
and the response from the node, in the same path. So it is actually twice the number of hops for the message to 
reach the node which has the key requested for.


## what is working?


The create, join, stablize, fix_fingers, update_successor_list, sending and receiving a message, is working fine.
So basically everything in the paper is working. 
If n is very large, we are basically adding such a large amount of nodes to the chord and since 
the join is a costly operation it takes a lot of time to add the nodes to the chord

for 3000 nodes and 10 messages to be sent by each node, the total time taken was around 95 seconds and the average hop count was 16.80
the time taken to join all nodes and fix the finger table took around 85 seconds and the sending message took around 1-2 seconds. (we have 
a wait time of 10 seconds, before we terminate the entire process) 
There is a wait time of 5 milliseconds for each node to fix its finger table.
if we remove the sleep time when fixing the finger table of all the nodes, the total time taken is reduced to around 45 seconds
and joining and fixing the finger table took around 32-35 seconds. But we lost the optimal hop count as the average hop count increased to around 80 hops per message
this is because the messages are being sent before every node has its finger table fixed, hence the number of hops increases.
So we have the wait time in our code. ( in file node_super.ex, line# 101.)


## largest network we managed to deal with

The largest network we managed to deal with was with 10000 nodes and the average hop count for the same was 19.4480