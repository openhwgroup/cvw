import binary_parser as bp
LEN = 7
def main():
    D = "0001000"
    negD = "1111000"
    neg2D = "1110000"
    X = fillzeros(((bp.parse_to_binary(int(bp.parse_to_num(D))*5/4))).decode())

    WS = X 
    WC = LEN * "0"
    cycles=0
    print(f"X   = {X}")
    print(f"D   = {D}")
    while (True):
        if (cycles > 5): return
        print("*"*29)
        print(f"WS  = {WS} ")
        print(f"WC  = {WC} ")
        sum = add(WS,WC)
        if (sum == (LEN * "0")):
            print("0 detection")
            return
        if (sum == neg2D):
            print("special case detected")
            #return
        wsmsbs = fillzeros(WS[0:4])
        wcmsbs = fillzeros(WC[0:4])
        truncsum = add(wsmsbs, wcmsbs)[LEN-4:LEN]
        addend,q = qslc(truncsum,D,negD)
        print(f"Wmsbs = {truncsum}")
        print(f"q = {q}")
        print(f"A   = {addend}")
        WSA,WCA = csadd(WS,WC, addend)
        print(f"WSA = {WSA}")
        print(f"WCA = {WCA}")
        WSN = WSA[1:] + "0"
        WCN = WCA[1:] + "0"
        WS = WSN
        WC = WCN
        cycles+=1
        
def add(A,B):
    return fillzeros(bp.parse_to_binary(int(bp.parse_to_num(A)) + int(bp.parse_to_num(B))).decode())
def csadd(A,B,C):
    WSA = ""
    WCA = ""
    for i in range(LEN):
        WSA += "1" if bool(A[i]=="1") ^ bool(B[i]=="1") ^ bool(C[i]=="1") else "0"
        if (i < LEN-1):
            WCA += "1" if (int(A[i+1]) + int(B[i+1]) + int(C[i+1])) > 1 else "0" 
    return WSA, (WCA+"0")

def fillzeros(x):
    if (len(x) > LEN):
        return x[len(x)-LEN:]
    return ((LEN - len(x))*"0")+x
def qslc(truncsum,D, negD):
    if truncsum == "1111":
        return "0" * LEN, "0"
    elif truncsum[0] == "1":
        return D, "-1"
    else: 
        return negD, "1"




main()