	/************ MC404C, Giuliano Sider, 20/10/2015
*** Atividade Desafio 2: biblioteca para gerenciar lista ligadas (alocadas estaticamente)
*** e programa teste para usá-las.

Structure of program:
"main user input loop" implements the "LinkedListManager test module".
"LinkedListManager test module" depends on "Linked List library of functions".
"Linked List library of functions" depends on "Memory Free Store service"

inter procedure etiquette: subs clobber r0-r3. all others are callee-saved (ARM convention)
************/


.syntax unified
.text
.global main
.align

main:
push { r4-r7, lr }
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
	ldr r4, =BranchTable @ address of table of branches for the menu
	tbb [r4, r1] @ load the appropriate jump address to handle the user's command (directly addressed by ascii code)
//branch to my LinkedListManager test module functions: they use r4-r7 freely

Quit:
	// clean up work here

	ldr r0, =GoodbyeMsg
	bl printf
pop { r4-r7, pc }

CreateList: @ creates an empty list and returns its identifier (index to be used in our application array)
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
	bl printf @ print success message along with list_id (r1) for the user
	b QueryUser

ListFreeStoreIsEmpty:
	ldr r0, =NoSpaceForListMsg
	ldr r1, MaxLists @ print the max number of lists set at compile time
	//ldr r1, [r1]
	bl printf
	b QueryUser

FreeStoreRetrieve: @ List* FreeStoreRetrieve(List **freestorehead) : returns allocated list, or NULL if there is no space
	ldr r1, [r0] @ if ( (*freestorehead).next != NULL )
	ldr r2, [r1, 4] @ if the next pointer is NULL we reached the empty freestore sentinel
	cbz r2, EmptyListSentinelReached
	str r2, [r0] @ *freestorehead = (*freestorehead).next
	mov r0, r1 @ return pointer to what was the old freestore head (retrieved item)
mov pc, lr
EmptyListSentinelReached:
	mov r0, 0 @ return NULL pointer: allocation is impossible
mov pc, lr

DeleteList: @ takes the id of list to delete from standard input and deletes it
	bl ObtainUserInputList @ get validated list id from user (in r0)
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
	mov r1, r7 @ list index that was deleted
	bl printf
	b QueryUser
ListDoesNotExist:
	ldr r0, =ListDoesNotExistMsg
	bl printf
	b QueryUser

FreeStoreReturn: @ void FSR(List** FSHead, List* l)
@ returns list to the freestore pointed to by FSHead, making it the new head of the freestore
	@cbz r1, ListReturnedToFreeStore @ so deleting a NULL list has no consequenes
	ldr r2, [r0] @ load freestore head to r2
	str r2, [r1, 4] @ next pointer set to former head
	str r1, [r0] @ the head of the freestore is now the element to be deleted
ListReturnedToFreeStore:
mov pc, lr

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
	eorne r6, r6, r5 @ afternext.n/p = afternext.n/p XOR next XOR afternext
	strne r6, [r1, 4] @ we made afternext have current as its predecessor
	ldr r4, [r1, 4] @ load current.n/p @ which might be head.n/p, which is fine
	eor r3, r2, r3 @ obtain next XOR afternext
	eor r4, r4, r3 @ current.n/p = current.n/p XOR next XOR afternext
	str r4, [r1, 4]
	ldr r0, =ListNodeFreeStoreHead
	mov r1, r2 @ call FreeStoreReturn(ListNodeFreeStoreHead, next), deleting next node
	bl FreeStoreReturn
EndLinkedListDeleteNext:
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
	pop { r0 } @ exceptional condition (out of bounds): trash the lr (must only bl to this routine!) and return to main loop
	b QueryUser

SearchList:
	bl ObtainUserInputList
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
	b QueryUser
ListDoesNotExist2: 
	ldr r0, =ListDoesNotExistMsg
	bl printf
	b QueryUser

LinkedListFindKey: @ LLFKey(List *list, int key)
push { lr }
	mov r4, r1 @ keep key here
	bl LinkedListFindKeyPosition @ returns (predecessor_node, key_node) -> (r0, r1)
	cbz r1, KeyNotFoundInList @ key_node is NULL, there is no key in list
	ldr r2, [r1] @ load key of the key position node
	cmp r2, r4 @ is it equal to key? if not, there is no key in list
	beq KeyNotFoundInList
	mov r0, 0 @ key is in key position node, signal success
pop { pc }
KeyNotFoundInList:
	mov r0, -1 @ signals failure
pop { pc }

LinkedListInsertKey: @ LLIKey(List *list, int key)
push { r4-r7, lr } @ r5 -> list header, r4 -> key to insert, r6 -> pred node, r7 -> next node
	mov r4, r1 @ keep key here
	mov r5, r0 @ keep list header here
	bl LinkedListFindKeyPosition @ returns (predecessor_node, key_node_pos) -> (r0, r1)
	cbz r1, InsertKeyInLinkedList @ if key_node is NULL, insertion happens (at the tail, in fact)
	ldr r2, [r1] @ load r2 = key_node_pos.key
	cmp r2, r4 @ does the key actually belong to the list?
	beq KeyAlreadyInListOrAllocationFailure
InsertKeyInLinkedList:
	mov r0, r5 @ list header (in case tail has to be updated)
	mov r1, r0 @ insertion after this
	mov r2, r1 @ insertion before this
	mov r3, r4 @ integer key to be inserted
	bl LinkedListInsertNext
	cbz r0, KeyAlreadyInListOrAllocationFailure @ returned NULL: must be allocation failure
	@ call LLINext(List *header, List *current, List *next, int key) returns ptr to newnode
	
	mov r0, 0 @ signal success
pop { r4-r7, pc }
KeyAlreadyInListOrAllocationFailure:
	mov r0, -1 @ then don't insert and return failure code
pop { r4-r7, pc }

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
	cbz r0, InsertKeyAsTheNewTail @ next is NULL, so we're inserting at the end
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
push { lr }
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
pop { pc }
KeyNotFoundInList2:
	mov r0, -1 @ signals failure
pop { pc }


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
	b FindLinkedListKeyPositionLoop @ continue the search to the next node
DoneLinkedListFindKeyPosition:
	mov pc, lr @ return ( current, next ), respectively at r0, r1

ObtainUserInputKey:
	ldr r0, =NumericArgumentInputString
	ldr r1, =(UserArgument+4) @ user argument #2
	bl scanf
	ldr r0, =(UserArgument+4)
	ldr r0, [r0]
mov pc, lr @ return the key we have obtained from stdin (no validation is necessary)

GenerateRandList:

	
	ldr r0, =GenerateRandListMsg
	bl printf
	b QueryUser

HelpUser:
	ldr r0, =UsageMsg
	bl printf
	b QueryUser

InsertKey:
	bl ObtainUserInputList
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
	b QueryUser
ListDoesNotExist3:
	ldr r0, =ListDoesNotExistMsg
	bl printf
	b QueryUser

IsListFreeStoreEmpty: @ ILFSEmpty (List **freestorehead), returns 1 if FS is empty, 0 otherwise
	ldr r0, [r0]
	ldr r0, [r0, 4] @ r0 = (*freestorehead)->next == NULL ? 1 : 0
	cmp r0, 0
	ite eq
	moveq r0, 1
	movne r0, 0
mov pc, lr

ShowLists:


	ldr r0, =ShowListsMsg
	bl printf
	b QueryUser
.align

MemoryMap:


	ldr r0, =MemoryMapMsg
	bl printf
	b QueryUser
.align

PrintList:


	ldr r0, =PrintListMsg
	bl printf
	b QueryUser
.align

RemoveKey:
	bl ObtainUserInputList
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
	b QueryUser
ListDoesNotExist4:
	ldr r0, =ListDoesNotExistMsg
	bl printf
	b QueryUser

InputError:
	mov r0, 0
	ldr r1, =FileModeString
	bl fdopen
	bl feof @ if (feof(fdopen(0, "r")) != 0) then: we have an EOF. Quit.
	bne Quit
	ldr r0, =InputErrorMsg
	bl printf
	b QueryUser
FileModeString: .asciz "r"

InputErrorMsg: .asciz "bad command. press 'h' to view USAGE message\n"
SuccessfulRemoveKeyMsg: .asciz "Key %i successfully inserted in list %i\n"
UnSuccessfulRemoveKeyMsg: .asciz "Key %i does not belong to list %i\n"
PrintListMsg: .asciz "Printing list\n"
MemoryMapMsg: .asciz "Showing memory\n"
ShowListsMsg: .asciz "Showing lists\n"
SuccessfulInsertKeyMsg: .asciz "Key %i successfully inserted in list %i\n"
FreeStoreEmptyOnInsertionMsg: .asciz "Could not insert key %i in list %i because list node freestore is empty\n"
KeyAlreadyInListMsg: .asciz "Could not insert key %i in list %i because key already belongs to list\n"
GenerateRandListMsg: .asciz "Generating random list\n"
SuccessfulSearchListMsg: .asciz "The key %i was found in the list %i\n"
UnSuccessfulSearchListMsg: .asciz "The key %i was not found in list %i\n"
DeleteListMsg: .asciz "Deleting list number %i\n"
ListDoesNotExistMsg: .asciz "The list with number %i you have requested does not exist. press 'l' for a full listing\n"
CreateListMsg: .asciz "Creating new list with id %i\n"
NoSpaceForListMsg: .asciz "There is not enough space for a new list: maximum of %i reached. delete a list and try again\n"
ListOutOfBoundsMsg: .asciz "The list id you have provided is out of bounds for this application\n"

QueryString1: .asciz " %c" @ read command character and //discard everything else up to a line break
NumericArgumentInputString: .asciz " %i" @ read second part of command, if applicable
//DoubleNumericArgumentInputString: .asciz " %i %i" @ read second part of command, if applicable
WelcomeMsg: .asciz "Welcome to Linked List Manager Live\n\n%s"
GoodbyeMsg: .asciz "Thank you for using LinkedListManager\nHave a good\n"
UsageMsg: .ascii "USAGE: (all lower case letters)\n"
			.ascii "\tTo create a new list:      c\n"
			.ascii "\tTo delete a list:          d <list>\n"
			.ascii "\tTo find a key in a list:   f <key> <list>\n"
			.ascii "\tTo generate a random list: g\n"
			.ascii "\tTo show this help menu:    h OR ?\n"
			.ascii "\tTo insert a key:           i <key> <list>\n"
			.ascii "\tTo show all active lists:  l\n"
			.ascii "\tTo dump memory contents :  m\n"
			.ascii "\tTo print a list:           p <list> OR < list range > OR * \n"
			.ascii "\tTo quit:                   q\n"
			.asciz "\tTo remove a key:           r <key> <list>\n\n"

.align 8 @ helps debugging
BranchTable: @ jump table with addresses to be loaded directly to PC based on
				@ ascii value of user input character that denotes user command
	@ c,   d    f    h    i    l    m     p    q    r    ?    are the commands
	@ 0x63 0x64 0x66 0x68 0x69 0x6c 0x6d  0x70 0x71 0x72 0x3f
	@ 99   100  102  104  105  108  109   112  113  114  63
// Quit is the first branch. TBB jumps by an offset of twice the value in the table.
.rept '?' @ until we get to '?''
	.byte (InputError-Quit)/2 @ invalid command in this range of ascii
.endr
.byte (HelpUser-Quit)/2 @ '?' command
.rept ('c' - '?' - 1) @ until we get to 'c'
	.byte (InputError-Quit)/2
.endr
@ 'c' command, d' command, 'e', 'f' command, 'g' command, 'h' command, 'i' command
.byte (CreateList-Quit)/2, (DeleteList-Quit)/2, (InputError-Quit)/2, (SearchList-Quit)/2
.byte (GenerateRandList-Quit)/2, (HelpUser-Quit)/2 , (InsertKey-Quit)/2 
.rept ('l'-'i'-1) @ until we get to 'l'
	.byte (InputError-Quit)/2
.endr
.byte (ShowLists-Quit)/2,(MemoryMap-Quit)/2 @ 'l' command, 'm' command
.rept ('p'-'m'-1) @ until we get to 'p'
	.byte (InputError-Quit)/2
.endr
.byte (PrintList-Quit)/2, 0, (RemoveKey-Quit)/2 @ 'p' command, 'q' command, 'r' command
.rept (255-'r') @ cover the remaining ascii characters
	.byte (InputError-Quit)/2
.endr


//application helper functions:

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
	pop { r0 } @ exceptional condition (out of bounds): trash the lr (must only bl to this routine!) and return to main loop
	b QueryUser
	
ObtainUserInputKey:
	ldr r0, =NumericArgumentInputString
	ldr r1, =(UserArgument+4) @ user argument #2
	bl scanf
	ldr r0, =(UserArgument+4)
	ldr r0, [r0]
mov pc, lr @ return the key we have obtained from stdin (no validation is necessary)

//my linked list library functions:

.equ MAXLISTS, 1024 @ maximum number of lists allowed in our manager
MaxLists: .word MAXLISTS @ this way MaxLists can be any constant

.data 
.align

//application variables (user input) and array of lists for the LinkedList test application
UserCommand: .word 0 @ c, i, f, r, d, p, l, m, h, q are all valid commands
UserArgument: .word 0, 0 // used for <list> and <key> arguments

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




















