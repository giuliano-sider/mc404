
### Python script to find the factorial of a number entered by the user ###

num = int(input("Enter a number: "))
factorial = 1

if num < 0:
   print("USAGE: fact.py <non negative integer>")
else:
   for i in range(1,num + 1): # half open interval
       factorial = factorial*i
   print ( "The factorial of " + str(num) + " is " + str(factorial) )
