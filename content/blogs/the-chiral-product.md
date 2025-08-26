# The Chiral Product: An Algebraic Approach to Mutation in Linearly Typed Systems

<!-- > I will show that by adjoining a chiral product type to linear typing one can represent objects with channels between them like the disjunctive product,
> but with the added constraint that information only flows one way,
> that is to say that the behaviour of eliminating the past cannot depend on the elimination of the future.
> This produces a finer gradation of product types that I will demonstrate invaluable in constructing a purely algebraic approach to mutation handling. -->

> By adding a non-commutative product type to linear typing we can represent directed communication, and hence the flow of time.
> Such a system can very naturally represent mutation and I hope that by the end of this you see the same promise in this system that I do.

*The reader should be familiar with programming using channels for concurrency or parallelism, and references in strongly typed systems*

*It is not required for you to know about category theory or type theory but certain concise explanations and technical sections may require it.*
*These sections will be annotated with the following symbol (* --[summary_icon]-- *) as not to spook more casual readers.*

## Introduction

Mutation handling in languages tend to have 3 main goals that up until now have formed an impossible triangle:

- Safety:
  Often in the form of memory aliasing rules, safety is important to ensure memory is not corrupted from different regions of code operating on the same region of memory.
- Versatility:
  A solution to mutation handling can only be as effective as its domain of application is broad, at the end of the day all systems have their limits but a system that is too weak can lead its users to write against the language and not with it.
- Simplicity:
  Overbearing semantics can impose roadblocks on development by requiring large type-level refactors for behavioural changes to codebases.

Most languages have historically opted to ditch safety in favour of versatility and simplicity. This naively maximises the space of valid programs and in doing so diluting what it even means for a program to be valid.

Some languages provide safety and simplicity, usually by leveraging calling conventions. The downside of is that because captures are not represented in the type system, they cannot be processed using custom data-structures, only with language provided control flow. *It is important to note that this is often sufficient for a wide variety of use cases*.

Finally, and gaining traction, are approaches that maximise versatility whilst maintaining safety. This includes type level abstractions like state monad transformers, and lifetimes. These approaches have a certain virality, often prompting and subsequently complicating large refactors by introducing a lot of book-keeping which can be hard to encapsulate.

I aim to make progress towards a solution that solves **all** the above problems whilst maintaining the deadlock free guarantee from linear typing, hopefully allowing for the writing of strongly normalising languages that are safe, versatile, and simple to use.

## Preface

I will use a bastardised Haskell syntax for talking about the type system itself in terms of building blocks we can compose together.

A rust inspired syntax will then be used to describe the programs we would like to represent.

It is important to specify that all resources are consumed **by value** unless specified otherwise, even when I am using Haskell syntax.
I was debating wether to use syntax from the experimental GHC extension [linaer haskell](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/linear_types.html) to express this, but decided against it for the sake of clarity.
When I say something like "duplicate" or "drop" I am on about a process that is done by value, as opposed to cloning by immutable reference or implementing destructor logic by mutable reference.

For those unfamiliar with haskell:

- The symbol `::` binds the identifier on the left to the type on the right (I know its dumb).
- The type `a -> b` represents a function from type `a` to type `b`.

<!-- The type `a ~= b` (with the same precedence as `->`) represents an [isomorphism](https://en.wikipedia.org/wiki/Isomorphism) between type `a` and type `b`
(meaning `a` and `b` can be swapped between by value without complication). -->

## Intro To Linear Typing

--[h2_content[--

Many readers will be familiar with the [rust language](https://www.rust-lang.org/), which uses a type system that doesn't assume that provided resources can be duplicated, this is called Affine typing in the technical lingo. Linear typing takes this one step further and also does not assume that a provided resource can be dropped.

Written in terms of contracts between different areas of the program:

- Entitlements may not be exceeded.
- Obligations may not be avoided.

The first type we have to introduce is called the **linear consumer**, denoted `~a`.
It is satisfied by consuming a single instance of `a` and notably cannot be duplicated or discarded (this is similar to [`oneshot::Sender`](https://docs.rs/futures/latest/futures/channel/oneshot/struct.Sender.html) in rust).

The nature of its consumption is defined by the function:
```hs
send :: (a, ~a) -> ()
```

Which combines the values together, annihilating them both.

### Product Types

<!-- --[details[--

**What constitutes a product type?**

--], [--

A bifunctor `P` is a **product type** iff:

- `P` is associative, satisfying the [pentagon identity](https://ncatlab.org/nlab/show/pentagon+identity#idea).
- There is a lifting natural transformation from the *conjunctive* product (`,`) to `P` that respects the [pentagon identities](https://ncatlab.org/nlab/show/pentagon+identity#idea)
- There is a lifting natural transformation from `P` to the *disjunctive* product (`||`) that respects the [pentagon identities](https://ncatlab.org/nlab/show/pentagon+identity#idea).
- `P` is [strong](https://ncatlab.org/nlab/show/tensorial+strength#definition) over the *conjunctive* product (`,`) commuting with the associators and the lifting morphism.
- `P` is co-[strong](https://ncatlab.org/nlab/show/tensorial+strength#definition) over the *disjunctive* product (`||`) commuting with the associators and the lifting morphism.

--], [--

A **product type** is:

- Associative.
- An inclusive super-type of (`,`) and an inclusive sub-type of (`||`).

--]]-- -->

Product types allow developers to type data consisting of multiple values with their own types, if this sounds familiar, thats because it is!
Its essentially a *struct* type.

One of the main advantages of linear typing is that it makes deadlocks impossible, allowing you to guarantee halting in your programs.

To see how, suppose we naively implement the [oneshot channel](https://docs.rs/futures/latest/futures/channel/oneshot/fn.channel.html), similar to how it is in rust:
```hs
oneshot :: () -> (~a, Future a)
```

Using this we can construct the following **deadlock** causing program:
```rs
let sender, reciever = channel()
let value = reciever.await
send(value, sender)
```

The issue here is that we were allowed to use both the sender *and* the reciever in the same scope.

To make this **impossible** linear typing introduces *parallel structs*, a way to store multiple values that must be used entirely independently, often by construting seperate independent scopes.

The simplest of these structures is called *par*, *par* (the parallel product) is to parallel structs what *tuple* (the normal product) is to regular structs.

> The *par* of two types `a` and `b` is written `a || b`.

<!-- The regular (conjunctive) product type will be written `a, b`. Its instances are comprised of two **entirely independent** values which you can do with as you please, this is the product type as you are used to it.

The parallel (disjunctive) product type will be written `a || b`. Its instances are comprised of two **arbitrarily dependent** values which you must handle with care, restricting your options significantly, as you are forced by the rules of linear logic to disallow any form of interaction lest you introduce a deadlock.

Both of these product types are commutative (there exists `a, b ~= b, a` and `a || b ~= b || a`). -->

This lets us implement our original channel safely!:
```hs
oneshot :: () -> (~a || a)
```

As stated so far parallel structs are very limited, this is important for safety garuntees but I still need to explain what they *can* do, not just what they *can't* do.

Parallel structs may be destructured and then used to construct new parallel structs so long as what is initially forced to be handled in parallel stays in parallel. This raises the question of what you can do with values from two seperate parallel structs?

A single pair of values from two seperate parallel structs may be used together, with absolute freedom, this *connects* the original structs forcing the result and all other values to be handled in parallel. This forces a tree structure on *connections*, avoiding deadlocks.

In the case of par this allows us to define:
```hs
link :: ((a || b), (c || d)) -> ((a, c) || b || d)
```

<!-- ### Continuations

In linear logic a `Future` is simply a consumer of a consumer:
```hs
type Future a = ~(~a)
```

Futures are important as they are the basis of how constructs like the parallel product operate, the values contained within are not merely stored by value, but are accessed by means of providing continuations.

For example, if you are left with but a single value in the parallel product you may extract it as a future:
```hs
extract_parallel :: a || () -> Future a
```

--[details[--

**How may you use a `Future`?**

--], [--

The covariant functor `Future` is a monad.

--], [--

The `Future` generic behaves more or less how it does in most languages with `async`.

Although it lacks the ability to be polled in custom ways.

--]]-- -->

### Naive Mutation

The typical way to formulate a mutable reference in a linearly typed system is to model it as a value-consumer pair:
```hs
type &inout a = (a, ~a)
```

...allowing you to modify by value, and send the result to the owner once you are done!

In such a system borrowing has the following signature:
```hs
borrowInOut :: a -> (&inout a || a)
```

--]]--

## Problem Statement

We now have the context to analyse the following program with linear typing:
```rs
let mut a = 1
let mut b = 2

swap (&mut a) (&mut b)

a + b
```

Lets try to construct this with the tools above.

- We start with a pair of values `1, 2` of type `Int, Int`.
- Next lets apply `borrowInOut` to each value to get `(InOut Int || Int), (InOut Int || Int)`.
- This sets us up to use `link`, this modifies the state to `(InOut Int, InOut Int) || Int || Int`.
- Both mutable references can now be used together so we can swap them, leaving us with `Int || Int`.
- And from here... from here we are stuck.

Our values are now in parallel and must be handled separately, meaning we can't do the final step of adding them together.
There is no way to avoid this with current linear typing as the type system is blind to the following two things:

- The type `Int` has no way to *send* information to anything else in the program, and so there is no deadlock to be avoid by forcing integers to be handled independently.
- The statement `swap (&mut a) (&mut b)` depends in no way on the statement `a + b`, there is an order to these operations.

Current linear typing has no way to represent a *directed* flow of information and hence time.

> It is this specific capacity, that I have now introduced!

## The Ingredients --[wip]--

--[h2_content[--

### The Chiral Product

The first thing to be added is the namesake of this blog, the chiral product!

The chiral product is like an inbetween of the tuple (`a, b`) and par (`a || b`), and will be written `a >> b`, read `a` *then* `b`.

Where the tuple holds values that don't communicate at all, and par holds values that may communicate arbitrarily, the chiral product has *directional* communication.
The value on the left which we call the *present* can send information to the value on the right which we call the *future* but importantly, this does not go the other way around!

> *The past may not depend on the future*.

This ends up being incredibly useful, the tuples natural counterpart is par, and the natural counterpart of par is the tuple; they fit together nicely, one as computation, the other as data.
The chiral product is interesting, its natural counterpart is... itself! This is codified in the following rule:
```hs
weave :: ((a >> b), (c >> d)) -> ((a, c) >> (b, d))
```

### Purity --[wip]--

Having to worry about forming deadlocks by adding two `Int`s together seems overly paranoid, but how do we formalise this?

In less *fun* type systems purity is considered a property of the whole language, this is often described as a garuntee that evaluating the same piece of code will always give the same result, we can express this as a property of values instead.
A value is pure if it cannot communicate information to any other part of the program, it may have its own rich channel structure, but so long as it can't effect anything else its none of our concern.

We can now introduce our next ingredient, the `Pure` *modality*! 

The type `Pure a` is inhabited by all the instances of `a`, that are **pure**, it really is that simple. Speaking of- we call a type **simple** of all of its instances are **pure**, making the type itself overlap entirely with the pure modality.

In our example `Int` is a **simple** type.

<!-- --[details[--

**How can can you create `Pure` values?**

--], [--

`Pure` is a comonadic modality that is strong monoidal over positive conjunctives.

--], [--

From smaller pure values and from pure processes that only take in pure values.

Non-trivial pure instances tend to require a decent amount of effort to construct.

--]]-- -->

This tends to be a rather tricky property to create, so lets go over how it can be used!

Purity can persist into the future, as by definition the future can have no effect on the present:
```hs
depend :: Pure (a >> b) -> a >> Pure b
```

The information that purity provides also allows us to refine our product types into more useful forms:
```hs
sequence :: (a || Pure b) -> (a >> Pure b)

isolate :: (Pure a >> b) -> (Pure a, b)
```

The `sequence` rule in particular can be combined with `oneshot` to create a strictly directed channel:
```hs
retain :: () -> (~(Pure a) >> Pure a)
```

Using this with `weave` lets us send pure values to the future without worry!

### Borrowing --[wip]--

Finally, what we have all *hopefully* been waiting for, the mutation handling!
We can finally replace `&inout` with a primitive custom tailored to this system.

We may get a mutable reference in the present, and the borrowed value will eventually be used again in the future:
```hs
borrow :: a -> (&mut a >> a)
```

We may mutate a borrowed value so long as the process is pure and the result is not dependent on the future value:
```hs
mutate :: (&mut a, Pure (a -> b >> a)) -> b
```

> Shockingly this only takes two axioms.

The signature of `mutate` ensures that impurities cannot be introduced to the value being modified, this keeps the strict garuntees of the chiral product producted agains sneaky deadlocks.
This also means it is safe to treat a `&mut (Pure a)` as a `&mut a`, removing a potential function colouring issue that we can codify with a 3rd and final mutation axiom:
```hs
demote :: &mut (Pure a) -> &mut a
```

Although this is hardly the snazziest thing one can do with a `&mut (Pure a)`, by using a `retain` channel to satisfy `mutate` we can extract both the old value and a consumer to send the value to the future. If this sounds familiar, thats because its precisely `&inout`:
```hs
inout :: &mut (Pure a) -> &inout (Pure a)
```

This means that for pure values `&mut` and `&inout` are essentially the same, simplifying operations dramatically.

--[details[--

**My notes on mutual mutation.**

--], [--

It may perhaps be correct to generalise the `mutate` rule to accept a product of mutable references as input and force a certain structure to be preserved whilst emmiting a value. Intuitively such a rule *should* allow one handle 2 orthogonal mutations at the same time, returning a tuple of the result, whilst allowing room for some extra safe interaction.

The following allows orthogonal mutations:

```hs
mutate_pair :: (&mut a0, &mut a1) -> (Pure (a0, a1 -> b >> (a0, a1)) -> b)
```

But introduces deadlocks, as one mutable reference may outlive the other with no way to tell.

We could introduce an alternative definition:

```hs
mutate_pair :: (&mut a0, &mut a1) -> (Pure (a0 || a1 -> b >> (a0 || a1)) -> b)
```

However this, despite being more restrictive, this is still unsafe!

The issue is we have no clue how these mutable references relate to each other, it not safe to consume them assuming they are conjunctive and its not safe to update them assuming they are disjunctive, the only safe implementation is:

```hs
mutate_pair :: (&mut a0, &mut a1) -> (Pure (a0 || a1 -> b >> (a0, a1)) -> b)
```

Which is so restrictive as to be a joke, and I don't think it gets you anything over single mutations, nonetheless this is the best I can come up with.

--]]--

--]]--

## All Together Now --[wip]--

We now ready to face our original problem:
```rs
let mut a = 1
let mut b = 2

swap (&mut a) (&mut b)

a + b
```

We will now construct this program with our new tools.

- We again start with a pair of values `1, 2` of type `Int, Int`.
- Then we can `bororw` each `(&mut Int >> Int), (&mut Int >> Int)`.
- Now we can `weave` them together, getting `(&mut Int, &mut Int) >> (Int, Int)`.
- We can leverage the fact that `Int` is always **pure** to get `(&mut (Pure Int), &mut (Pure Int)) >> (Int, Int)`.
- Letting us apply `swap` to the borrowed values, leaving `(Int, Int)`.
- And finally, our resulting values are no longer in parallel, and we can add them together, getting just `Int` remaining.

## Conclusion --[wip]--

Yippe rawr I have the shineys.