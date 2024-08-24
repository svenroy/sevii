import api_gateway.{
  type ApiGatewayEvent, type ApiGatewayResponse, ApiGatewayEvent,
  ApiGatewayEventRequestContext,
}
import conversation
import gleam/bool
import gleam/dict
import gleam/http
import gleam/http/request
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/json.{type Json}
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import glen.{type Request, type Response, Text}
import glen/status

pub fn handler(handle_req: glen.Handler) {
  fn(event: Json, _context: Json) -> Promise(Json) {
    let api_gateway_event_result = api_gateway.decode_event(event)

    use <- bool.guard(
      when: result.is_error(api_gateway_event_result),
      return: api_gateway.new_response(status.internal_server_error)
        |> api_gateway.encode_response
        |> promise.resolve,
    )

    let assert Ok(api_gateway_event) = api_gateway_event_result
    let request = api_gateway_event_to_glen_request(api_gateway_event)
    use response <- promise.await(handle_req(request))

    response
    |> glen_response_to_api_gateway_response
    |> api_gateway.encode_response
    |> promise.resolve
  }
}

fn api_gateway_event_to_glen_request(
  api_gateway_event: ApiGatewayEvent,
) -> Request {
  let assert Ok(method) = http.parse_method(api_gateway_event.http_method)
  let js_request_from_body = js_request(build_url(api_gateway_event), _)

  let req =
    api_gateway_event.body
    |> option.unwrap("")
    |> js_request_from_body
    |> glen.convert_request
    |> request.set_method(method)

  api_gateway_event.headers
  |> dict.to_list
  |> list.fold(req, fn(acc, header) {
    acc |> request.set_header(header.0, header.1)
  })
}

fn build_url(api_gateway_event: ApiGatewayEvent) -> String {
  let ApiGatewayEvent(headers:, request_context:, query_string_parameters:, ..) =
    api_gateway_event
  let ApiGatewayEventRequestContext(domain_name:, path:) = request_context

  let protocol =
    headers
    |> dict_get_case_insensitive("X-Forwarded-Proto")
    |> result.unwrap("https")

  let query_string = option.unwrap(query_string_parameters, "")

  protocol <> "://" <> domain_name <> path <> query_string
}

fn glen_response_to_api_gateway_response(
  response: Response,
) -> ApiGatewayResponse {
  let res = api_gateway.new_response(response.status)

  let res = {
    case response.body {
      Text(body) -> res |> api_gateway.set_body(body)
      _ -> res
    }
  }

  response.headers
  |> list.fold(res, fn(acc, header) {
    acc |> api_gateway.set_header(header.0, header.1)
  })
}

// UTILS ----------

fn dict_get_case_insensitive(
  from: dict.Dict(String, value),
  key: String,
) -> Result(value, Nil) {
  let to = dict.new()

  from
  |> dict.each(fn(key, value) { dict.insert(to, string.lowercase(key), value) })

  dict.get(to, string.lowercase(key))
}

// FFIs ----------

@external(javascript, "./sevii_ffi.mjs", "new_request")
fn js_request(url: String, body: String) -> conversation.JsRequest

pub fn main() {
  io.println("Hello from sevii!")
}
