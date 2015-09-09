N= input('Entre com fatorial a calcular: ')
f=1
for i in range(2,N+1):
  f=f*i
print f
print "%2d!=%x (em hexadecimal)" %(N, f)
