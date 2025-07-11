---
layout: post
title: "Chinese Remainder Theorem"
categories: [ math ]
---

The general shape of a problem the Monotonic Stack solves is:

> Find the next element that breaks a trend (or count for how many elements a certain trend holds)

Examples are:

- find the next greater element
- find the next element which breaks monotonicity
- find how many buildings you can see from each building
- find the largest histogram

The input is usually an **array**. If it's not, you need to **build the array** or work with {value, index/span}. You NEED the information about position or span.

General intuition:
- Maintain a stack that has an **invariant**
- _**The invariant will be manually maintained**_ ← the most important thing to find here
- Only the elements removed from the stack are considered having a value. Whatever stays, has no answer.

  Insight:
- The stack can either contain **questions** (indices) or **answers** (values).
  - It depends on the direction of processing.
  - If you didn't see the answer yet, you store questions (indices). Else you store answers (values)

```java
Stack<Integer> stack = new Stack<>();

public int[] processAnswersToRight(List<Integer> input) {
  int[] result = new int[input.length];
  for (int i = 0; i < input.length; i++) {
    int nextValue = input[i];

    while (!stack.isEmpty() && nextValue > input[stack.peek()]) { // Trend broken
      int indexToAnswer = stack.poll();
      result[indexToAnswer] = nextValue;
    }

    stack.push(i); // The index we just processed has to be answered
  }
  return result;
}
```

---
