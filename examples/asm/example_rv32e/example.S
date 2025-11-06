.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
    li a0, 42
    # Initialization using Argument/Temporary Registers (a0=x10, a1=x11, a2=x12, a3=x13)
    addi a0, zero, 20      
    addi a1, zero, 8       
    addi a2, zero, 3       
    addi a3, zero, 2       

    # t0 = a0 - a1 (t0=x5)
    sub t0, a0, a1       

    # t1 = t0 << a3 (t1=x6)
    sll t1, t0, a3       

    # t2 = t1 OR 7 (t2=x7)
    ori t2, t1, 7        

    # s0 = t2 XOR a0 (s0=x8)
    xor s0, t2, a0       

    # s1 = s0 + a2 (s1=x9)
    add s1, s0, a2       

    # a4 = (s1 < 50)? 1:0 (a4=x14)
    slti a4, s1, 50     

    # t0 = s1 >> 2 (t0=x5)
    srai t0, s1, 2       
    
    # t1 = t0 AND 15 (t1=x6)
    andi t1, t0, 15      
    
    # t2 = (t1 < a1)? 1:0 (t2=x7)
    sltu t2, t1, a1      

    # t2 = t2 + 1 (t2=x7)
    addi t2, t2, 1
    
    # --- Instructions 11 - 15 ---
    # s0 = t2 + t1 (s0=x8)
    add s0, t2, t1

    # s1 = (s0 < t0)? 1:0 (s1=x9)
    slt s1, s0, t0

    # a4 = (s1 < 1)? 1:0 (a4=x14)
    sltiu a4, s1, 1

    # a0 = a4 OR a1 (a0=x10)
    or a0, a4, a1

    # a1 = a0 >> a2 (a1=x11)
    srl a1, a0, a2
    
    # --- Added Instructions (16 - 25) ---
    
    # 16. Logical AND (a2=x12)
    and a2, a0, a1       

    # 17. Addition (a3=x13)
    addi a3, a2, 100     

    # 18. Set Less Than Immediate (t0=x5)
    addi t0, zero, -10     
    slti t1, a3, -5      

    # 19. Exclusive OR (t2=x7)
    xori t2, t1, 0xFF    

    # 20. Shift Left Logical (s0=x8)
    slli s0, t2, 1       

    # 21. Subtraction (s1=x9)
    sub s1, s0, a0       

    # 22. Logical OR (a4=x14)
    or a4, s1, a2       

    # 23. Shift Right Logical (a0=x10)
    srli a0, a4, 5      

    # 24. Set Less Than Unsigned (a1=x11)
    sltu a1, a0, a3      

    # 25. Addition (a2=x12)
    addi a2, a1, 10      
    
    # Final result in a2

self_loop:
    j self_loop
