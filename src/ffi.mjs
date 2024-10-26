import * as $http from '../gleam_http/gleam/http.mjs';
import * as $request from '../gleam_http/gleam/http/request.mjs';
import * as $uri from '../gleam_stdlib/gleam/uri.mjs';

export function toJsRequest(req) {
    return new Request($uri.to_string($request.to_uri(req)), {
        method: $http.method_to_string(req.method),
        headers: req.headers.toArray(),
        body: req.body.body,
    });
}
