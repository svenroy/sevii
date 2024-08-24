export function new_request(url, body) {
    return new Request(url, { body: body || null })
}
