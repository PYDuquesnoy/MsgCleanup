# MsgCleanup
Interoperability Database Message Cleanup



## Introduction

This Utility scans the current IRIS Interoperability Namespace and liss Persistent Classes that may need to be cleaned up manually. 

It assumes all persistent entities in the namespace are Messages (or persistent classes referenced by messages whose lifecycle needs to be bound to a message lifecycle).

 It tries to match different cases:

1. Persistent Classes which have no Instances Referenced by Ens.MessageHeader. 
      Theses classes are probably referenced by other messages, and the referencing class needs to have a delete trigger.
2. Persistent Classes, which have some Instances not that are not directly referenced by Ens.MessageHeader
      Might be like case 1, or messages that have not been purged correctly.
3. Persistent Classes that use some persistent properties
      These classes  need to have a Delete Trigger that Purges the Persistent properties when this class is purged.

The List of "flagged" classes can then be reviewed by a SysAdmin & Developer to device further actions.

## Running the Code

### Unreferenced Persistent Classes

Run with:

```
do ##class(Alt.Msg.Scan).ListNotReferenced()
```

This lists all the Persistent Classes that have no instances referenced by Ens.MessageHeader. This coudl happen for different reasons:

* No message of this type has been sent.
* The Class is not used for Interoperability messages
* The Class is used in interoperability messages, but as part of other messages and thus not directly referenced by the Ens.MessageHeader class. In this case, instances of theses classes would not be automatically deleted by a Interoperability Message Purge.  It is necessary to manually define triggers to deleted the instances of these classes. The utility does not itself check that these triggers are defined. This list is more like a "review List" for the development team to check that all the required triggers are in place.



### Leftover instances in Persistent classes

Run with:

```
do ##class(Alt.Msg.Scan).ListLeftover(,0)
```

Note:  after reviewing the output, the second parameter can be set to 1 to force a delete.

This method Scans the content of Ens.MessageHeader to get a list of all the messages tat have been sent. For each message type detected, it verifies in the referenced class used for the MessageBody whether there are instances with Row Identifiers that have a value inferior to the lowest value not yet purged from Ens.MessageHeader. It returns a count of those instances for each MessageBody Classname.  



> Warning: This method assumes that the MessageBody classes defined use the Default IDKEY (Autonumeric and a Number) of IRIS. It should NOT be used if No default IDKeys/RowIds have been used for message classes.



### List Persistent Properties

Run with:

```
do ##class(Alt.Msg.Scan).ListPersistentProperties()
```

Scans all persistent classes of the namespace and for each, displays a list of all the properties that reference other persistent classes.

This list can be used for the Development team to verify if these classes are used in Interoperability messages and if a Trigger needs to be added to them for Message Purge to clean all the data as desired.
