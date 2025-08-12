@tool
@icon("res://addons/behaviour_toolkit/icons/BTBehaviour.svg")
class_name NarrativeNPC extends Node
## Node that uses the Gemini Flash API to create a narrative NPC.
##
## The node sends the player input to the Gemini Flash API and emits the
## response as a signal.

signal response_received(response: String)

@export var api_key: String = ""
@export var system_prompt: String = "You are a helpful NPC." 

var _http_request: HTTPRequest

func _ready() -> void:
    _http_request = HTTPRequest.new()
    add_child(_http_request)
    _http_request.request_completed.connect(_on_request_completed)

## Sends the given prompt to the Gemini Flash API.
func ask(prompt: String) -> void:
    if api_key == "":
        BehaviourToolkit.Logger.say("API key not set", self, BehaviourToolkit.LogType.WARNING)
        return

    var url := "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-flash:generateContent?key=" + api_key
    var headers := ["Content-Type: application/json"]

    var request_body := {
        "contents": [
            {
                "role": "user",
                "parts": [{"text": system_prompt + "\n" + prompt}]
            }
        ]
    }

    var json_body := JSON.stringify(request_body)
    _http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != OK or response_code != 200:
        BehaviourToolkit.Logger.say("Gemini request failed: " + str(response_code), self, BehaviourToolkit.LogType.WARNING)
        emit_signal("response_received", "")
        return

    var data := JSON.parse_string(body.get_string_from_utf8())
    var text: String = ""
    if typeof(data) == TYPE_DICTIONARY and data.has("candidates"):
        if data.candidates.size() > 0 and data.candidates[0].has("content"):
            var content = data.candidates[0].content
            if content.has("parts") and content.parts.size() > 0 and content.parts[0].has("text"):
                text = content.parts[0].text

    emit_signal("response_received", text)
