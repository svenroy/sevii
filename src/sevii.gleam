import conversation.{type JsRequest}
import glambda
import gleam/http/request.{type Request as HttpRequest}
import gleam/http/response.{
  type Response as HttpResponse, Response as HttpResponse,
}
import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option, None, Some}
import glen

pub fn http_handler(handler: glen.Handler) {
  handler |> handle_request |> glambda.http_handler
}

fn handle_request(handler: glen.Handler) {
  fn(req: HttpRequest(Option(String)), _ctx: glambda.Context) -> Promise(
    HttpResponse(Option(String)),
  ) {
    let glen_response = req |> to_js_request |> glen.convert_request |> handler

    use glen_response <- promise.await(glen_response)

    let body = case glen_response.body {
      glen.Text(s) | glen.File(s) -> Some(s)
      _ -> None
    }

    HttpResponse(
      body:,
      status: glen_response.status,
      headers: glen_response.headers,
    )
    |> promise.resolve
  }
}

@external(javascript, "./ffi.mjs", "toJsRequest")
fn to_js_request(req: HttpRequest(Option(String))) -> JsRequest
