# golang web 基础

## net/http 包分析

http 包提供了 HTTP 客户端和服务端的实现。

### 简易的http服务

首先让我们从一个最基本的http服务来入手，之后顺藤摸瓜，看看各个关键结构的定义。

```
package main

import (
  "io"
  "log"
  "net/http"
)

type a struct{}

func (*a) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  io.WriteString(w, "hello world version 1.")
}

func main() {
  err := http.ListenAndServe(":8080", &a{})
  if err != nil {
      log.Println(err.Error())
  }
}
```

main 函数中，调用 http.ListenAndServer 函数，监听 8080 端口。ListenAndServe 的第二个参数是一个自定义的结构 a 的实例，我们进入 ListenAndServer 中来看一下其定义：

```
func ListenAndServe(addr string, handler Handler) error {
  server := &Server{Addr: addr, Handler: handler}
  return server.ListenAndServe()
}
```

可以发现，第一个参数 addr 是一个 string，第二个参数 handler 是一个 Handler 结构，之后把这两个参数分别传入到 Server 结构中，再调用这个 Server 结构的 ListenAndServe() 方法。

接着我们看一下Handler接口的的定义:

```
type Handler interface {
  ServeHTTP(ResponseWriter, *Request)
}
```

明白的看到，只要是实现了 ServeHTTP 方法的实例就实现了 Handler 接口，可以作为 ListenAndServer 的第二个参数传入。这个 ServeHTTP 的两个参数就是 web 中典型的 request 以及 response 的那种形式。其中 request 是一个实际的结构，而 response 是一个接口。因为 net/http 包已经能够根据请求信息，自动帮我们创建 Request 结构体对象了。那么，net/http 包能不能也自动帮我们创建 Response 结构体对象呢？当然不能。因为很显然，对于每个服务器程序，其行为是不同的，也即需要根据请求构建各样的响应信息，因此我们只能自己构建这个 Response 了。

为了能更好地帮助我们，net/http 包首先为我们规定了一个构建 Response 的标准过程。该过程就是要求我们实现一个 Handler interface。

之后我们来看一下Server结构，这个结构定义了运行一个Http服务的相关的参数：

```
type Server struct {
  Addr           string        // TCP address to listen on, ":http" if empty
  Handler        Handler       // handler to invoke, http.DefaultServeMux if nil
  ReadTimeout    time.Duration // maximum duration before timing out read of the request
  WriteTimeout   time.Duration // maximum duration before timing out write of the response
  MaxHeaderBytes int           // maximum size of request headers, DefaultMaxHeaderBytes if 0
  TLSConfig      *tls.Config   // optional TLS config, used by ListenAndServeTLS

  // TLSNextProto optionally specifies a function to take over
  // ownership of the provided TLS connection when an NPN
  // protocol upgrade has occurred.  The map key is the protocol
  // name negotiated. The Handler argument should be used to
  // handle HTTP requests and will initialize the Request's TLS
  // and RemoteAddr if not already set.  The connection is
  // automatically closed when the function returns.
  TLSNextProto map[string]func(*Server, *tls.Conn, Handler)

  // ConnState specifies an optional callback function that is
  // called when a client connection changes state. See the
  // ConnState type and associated constants for details.
  ConnState func(net.Conn, ConnState)

  // ErrorLog specifies an optional logger for errors accepting
  // connections and unexpected behavior from handlers.
  // If nil, logging goes to os.Stderr via the log package's
  // standard logger.
  ErrorLog *log.Logger

  disableKeepAlives int32 // accessed atomically.
}
```

目前在这个例子中，我们就先深入到这个程度，只要知道，在最后的 server.ListenAndServe() 中，server 的 Handler 参数的 serverHTTP 方法会被调用，就可以了，具体细节先不做分析，当然还做了许多额外的操作。就是从 server.ListenAndServer 到 handler 的 ServerHTTP 方法被调用的这个过程暂不分析。只需要知道 ServerHTTP 方法被调用了就好。

### 使用 serverMux

之前的那个例子就像是学会了 1+1=2 一样，但是实际情况并没有那么简单，要是100个1相加该怎么办？还用之前的套路未免就太过原始了。越深入思考就越离本质更靠近一些。之前的思路，用一个函数来处理所有的路由情况。不论什么样的路由请求过来之后，都要去执行实例 a 的 ServeHTTP 方法，这样，实际情况下，要处理多路由的时候，ServeHTTP 就要写成类似下面这样：

```
func (*a) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    path := r.URL.String()
    switch path {
    case "/":
        io.WriteString(w, "<h1>root</h1><a href=\"abc\">abc</a>")
    case "/abc":
        io.WriteString(w, "<h1>abc</h1><a href=\"/\">root</a>")
    case "/def":
        io.WriteString(w, "<h1>abc</h1><a href=\"/\">root</a>")
    }
}
```

简单的情况下。看起来这样是可以的，如果路由很复杂呢，甚至还要分层呢？很容易想到空间换时间的思路，肯定需要一个结构把路由和对应的应该执行的函数的映射关系存起来，然后每有一个路由过来，就由一个服务去在映射关系中进行匹配，找到对应的函数去执行，再返回结果。这就用到了 serverMux 结构。

serveMux 也是一种 Handler。serverMux 的主要功能就是对发送过来的 http 请求进行分发，之后调用对应的 handler 来处理请求。 可以看一下 serverMux 以及其中的 muxEntry 的结构：

```
type ServeMux struct {
  mu    sync.RWMutex
  m     map[string]muxEntry
  hosts bool // whether any patterns contain hostnames
}

type muxEntry struct {
  explicit bool
  h        Handler
  pattern  string
}
```

可以看到，ServeMux 中的 m 用于存储映射关系，key 值为一个 string，value 值为一个 muxEntry 结构，其中包含 Handler 对象。

之后我们为之前的 server 加上新的 ServeMux 的功能：

```
package main

import (
  "io"
  "log"
  "net/http"
)

type a struct{}
type b struct{}

func (*a) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  //log.Println("the request url", r.RequestURI)
  //log.Println("r.Method", r.Method)
  io.WriteString(w, "hello world by mux the route is /a.")
}

func (*b) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  io.WriteString(w, "hello world by mux the route is /b.")
}

func main() {
  mux := http.NewServeMux()
  //往mux中注册新的路由
  mux.Handle("/a", &a{})
  mux.Handle("/b", &b{})
  //开启服务 具体的路由操作由 新生成的mux来负责
  err := http.ListenAndServe(":8080", mux)
  if err != nil {
      log.Println(err.Error())
  }
}
```

按照之前的分析，首先应该通过 mux.Handle 方法把路由注册进来，还可以看到，ListenAndServer 之前填入 Handler 实例的地方现在变成了 mux 实例，说明 mux 应该也实现了 Handler 接口的 serverHTTP 方法。首先来看一下 mux.Handle 方法：

```
func (mux *ServeMux) Handle(pattern string, handler Handler) {
  mux.mu.Lock()
  defer mux.mu.Unlock()

  if pattern == "" {
      panic("http: invalid pattern " + pattern)
  }
  if handler == nil {
      panic("http: nil handler")
  }
  if mux.m[pattern].explicit {
      panic("http: multiple registrations for " + pattern)
  }

  mux.m[pattern] = muxEntry{explicit: true, h: handler, pattern: pattern}

  if pattern[0] != '/' {
      mux.hosts = true
  }

  // Helpful behavior:
  // If pattern is /tree/, insert an implicit permanent redirect for /tree.
  // It can be overridden by an explicit registration.
  n := len(pattern)
  if n > 0 && pattern[n-1] == '/' && !mux.m[pattern[0:n-1]].explicit {
      // If pattern contains a host name, strip it and use remaining
      // path for redirect.
      path := pattern
      if pattern[0] != '/' {
          // In pattern, at least the last character is a '/', so
          // strings.Index can't be -1.
          path = pattern[strings.Index(pattern, "/"):]
      }
      mux.m[pattern[0:n-1]] = muxEntry{h: RedirectHandler(path, StatusMovedPermanently), pattern: pattern}
  }
}
```

可以看到，Handle 方法首先会把传入的 pattern 参数以及 Handler 接口存入到 mux 的 map 中，并且进行一些检测，比如该路由是否已经注册进来（explicit 参数），handle 是否为空等等。之后会判断 pattern[0] 是否为'/‘，如果不是的话，说明传过来的 pattern 可能有包含了主机的名称（这个还是不太明确，不知道什么时候会出现这种请情况）。此外还进行了一些额外的操作，比如把名称为 /path/ 的路由重定向到 /path 上面。

之后再来看一下 http.ListenAndServer 的时候，mux 的 ServerHTTP 方法是如何进行操作的：

```
func (mux *ServeMux) ServeHTTP(w ResponseWriter, r *Request) {
  if r.RequestURI == "*" {
      if r.ProtoAtLeast(1, 1) {
          w.Header().Set("Connection", "close")
      }
      w.WriteHeader(StatusBadRequest)
      return
  }
  h, _ := mux.Handler(r)
  h.ServeHTTP(w, r)
}

func (mux *ServeMux) Handler(r *Request) (h Handler, pattern string) {
  if r.Method != "CONNECT" {
      if p := cleanPath(r.URL.Path); p != r.URL.Path {
          _, pattern = mux.handler(r.Host, p)
          url := *r.URL
          url.Path = p
          return RedirectHandler(url.String(), StatusMovedPermanently), pattern
      }
  }

  return mux.handler(r.Host, r.URL.Path)
}

// handler is the main implementation of Handler.
// The path is known to be in canonical form, except for CONNECT methods.
func (mux *ServeMux) handler(host, path string) (h Handler, pattern string) {
  mux.mu.RLock()
  defer mux.mu.RUnlock()

  // Host-specific pattern takes precedence over generic ones
  if mux.hosts {
      h, pattern = mux.match(host + path)
  }
  if h == nil {
      h, pattern = mux.match(path)
  }
  if h == nil {
      h, pattern = NotFoundHandler(), ""
  }
  return
}
```

可以看到比较关键的两句: h,_:=mux.Handler(r) 会根据 request 来返回一个合适的 handler，之后调用这个返回回来的 handler 的 ServerHTTP 方法，进行具体的执行，这一段就相当于是一个分发 request 请求的作用了。再看一下后面的 Handler 的方法，如果 r.Method 不是 CONNECT 的时候，就调用 mux.handler 函数，这个函数会去具体执行匹配操作，最后返回对应的 handler 实例。之后会调用这个实例的 ServeHTTP 方法，执行真正的对应的最底层的操作。举一个极端的例子，比如有好多组件都声称自己执行的是调用数据库的操作，实际真正的操作可能是最后一个组件执行，前面几个组件只是负责转发，由于项目很大，并且为了方便扩展，就需要分层，分层之后必然虽然顶层结构清晰了，但一层一层包装下来，请求转发的工作也需要专门有组件来负责，就是将请求转到合适的下一个组件去执行。

### serverMux 中的 HandleFunc 方法

在上面的几个基本例子中，虽然我们自定义了结构体，但是只为了实现 Handler 接口，并没有添加什么个性化的操作，当然实际情况中并不总是像这样简单，但是从框架的角度讲，我们最终希望实现的是，能直接把一个方法注册给一个接口。实时上这就是 HandleFunc 方法所做的，看下面的例子：

```
package main

import (
  "io"
  "net/http"
)

func main() {
  http.HandleFunc("/", sayhello)
  http.ListenAndServe(":8080", nil)
}

func sayhello(w http.ResponseWriter, r *http.Request) {
  io.WriteString(w, "hello world by handlefunc")
}
```

我们直接通过 HandleFunc 方法把自己写的 sayhello 方法注册到了 ”/“ 的路由下，内部实现起来，无非就是程序自己帮我们生成了一个 ServMux 实例：

```
func HandleFunc(pattern string, handler func(ResponseWriter, *Request)) {
  DefaultServeMux.HandleFunc(pattern, handler)
}
```

其中的 DefaultServeMux 是系统帮我们默认生成的:

```
// DefaultServeMux is the default ServeMux used by Serve.
var DefaultServeMux = NewServeMux()
```

之后按照上面的分析，还会执行 mux.Handler 方法，只不过此时的 Mux 是系统自动帮我们 new 出来的，本质上和之前的是一样的。

## go-restful 库分析

在实际项目中，比如 k8s 的 apiserver 中，并没有像上面介绍的那么简单，为了实现路由注册时候的分层，还是有一些额外的工作要坐的，因此常常会用到各种框架，k8s 的 apiserver 中用到的是 go-restful 的工具。

go-restful 本质上来说就是对上面提到的 serverMux 的进一步封装，再起基础上又做了许多额外的工作。相当于对路由进行了分类，每次往 HandleFunc 中注册过去的路由都是一个新的类别，里面可能包含许多具体的 CURD 子路由。

比如下面这个例子：

```
package main

import (
  "log"
  "net/http"
  "strconv"

  "github.com/emicklei/go-restful"
  "github.com/emicklei/go-restful/swagger"
)

type User struct {
  Id, Name string
}

type UserResource struct {
  // normally one would use DAO (data access object)
  users map[string]User
}

//将路由以webservice的方式注册到container中
func (u UserResource) Register(container *restful.Container) {
  ws := new(restful.WebService)
  //这个是根路径
  ws.
      Path("/users").
      Doc("Manage Users").
      Consumes(restful.MIME_XML, restful.MIME_JSON).
      Produces(restful.MIME_JSON, restful.MIME_XML) // you can specify this per route as well
   //后面是根路径之后的每个具体的方法
  ws.Route(ws.GET("/{user-id}").To(u.findUser).
      // docs
      Doc("get a user").
      Operation("findUser").
      Param(ws.PathParameter("user-id", "identifier of the user").DataType("string")).
      Writes(User{})) // on the response

  ws.Route(ws.PUT("/{user-id}").To(u.updateUser).
      // docs
      Doc("update a user").
      Operation("updateUser").
      Param(ws.PathParameter("user-id", "identifier of the user").DataType("string")).
      ReturnsError(409, "duplicate user-id", nil).
      Reads(User{})) // from the request

  ws.Route(ws.POST("").To(u.createUser).
      // docs
      Doc("create a user").
      Operation("createUser").
      Reads(User{})) // from the request

  ws.Route(ws.DELETE("/{user-id}").To(u.removeUser).
      // docs
      Doc("delete a user").
      Operation("removeUser").
      Param(ws.PathParameter("user-id", "identifier of the user").DataType("string")))

  container.Add(ws)
}

// GET http://localhost:8080/users/1
//
func (u UserResource) findUser(request *restful.Request, response *restful.Response) {
             ...
}

// POST http://localhost:8080/users
// <User><Name>Melissa</Name></User>
//
func (u *UserResource) createUser(request *restful.Request, response *restful.Response) {
             ...
}

// PUT http://localhost:8080/users/1
// <User><Id>1</Id><Name>Melissa Raspberry</Name></User>
//
func (u *UserResource) updateUser(request *restful.Request, response *restful.Response) {
             ...
}

// DELETE http://localhost:8080/users/1
//
func (u *UserResource) removeUser(request *restful.Request, response *restful.Response) {
             ...
}

func main() {

   //创建一个新的container 将user的路由放到container当中
  wsContainer := restful.NewContainer()
  u := UserResource{map[string]User{}}
  u.Register(wsContainer)

  //配置swagger
  config := swagger.Config{
      WebServices:    wsContainer.RegisteredWebServices(), // you control what services are visible
      WebServicesUrl: "http://localhost:8080",
      ApiPath:        "/apidocs.json",

      // Optionally, specifiy where the UI is located
      SwaggerPath:     "/apidocs/",
      SwaggerFilePath: "/Users/emicklei/xProjects/swagger-ui/dist"}
  swagger.RegisterSwaggerService(config, wsContainer)
    //开启服务 监听8080端口
  log.Printf("start listening on localhost:8080")
  server := &http.Server{Addr: ":8080", Handler: wsContainer}
  log.Fatal(server.ListenAndServe())
}
```

结合之前的分析，可以看到 server := &http.Server{Addr: ":8080", Handler: wsContainer} 传入的 Handler 实例是一个 wsContainer，说明 wsContainer 也是 Handler 接口的一个实现，我们来看一下它的具体结构及其 ServerHTTP 方法：

```
type Container struct {
  webServices            []*WebService
  ServeMux               *http.ServeMux
  isRegisteredOnRoot     bool
  containerFilters       []FilterFunction
  doNotRecover           bool // default is false
  recoverHandleFunc      RecoverHandleFunction
  serviceErrorHandleFunc ServiceErrorHandleFunction
  router                 RouteSelector // default is a RouterJSR311, CurlyRouter is the faster alternative
  contentEncodingEnabled bool          // default is false
}

func (c Container) ServeHTTP(httpwriter http.ResponseWriter, httpRequest *http.Request) {
  c.ServeMux.ServeHTTP(httpwriter, httpRequest)
}
```

可以看到，container 结构中包含了我们之前提到的 ServeMux 路由分发器，其 ServerHTTP 方法就是直接调用的 ServeMux 实例的 ServerHTTP 方法。从这里也可以明显看出来，container 实例是对 golang 中的 ServeMux 实例的进一步封装。

结合最初的user的例子大致看一下 go-restful 的使用，首先是生成一个 container 实例，此时其中的路由是空的，之后在具体注册路由的时候，由于要进行分层的处理，每一类路由会被封装成为一个 webservice 实例，其中的 route 实例是可以替换的，默认是按照 jsr311 标准实现的：

```
type WebService struct {
  rootPath       string
  pathExpr       *pathExpression // cached compilation of rootPath as RegExp
  routes         []Route
  produces       []string
  consumes       []string
  pathParameters []*Parameter
  filters        []FilterFunction
  documentation  string
  apiVersion     string
}
```

一个 webservice 实例包含一系列的 routes， 每个 route 实例都有对应的执行方法，参数以及 url，以及执行额外操作时候所需要的一些参数比如 filter 的相关函数对象。

可以看到，go-restful 涉及到的对象主要分为以下几个层次：

- Container
- webService
- Route

其中 container 是最上层的对象，相当于是对 serveMux 实例的一个封装，其中有多个 webService，每个 webService 相当于是包含了一类 api 请求，里面包含了多个 Route。

每次把 router 注册(对应的路由及函数)到 webservice 中后，还要通过 container.Add(ws)将这一类的 webservice 加入到对应的 container 当中。

在 add 方法中，会对 container 中的 serverMux 进行处理(就是按照上面介绍的 根据 HandFunc 往进去注册一些路由和方法的映射关系)调用上面所介绍的 ServeMux.HandleFunc 方法，将对应的 pattern 注册给 serverMux. 而 Container 中 serverMux 的 handler 只有 dispatch，说明 container 包装的入口函数就是 dispatch, 即所以 webservice 过来的请求通过 serverMux 转发给 c.dispatch 函数来完成。这个函数会根据请求寻找对应的 route ，然后执行 route 对应的函数，默认情况下，会按照 jsr311 的标准，选择出对应的 webservice 中的对应的路由，并且执行路由的对应方法。此外，还会处理 filter 函数并且进行一些额外操作，具体可参考源码。

go-restful 还支持对每一层对象添加对应的fliter方法，用于对方法进行一层封装，用于进行 pre function 以及 after function 操作，使用起来也很简单，比如像下面这个例子：

```
package main

import (
  "github.com/emicklei/go-restful"
  "io"
  "log"
  "net/http"
)

// This example shows how the different types of filters are called in the request-response flow.
// The call chain is logged on the console when sending an http request.
//
// GET http://localhost:8080/1
// GET http://localhost:8080/2

var indentLevel int

func container_filter_A(req *restful.Request, resp *restful.Response, chain *restful.FilterChain) {
  log.Printf("url path:%v\n", req.Request.URL)
  trace("container_filter_A: before", 1)
  chain.ProcessFilter(req, resp)
  trace("container_filter_A: after", -1)
}

func container_filter_B(req *restful.Request, resp *restful.Response, chain *restful.FilterChain) {
  trace("container_filter_B: before", 1)
  chain.ProcessFilter(req, resp)
  trace("container_filter_B: after", -1)
}

func service_filter_A(req *restful.Request, resp *restful.Response, chain *restful.FilterChain) {
  trace("service_filter_A: before", 1)
  chain.ProcessFilter(req, resp)
  trace("service_filter_A: after", -1)
}

func service_filter_B(req *restful.Request, resp *restful.Response, chain *restful.FilterChain) {
  trace("service_filter_B: before", 1)
  chain.ProcessFilter(req, resp)
  trace("service_filter_B: after", -1)
}

func route_filter_A(req *restful.Request, resp *restful.Response, chain *restful.FilterChain) {
  trace("route_filter_A: before", 1)
  chain.ProcessFilter(req, resp)
  trace("route_filter_A: after", -1)
}

func route_filter_B(req *restful.Request, resp *restful.Response, chain *restful.FilterChain) {
  trace("route_filter_B: before", 1)
  chain.ProcessFilter(req, resp)
  trace("route_filter_B: after", -1)
}

//用于定义输出结果中的层级关系 使得输出结果好看一些
func trace(what string, delta int) {
  indented := what
  if delta < 0 {
      indentLevel += delta
  }
  for t := 0; t < indentLevel; t++ {
      indented = "." + indented
  }
  log.Printf("%s", indented)
  if delta > 0 {
      indentLevel += delta
  }
}

func main() {
   //这里采用了默认自动生成的container实例
   //当然也可以使用 新生成的container 来调用其Filter方法
  restful.Filter(container_filter_A)
  restful.Filter(container_filter_B)

  ws1 := new(restful.WebService)
  ws1.Path("/1")
  ws1.Filter(service_filter_A)
  ws1.Filter(service_filter_B)
  ws1.Route(ws1.GET("").To(doit1).Filter(route_filter_A).Filter(route_filter_B))

  ws2 := new(restful.WebService)
  ws2.Path("/2")
  ws2.Filter(service_filter_A)
  ws2.Filter(service_filter_B)
  ws2.Route(ws2.GET("").To(doit2).Filter(route_filter_A).Filter(route_filter_B))

  restful.Add(ws1)
  restful.Add(ws2)

  log.Print("go-restful example listing on http://localhost:8080/1 and http://localhost:8080/2")
  log.Fatal(http.ListenAndServe(":8080", nil))
}

func doit1(req *restful.Request, resp *restful.Response) {
  io.WriteString(resp, "nothing to see in 1")
}

func doit2(req *restful.Request, resp *restful.Response) {
  io.WriteString(resp, "nothing to see in 2")
}

/*output
2015/08/18 18:03:53 go-restful example listing on http://localhost:8080/1 and http://localhost:8080/2
2015/08/18 18:04:10 url path:/1
2015/08/18 18:04:10 container_filter_A: before
2015/08/18 18:04:10 .container_filter_B: before
2015/08/18 18:04:10 ..service_filter_A: before
2015/08/18 18:04:10 ...service_filter_B: before
2015/08/18 18:04:10 ....route_filter_A: before
2015/08/18 18:04:10 .....route_filter_B: before
2015/08/18 18:04:10 .....route_filter_B: after
2015/08/18 18:04:10 ....route_filter_A: after
2015/08/18 18:04:10 ...service_filter_B: after
2015/08/18 18:04:10 ..service_filter_A: after
2015/08/18 18:04:10 .container_filter_B: after
2015/08/18 18:04:10 container_filter_A: after
*/
```

## net.http 重要概念总结

net.http 包里面有很多文件，都是和 http 协议相关的，比如设置 cookie，header 等。其中最重要的一个文件就是 server.go。我们看看这个文件里面的一些概念。

### 几个重要概念

－ ResponseWriter： 生成 Response 的接口
－ Handler： 处理请求和生成返回的接口
－ ServeMux： 路由，ServeMux 也是一种 Handler
－ Conn: 网络连接

### Handler 接口

```
type Handler interface {
    ServeHTTP(ResponseWriter, *Request)  // 具体的逻辑函数
}
```

实现了 handler 接口的对象就意味着往 server 端添加了处理请求的逻辑。

### ResponseWriter, Flusher, Hijacker 接口

```
// ResponseWriter 的作用是被 Handler 调用来组装返回的 Response 的
type ResponseWriter interface {
    // 这个方法返回 Response 返回的 Header 供读写
    Header() Header
 
    // 这个方法写 Response 的 Body
    Write([]byte) (int, error)
     
    // 这个方法根据 HTTP State Code 来写 Response 的 Header
    WriteHeader(int)
}
 
// Flusher 的作用是被 Handler 调用来将写缓存中的数据推给客户端
type Flusher interface {
    // 这个方法将写缓存中数据推送给客户端
    Flush()
}
 
// Hijacker 的作用是被 Handler 调用来关闭连接的
type Hijacker interface {
    // 这个方法让调用者主动管理连接
    Hijack() (net.Conn, *bufio.ReadWriter, error)
 
}
```

### response 结构

实现上述三个接口的结构是 response 结构 (这个结构是 http 包私有的，在文档中并没有显示，需要去看源码)

```
// response 包含了所有 server 端的 http 返回信息
type response struct {
    conn          *conn         // 保存此次 HTTP 连接的信息
    req           *Request // 对应请求信息
    chunking      bool     // 是否使用 chunk
    wroteHeader   bool     // header是否已经执行过写操作
    wroteContinue bool     // 100 Continue response was written
    header        Header   // 返回的 http 的 Header
    written       int64    // Body 的字节数
    contentLength int64    // Content 长度
    status        int      // HTTP 状态
    needSniff     bool     // 是否需要使用sniff。（当没有设置 Content-Type 的时候，开启 sniff 能根据 HTTP body 来确定 Content-Type）
     
    closeAfterReply bool     //是否保持长链接。如果客户端发送的请求中 connection 有 keep-alive，这个字段就设置为 false。
 
    requestBodyLimitHit bool //是否 requestBody 太大了（当 requestBody 太大的时候，response 是会返回 411 状态的，并把连接关闭）
}
```

在 response 中是可以看到：

```
func (w *response) Header() Header
func (w *response) WriteHeader(code int)
func (w *response) Write(data []byte) (n int, err error)
func (w *response) Flush()
func (w *response) Hijack() (rwc net.Conn, buf *bufio.ReadWriter, err error)
```

所以说 response 实现了 ResponseWriter,Flusher,Hijacker 这三个接口

### HandlerFunc

handlerFunc 是经常使用到的一个 type

```
// 这里将HandlerFunc定义为一个函数类型，因此以后当调用a = HandlerFunc(f)之后, 调用a的ServeHttp实际上就是调用f的对应方法
type HandlerFunc func(ResponseWriter, *Request)
 
// ServeHTTP calls f(w, r).
func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
    f(w, r)
}
```

这里需要多回味一下了，这个 HandlerFunc 定义和 ServeHTTP 合起来是说明了什么？说明 HandlerFunc 的所有实例是实现了 ServeHttp 方法的。另，实现了 ServeHttp 方法就是什么？实现了接口 Handler!

所以你以后会看到很多这样的句子：

```
func AdminHandler(w ResponseWriter, r *Request) {
    ...
}
handler := HandlerFunc(AdminHandler)
handler.ServeHttp(w,r)
```

请不要讶异，你明明没有写ServeHttp，怎么能调用呢？ 实际上调用ServeHttp就是调用AdminHandler。

如果你理解了HandlerFunc，你对下面两个句子一定不会讶异了

```
func NotFound(w ResponseWriter, r *Request) { Error(w, "404 page not found", StatusNotFound) }
 
func NotFoundHandler() Handler { return HandlerFunc(NotFound) }
```

### ServerMux 结构

它就是 http 包中的路由规则器。你可以在 ServerMux 中注册你的路由规则，当有请求到来的时候，根据这些路由规则来判断将请求分发到哪个处理器（Handler）。

它的结构如下：

```
type ServeMux struct {
    mu sync.RWMutex   //锁，由于请求设计到并发处理，因此这里需要一个锁机制
    m  map[string]muxEntry  // 路由规则，一个 string 对应一个 mux 实体，这里的 string 就是注册的路由表达式
}
```

下面看一下 muxEntry

```
type muxEntry struct {
    explicit bool   // 是否明确的匹配
    h        Handler // 这个路由表达式对应哪个 handler
}
```

看到这两个结构就应该对请求是如何路由的有思路了：

当一个请求 request 进来的时候，server 会依次根据 ServeMux.m 中的 string（路由表达式）来一个一个匹配，如果找到了可以匹配的 muxEntry,就取出 muxEntry.h , 这是个 handler，调用 handler 中的 ServeHTTP（ResponseWriter, *Request）来组装 Response，并返回。

ServeMux 定义的方法有:

```
func (mux *ServeMux) match(path string) Handler   //根据path获取Handler
func (mux *ServeMux) handler(r *Request) Handler  //根据Request获取Handler，内部实现调用match
func (mux *ServeMux) ServeHTTP(w ResponseWriter, r *Request) //！！这个说明，ServeHttp也实现了Handler接口，它实际上也是一个Handler！内部实现调用handler
func (mux *ServeMux) Handle(pattern string, handler Handler) //注册handler方法
 
func (mux *ServeMux) HandleFunc(pattern string, handler func(ResponseWriter, *Request))  //注册handler方法（直接使用func注册）
```

在godoc文档中经常见到的DefaultServeMux是http默认使用的ServeMux

```
var DefaultServeMux = NewServeMux()
```

如果我们没有自定义ServeMux，系统默认使用这个ServeMux。

换句话说，http包外层（非ServeMux）中提供的几个方法：

```
func Handle(pattern string, handler Handler) { DefaultServeMux.Handle(pattern, handler) }
func HandleFunc(pattern string, handler func(ResponseWriter, *Request)) {
    DefaultServeMux.HandleFunc(pattern, handler)
}
```

实际上就是调用 ServeMux 结构内部对应的方法。

### Server

下面还剩下一个Server结构

```
type Server struct {
    Addr           string        // 监听的地址和端口
    Handler        Handler       // 所有请求需要调用的Handler（实际上这里说是ServeMux更确切）如果为空则设置为DefaultServeMux
    ReadTimeout    time.Duration // 读的最大Timeout时间
    WriteTimeout   time.Duration // 写的最大Timeout时间
    MaxHeaderBytes int           // 请求头的最大长度
    TLSConfig      *tls.Config   // 配置TLS
}
```

Server提供的方法有：

```
func (srv *Server) Serve(l net.Listener) error   //对某个端口进行监听，里面就是调用for进行accept的处理了
func (srv *Server) ListenAndServe() error  //开启http server服务，内部调用Serve
func (srv *Server) ListenAndServeTLS(certFile, keyFile string) error //开启https server服务，内部调用Serve
```

当然Http包也直接提供了方法供外部使用，实际上内部就是实例化一个Server，然后调用ListenAndServe方法

```
func ListenAndServe(addr string, handler Handler) error   //开启Http服务
func ListenAndServeTLS(addr string, certFile string, keyFile string, handler Handler) error //开启HTTPs服务
```

### 具体例子分析

下面根据上面的分析，我们对一个例子我们进行阅读。这个例子搭建了一个最简易的Server服务。当调用 http://XXXX:12345/hello 的时候页面会返回 “hello world”

```
func HelloServer(w http.ResponseWriter, req *http.Request) {
    io.WriteString(w, "hello, world!\n")
}
 
func main() {
    http.HandleFunc("/hello", HelloServer)
    err := http.ListenAndServe(":12345", nil)
    if err != nil {
        log.Fatal("ListenAndServe: ", err)
    }
 
}
```

#### 首先调用Http.HandleFunc

按顺序做了几件事：

1 调用了DefaultServerMux的HandleFunc

2 调用了DefaultServerMux的Handle

3 往DefaultServeMux的map[string]muxEntry中增加对应的handler和路由规则

#### 其次调用http.ListenAndServe(":12345", nil)

按顺序做了几件事情：

1 实例化Server

2 调用Server的ListenAndServe()

3 调用net.Listen("tcp", addr)监听端口

4 启动一个for循环，在循环体中Accept请求

5 对每个请求实例化一个Conn，并且开启一个goroutine为这个请求进行服务go c.serve()

6 读取每个请求的内容w, err := c.readRequest()

7 判断header是否为空，如果没有设置handler（这个例子就没有设置handler），handler就设置为DefaultServeMux

8 调用handler的ServeHttp

9 在这个例子中，下面就进入到DefaultServerMux.ServeHttp

10 根据request选择handler，并且进入到这个handler的ServeHTTP

```
       mux.handler(r).ServeHTTP(w, r)
```

11 选择handler：

```
    A 判断是否有路由能满足这个request（循环遍历ServerMux的muxEntry）

    B 如果有路由满足，调用这个路由handler的ServeHttp

    C 如果没有路由满足，调用NotFoundHandler的ServeHttp
```

## go-restful 重要概念总结

### Route

路由包含两种，一种是标准 JSR311 接口规范的实现 RouterJSR311，一种是快速路由 CurlyRouter。CurlyRouter 支持正则表达式和动态参数，相比 RouterJSR311 更加轻量级，apiserver 中使用的就是这种路由。

一条 Route 的设定包含：请求方法(Http Method)，请求路径(URL Path)，处理方法以及可选的接受内容类型(Content-Type)，响应内容类型(Accept)等。

### WebService

WebService 逻辑上是 Route 的集合，功能上主要是为一组 Route 统一设置包括 root path，请求响应的数据类型等一些通用的属性。需要注意的是，WebService 必须加入到 Container 中才能生效。

```
func InstallVersionHandler(mux Mux, container *restful.Container) {
    // Set up a service to return the git code version.
    versionWS := new(restful.WebService)

    versionWS.Path("/version")
    versionWS.Doc("git code version from which this is built")
    versionWS.Route(
        versionWS.GET("/").To(handleVersion).
            Doc("get the code version").
            Operation("getCodeVersion").
            Produces(restful.MIME_JSON).
            Consumes(restful.MIME_JSON).
            Writes(version.Info{}))
    container.Add(versionWS)
}
```

### Container

Container 逻辑上是 WebService 的集合，功能上可以实现多终端的效果。例如，下面代码中创建了两个 Container，分别在不同的 port 上提供服务。

```
func main() {
    ws := new(restful.WebService)
    ws.Route(ws.GET("/hello").To(hello))
    // ws被添加到默认的container restful.DefaultContainer中
    restful.Add(ws)
    go func() {
      // restful.DefaultContainer 监听在端口8080上
        http.ListenAndServe(":8080", nil)
    }()

    container2 := restful.NewContainer()
    ws2 := new(restful.WebService)
    ws2.Route(ws2.GET("/hello").To(hello2))
    // ws2被添加到container container2中
    container2.Add(ws2)
    // container2中监听在端口8081上
    server := &http.Server{Addr: ":8081", Handler: container2}
    log.Fatal(server.ListenAndServe())
}

func hello(req *restful.Request, resp *restful.Response) {
    io.WriteString(resp, "default world")
}

func hello2(req *restful.Request, resp *restful.Response) {
    io.WriteString(resp, "second world")
}
```

### Filter

Filter 用于动态的拦截请求和响应，类似于放置在相应组件前的钩子，在相应组件功能运行前捕获请求或者响应，主要用于记录 log，验证，重定向等功能。go-restful 中有三种类型的 Filter.

#### Container Filter

运行在 Container 中所有的 WebService 执行之前。

```
// install a (global) filter for the default container (processed before any webservice)
restful.Filter(globalLogging)
```

#### WebService Filter

运行在WebService中所有的Route执行之前。

```
// install a webservice filter (processed before any route)
ws.Filter(webserviceLogging).Filter(measureTime)
```

#### Route Filter

运行在调用Route绑定的方法之前。

```
// install 2 chained route filters (processed before calling findUser)
ws.Route(ws.GET("/{user-id}").Filter(routeLogging).Filter(NewCountFilter().routeCounter).To(findUser))
```

## 使用样例

下面代码是官方提供的例子。

```
package main

import (
    "github.com/emicklei/go-restful"
    "log"
    "net/http"
)

type User struct {
    Id, Name string
}

type UserResource struct {
    // normally one would use DAO (data access object)
    users map[string]User
}

func (u UserResource) Register(container *restful.Container) {
    // 创建新的WebService
    ws := new(restful.WebService)
  
    // 设定WebService对应的路径("/users")和支持的MIME类型(restful.MIME_XML/ restful.MIME_JSON)
    ws.
        Path("/users").
        Consumes(restful.MIME_XML, restful.MIME_JSON).
        Produces(restful.MIME_JSON, restful.MIME_XML) // you can specify this per route as well

    // 添加路由： GET /{user-id} --> u.findUser
    ws.Route(ws.GET("/{user-id}").To(u.findUser))
  
    // 添加路由： POST / --> u.updateUser
    ws.Route(ws.POST("").To(u.updateUser))
  
    // 添加路由： PUT /{user-id} --> u.createUser
    ws.Route(ws.PUT("/{user-id}").To(u.createUser))
  
    // 添加路由： DELETE /{user-id} --> u.removeUser
    ws.Route(ws.DELETE("/{user-id}").To(u.removeUser))

    // 将初始化好的WebService添加到Container中
    container.Add(ws)
}

// GET http://localhost:8080/users/1
//
func (u UserResource) findUser(request *restful.Request, response *restful.Response) {
    id := request.PathParameter("user-id")
    usr := u.users[id]
    if len(usr.Id) == 0 {
        response.AddHeader("Content-Type", "text/plain")
        response.WriteErrorString(http.StatusNotFound, "User could not be found.")
    } else {
        response.WriteEntity(usr)
    }
}

// POST http://localhost:8080/users
// <User><Id>1</Id><Name>Melissa Raspberry</Name></User>
//
func (u *UserResource) updateUser(request *restful.Request, response *restful.Response) {
    usr := new(User)
    err := request.ReadEntity(&usr)
    if err == nil {
        u.users[usr.Id] = *usr
        response.WriteEntity(usr)
    } else {
        response.AddHeader("Content-Type", "text/plain")
        response.WriteErrorString(http.StatusInternalServerError, err.Error())
    }
}

// PUT http://localhost:8080/users/1
// <User><Id>1</Id><Name>Melissa</Name></User>
//
func (u *UserResource) createUser(request *restful.Request, response *restful.Response) {
    usr := User{Id: request.PathParameter("user-id")}
    err := request.ReadEntity(&usr)
    if err == nil {
        u.users[usr.Id] = usr
        response.WriteHeader(http.StatusCreated)
        response.WriteEntity(usr)
    } else {
        response.AddHeader("Content-Type", "text/plain")
        response.WriteErrorString(http.StatusInternalServerError, err.Error())
    }
}

// DELETE http://localhost:8080/users/1
//
func (u *UserResource) removeUser(request *restful.Request, response *restful.Response) {
    id := request.PathParameter("user-id")
    delete(u.users, id)
}

func main() {
    // 创建一个空的Container
    wsContainer := restful.NewContainer()
  
    // 设定路由为CurlyRouter
    wsContainer.Router(restful.CurlyRouter{})
  
    // 创建自定义的Resource Handle(此处为UserResource)
    u := UserResource{map[string]User{}}
  
    // 创建WebService，并将WebService加入到Container中
    u.Register(wsContainer)

    log.Printf("start listening on localhost:8080")
    server := &http.Server{Addr: ":8080", Handler: wsContainer}
    
    // 启动服务
    log.Fatal(server.ListenAndServe())
}
```

上面的示例构建 Restful 服务，分为几个步骤，apiserver 中也是类似的:

1. 创建 Container。
2. 创建自定义的 Resource Handle，实现 Resource 相关的处理方法。
3. 创建对应于 Resource 的 WebService，在 WebService 中添加相应 Route，并将 WebService 加入到 Container 中。
4. 启动监听服务。

## http.ServeMux 源码剖析

### web server 概述

使用 go 语言搭建一个 web 服务器是很简单的，几行代码就可以搭建一个稳定的高并发的 web server。

```
// hello world, the web server
func HelloServer(w http.ResponseWriter, req *http.Request) {
    io.WriteString(w, "hello, world!\n")
}
func main() {
    http.HandleFunc("/hello/", HelloServer)
    err := http.ListenAndServe(":8080", nil)
    if err != nil {
        log.Fatal("ListenAndServe: ", err)
    }
}
```

一个 go web 服务器正常运行起来大概需要以下几个步骤： 

- 创建 listen socket，循环监听 listen socke 
- accept 接受新的链接请求，并创建网络连接 conn，然后开启一个 goroutine 负责处理该链接。 
- 从该链接读取请求参数构造出 http.Request 对象，然后根据请求路径在路由表中查找，找到对应的上层应用的处理函数，把请求交给应用处理函数。 
- 应用处理函数根据请求的参数等信息做处理，返回不同的信息给用户 
- 应用层处理完该链接请求后关闭该链接(正常流程，如果是 http alive 则不关闭该链接)

这里面路由表是比较重要的，我们具体分析下 http.Server 是如何做路由的。 
路由表实际上是一个 map 
key 是路径 ==> “/hello” 
value 是该路径所对应的处理函数 ==> HelloServer

### 路由表结构

go语言默认的路由表是 ServeMux，结构如下

```
type ServeMux struct {
    mu    sync.RWMutex
    m     map[string]muxEntry //存放具体的路由信息 
}
type muxEntry struct {
    explicit bool
    h        Handler
    pattern  string
}
//muxEntry.Handler是一个接口
type Handler interface {
    ServeHTTP(ResponseWriter, *Request)
}
//这边可能会有疑惑 
//http.HandleFunc("/hello/", HelloServer)
//helloServer是一个function啊，并没有实现ServeHTTP接口啊
//这是因为虽然我们传入的是一个function，但是HandleFunc会把function转为实现了ServeHTTP接口的一个新类型 HandlerFunc。
/*
func (mux *ServeMux) HandleFunc(pattern string, handler     func(ResponseWriter, *Request)) {
    mux.Handle(pattern, HandlerFunc(handler))
}
type HandlerFunc func(ResponseWriter, *Request)
// ServeHTTP calls f(w, r).
func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
    f(w, r)
}
*/
```

### 路由注册过程

注册过程其实就是往 map 中插入数据，**值得注意的一个地方是如果 
注册路径是 /tree/ 并且没有 /tree的路由信息，那么会在路由表中自动增加一条 /tree 的路由，/tree 的处理函数是重定向到 /tree/。但是如果注册的是 /tree 是不会自动添加 /tree/ 的路由的.**

```
// Handle registers the handler for the given pattern.
// If a handler already exists for pattern, Handle panics.
func (mux *ServeMux) Handle(pattern string, handler Handler) {
    mux.mu.Lock()
    defer mux.mu.Unlock()
    mux.m[pattern] = muxEntry{explicit: true, h: handler, pattern: pattern}
    n := len(pattern)
    if n > 0 && pattern[n-1] == '/' && !mux.m[pattern[0:n-1]].explicit {
        path := pattern
        fmt.Printf("redirect for :%s to :%s", pattern, path)
        mux.m[pattern[0:n-1]] = muxEntry{h: RedirectHandler(path, StatusMovedPermanently), pattern: pattern}
    }
}
```

### 路由查找过程

路由查找过程就是遍历路由表，找到最长匹配请求路径的路由信息并返回，如果找不到返回 NotFoundHandler

```
func (mux *ServeMux) handler(host, path string) (h Handler, pattern string) {
    mux.mu.RLock()
    defer mux.mu.RUnlock()
    if h == nil {
        h, pattern = mux.match(path)
    }
    if h == nil {
        h, pattern = NotFoundHandler(), ""
    }
    return
}
func (mux *ServeMux) match(path string) (h Handler, pattern string) {
    var n = 0
    for k, v := range mux.m {
        if !pathMatch(k, path) {
            continue
        }
        //找出匹配度最长的
        if h == nil || len(k) > n {
            n = len(k)
            h = v.h
            pattern = v.pattern
        }
    }
    return
}
// 如果路由表中的路径是不以 '/' 结尾的: /hello
// 那么只有请求路径为 '/hello' 完全匹配时才符合
// 如果路由表中的注册路径是以 '/' 结尾的: /hello/
// 那么请求路径只要满足 '/hello/*' 就符合该路由
func pathMatch(pattern, path string) bool {
    n := len(pattern)
    if pattern[n-1] != '/' {
        return pattern == path
    }
    return len(path) >= n && path[0:n] == pattern
}
```

# References

1. [http://wangzhezhe.github.io/blog/2015/09/14/servmux/](http://wangzhezhe.github.io/blog/2015/09/14/servmux/)
2. [http://www.chingli.com/coding/understanding-go-web-app/](http://www.chingli.com/coding/understanding-go-web-app/)
3. [http://www.cnblogs.com/yjf512/archive/2012/08/22/2650873.html](http://www.cnblogs.com/yjf512/archive/2012/08/22/2650873.html)
4. [http://www.cnblogs.com/ldaniel/p/5868384.html?utm_source=itdadao&utm_medium=referral](http://www.cnblogs.com/ldaniel/p/5868384.html?utm_source=itdadao&utm_medium=referral)










