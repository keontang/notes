# Types

One of the main reasons I embrace Golang is its simple and concise type system. It follows the principle of least surprise and as per Rob Pike these design choices were largely influenced by the prior experiences.

In this post, I will discuss some of the main concepts which are essential in understanding Golang's type system.

## Pre-declared Types

Golang by default includes several pre-declared [boolean, numeric and string types](https://golang.org/ref/spec#Boolean_types). These pre-declared types are used to construct other composite types, such as array, struct, pointer, slice, map and channel.

## Named vs Unnamed Type

reference: [https://golang.org/ref/spec#Types](https://golang.org/ref/spec#Types)

A type can be represented with an identifier (called type name) or from a composition of previously declared types (called type literal). In Golang, these two forms are known as named and unnamed types respectively.

type literal: 由先前已声明类型组合而成的类型, 包括 array, struct, pointer, slice, map, channel, function, interface. 比如 [2]int,[]int, chan int, map[string]string, *int 等. 

**A simple way of thinking about it is that named types are those you define with the type statement, and unnamed types are composite types defined by a type literal**.

Named types can have their own method sets. As I explained in a [previous post](./learning_go.md), methods are also a form of functions, which you can specify a receiver.

```
type Map map[string]string

//this is valid
func (m Map) Set(key string, value string){
    m[key] = value 
}

//this is invalid
func (m map[string]string) Set(key string, value string){
    m[key] = value 
}
```

You can define a method with named type `Map` as the receiver; but if you try to define a method with unnamed type `map[string]string` as the receiver it's invalid.

An important thing to remember is **pre-declared types are also named types**. So `int` is a named type, but `*int` or `[]int` is not.

## Underlying Type

Every type do have an *underlying* type. Pre-declared types and type literals refers to itself as the underlying type. When declaring a new type, you have to provide an existing type. The new type will have the same underlying type as the existing type.

Let's see an example:

```
type Map map[string]string
type SpecialMap Map
```

Here the underlying type of `map[string]string` is itself, while underlying type of `Map` and `SpecialMap` is `map[string]string`.

Another important thing to note is **the declared type will not inherit any method from the existing type or its underlying type**. However, method set of an interface type and elements of composite type will remain unchanged. Idea here is if you define a new type, you would probably want to define a new method set for it as well.

## Assignability

```
type Mystring string
var str string = "abc"
var my_str MyString = str //gives a compile error
```

You can't assign `str` to `my_str` in the above case. That's because `str` and `my_str` are of different types. Basically, to assign a value to a variable, value's type should be identical to the variable's type. It is also possible to assign a value to a variable if their underlying types are identical and one of them is an unnamed type.

Let's try to understand this with a more elaborative example:

```
package main

import "fmt"

type Person map[string]string
type Job map[string]string

func keys(m map[string]string) (keys []string) {
    for key, _ := range m {
      keys = append(keys, key)
    }

    return
}

func name(p Person) string {
    return p["first_name"] + " " + p["last_name"]
}

func main(){
    var person = Person{"first_name": "Rob", "last_name": "Pike"}
    var job = Job{"title": "Commander", "project": "Golang"}

    fmt.Printf("%v\n", name(person))
    fmt.Printf("%v", name(job)) //this gives a compile error

    fmt.Printf("%v\n", keys(person))
    fmt.Printf("%v\n", keys(job))
}
```

Here both `Person` and `Job` has map[string]string as the underlying type. If you try to pass an instance of type `Job`, to `name` function it gives a compile error because it expects an argument of type `Person`. However, you will note that we can pass instances of both `Person` and `Job` types to `keys` function which expects an argument of unamed type `map[string]string`.

If you still find assignability of types confusing; I'd recommend you to read the explanations by Rob Pike in [the following discussion](#qat).

## Type Embedding

Previously, I mentioned when you declare a new type, it will not inherit the method set of the existing type. However, there's a way you can embed a method set of an existing type in a new type. This is possible by using the properties of annonymous field in a `struct` type. When you define a annonymous field inside a `struct`, all its fields and methods will be promoted to the defined struct type.

```
package main

type User struct {
    Id   int
    Name string
}

type Employee struct {
    User       //annonymous field
    Title      string
    Department string
}

func (u *User) SetName(name string) {
    u.Name = name
}

func main(){
    employee := new(Employee)
    employee.SetName("Jack")
}
```

Here the fields and methods of `User` type get promoted to Employee, enabling us to call `SetName` method on an instance of `Employee` type.

## Type Conversions

Basically, you can convert between a named typed and its underlying type. For example:

```
type Mystring string

  var my_str Mystring = Mystring("awesome")
  var str string = string(my_str)
```

There are [few rules](https://golang.org/ref/spec#Conversions) to keep in mind when it comes to type conversions. Apart from conversions involving string types, all other conversions will only modify the type but not the representation of the value.

You can convert a string to a slice of integers or bytes and vice-versa.

```
[]byte("hellø")

string([]byte{'h', 'e', 'l', 'l', '\xc3', '\xb8'})
```

More robust and complex run-time type manupilations are possible in Golang using the Interfaces and [Relection Package](https://blog.golang.org/laws-of-reflection). We'll see more about them in a future post.

# <h2 id="qat">question about types</h2>

---
jm:
```
Hi,
In the program below, can someone explain why the compiler treats Int and int as non-interchangeable but 
map[interface{}]interface{} and Map as interchangeable?

Note, when lines 42 and 43 are uncommented, this is what the compiler gives:
     test2.go:42: cannot use i2 (type Int) as type int in function argument
     test2.go:43: cannot use i (type int) as type Int in function argument

I am using the latest 8g compiler.

Thanks,
John

-----

//

package main

import (
        "fmt"
        "reflect"
)

type Int int
type Map map[interface{}]interface{}

func Printint(i int) {
        fmt.Printf("int (%s) (%v)\n", i, i)
}

func PrintInt(i Int) {
        fmt.Printf("Int (%s) (%v)\n", i, i)
}

func Printmap(m map[interface{}]interface{}) {
        fmt.Printf("map (%v)\n", reflect.Typeof(m))
        for k, v := range m {
                fmt.Printf("k (%v) v (%v)\n", k, v)
        }
}

func PrintMap(m Map) {
        fmt.Printf("Map (%v)\n", reflect.Typeof(m))
        for k, v := range m {
                fmt.Printf("k (%v) v (%v)\n", k, v)
        }
}

func main() {
        i := 1
        i2 := Int(2)

        Printint(i)
        PrintInt(i2)

        //Printint(i2)        // line 42: won't compile
        //PrintInt(i)        // line 43: won't compile

        fmt.Printf("-----\n")

        m := map[interface{}]interface{} {
                "x": 1,
        }

        m2 := Map {
                "x": 2,
        }

        fmt.Printf("m (%v)\n", reflect.Typeof(m))
        fmt.Printf("m2 (%v)\n", reflect.Typeof(m2))

        Printmap(m)
        PrintMap(m2)

        Printmap(m2)
        PrintMap(m)
}
```

---
Rob 'Commander' Pike:
```
It's all in the spec.  Int and int are both named types, so they are
different types.  Map is a named type but map[interface{}]interface{}
is not; since their separate declarations are identical they can be
assigned between.
Here's a much simpler example showing the effect; since Pint and *int
are equivalent but only one is named. This compiles without incident.

package main

func main() {
        type Pint *int
        var p *int
        var P Pint
        p = P
        _ = p
}

-rob
```

---
jm:
```
On 12/09/2010 09:22 PM, Rob 'Commander' Pike wrote:
> It's all in the spec.
Sorry. I was looking everywhere but.

>    Int and int are both named types, so they are
> different types.  Map is a named type but map[interface{}]interface{}
> is not; since their separate declarations are identical they can be
> assigned between.
>
> Here's a much simpler example showing the effect; since Pint and *int
> are equivalent but only one is named. This compiles without incident.
Having read the spec, I've another question. So in your example, if I did something
like:
     type Xint Pint
Pint and Xint are named types with *int as the underlying type (right?). Now Xint
and Pint will be treated as *int and can be passed to "func x(*int)", but Xint will
_not_ be treated as Pint, and cannot be passed to "func y(Pint)", is that correct?
If this is true, can you give an explanation (or point me to the doc) on why this is
so (I suspect my misunderstanding is b/c of coming from OO).

Thanks,
John

> package main
>
> func main() {
>         type Pint *int
>         var p *int
>         var P Pint
>         p = P
>         _ = p
> }
>
>
> -rob
```

---
Rob 'Commander' Pike:
```
That's correct.
The reasoning goes like this: If you take the trouble to name Pint and
Xint, it's because you want them to be distinct.  (This isn't C, where
a typedef is just an alias.)  But sometimes it makes sense to speak of
the structure as all you care about; consider things like the indexing
functions in the bytes package.  So we allow assignment in those
cases.

The motivating example in our thinking was something like type Point
struct { X, Y float }.   Another named type with the same fields
probably is a different idea or it would share the declaration; they
shouldn't be interchangeable.  Another way to say it is that if they
don't have the same methods (even potentially), they shouldn't be
assignable.  On the other hand a generic struct { X, Y int } is
talking just about the structure, not its interpretation, so it makes
sense to allow assignment between that type and Point.

Also, although I cannot reconstruct the history, the current rules
were arrived at largely through experience coupled with a desire for a
simple specification.  They aren't arbitrary.

-rob
```

---
soapboxcicero:
```
I've never had a problem with this aspect of the type system but I've
always felt a bit uneasy about this distinction in a way I couldn't
articulate. After reading the last e-mail, I feel quite enlightened,
however. Thanks for the lucid explanation, Rob. And thank you for
asking the question, John.
```

---
jm:
```
Thanks. Just what I was looking for.
So, other than explaining how types work, is there much of a use case
for the T2 in the examples in the spec?

    type T1 string
    type T2 T1

It would seem that "type T2 T1" actually hides (e.g., if it was in a
separate file) the fact that the underlying type of T2 is string and could
only be used with functions dealing with string (and those of T2).

Thanks again,
John
```

---
Steven Blenkinsop:
```
On Thursday, December 9, 2010, John Marshall <John.M...@ec.gc.ca> wrote:
> Thanks. Just what I was looking for.
>
> So, other than explaining how types work, is there much of a use case
> for the T2 in the examples in the spec?
>
>    type T1 string
>    type T2 T1
>
> It would seem that "type T2 T1" actually hides (e.g., if it was in a
> separate file) the fact that the underlying type of T2 is string and could
> only be used with functions dealing with string (and those of T2).
>
> Thanks again,
> John
>
string is another named type so you couldn't pass a T1 where a string
is expected. The use in the spec is for illustration purposes. The
purpose of such a declaration could be to ensure the two types T1 and
T2 are represented the same even if that representation changes, so
they will always be conversion compatible. This makes more sense in
the more complex case of a struct type, where it's not only more
likely for the definition to change, but this type of transitory
declaration reduces code duplication and makes the relationship clear,
and it may not even be possible to declare the two types independently
of each other and still have them be conversion compatible (if the
types are declared in separate packages and have private fields).
```

---
jm:
```
On 12/10/2010 12:28 AM, Steven wrote:
> On Thursday, December 9, 2010, John Marshall<John.M...@ec.gc.ca>  wrote:
>> Thanks. Just what I was looking for.
>>
>> So, other than explaining how types work, is there much of a use case
>> for the T2 in the examples in the spec?
>>
>>     type T1 string
>>     type T2 T1
>>
>> It would seem that "type T2 T1" actually hides (e.g., if it was in a
>> separate file) the fact that the underlying type of T2 is string and could
>> only be used with functions dealing with string (and those of T2).
>>
>> Thanks again,
>> John
>>
> string is another named type so you couldn't pass a T1 where a string
> is expected.
Oops. I knew that :)

> The use in the spec is for illustration purposes. The
> purpose of such a declaration could be to ensure the two types T1 and
> T2 are represented the same even if that representation changes, so
> they will always be conversion compatible. This makes more sense in
> the more complex case of a struct type, where it's not only more
> likely for the definition to change, but this type of transitory
> declaration reduces code duplication and makes the relationship clear,
> and it may not even be possible to declare the two types independently
> of each other and still have them be conversion compatible (if the
> types are declared in separate packages and have private fields).
Thanks Rob and Steven.
John
```


# reference

1. [http://www.laktek.com/2012/01/27/learning-go-types/](http://www.laktek.com/2012/01/27/learning-go-types/)
2. [https://golang.org/ref/spec](https://golang.org/ref/spec)