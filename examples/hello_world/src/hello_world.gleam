import gleam/http
import gleam/javascript/promise.{type Promise}
import gleam/json
import glen
import glen/status
import sevii

fn router(req: glen.Request) -> Promise(glen.Response) {
  case glen.path_segments(req) {
    [] -> {
      use <- glen.require_method(req, http.Get)
      json.object([#("Hello", json.string("world"))])
      |> json.to_string
      |> glen.json(status.ok)
      |> promise.resolve
    }

    _ -> glen.response(status.not_found) |> promise.resolve
  }
}

pub fn handler(event, context) {
  sevii.http_handler(router)(event, context)
}

pub fn main() {
  glen.serve(3001, router)
}
// fn route_handler(
//   req: HttpRequest(glen.RequestBody),
// ) -> Promise(HttpResponse(glen.ResponseBody)) {
//   case glen.path_segments(req) {
//     ["healthCheck", "liveness"] -> {
//       use <- glen.require_method(req, http.Get)

//       json.object([#("message", json.string("Service is up and running"))])
//       |> json.to_string
//       |> glen.json(status.ok)
//       |> promise.resolve
//     }
//     ["healthCheck", "readiness"] -> {
//       use <- glen.require_method(req, http.Get)

//       json.object([#("message", json.string("Service is ready"))])
//       |> json.to_string
//       |> glen.json(status.ok)
//       |> promise.resolve
//     }
//     _ -> glen.response(status.not_found) |> promise.resolve
//   }
// }

// pub fn handler(event, ctx) {
//   http_handler(route_handler)(event, ctx)
// }

// pub fn main() {
//   glen.serve(8000, route_handler)
// }
