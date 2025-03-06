---
layout: post
title: "Chinese Remainder Theorem"
categories: math
---

> I always forget how the Chinese Remainder Theorem works, so I write it down in a moron-guide form here.

Problem I'm solving:

- Consider a set of buses, where a bus with a number `n` goes every `n` minutes.
- All buses start at `t=0`.
- All bus numbers are coprime.

I want to find the earliest moment `T` where:

- bus 5 arrives 3 minutes after `T`
- bus 11 arrives 7 minutes after `T`
- bus 13 arrives 2 minutes after `T`

I _can_ solve it by checking every integer starting from 1, but **Chinese Remainder Theorem** allows me to skip the
iteration.

## Congruence

This problem is a set of **congruences**:

```
T ≡ 3 (mod 5)
T ≡ 7 (mod 11)
T ≡ 2 (mod 13)
```

A **congruence** `a ≡ b (mod z)` means that `a % z = b % z`.

## Modular multiplicative inverse

For given numbers `a` and `m`, the **Modular Multiplicative Inverse** is such `I` that:

```
a * I ≡ 1 (mod m)
```

Why the name? Normally, a **multiplicative inverse** would mean such `x` that `a * x = 1`. Here, I also have `mod`
so it's **modular**.

How do I find it? It's usually small-ish, so I iterate from 1 until I find it. General code looks like this (in java or
python):

```java
private static long modInverse(long a, long m) {
  for (long x = 1; x < m; x++) {
    if ((a * x) % m == 1) return x;
  }
}
```

```python
def mod_inverse(a, m):
  for x in range(1, m):
    if (a * x) % m == 1:
      return x
```

# Solution

Generally, the equations are:

```
T ≡ a1 (mod m1)
T ≡ a2 (mod m2)
T ≡ a3 (mod m3)

... (can be more, I stick to 3)
```

First, calculate the **Total Modulus** `M`:

```
M = m1 * m2 * m3

M = 5 * 11 * 13 = 715
```

Now, for each entry in the set of congruences I'll do the following:

- Count `Mi` equal to **product of other moduli**. I won't multiply the other, I will divide `M` by my modulo `mi`
  instead.

```
Mi = M / mi

M1 = 715 / 5 = 143
M2 = 715 / 11 = 65
M3 = 715 / 13 = 55
```

- Find **Modular Multiplicative Inverse** `Ii` of each entry (using the algorithm above).

```
Ii = modInverse(ai, mi)

I1 = 2
I2 = 10
I3 = 9
```

- Calculate **Term Contribution** `Ti`

**Term contribution** is calculated by multiplying three numbers:

```
Ti = ai * Mi * Ii

T1 = 3 * 143 * 2 = 858
T2 = 7 * 65 * 10 = 4550
T3 = 2 * 55 * 9 = 990
```

After these are known, I sum them up:

```
Tsum = T1 + T2 + T3 = 858 + 4550 + 990 = 6398
```

The final solution `T` is found by finding:

```
T = Tsum % M = 6398 % 715 = 678
```

The general solution for the case is:

```
T mod (M)

678 mod (715)
```

With earliest `T` being `678`.

---
