/************ MC404C, Giuliano Sider, RA 146271, 20/10/2015 *************
*** Atividade Desafio 2: biblioteca para gerenciar lista ligadas (alocadas estaticamente)
*** e programa teste para usá-las.

STRUCTURE OF PROGRAM:
The "main user input loop" implements the "LinkedListManager test application".
The "LinkedListManager test application" depends on "Linked List library of functions"
and also uses the "Memory Free Store Service", specifically the service for 
retrieving/returning a linked list header with a unique identifier.
The "Linked List library of functions" depends on "Memory Free Store Service."
The majority of the code (from main to about line 430) handles the user interface of the
test application. The FreeStore service and the library of linked list functions
occupy the last 200 lines or so. The linked lists used are (ordered) "XOR linked lists",
a curious variation of the garden variety singly linked list (with a header node that has
1. a list tail pointer, 2. a list head pointer, where both are NULL==0 if the list is empty).
The headers are obtained from a different freestore than the list nodes, even though they
really have the same memory layout. The reason is so that they possess a unique id used
by the test application. The XOR linking endows the user with the ability to traverse a
singly linked list in both directions! 

typedef struct XORList {
	int key;
	int np; // np = addr_predecessor_node XOR addr_successor_node 
} XORList;

In the case of the header, the "key" really is a pointer to the tail (so that we could
traverse starting from the tail if desired). The predecessor of the header is NULL==0.
The price to pay: 1. slightly more calculation involved, 2. except for the header and tail,
we must know the address of two adjacent nodes (any nodes) for us to go anywhere. Consult
Cormem, Leierson, Rivest, Stein, 3rd ed., p. XYZ, exercise AB, for the source of inspiration.

The static FreeStores where data is obtained are linked lists themselves, with the same
memory layout. A sentinel node with a NULL next pointer signals an empty list. The keys of
the nodes in the list header freestore contain a unique id for the list (used by the application).

The user interface subroutines are self-documenting; see below for the library functions.
NOTE: inter procedure etiquette: subs clobber r0-r3, r12 (in general, but not necessarily).
All others are callee-saved (ARM convention). Registers parameter are r0, r1, ...
input and output arguments are placed in those registers
in the same order given by the function signature.

FUNCTION: XORLinkedListPrint: @ void XORLLPrint( List * header)
INPUT: r0 = > pointer to header of the XOR linked list
OUTPUT: 
SIDE EFFECTS: Prints keys to stdout or <empty> if the the list is empty
NOTE: 

FUNCTION: LinkedListPrint: @ void LLPrint( List * header)
INPUT: r0 = > pointer to header of the linked list
OUTPUT: 
SIDE EFFECTS: Prints keys to stdout
NOTE: this is for printing the freestores, which are not XOR linked

FUNCTION: LinkedListDeleteNodes: @ void LLD(List* header)
INPUT: r0 = > pointer to header of the linked list
OUTPUT: 
SIDE EFFECTS: takes a list header and deletes all the nodes (but not the header)
NOTE: used before deleting a list (header)

FUNCTION: LinkedListDeleteNext: @ LLDNext(List *header, List *current, List *next) // deletes next node
INPUT: r0 = > pointer to header of the linked list, r1 = > pointer to list node
       r2 = > pointer to node after the one in r1.
OUTPUT: 
SIDE EFFECTS: Deletes the 'next' node, returning it to the list node freestore
NOTE: the header is necessary only to update the tail pointer, if we deleted the tail
of the list. if our application doesn't need tail access in the header, it could change the
implementation.

FUNCTION: LinkedListFindKey: @ LLFKey(List *list, int key)
INPUT: r0 = > pointer to header of the linked list, r1 = > 32 bit integer key
OUTPUT: r0 = > 0 when key belongs to the list, -1 otherwise
SIDE EFFECTS: 
NOTE: 

FUNCTION: LinkedListInsertKey: @ LLIKey(List *list, int key)
INPUT: r0 = > pointer to header of the linked list, r1 = > 32 bit integer key
OUTPUT: r0 = > 0 if key was successfully inserted in the list, -1 otherwise
SIDE EFFECTS: Inserts key in its proper place (non-decreasing order) in the
ordered XOR linked list.
NOTE: Two reasons for failure: 1. empty list node free store, 2. key already
belongs to list. User must query the freestore to find out.

@ call LLINext(List *header, List *current, List *next, int key) returns ptr to newnode
FUNCTION: LinkedListInsertNext: LLINext(List *header, List *current, List *next, int key)
INPUT: r0 = > pointer to header of the linked list, r1 = > pointer to list node
       r2 = > pointer to node after the one in r1, r3 = > 32 bit signed integer key
OUTPUT: r0 = > returns pointer to the node newly created (obtained from list node freestore),
		or NULL if unsuccessful.
SIDE EFFECTS: inserts a new node with key, between current and next nodes of the list
NOTE: header, again, is only necessary for updating the tail pointer (if we insert there)

FUNCTION: LinkedListRemoveKey: @ LLRKey(List *list, int key)
INPUT: r0 = > pointer to header of the linked list, r1 = > 32 bit signed integer key
OUTPUT: r0 = > 0 if successful, -1 otherwise
SIDE EFFECTS: Deletes the node with key from the list, returning it to the freestore.
NOTE: It assumes, like the other routines, that the list is in increasing order. If the
key is not found, it returns unsuccessfully.

FUNCTION: LinkedListFindKeyPosition: @ FKPosition(List *l, int key)
INPUT: r0 = > pointer to header of the linked list, r1 = > 32 bit signed integer key
OUTPUT: r0 = > predecessor node, r1 = > next node
SIDE EFFECTS: returns addresses of the list node that is bigger than or equal to a key,
			  and its preceding element in an XOR linked list.
NOTE: it effectively returns the tail of the list and NULL if the key is not found

FUNCTION: FreeStoreRetrieve: @ List* FreeStoreRetrieve(List **freestorehead) : returns allocated list, or NULL if there is no space
INPUT: r0 = > pointer to the address of a freestore of lists
OUTPUT: r0 = > pointer to newly allocated element, or NULL if the freestore is empty.
SIDE EFFECTS: Sets the head of the freestore to the next available element.
NOTE: can be used for both list node and list header freestores: same structure

FUNCTION: FreeStoreReturn: @ void FSR(List** FSHead, List* l)
INPUT: r0 = > pointer to the address of a freestore of lists, r1 = > pointer to list element
OUTPUT: 
SIDE EFFECTS: Clobbers r0-r3, r12, as per the ARM calling convention.
NOTE: can be used for both list node and list header freestores: same structure. But when
using the list header freestore in this application, the user should return the unique id
to the key attribute of the returned list header.

FUNCTION: IsListFreeStoreEmpty: @ ILFSEmpty (List **freestorehead), returns 1 if FS is empty, 0 otherwise
INPUT: r0 = > pointer to the address of a freestore of lists
OUTPUT: r0 = > 1 if freestore is empty, 0 otherwise
SIDE EFFECTS:
NOTE: 

*************************************************************************/

.syntax unified
.text
.global main
.align

main:
push { lr }
	ldr r0, =WelcomeMsg
	ldr r1, =UsageMsg @ command cheat sheet for the application
	bl printf
	//bl InitLinkedListManager @ prepares an array which initially stores empty lists
QueryUser:
	mov r0, 0x3e @ prompt character: '>'
	bl putchar
	ldr r0, =QueryString1 @ get first letter of user command
	ldr r1, =UserCommand @ scanf stores command here
	bl scanf
	cmp r0, 1 @ scanf should return 1 for the character specifier read
	bne InputError
	ldr r1, =UserCommand @ get user command that was stored by scanf
	ldr r1, [r1]
	ldr r2, =BranchTable @ address of table of branches for the menu
	ldr lr, =QueryUser @ return to QueryUser when whatever branch is done
	add lr, 1 @ must set the THUMB bit
	tbh [r2, r1, lsl 1] @ load the appropriate jump address to handle the user's command (directly addressed by ascii code)

/******************* LinkedListManager test module functions *********************/
Quit:
	ldr r0, =GoodbyeMsg
	bl printf
	mov r0, 0
bl exit

CreateList: @ creates an empty list and returns its identifier (index to be used in our application array)
push { lr }
	ldr r0, =ListHeaderFreeStoreHead @ retrieve a header (comes with a unique id) for a new list
	bl FreeStoreRetrieve @ same function for both types of freelist we use in this application: they have the same structure
	cbz r0, ListFreeStoreIsEmpty // if it returns NULL then there is no space for a new list
	mov r2, 0
	str r2, [r0, 4] @ new_list->head = NULL @ list is empty
	ldr r1, [r0] @ load unique id of list (stored in first position)
	ldr r3, =ArrayOfLists
	str r0, [r3, r1, lsl 2] @ ArrayOfLists[list_id] = &new_list
	str r2, [r0] @ new_list->tail = NULL @ list is empty
	ldr r0, =CreateListMsg
	push { r1 } @ keep list id for return value
	bl printf @ print success message along with list_id (r1) for the user
	pop { r1 }
	mov r0, r1 @ return list id
	pop { pc }
ListFreeStoreIsEmpty:
	ldr r0, =NoSpaceForListMsg
	ldr r1, MaxLists @ print the max number of lists set at compile time
	bl printf
	mov r0, -1 @ return unsuccessful signal
pop { pc }

DeleteList: @ takes the id of list to delete from standard input and deletes it
push { r6-r7, lr }
	bl ObtainUserInputList @ get validated list id from user (in r0)
	cmp r0, 0 @ if it returns a negative value, list doesn't exist
	blt ListDoesNotExist
	ldr r2, =ArrayOfLists
	ldr r6, [r2, r0, lsl 2] @ r6 = ArrayOfLists[list_id] (ptr to list header here)
	cbz r6, ListDoesNotExist @ null pointer means there is no list there
	mov r3, 0
	str r3, [r2, r0, lsl 2] @ ArrayOfLists[list_id] = 0 (no more list)
	mov r7, r0 @ save index here so we can print it later
	mov r0, r6 @ call LinkedListDeleteNodes(listheader) from linked list library
	bl LinkedListDeleteNodes @ empties list, leaving only the header
	str r7, [r6] @ first field of list header receives id (for the list header freestore service used in this application)
	ldr r0, =ListHeaderFreeStoreHead @ FreeStoreReturn(fs_head, listheader)
	mov r1, r6 @ return list header to our application's list header free store (with its unique id back in place)
	bl FreeStoreReturn @ from the freestore thou cometh, to the freestore thou shalt return
	ldr r0, =DeleteListMsg
	mov r1, r7 @ index of list that was deleted
	bl printf
	pop { r6-r7, pc }
ListDoesNotExist:
	ldr r0, =ListDoesNotExistMsg
	bl printf
pop { r6-r7, pc }

SearchList:
push { r4-r6, lr }
	bl ObtainUserInputList
	cmp r0, 0 @ if it returns a negative value, list doesn't exist
	blt ListDoesNotExist2
	ldr r2, =ArrayOfLists
	ldr r5, [r2, r0, lsl 2] @ r5 = ArrayOfLists[list_id] (ptr to list header here)
	cbz r5, ListDoesNotExist2 @ null pointer means there is no list there
	mov r4, r0 @ keep the list index here
	bl ObtainUserInputKey
	mov r6, r0 @ keep key here
	mov r1, r0
	mov r0, r5 @ call LinkedListFindKey(list, key)
	bl LinkedListFindKey
	cmp r0, 0
	ite eq
	ldreq r0, =SuccessfulSearchListMsg
	ldrne r0, =UnSuccessfulSearchListMsg
	mov r1, r6 @ print key
	mov r2, r4 @ print list index, FYI
	bl printf
	pop { r4-r6, pc }
ListDoesNotExist2: 
	ldr r0, =ListDoesNotExistMsg
	bl printf
pop { r4-r6, pc }

GenerateRandList:
push { r4-r6, lr }
	bl ObtainUserInputKey
	cmp r0, 0
	ble UnSuccessfulGenerateRandList @ must be a valid number of keys!
	mov r5, r0 @ keep number of keys to generate here
	bl CreateList
	cmp r0, 0 @ negative value means no list was created
	blt UnSuccessfulGenerateRandList
	ldr r2, =ArrayOfLists
	ldr r4, [r2, r0, lsl 2] @ load r4 = ArrayOfLists[list id] (contains ptr to list header)
	mov r6, r0 @ list id kept here
GenerateMoreRandKeys:
	mov r0, 0
	mov r1, 1 << 16 @ range of keys
	bl RandInt @ int RandInt(lower bound, upper bound)
	mov r1, r0
	mov r0, r4
	bl LinkedListInsertKey @ call LLIKey( listheader, key )
	subs r5, 1
	bne GenerateMoreRandKeys @ still more keys to generate and insert
	ldr r0, =GenerateRandListMsg
	mov r1, r6 @ print list id for user
	bl printf
UnSuccessfulGenerateRandList:
pop { r4-r6, pc }

HelpUser:
push { lr }
	ldr r0, =UsageMsg
	bl printf
pop { pc }

InsertKey:
push { r4-r6, lr }
	bl ObtainUserInputList
	cmp r0, 0 @ if it returns a negative value, list doesn't exist
	blt ListDoesNotExist3
	ldr r2, =ArrayOfLists
	ldr r5, [r2, r0, lsl 2] @ r5 = ArrayOfLists[list_id] (ptr to list header here)
	cbz r5, ListDoesNotExist3 @ null pointer means there is no list there
	mov r4, r0 @ keep the list index here
	bl ObtainUserInputKey
	mov r6, r0 @ keep key here
	mov r1, r0
	mov r0, r5 @ call LinkedListFindKey(list, key)
	bl LinkedListInsertKey
	cbnz r0, UnSuccessfulInsertKey @ LLIKey returns zero on successful insertion
	ldr r0, =SuccessfulInsertKeyMsg
	b PrintInsertKeyMsg
UnSuccessfulInsertKey:
	ldr r0, =ListNodeFreeStoreHead
	bl IsListFreeStoreEmpty
	cmp r0, 1 @ it returns 1 if free store is empty, 0 otherwise
	ite eq
	ldreq r0, =FreeStoreEmptyOnInsertionMsg
	ldrne r0, =KeyAlreadyInListMsg @ only other possibility for failure to insert key
PrintInsertKeyMsg:
	mov r1, r6 @ print key
	mov r2, r4 @ print list index, FYI
	bl printf
	pop { r4-r6, pc }
ListDoesNotExist3:
	ldr r0, =ListDoesNotExistMsg
	bl printf
pop { r4-r6, pc }

ShowLists:
push { r4-r7, lr }
	ldr r4, =ArrayOfLists
	mov r5, 0 @ index to the array of list header pointers
	ldr r7, MaxLists
ShowListsLoop:
	cmp r5, r7
	bge DoneShowLists
	ldr r6, [r4, r5, lsl 2] @ r6 = ArrayOfLists[i] (contains pointer to list)
	cbz r6, ShowNextList @ if NULL, increment index and try to show the next list
	ldr r0, =ShowListsMsg
	mov r1, r5 
	bl printf @ showing list i 
	mov r0, r6
	bl XORLinkedListPrint @ LLPrint(List *listheader)
	mov r0, '\n'
	bl putchar
ShowNextList:
	add r5, 1 @ look at
	b ShowListsLoop
DoneShowLists:
pop { r4-r7, pc }

MemoryMap:
push { lr }
	ldr r0, =MemoryMapMsg1
	ldr r1, =ListHeaderFreeStoreHead
	ldr r1, [r1] @ load the address of the free store head
	ldr r2, [r1] @ id of list header
	ldr r3, [r1, 4] @ next pointer of list header
	bl printf
	ldr r0, =ListHeaderFreeStoreHead
	ldr r0, [r0] @ load the address of the free store head
	bl LinkedListPrint @ call LLPrint(List *list)
	ldr r0, =MemoryMapMsg2
	ldr r1, =ListNodeFreeStoreHead
	ldr r1, [r1] @ load the address of the free store head
	ldr r2, [r1] @ content of list header
	ldr r3, [r1, 4] @ next pointer of list header
	bl printf
	ldr r0, =ListHeaderFreeStoreHead
	ldr r0, [r0] @ load the address of the free store head
	bl LinkedListPrint @ call LLPrint(List *list)
pop { pc }

PrintList:
push { r5, lr }
	bl ObtainUserInputList
	cmp r0, 0 @ if it returns a negative value, list doesn't exist
	blt ListDoesNotExist5
	ldr r2, =ArrayOfLists
	ldr r5, [r2, r0, lsl 2] @ r5 = ArrayOfLists[list_id] (ptr to list header here)
	cbz r5, ListDoesNotExist5 @ null pointer means there is no list there
	mov r1, r0 @ print list index
	ldr r0, =PrintListMsg
	bl printf
	mov r0, r5
	bl XORLinkedListPrint @ XORLLPrint(List *header)
	pop { r5, pc }
ListDoesNotExist5:
	ldr r0, =ListDoesNotExistMsg
	bl printf
pop { r5, pc }

RemoveKey:
push { r4-r6, lr }
	bl ObtainUserInputList
	cmp r0, 0 @ if it returns a negative value, list doesn't exist
	blt ListDoesNotExist4
	ldr r2, =ArrayOfLists
	ldr r5, [r2, r0, lsl 2] @ r5 = ArrayOfLists[list_id] (ptr to list header here)
	cbz r5, ListDoesNotExist4 @ null pointer means there is no list there
	mov r4, r0 @ keep the list index here
	bl ObtainUserInputKey
	mov r6, r0 @ keep key here
	mov r1, r0
	mov r0, r5 @ call LinkedListFindKey(list, key)
	bl LinkedListRemoveKey @ returns 0 upon success, -1 if key not in list
	cmp r0, 0
	ite eq
	ldreq r0, =SuccessfulRemoveKeyMsg
	ldrne r0, =UnSuccessfulRemoveKeyMsg
	mov r1, r6 @ print key
	mov r2, r4 @ print list index, FYI
	bl printf
	pop { r4-r6, pc }
ListDoesNotExist4:
	ldr r0, =ListDoesNotExistMsg
	bl printf
pop { r4-r6, pc }

InputError:
push { lr }
	ldr r0, =InputErrorMsg
	bl printf
pop { pc }

InputErrorMsg: .asciz "bad command. press 'h' to view USAGE message\n"
SuccessfulRemoveKeyMsg: .asciz "Key %i successfully removed in list %i\n"
UnSuccessfulRemoveKeyMsg: .asciz "Key %i does not belong to list %i\n"
PrintListMsg: .asciz "Printing list %i\n"
MemoryMapMsg1: .asciz "Showing list header free store\nHeader at %08X with id %i and next pointer %08X\n"
MemoryMapMsg2: .asciz "Showing list node free store\nHeader at %08X with content %i and next pointer %08X\n"
ShowListsMsg: .asciz "Showing list %i:\n"
SuccessfulInsertKeyMsg: .asciz "Key %i successfully inserted in list %i\n"
FreeStoreEmptyOnInsertionMsg: .asciz "Could not insert key %i in list %i because list node freestore is empty\n"
KeyAlreadyInListMsg: .asciz "Could not insert key %i in list %i because key already belongs to list\n"
GenerateRandListMsg: .asciz "Generated random list with id %i\n"
SuccessfulSearchListMsg: .asciz "The key %i was found in the list %i\n"
UnSuccessfulSearchListMsg: .asciz "The key %i was not found in list %i\n"
DeleteListMsg: .asciz "Deleting list number %i\n"
ListDoesNotExistMsg: .asciz "The list you have requested does not exist. press 'l' for a full listing\n"
CreateListMsg: .asciz "Creating new list with id %i\n"
NoSpaceForListMsg: .asciz "There is not enough space for a new list: maximum of %i reached. delete a list and try again\n"
ListOutOfBoundsMsg: .asciz "The list id you have provided is out of bounds for this application\n"
PrintEmptyList: .asciz "<empty>\n"
PrintListKeyStr: .asciz "%i "
QueryString1: .asciz " %c" @ read command character
NumericArgumentInputString: .asciz " %i" @ read second part of command, if applicable
WelcomeMsg: .asciz "Welcome to Linked List Manager Live\n\n%s"
GoodbyeMsg: .asciz "Thank you for using LinkedListManager\nHave a good\n"
UsageMsg: .ascii "USAGE: (all lower case letters)\n"
			.ascii "\tTo create a new list:      c\n"
			.ascii "\tTo delete a list:          d <list>\n"
			.ascii "\tTo find a key in a list:   f <list> <key>\n"
			.ascii "\tTo generate a random list: g <number of keys>\n"
			.ascii "\tTo show this help menu:    h OR ?\n"
			.ascii "\tTo insert a key:           i <list> <key>\n"
			.ascii "\tTo show all active lists:  l\n"
			.ascii "\tTo dump memory contents :  m\n"
			.ascii "\tTo print a list:           p <list>\n"
			.ascii "\tTo quit:                   q\n"
			.asciz "\tTo remove a key:           r <list> <key>\n\n"

BranchTable: @ jump table with addresses to be loaded directly to PC based on
				@ ascii value of user input character that denotes user command
	@ c,   d    f    h    i    l    m     p    q    r    ?    are the commands
	@ 0x63 0x64 0x66 0x68 0x69 0x6c 0x6d  0x70 0x71 0x72 0x3f
	@ 99   100  102  104  105  108  109   112  113  114  63
// Quit is the first branch. TBH jumps by an offset of twice the value in the table.
.rept '?' @ until we get to '?''
	.hword (InputError-Quit)/2 @ invalid command in this range of ascii
.endr
.hword (HelpUser-Quit)/2 @ '?' command
.rept ('c' - '?' - 1) @ until we get to 'c'
	.hword (InputError-Quit)/2
.endr
@ 'c' command, d' command, 'e', 'f' command, 'g' command, 'h' command, 'i' command
.hword (CreateList-Quit)/2, (DeleteList-Quit)/2, (InputError-Quit)/2, (SearchList-Quit)/2
.hword (GenerateRandList-Quit)/2, (HelpUser-Quit)/2 , (InsertKey-Quit)/2 
.rept ('l'-'i'-1) @ until we get to 'l'
	.hword (InputError-Quit)/2
.endr
.hword (ShowLists-Quit)/2, (MemoryMap-Quit)/2  @ 'l' command
.rept ('p'-'m'-1) @ until we get to 'p'
	.hword (InputError-Quit)/2
.endr
.hword (PrintList-Quit)/2, 0, (RemoveKey-Quit)/2 @ 'p' command, 'q' command, 'r' command
.rept (255-'r') @ cover the remaining ascii characters
	.hword (InputError-Quit)/2
.endr

/******************** application helper functions: *********************/

.macro addlinebreak @ clobbers r0-r3, r12, courtesy of ARM calling convention
	mov r0, '\n'
	bl putchar
.endm

.align
RandInt: @ int RandInt(int low_bound, int high_bound) @ recycled/imported from qsort!
range .req r1 @ return a (uniformly) distributed integer in the range [low_bound, high_bound]
q .req r2
low_bound .req r5
high_bound .req r6
push { r4-r6, lr }
	mov low_bound, r0 @ low_bound == r5, high_bound == r6 (both defined above at qsort)
	mov high_bound, r1
	bl rand @ 32 bit (pseudo) random integer at r0
	sub range, high_bound, low_bound
	add range, 1 @ high_bound - low_bound + 1 is the size of desired interval
	udiv q, r0, range @ q = floor ( rnd / range ). REFRESHER: UDIV {Rd}, Rm, Rn. Rd := Rm / Rn
	mls r0, q, range, r0 @ rnd - q*range = remainder. REFRESHER: MLS {Rd}, Rm, Rn, Ra. Rd := Ra - Rm*Rn
	add r0, low_bound @ now r0 has an integer plucked from a uniform [low_bound, high_bound] distribution
pop { r4-r6, pc }

ObtainUserInputList: @ returns in r0 a valid (within bounds) list id obtained from user
push { lr }
	ldr r0, =NumericArgumentInputString @ read one integer (list number)
	ldr r1, =UserArgument @ store user's list id here
	bl scanf
	ldr r0, =UserArgument @ we'll validate user input (check if within bounds)
	ldr r0, [r0] @ list id left in r0 for return	
	ldr r2, MaxLists
	cmp r0, r2 @ is the user's list id in the range [0, MaxLists) ?
	bhs OutOfBoundsList @ get >= to MaxLists and negative values in one swoop
	pop { pc }
OutOfBoundsList:
	ldr r0, =ListOutOfBoundsMsg
	bl printf
	mov r0, -1 @ signal error
pop { pc }

ObtainUserInputKey:
push { lr }
	ldr r0, =NumericArgumentInputString
	ldr r1, =(UserArgument+4) @ user argument #2
	bl scanf
	ldr r0, =(UserArgument+4)
	ldr r0, [r0]
pop { pc } @ return the key we have obtained from stdin (no validation is necessary)

/********************** MY LINKED LIST LIBRARY FUNCTIONS *********************/

XORLinkedListPrint: @ XORLLPrint( List * header)
push { r4-r6, lr }
	ldr r4, [r0, 4] @ load the np (always next for the header) pointer
	cbz r4, XORLinkedListPrintEmpty
	mov r5, r0 @ keep current node here
XORLinkedListPrintLoop:
	cbz r4, XORLinkedListPrintDone @ when next is NULL we are done
	ldr r2, [r4, 4] @ load next.np
	eor r6, r2, r5 @ afternext = next.np XOR current
	ldr r0, =PrintListKeyStr
	ldr r1, [r4] @ load next node's key for printing
	bl printf
	mov r5, r4 @ next becomes current
	mov r4, r6 @ afternext becomes next
	b XORLinkedListPrintLoop
XORLinkedListPrintDone:
	addlinebreak @ calls putchar('\n')
	pop { r4-r6, pc }
XORLinkedListPrintEmpty:
	ldr r0, =PrintEmptyList
	bl printf
pop { r4-r6, pc }

LinkedListPrint: @ LLPrint( List * header) @ this is for printing the freestores, which are not XOR linked
push { r4-r6, lr }
	ldr r4, [r0, 4] @ load the np (always next for the header) pointer
	mov r5, r0 @ keep current node here
LinkedListPrintLoop:
	cbz r4, LinkedListPrintDone @ when next is NULL we are done
	ldr r6, [r4, 4] @ load afternext = next.next_ptr
	ldr r0, =PrintListKeyStr
	ldr r1, [r4] @ load next node's key for printing
	bl printf
	mov r5, r4 @ next becomes current
	mov r4, r6 @ afternext becomes next
	b LinkedListPrintLoop
LinkedListPrintDone:
	addlinebreak @ calls putchar('\n')
pop { r4-r6, pc }

LinkedListDeleteNodes: @ void LLD(List* header) : takes a list header and deletes all the nodes (not the header)
push { r4-r5, lr }
	mov r4, r0 @ r4 = header (which is not NULL)
EmptyOutLinkedList:
	ldr r5, [r4, 4] @ load next node pointer (not an 'np' value for header)
	cbz r5, FinishedLinkedListDeleteNodes @ we are done: next is NULL
	mov r0, r4 @ header
	mov r1, r4 @ header is the current node in our calls to LLDNext here
	mov r2, r5 @ next node is the one to be deleted
	bl LinkedListDeleteNext @ LLDNext(header, header, next) @ deletes next node
	b EmptyOutLinkedList
FinishedLinkedListDeleteNodes:
pop { r4-r5, pc }

LinkedListDeleteNext: @ LLDNext(List *header, List *current, List *next) // deletes next node
push { r4-r6, lr } @ r0 -> header, r1 -> current, r2 -> next, r3 -> afternext,
	cbz r2, EndLinkedListDeleteNext @ if next == NULL then return
	ldr r4, [r2, 4] @ load next node's n/p field
	eor r5, r1, r2 @ r5 = next XOR current @ will be used in a calculation in IT block
	eors r3, r1, r4 @ afternext = current XOR next.n/p 
	iteee eq @ if afternext is NULL
	streq r1, [r0] @ header.tail = current @ current is the new tail of the list
	ldrne r6, [r3, 4] @ r6 = afternext.n/p 
	eorne r6, r6, r5 @ afternext.n/p = afternext.n/p XOR next XOR current
	strne r6, [r3, 4] @ we made afternext have current as its predecessor
	ldr r4, [r1, 4] @ load current.n/p @ which might be head.n/p, which is fine
	eor r3, r2, r3 @ obtain next XOR afternext
	eor r4, r4, r3 @ current.n/p = current.n/p XOR next XOR afternext
	str r4, [r1, 4] @ we made current have afternext as its successor
	ldr r0, =ListNodeFreeStoreHead
	mov r1, r2 @ call FreeStoreReturn(ListNodeFreeStoreHead, next), deleting next node
	bl FreeStoreReturn
EndLinkedListDeleteNext:
pop { r4-r6, pc }

LinkedListFindKey: @ LLFKey(List *list, int key)
push { r4, lr }
	mov r4, r1 @ keep key here
	bl LinkedListFindKeyPosition @ returns (predecessor_node, key_node) -> (r0, r1)
	cbz r1, KeyNotFoundInList @ key_node is NULL, there is no key in list
	ldr r2, [r1] @ load key of the key position node
	cmp r2, r4 @ is it equal to key? if not, there is no key in list
	bne KeyNotFoundInList
	mov r0, 0 @ key is in key position node, signal success
	pop { r4, pc }
KeyNotFoundInList:
	mov r0, -1 @ signals failure
pop { r4, pc }

LinkedListInsertKey: @ LLIKey(List *list, int key)
push { r4-r5, lr } @ r5 -> list header, r4 -> key to insert, r6 -> pred node, r7 -> next node
	mov r4, r1 @ keep key here
	mov r5, r0 @ keep list header here
	bl LinkedListFindKeyPosition @ returns (predecessor_node, key_node_pos) -> (r0, r1)
	cbz r1, InsertKeyInLinkedList @ if key_node is NULL, insertion happens (at the tail, in fact)
	ldr r2, [r1] @ load r2 = key_node_pos.key
	cmp r2, r4 @ does the key actually belong to the list?
	beq KeyAlreadyInListOrAllocationFailure
InsertKeyInLinkedList:
	mov r2, r1 @ insertion before this
	mov r1, r0 @ insertion after this
	mov r3, r4 @ integer key to be inserted
	mov r0, r5 @ list header (in case tail has to be updated)
	bl LinkedListInsertNext
@ call LLINext(List *header, List *current, List *next, int key) returns ptr to newnode
	cbz r0, KeyAlreadyInListOrAllocationFailure @ returned NULL: must be allocation failure
	mov r0, 0 @ signal success
	pop { r4-r5, pc }
KeyAlreadyInListOrAllocationFailure:
	mov r0, -1 @ then don't insert and return failure code
pop { r4-r5, pc }

LinkedListInsertNext: @ inserts a new node with key, between current and next nodes
@ call LLINext(List *header, List *current, List *next, int key) returns ptr to newnode
push { r4-r7, lr } @ save the multiple arguments
	push { r0-r3 }
	ldr r0, =ListNodeFreeStoreHead
	bl FreeStoreRetrieve @ returns newnode in r0
	pop { r4-r7 } @ restore the multiple argument list now
	cbz r0, EndLinkedListInsertNext @ returns NULL immediately
	str r7, [r0] @ newnode.key = key
	eor r1, r5, r6 @ newnode.np = current XOR next
	str r1, [r0, 4]
	ldr r1, [r5, 4] @ load current.np
	eor r1, r1, r6
	eor r1, r1, r0 @ current.np = current.np XOR next XOR newnode
	str r1, [r5, 4] 
	cbz r6, InsertKeyAsTheNewTail @ if next is NULL, we're inserting at the end
	ldr r1, [r6, 4] @ load next.np
	eor r1, r1, r5
	eor r1, r1, r0 @ next.np = next.np XOR current XOR newnode
	str r1, [r6, 4]
	b EndLinkedListInsertNext
InsertKeyAsTheNewTail:
	str r0, [r4] @ header.tail = newnode
EndLinkedListInsertNext: 
pop { r4-r7, pc }

LinkedListRemoveKey: @ LLRKey(List *list, int key)
push { r4-r7, lr }
	mov r4, r1 @ keep key here
	mov r5, r0 @ keep list header here
	bl LinkedListFindKeyPosition @ returns (predecessor_node, key_node) -> (r0, r1)
	cbz r1, KeyNotFoundInList2 @ key_node is NULL, there is no key in list
	ldr r2, [r1] @ load key of the key position node
	cmp r2, r4 @ is it equal to key? if not, there is no key in list
	bne KeyNotFoundInList2
	mov r6, r1 @ keep keynode here
	mov r7, r0 @ save predecessor node here
	mov r0, r5
	mov r1, r7
	mov r2, r6
	bl LinkedListDeleteNext @ LLDNext(List *header, List *current, List *next)
	mov r0, 0 @ key is in key position node, signal success
	pop { r4-r7, pc }
KeyNotFoundInList2:
	mov r0, -1 @ signals failure
pop { r4-r7, pc }

LinkedListFindKeyPosition: @ FKPosition(List *l, int key) @ returns addresses of list element
@ bigger than or equal to a key, and its preceding element in an XOR linked list
@ note: it effectively returns the tail of the list and NULL if the key is not found
	mov r2, r1 @ key will be kept in r2, current in r0 and next in r1
	ldr r1, [r0, 4] @ next = header.np @ now invariant is set up
LinkedListFindKeyPositionLoop:
	cbz r1, DoneLinkedListFindKeyPosition @ if next is NULL, we are finished
	ldr r3, [r1] @ r3 = next.key
	cmp r3, r2 @ if next.key >= key then we are done
	bge DoneLinkedListFindKeyPosition
	ldr r3, [r1, 4] @ r3 = next.np
	eor r3, r0, r3 @ afternext = current XOR next.np
	mov r0, r1 @ current = next
	mov r1, r3 @ next = afternext
	b LinkedListFindKeyPositionLoop @ continue the search to the next node
DoneLinkedListFindKeyPosition:
mov pc, lr @ return ( current, next ), respectively at r0, r1

/********************** FREESTORE FUNCTIONS *********************/

FreeStoreRetrieve: @ List* FreeStoreRetrieve(List **freestorehead)
	ldr r1, [r0] @ if ( (*freestorehead).next != NULL )
	ldr r2, [r1, 4] @ if the next pointer is NULL we reached the empty freestore sentinel
	cbz r2, EmptyListSentinelReached
	str r2, [r0] @ *freestorehead = (*freestorehead).next
	mov r0, r1 @ return pointer to what was the old freestore head (retrieved item)
	mov pc, lr
EmptyListSentinelReached:
	mov r0, 0 @ return NULL pointer: allocation is impossible
mov pc, lr

FreeStoreReturn: @ void FSR(List** FSHead, List* l)
@ returns list to the freestore pointed to by FSHead, making it the new head of the freestore
	ldr r2, [r0] @ load freestore head to r2
	str r2, [r1, 4] @ next pointer set to former head
	str r1, [r0] @ the head of the freestore is now the element to be deleted
mov pc, lr

IsListFreeStoreEmpty: @ ILFSEmpty (List **freestorehead), returns 1 if FS is empty, 0 otherwise
	ldr r0, [r0]
	ldr r0, [r0, 4] @ r0 = (*freestorehead)->next == NULL ? 1 : 0
	cmp r0, 0
	ite eq
	moveq r0, 1
	movne r0, 0
mov pc, lr

/********** APPLICATION DATA / LIST HEADER FREESTORE / LIST NODE FREESTORE *************/

.equ MAXLISTS, 1024 @ maximum number of lists allowed in our manager
MaxLists: .word MAXLISTS @ this way MaxLists can be any constant

.data 
.align
//application variables (user input) and array of lists for the LinkedList test application
UserCommand: .word 0 @ c, i, f, r, d, p, l, m, h, q are all valid commands
UserArgument: .word 0, 0 // used for <list> and <key> arguments, respectively

//.equ MAXLISTS, 1024 @ maximum number of lists allowed in our manager
//MaxLists: .word MAXLISTS @ this way MaxLists can be any constant
ArrayOfLists:
.rept MAXLISTS
	.word 0 @ pointer to a list, initially no list loaded there
.endr

// freestore service from which we pull list headers 
// they come with a unique identifier that must be returned upon deletion.
// if this service is not required, it's possible to use regular list nodes
// as list headers themselves (same memory layout, same next pointers in the store)
.equ fillvalue, 0 @ count up from 0 for the default keys
.equ LISTHEADERFREESTORESIZE, MAXLISTS @ 1024 units -> 1024*8 = 8192 bytes
ListHeaderFreeStore:
.equ freestorenext, ListHeaderFreeStore+8
.rept LISTHEADERFREESTORESIZE
	.word fillvalue
	.word freestorenext
	.equ fillvalue, fillvalue+1 // these will be used as list identifiers (and indices for our array in this application)
	.equ freestorenext, freestorenext+8
.endr
.word fillvalue
.word 0 @ this is the empty freestore sentinel node
ListHeaderFreeStoreHead: .word ListHeaderFreeStore @ head of free store maintained by the memory manager

// last but not the least, the free store service 
// for list nodes used by the linked list library
.equ fillvalue, 0 @ count up from 0 for the default keys
.equ LISTNODEFREESTORESIZE, 4096 @ 4096 units ->
ListNodeFreeStore:
.equ freestorenext, ListNodeFreeStore+8
.rept LISTNODEFREESTORESIZE
	.word fillvalue
	.word freestorenext
	.equ fillvalue, fillvalue+1
	.equ freestorenext, freestorenext+8
.endr
.word fillvalue
.word 0 @ this is the empty freestore sentinel node
ListNodeFreeStoreHead: .word ListNodeFreeStore @ head of free store maintained by the memory manager

