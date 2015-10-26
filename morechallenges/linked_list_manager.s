	/************ MC404C, Giuliano Sider, 20/10/2015
*** Atividade Desafio 2: biblioteca para gerenciar lista ligadas (alocadas estaticamente)
*** e programa teste para usá-las.

Structure of program:
"main user input loop" implements the "LinkedListManager test module".
"LinkedListManager test module" depends on "Linked List library of functions".
"Linked List library of functions" depends on "Memory Free Store service"
************/


.syntax unified
.text
.global main
.align

main:
push { r4-r7, lr }
branchtable .req r5
command .req r6
	ldr r0, =WelcomeMsg
	ldr r1, =UsageMsg @ command cheat sheet for the application
	bl printf
	ldr r4, =UserCommand @ scanf stores command here
	ldr branchtable, =CommandBranch @ address of table of branches for the menu
	//bl InitLinkedListManager @ prepares an array which initially stores empty lists
QueryUser:
	ldr r0, =QueryString1 @ get first letter of user command
	mov r1, r4 
	bl scanf
	cmp r0, 1 @ scanf should return 1 for the character specifier read
	bne InputError
	ldr command, [r4] @ get user command that was stored by scanf
	ldr pc, [branchtable, command, lsl 2] @ load the appropriate jump address to handle the user's command (directly addressed by ascii code)
Quit:
	ldr r0, =GoodbyeMsg
	bl printf

pop { r4-r7, pc }


QueryString1: .asciz " %c" @ read the first part of the command
NumericArgumentInputString: .asciz " %i" @ read second part of command, if applicable
DoubleNumericArgumentInputString: .asciz " %i %i" @ read second part of command, if applicable
WelcomeMsg: .asciz "Welcome to Linked List Manager Live\n\n%s"
InputErrorMsg: .asciz "bad command. press 'h' to view USAGE message\n"
GoodbyeMsg: .asciz "Thank you for using LinkedListManager\nHave a good\n"
UsageMsg: .ascii "USAGE: (all lower case letters)\n"
			.ascii "\tTo create a new list:      c\n"
			.ascii "\tTo delete a list:          d <list>\n"
			.ascii "\tTo find a key in a list:   f <key> <list>\n"
			.ascii "\tTo generate a random list: g"
			.ascii "\tTo show this help menu:    h OR ?\n"
			.ascii "\tTo insert a key:           i <key> <list>\n"
			.ascii "\tTo show all active lists:  l\n"
			.ascii "\tTo dump memory contents :  m\n"
			.ascii "\tTo print a list:           p <list> OR < list range > OR * \n"
			.ascii "\tTo quit:                   q\n"
			.asciz "\tTo remove a key:           r <key> <list>\n\n"

.align 8 @ helps debugging
CommandBranch: @ jump table with addresses to be loaded directly to PC based on
				@ ascii value of user input character that denotes user command
	@ c,   d    f    h    i    l    p    q    r    ?    are the commands
	@ 0x63 0x64 0x66 0x68 0x69 0x6c 0x70 0x71 0x72 0x3f
	@ 99   100  102  104  105  108  112  113  114  63
.rept '?' @ until we get to '?''
	.word InputError+1 @ thumb state requires that lsb of branch address be 1
.endr
.word HelpUser+1 @ '?' command
.rept 'c'-'?'-1 @ until we get to 'c'
	.word InputError+1
.endr
.word CreateList+1 @ 'c' command
.word DeleteList+1 @ 'd' command
.word InputError+1 @ 'e'
.word SearchList+1 @ 'f' comand
.word GenerateRandList+1 @ 'g'
.word HelpUser+1 @ 'h' command 
.word InsertKey+1 @ 'i' command 
.rept 'l'-'i'-1 @ until we get to 'l'
	.word InputError+1
.endr
.word ShowLists+1 @ 'l' command
.word MemoryMap+1 @ 'm' command
.rept 'p'-'m'-1 @ until we get to 'p'
	.word InputError+1
.endr
.word PrintList+1 @ 'p' command
.word Quit+1 @ 'q' command
.word RemoveKey+1 @ 'r' command
.rept 255-'r' @ cover the remaining ascii characters
	.word InputError+1
.endr



//my LinkedListManager test module functions
CreateList: @ creates an empty list and returns its index
	push { r4-r6 }
	ldr r3, =NextList @ address of NextList
	ldr r2, [r3] @ value of nextlist: try to create the new list at this position
	mov r1, r2 @ index i of FindPlaceForNewList loop
	ldr r4, =ArrayOfLists
	ldr r5, =MaxLists
	ldr r5, [r5] @ value of Maxlists. this way MAXLISTS can be any constant we want
FindPlaceForNewList:
	ldr r0, [r4, r6, lsl 4] @ while ArrayOfLists[i] != -1 (-1 is inactive (free) list), do:
	cmp r0, -1
	beq DoCreateTheNewList @ we found an empty place to put the new list. yay
	add r1, 1
	cmp r1, r5 @ if i == MAXLISTS, wrap it zero
	it eq
	mov r1, 1
	cmp r1, r2 @ if i == NextList, then we went all the way around.. alas, no space for the list 
	bne FindPlaceForNewList @ keep looking for space for this list
@ if we fall here, there is no space:
	ldr r0, NoSpaceInListArrayMsg
	mov r1, r5 @ print MAXLISTS for the user
	bl printf
	mov r0, -1 @ signals unsuccessful return
	b EndCreateList
DoCreateTheNewList:
	mov r0, 0xffffffff @ this signals an active but empty list
	str r0, [r4, r6, lsl 2] @ ArrayOfLists[i] = -1
	mov r6, r1 @ keep a copy to be fed to printf for user notification
	add r1, 1 @ i++ mod MAXLISTS will become the new NextList index
	cmp r1, r5 @ has i reached MAXLISTS ?
	it eq
	moveq r1, 0 @ then wrap it to zero
	str r1, [r3] @ NextList = i
	mov r1, r6 @ print the index where we stored the list
	ldr r0, =CreateListMsg
	bl printf
	mov r0, r6 @ non negative index of list signals successful return
EndCreateList:
	pop { r4-r6 }
	b QueryUser
CreateListMsg: .asciz "Creating new list with id %i\n"
NoSpaceInListArrayMsg: .asciz "There is not enough space for a new list: maximum of %i reached. delete a list and try again\n"
.align

CheckIfListExists:

DeleteList: @ takes the id of list to delete from standard input and deletes it

	ldr r0, =NumericArgumentInputString
	ldr r4, =UserArgument
	mov r1, r4
	bl scanf @ read user input for what list to delete

	ldr r1, [r4]
	cmp r1, 0
	blt ListDoesNotExist @ out of bounds access
	ldr r2, =MaxLists
	cmp r1, r2
	bge ListDoesNotExist @ out of bounds access
	ldr r2, =ArrayOfLists
	ldr r0, [r2, r1, lsl 4] @ r0 = ArrayOfLists[list_id], pointer to the list
	cmp r0, -1
	beq ListDoesNotExist @ it's set to -1 (inactive) in our array
@ so now we know the list exists (although it could be empty)
	ldr r1, =FreeStoreHead @ for LinkedListDelete to return allocated memory and update the freestore
	bl LinkedListDelete
	ldr r2, =ArrayOfLists
	mov r3, -1

	ldr r0, =DeleteListMsg
	ldr r1, =UserArgument
	ldr r1, [r1]
	bl printf
	mov r0, 0 @ successful delete
	b QueryUser
ListDoesNotExist:
	ldr r0, =ListDoesNotExistMsg
	bl printf
	mov r0, -1 @ signal failure
	b QueryUser
DeleteListMsg: .asciz "Deleting list number %i\n"
ListDoesNotExistMsg: .asciz "The list with number %i you have requested does not exist. press 'l' for a full listing\n"
.align

SearchList:
	ldr r1, =UserArgument @ place where scanf puts the numeric argument (key) to be found
	add r2, r1, 4 @ we read two 32 bit integer arguments, key and list (identifier)
	ldr r0, =DoubleNumericArgumentInputString
	bl scanf
	ldr r3, =UserArgument
	ldr r1, [r3] @ pass the value of the key in r1
	ldr r2, =ArrayOfLists
	ldr r0, [r2, ]
	ldr r0, =SearchListMsg
	bl printf
	b QueryUser
SearchListMsg: .asciz "Searching list\n"
.align

GenerateRandList:

	

	b QueryUser
GenerateRandListMsg: .asciz "Generating random list\n"

HelpUser:
	ldr r0, =UsageMsg
	bl printf
	b QueryUser
.align

InsertKey:
	ldr r0, =InsertKeyMsg
	bl printf
	b QueryUser
InsertKeyMsg: .asciz "Inserting new key\n"
.align

ShowLists:
	ldr r0, =ShowListsMsg
	bl printf
	b QueryUser
ShowListsMsg: .asciz "Showing lists\n"
.align

MemoryMap:
	ldr r0, =MemoryMapMsg
	bl printf
	b QueryUser
MemoryMapMsg: .asciz "Showing memory\n"
.align

PrintList:
	ldr r0, =PrintListMsg
	bl printf
	b QueryUser
PrintListMsg: .asciz "Printing list\n"
.align

RemoveKey:
	ldr r0, =RemoveKeyMsg
	bl printf
	b QueryUser
RemoveKeyMsg: .asciz "Removing key\n"
.align

InputError:
	ldr r0, =InputErrorMsg
	bl printf
	b QueryUser

//my linked list library functions 
LinkedListDelete: @ takes pointer to head of list in r0. takes pointer to (head of) freestore in r1
	ldr r3, [r1] @ keep original Freestore head here so we can update
DoLinkedListDelete:
	cbz r0, DoneWithLinkedListDelete @ null (empty) list. done
	ldr r2, [r0, 4] @ load next pointer in r2
	str r3, [r0, 4] @ this list node is returned to the free store (deleted)
	mov r3, r0, @ head of freestore is now the list node we deleted 
	mov r0, r2 @ new head of list to inspect is the old next pointer
	b DoLinkedListDelete
DoneWithLinkedListDelete:
	str r3, [r1] @ save the new freestore head pointer value
mov pc, lr


.data 
.align

//application variables (user input) and array of lists for the LinkedList test application
UserCommand: .word 0 @ c, i, f, r, d, p, l, m, h, q are all valid commands
UserArgument: .word 0, 0

.equ MAXLISTS 1024 @ maximum number of lists allowed in our manager
MaxLists: .word MAXLISTS
NextList: .word 0 @ try to insert the next created list at this index
//ListCount: .word 0 @ static variable keeping count of the lists we have created.
				@ incremented every time we make a list. when it gets to 1024 we have to loop
				@ through the array to find space for a new list (or we could implement
				@ a defrag routine TO DO). if no space, return error
ArrayOfLists:
.rept MAXLISTS
	//.word 0 @ field for the identifier of the list (counts up from 0)
	.word 0 @ pointer to a list; all lists initially inactive (-1). 0 signals active/empty list
.endr

//last but not the least, the free store service used by the linked list library
.equ fillvalue, 0 @ count up from 0 for the default keys
.equ FREESTORESIZE, 4096 @ allocate 8*65536 = 0.5 MB
FreeStore:
.equ freestorenext, FreeStore+8
.rept FREESTORESIZE
	.word fillvalue
	.word freestorenext
	.equ fillvalue, fillvalue+1
	.equ freestorenext, freestorenext+8
.endr
.word fillvalue
.word 0 @ end of the list marked with a null pointer
FreeStoreHead: .word FreeStore @ head of free store maintained by the program




















