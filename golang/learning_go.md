# Learning Go

## Getting the start

Installation of Go involves some steps, but it's [well documented](https://golang.org/doc/install). If you followed the steps correctly, you should have the Go compiler installed without any issue.

As recommended in the official site, I started learning the basics with the in-browser [tour of Go](https://tour.golang.org/list). It covers the essentials of Go with good examples. Once you are done with the tour, I recommend reading [Effective Go](https://golang.org/doc/effective_go.html), which has a good coverage on how to write idiomatic Go code.

Make sure you configure your text editor to support Go syntax highlighting before moving on to coding. Here's a [comprehensive list](http://go-lang.cat-v.org/text-editors/) with details on how to configure Go for various editors.

## Reference

Being a new language (and terribly named), Google search isn't that much of a help when coding Go. I recommend to keep the [language spec](https://golang.org/ref/spec) at you disposal and always refer to it when in doubt. I hope more resources would be available as the language gains more popularity.

One of the best features of Go is its rich [standard library](https://golang.org/pkg/)(or default packages). You will find default packages for most common tasks such as [handling HTTP requests](https://golang.org/pkg/net/http/), [image manipulation](https://golang.org/pkg/image/), [cryptography](https://golang.org/pkg/crypto/) and [encoding/decoding JSON](https://golang.org/pkg/encoding/json/). Most of these packages contains good documentation and package documentation also links to source files of the package, making it easier to read the code.

You will find lot of third-party packages written in Go.

## Organizing Code

In Go, you have to organize your code using packages. Every file in a Go program should belong to a package. During the compilation, compiler will combine all files with same package clause together. There's no requirement to keep the files of same package in the same directory. You have the flexibility to physically organize your files in a way you prefer. However, you can have only one package clause for a file.

Inside a package you can declare variables, constants, types and functions. All these top level declarations will be scoped to the package. If you want expose an identifier to outside, you must start its name with a capital letter. In Go this is known as `exporting` and there's no concept of access modifiers, which's one thing less to worry when coding Go.

To use a package in another place you must import it. Imports are scoped to the file, so if you use a package on different files they must all individually import it, even if they all belong to the same package.

Here's an example of a typical Go file. Note the package clause, import and exporting of function identifier.

```
package foo

import "bar"

var my_var = "baz"

func Baz() string {
    return my_var 
}
```

## Identifiers & Declarations

Identifiers can only contain unicode letters, digits and underscore (`_`). This means identifiers such as `awesome?` is invalid, but you can have identifiers such as as `µ` (using unicode letters).

In Go, you can declare multiple identifiers using expressions. Since functions can also return multiple values, we can have expressive statements like this:

```
var x, y = getCoords()
```

Imagine if you are only concerned about the `y` value in the above context and doesn't actually need `x`. You can assign the blank identifier(`_`) to the values you are not interested. So the above example can be modified to:

```
var _, y = getCoords()
```

You can also group declarations with brackets.

```
var (
        name string 
        age = 20
)
```

Apart from using var to declare variables, there's also a short-hand form using `:=`. Here you can omit the type and let it to be deduced at the runtime from the expression. Short-hand form can only be used inside functions (and also in some cases as initializers for if, for and switch statements). You can also declare multiple variables with the short-hand expression. Another interesting thing here is you are allowed to redeclare variables in multi-variable short-hand declarations if there's at least one new variable in the declaration. Here's an example:

```
func name() string {
    first_name := "John" 
    first_name, last_name := "Peter", "Pan"

    return first_name + " " + last_name 

}
```

## Functions & Methods

As I mentioned earlier, functions in Go can have multiple returns. In idiomatic Go, main purpose of multiple returns is for error handling. You define one parameter as the result and other parameter as the error. Caller of the function should check for the value of error parameter and handle if there's an error. Let me explain this with an example:

```
func getFile() (file *File, error os.Error) {
    ...
} 

func process() string {
    file, error := getFile()

    if error != nil {
      print("Error occurred in retrieving the file.")
      return ""
    }

    // do something with the file

    return result
}
```

Every function in Go must always end with a `return` statement or a `panic` statement or have no return values. You cannot simply return inside a control statement such as `if` or `switch` (Update: As Jeff Wendling mentioned in comments you can do this, if you have a `return` statement also at the end). Some may call this a language feature that helps to the code more obvious, but the Go core team accepts this as a known issue: [http://code.google.com/p/go/issues/detail?id=65](http://code.google.com/p/go/issues/detail?id=65)

Go do also have methods. But unlike in other languages where methods are bound to objects, in Go methods are bound to a base type (actually, Go doesn't have a concept of objects). Basically, a method is same as a function with a explicit receiver defined as the first argument. Note that you can define methods only for the types declared in the same package.

Here's an example on how methods can be defined and called.

```
type mystring string

func (s mystring) capitalize() string {
    ...
}

func main() {
    var str mystring = "paul"
    print(str.capitalize())
}
```

## String & Character Literals

Similar to C, Go has both character literals and string literals. Character literals should be written inside single quotes ('a' or '\u12e4').

String literals can be in two forms. One is known as the raw form, where you write the string inside back quotes (\`abc\`) and the other is known as the interpreted form, where the string is written inside double-quotes ("abc"). Strings in raw form can span multiple lines, while interpreted string must be in a single line. In raw form if you write \`\n\` it will be output as it is, whereas in interpreted form it will treated as in the context of character literals (escapes properly and creates a new line).

Don't confuse interpreted-form to string interpolation you find in other languages. Closest thing to string interpolation in Go is `fmt.Sprintf` function.

```
fmt.Sprintf("The value is %v", 15) //output: The value is 15
```

## Control Flow

There are two ways to do control flow in Go - using `if` and `switch` statements. You can provide an initializer statement before the conditional expression. These expressions need not to be wrapped in parenthesies.

Branches in `if` statements should always be written inside blocks(enclosed by {}). Go doesn't support ternary operator (?:) or single line if statements as in other languages. When writing an else statement it should always be in the same line with closing curly backet of the previous `if` branch.

```
if a := getScore(); a > 500 && game_over == true {
    print("You have a high score!")
} else {
    print("You score is low!")
}
```

Cases in `switch` statements has implicit break in Go. There's no default cascading through case statements (Update: As Jeff Wendling mentioned in the comments you can use `fallthrough` keyword to cascade through cases). If you want multiple cases to provide same behavior you may define them in a comma separated list. Also, in `switch` statements you can omit the expression if you want, such instances are evaluated as `true`.

```
switch color {
    case "red": print("danger")
    case "green", "yellow", "blue": print("normal")
}
```

## Compiling

Go's compiler follows a no bullshit approach and quite adamant about the structure of your code. There's no such a thing as warnings in Go compiler. If it finds an issue it won't just compile. Importing packages and not using them, declaring variables and not using them will stop compiler from compiling your code. At the beginning, you will feel such nitpickings are a hindrance, but as you get used to it you will feel you are writing more clean code.

In this post, I touched only the surface of Go programming. In future posts, I'm planning to dig deeper covering topics such as slices, interfaces, channels, goroutines and testing.
