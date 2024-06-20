import binary_parser as bp
def main(X,D,LEN):
    invD = inv(D,LEN)

    neg2D = neg2(D,LEN)

    WS = X 
    WC = LEN * "0"
    cycles=0
    negD = neg(D,LEN)
    print(f"X   = {X}")
    print(f"D   = {D}")
    print(f"negD= {negD}")
    while (True):
        #if (cycles > 5): return
        print("*"*29)
        #print(f"WS  = {hex(bp.parse_to_num(WS))} ")
        #print(f"WC  = {hex(bp.parse_to_num(WC))} ")

        print(f"WS  = {WS}")
        print(f"WC  = {WC}")
        #print(f"WC  = {WC} ")
        sum = add(WS,WC,LEN)
        print(f"sum  ={sum}")
        if (sum == (LEN * "0")):
            print("0 detection")
            return
        if (sum == neg2D):
            print("special case detected")
            return
        wsmsbs = fillzeros(WS[0:4],LEN)
        wcmsbs = fillzeros(WC[0:4],LEN)
        truncsum = add(wsmsbs, wcmsbs,LEN)[LEN-4:LEN]
        addend,q = qslc(truncsum,D,invD,LEN)
        print(f"Wmsbs = {truncsum}")
        print(f"q = {q}")
        print(f"A   = {addend}")
        # this part is exactly like the hardware
        WSA,WCA = csadd(WS,WC, addend,q,LEN)
        print(f"WSA = {WSA}")
        print(f"WCA = {WCA}")
        WSN = WSA[1:] + "0"
        WCN = WCA[1:] + "0"
        WS = WSN
        WC = WCN
        cycles+=1
        
def add(A,B,LEN):
    return fillzeros(bp.parse_to_binary(int(bp.parse_to_num(A)) + int(bp.parse_to_num(B))).decode(),LEN)
def csadd(A,B,C,q,LEN):
    WSA = ""
    WCA = ""
    for i in range(LEN):
        WSA += "1" if bool(A[i]=="1") ^ bool(B[i]=="1") ^ bool(C[i]=="1") else "0"
        if (i < LEN-1):
            WCA += "1" if (int(A[i+1]) + int(B[i+1]) + int(C[i+1])) > 1 else "0" 
    return WSA, (WCA+("1" if q == "1" else "0"))

def fillzeros(x,LEN):
    if (len(x) > LEN):
        return x[len(x)-LEN:]
        
    return ((LEN - len(x))*"0")+x
def qslc(truncsum,D, invD,LEN):
    if truncsum == "1111":
        return "0" * LEN, "0"
    elif truncsum[0] == "1":
        return D, "-1"
    else: 
        return invD, "1"



def neg(x,LEN):
    invx = inv(x,LEN)
    invxp1 = fillzeros(bp.parse_to_binary(int(bp.parse_to_num(invx)+1)).decode(),LEN)
    return invxp1



def inv(D,LEN):
    invD=""
    for i in range(LEN):
        if D[i]=="0":
            invD += "1"
        elif D[i] =="1":
            invD += "0"
    return invD
def neg2(D,LEN):
    return neg(D,LEN)[1:]+"0"
    


X = "000101000000000000000011110"
D = "000101000000000000000000000"

print(X)
if len((bp.parse_to_binary(int(bp.parse_to_num(D))*5/4)).decode()) > (len(D)-3) or not ".0" in str(float(bp.parse_to_num(D))*5/4):
    print("INVLAID X")
    exit()
print(X)
print(D)
print(inv(D, len(D)))
print(str(float(bp.parse_to_num(D))*5/4))
print(neg("1111",4))
main(X,D,len(D))