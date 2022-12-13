li x1, 3
li x5, 5
li x6, -2
li x7, 0x103
li x2, 0x100
sb x1, 0(x2)
sb x5, 1(x2)
sb x6, 0(x7)
sh x6, 1(x7)
sw x6, 1(x7)
lb x3, 0(x2)
lh x4, 0(x2)
lb x8, 0(x7)
lbu x9, 0(x7)
lhu x10, 2(x2)
lh x11, 2(x2)
lw x13, 1(x7) 
sb x5, 2(x2)
lbu x10, 2(x2)
end:
j end
