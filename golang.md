## golang 下划线(underscore)的意义
"_"(下划线)，可以简单理解为赋值但以后不再使用，在golang中使用比较多，使用场合不单一，这里稍作总结，方便理解

### 用在import
```
import  _  "net/http/pprof"

pprof常见用法
```

引入包，会先调用包中的初始化函数，这种使用方式仅让导入的包做初始化，而不使用包中其他功能

### 用在返回值
```
for _,v := range Slice{}

_,err := func()
```

表示忽略某个值。单函数有多个返回值，用来获取某个特定的值

### 用在变量
```
type T struct{}
var _ I = T{}

其中 I为interface
```

上面用来判断 type T是否实现了 I ,用作类型断言，如果T没有实现借口 I ，则编译错误.

还比如:
```
var _ Volumes = (*Aliyun)(nil)
```
