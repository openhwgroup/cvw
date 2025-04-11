Extended Euclidean Algorithm

EEA Cycle Estimates

Main loop body: 25 (N times)
swap_and_negate: 22 (S times)
gf_degree: 10 (twice per loop)
Number of Loops: N

\ext{Total Cycles} = N \times (25 + 2 \times 10) + S \times 22

Pseuo-Code

r0 := m
r1 := a
s0 := 0
s1 := 1

while r1 \neq 0:
    deg_r0 = degree(r0)
    deg_r1 = degree(r1)
    shift = deg_r0 - deg_r1

    if shift < 0:
        swap(r0, r1)
        swap(s0, s1)
        shift := -shift

    r0 = r0 ^ (r1 << shift)
    s0 = s0 ^ (s1 << shift)

if r0 \neq 1:
    return "No inverse"
else:
    return s0


LaTeX
------
\documentclass{article}
\usepackage{algorithm}
\usepackage{algpseudocode}
\usepackage{amsmath}

\begin{document}

\begin{algorithm}
\caption{Extended Euclidean Algorithm in GF(2\textsuperscript{8})}
\begin{algorithmic}[1]
\Require Input value $a$, modulus $m$ (usually $0x11B$)
\Ensure Return $s_0$ such that $s_0 \cdot a \equiv 1 \pmod{m}$ if inverse exists

\State $r_0 \gets m$
\State $r_1 \gets a$
\State $s_0 \gets 0$
\State $s_1 \gets 1$

\While{$r_1 \ne 0$}
    \State $d_0 \gets \text{deg}(r_0)$
    \State $d_1 \gets \text{deg}(r_1)$
    \State $\text{shift} \gets d_0 - d_1$
    
    \If{$\text{shift} < 0$}
        \State Swap $r_0 \leftrightarrow r_1$
        \State Swap $s_0 \leftrightarrow s_1$
        \State $\text{shift} \gets -\text{shift}$
    \EndIf
    
    \State $r_0 \gets r_0 \oplus (r_1 \ll \text{shift})$
    \State $s_0 \gets s_0 \oplus (s_1 \ll \text{shift})$
    
    \State Mask $r_0$ and $s_0$ to 9 bits: $r_0 \gets r_0 \mathbin{\&} 0x1FF$, $s_0 \gets s_0 \mathbin{\&} 0x1FF$
\EndWhile

\If{$r_0 = 1$}
    \State \Return $s_0$ \Comment{Inverse found}
\Else
    \State \Return \textbf{error} \Comment{No inverse exists}
\EndIf
\end{algorithmic}
\end{algorithm}

\end{document}
