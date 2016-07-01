## Remove the trailing comma from json file

For example:
```
{
    "name": "Deamon",
    "age": 20,
}
```

We need to remove the trailing comma after `20`.

We can use sed to do this:
```
sed -i -zr 's/,([^,]*$)/\1/' xxxx.json
```

`-zr` means:
```
-z, --null-data
    separate lines by NUL characters

-r, --regexp-extended
    use extended regular expressions in the script.
```
