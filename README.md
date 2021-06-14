# MsgCleanup
Interoperability Database Message Cleanup


This Utility scans the current IRIS Interoperability Namespace and list Persitent Classes that may need to be cleaned up manually. It assumes all persistent entities in the namespace are Messages (or pertistente clases referenced by messages whose lifecycle needs to be bound to a message lifecycle). It tries to match different cases:
1- Persistent Clases which have no Instances Referenced by Ens.MessageHeader. 
   Theses classes are probably referenced by other messages, and the referencing class needs to have a delete trigger.
2- Persistent Classes, which have some Intances not that are not directly referenced by Ens.MessageHeader
   Might be like case 1, or messages that have not been purge correctly.
3- Persistent Classes that use some persistent properties
   They need to have a Delete Trigger that Purges the Persistent properties when this class is purged.
  
  
The Lisf of "flagged" classes can then be reviewed by a SysAdmin & Developer to device furthger actions.
