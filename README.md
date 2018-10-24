# Chord

The implementation of the chord protocol in elixir using the Actor Model


#Group Information

Name: Ashwin Kalyana Kumar, UFID: 13517733
Name: Jinansh Rupesh Patel, UFID: 94318155 

## Installation

There is no need for installation.
To run the project on a machine that has Elixir and Mix, unzip the files and run the following
from the 'gossip' folder


Sample Output: 100,45359126

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

##Bonus part documentation

We selected r random nodes in the chord network and then sent a message to the process to voluntaruly terminate.
These nodes will inform its successor and predecessor that its leaving. It will also give its key list to its successor
the predecessor and successor will change their successor and predecessor respectively. the predecessor will also
update its successor list and finger table. 
when updating the successor list, if all five of the node's successor is gone, then the chord network is broken. Hence that particular node will
terminate too. This might cause additional uncaught errors to be raised. But whenever a chord node is broken, it will be printed that "Chord Ring Network is broken"

Below is the output for 10 nodes with 3 messages to be sent by each node. One node was deleted. (node 5). We are printing the final state of each node after everything was completed. 
WE can see that Node 6 got 2 keys and the successor and predecessor of 4 and 6 are updated. 

C:\Users\Jinansh\Desktop\UF Study\DOS\Projects\Project 3\chord-master>iex -S mix
Compiling 1 file (.ex)
Interactive Elixir (1.7.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> Chord.main(10,3)
adding nodes in the order
[1, 8, 4, 2, 5, 6, 3, 7, 10, 9]
Average number of hops: 4.666666666666667
Printing 1
%NodeStruct{
  finger_table: [{2, nil}, {3, nil}, {5, nil}, {9, nil}],
  fingure_table_new: %{
    2 => #PID<0.140.0>,
    3 => #PID<0.143.0>,
    5 => #PID<0.141.0>,
    9 => #PID<0.146.0>
  },
  forward_table: %{
    {1, 1} => #PID<0.137.0>,
    {1, 2} => #PID<0.137.0>,
    {1, 3} => #PID<0.137.0>
  },
  id: 1,
  keys: [1],
  number_of_messages: 0,
  parent_pid: #PID<0.134.0>,
  pred_id: 10,
  predecessor: #PID<0.145.0>,
  succ_id: 2,
  successor: #PID<0.140.0>,
  supervisorList: [{2, #PID<0.140.0>}, {3, nil}, {4, nil}, {5, nil}, {6, nil}]
}
Printing 8
%NodeStruct{
  finger_table: [{9, nil}, {10, nil}],
  fingure_table_new: %{9 => #PID<0.146.0>, 10 => #PID<0.145.0>},
  forward_table: %{
    {8, 1} => #PID<0.138.0>,
    {8, 2} => #PID<0.138.0>,
    {8, 3} => #PID<0.138.0>
  },
  id: 8,
  keys: '\b',
  number_of_messages: 0,
  parent_pid: #PID<0.134.0>,
  pred_id: 7,
  predecessor: #PID<0.144.0>,
  succ_id: 9,
  successor: #PID<0.146.0>,
  supervisorList: [{9, #PID<0.146.0>}, {10, nil}, {1, nil}, {2, nil}, {3, nil}]
}
Printing 4
%NodeStruct{
  finger_table: [{5, nil}, {6, nil}, {8, nil}],
  fingure_table_new: %{
    5 => #PID<0.141.0>,
    6 => #PID<0.142.0>,
    8 => #PID<0.138.0>
  },
  forward_table: %{
    {4, 1} => #PID<0.139.0>,
    {4, 2} => #PID<0.139.0>,
    {4, 3} => #PID<0.139.0>
  },
  id: 4,
  keys: [4],
  number_of_messages: 0,
  parent_pid: #PID<0.134.0>,
  pred_id: 3,
  predecessor: #PID<0.143.0>,
  succ_id: 6,
  successor: #PID<0.142.0>,
  supervisorList: [
    {6, #PID<0.142.0>},
    {7, #PID<0.144.0>},
    {8, nil},
    {9, nil},
    {10, nil}
  ]
}
Printing 2
%NodeStruct{
  finger_table: [{3, nil}, {4, nil}, {6, nil}, {10, nil}],
  fingure_table_new: %{
    3 => #PID<0.143.0>,
    4 => #PID<0.139.0>,
    6 => #PID<0.142.0>,
    10 => #PID<0.145.0>
  },
  forward_table: %{
    {2, 1} => #PID<0.140.0>,
    {2, 2} => #PID<0.140.0>,
    {2, 3} => #PID<0.140.0>
  },
  id: 2,
  keys: [2],
  number_of_messages: 0,
  parent_pid: #PID<0.134.0>,
  pred_id: 1,
  predecessor: #PID<0.137.0>,
  succ_id: 3,
  successor: #PID<0.143.0>,
  supervisorList: [{3, #PID<0.143.0>}, {4, nil}, {5, nil}, {6, nil}, {7, nil}]
}
Printing 6
%NodeStruct{
  finger_table: [{7, nil}, {8, nil}, {10, nil}],
  fingure_table_new: %{
    7 => #PID<0.144.0>,
    8 => #PID<0.138.0>,
    10 => #PID<0.145.0>
  },
  forward_table: %{{6, 1} => #PID<0.142.0>, {6, 3} => #PID<0.142.0>},
  id: 6,
  keys: [6, 5],
  number_of_messages: 0,
  parent_pid: #PID<0.134.0>,
  pred_id: 4,
  predecessor: #PID<0.139.0>,
  succ_id: 7,
  successor: #PID<0.144.0>,
  supervisorList: [{7, #PID<0.144.0>}, {8, nil}, {9, nil}, {10, nil}, {1, nil}]
}
Printing 3
%NodeStruct{
  finger_table: [{4, nil}, {5, nil}, {7, nil}],
  fingure_table_new: %{
    4 => #PID<0.139.0>,
    5 => #PID<0.141.0>,
    7 => #PID<0.144.0>
  },
  forward_table: %{
    {3, 1} => #PID<0.143.0>,
    {3, 2} => #PID<0.143.0>,
    {3, 3} => #PID<0.143.0>
  },
  id: 3,
  keys: [3],
  number_of_messages: 0,
  parent_pid: #PID<0.134.0>,
  pred_id: 2,
  predecessor: #PID<0.140.0>,
  succ_id: 4,
  successor: #PID<0.139.0>,
  supervisorList: [
    {4, #PID<0.139.0>},
    {5, #PID<0.141.0>},
    {6, nil},
    {7, nil},
    {8, nil}
  ]
}
Printing 7
%NodeStruct{
  finger_table: [{8, nil}, {9, nil}],
  fingure_table_new: %{8 => #PID<0.138.0>, 9 => #PID<0.146.0>},
  forward_table: %{
    {7, 1} => #PID<0.144.0>,
    {7, 2} => #PID<0.144.0>,
    {7, 3} => #PID<0.144.0>
  },
  id: 7,
  keys: '\a',
  number_of_messages: 0,
  parent_pid: #PID<0.134.0>,
  pred_id: 6,
  predecessor: #PID<0.142.0>,
  succ_id: 8,
  successor: #PID<0.138.0>,
  supervisorList: [
    {8, #PID<0.138.0>},
    {9, #PID<0.146.0>},
    {10, nil},
    {1, nil},
    {2, nil}
  ]
}
Printing 10
%NodeStruct{
  finger_table: [{1, nil}],
  fingure_table_new: %{1 => #PID<0.137.0>},
  forward_table: %{
    {10, 1} => #PID<0.145.0>,
    {10, 2} => #PID<0.145.0>,
    {10, 3} => #PID<0.145.0>
  },
  id: 10,
  keys: '\n',
  number_of_messages: 0,
  parent_pid: #PID<0.134.0>,
  pred_id: 9,
  predecessor: #PID<0.146.0>,
  succ_id: 1,
  successor: #PID<0.137.0>,
  supervisorList: [
    {1, #PID<0.137.0>},
    {2, #PID<0.140.0>},
    {3, nil},
    {4, nil},
    {5, nil}
  ]
}
Printing 9
%NodeStruct{
  finger_table: [{10, nil}],
  fingure_table_new: %{10 => #PID<0.145.0>},
  forward_table: %{
    {9, 1} => #PID<0.146.0>,
    {9, 2} => #PID<0.146.0>,
    {9, 3} => #PID<0.146.0>
  },
  id: 9,
  keys: '\t',
  number_of_messages: 0,
  parent_pid: #PID<0.134.0>,
  pred_id: 8,
  predecessor: #PID<0.138.0>,
  succ_id: 10,
  successor: #PID<0.145.0>,
  supervisorList: [
    {10, #PID<0.145.0>},
    {1, #PID<0.137.0>},
    {2, #PID<0.140.0>},
    {3, nil},
    {4, nil}
  ]
}


We tested our code with 100 nodes and the chord node was stable and the messages were getting delivered successfully until 98 nodes failed.
There was only 2 nodes that was alive but they had all the keys in the node and the messages were still getting deliver
Below is the output for the same. We can also see that the average hop count is 1.0, as there are only 2 nodes in the network active.


C:\Users\Jinansh\Desktop\UF Study\DOS\Projects\Project 3\chord-master>iex -S mix
Compiling 1 file (.ex)
Interactive Elixir (1.7.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> Chord.main(100,3)
adding nodes in the order
[84, 57, 44, 17, 10, 77, 6, 71, 12, 90, 68, 65, 20, 67, 55, 50, 37, 75, 96, 9,
 56, 14, 26, 45, 60, 54, 40, 81, 63, 92, 76, 28, 30, 70, 99, 89, 24, 69, 23, 21,
 48, 29, 32, 16, 46, 19, 43, 22, 51, 88, ...]
Although the supervisor list has dangling pointers, they will never be visited. 

This is a complete implementation of the chord protocol and is very flexible. 

This does not work with one single node in the network, as with one node, it will not be a chord ring.
But our code works with only 2 nodes. 

The number of nodes to be removed can be updated here:

file: chord.ex line# 64
spawn_link(fn -> NodeSuper.vol_die(n,98) end)
                      ^ <- put the number of nodes to be deleted here