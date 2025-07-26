@tool
class_name NarrativeNPC extends Node
## Node that uses the Gemini Flash API for conversational NPCs.

signal reply_received(reply: String)

@export var api_key: String = ""
@export var persona_prompt: String = "You are a helpful villager."
@export var model_url: String = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key="
@export var temperature: float = 0.5

var _conversation: Array = []
var _request: HTTPRequest

func _ready():
        _request = HTTPRequest.new()
        add_child(_request)
        _request.connect("request_completed", _on_request_completed)

func ask(message: String) -> void:
        if api_key == "":
                BehaviourToolkit.Logger.say(
                        "No Gemini API key provided.",
                        self,
                        BehaviourToolkit.LogType.ERROR
                )
                return

        _conversation.append({"role": "user", "text": message})

        var messages: Array = []
        if persona_prompt != "":
                messages.append({"parts": [{"text": persona_prompt}]})
        for entry in _conversation:
                messages.append({"parts": [{"text": entry.text}]})

        var data := {
                "contents": messages,
                "generationConfig": {"temperature": temperature}
        }
        var json_payload = JSON.stringify(data)
        var headers := ["Content-Type: application/json"]
        var url = model_url + api_key
        _request.request(url, headers, HTTPClient.METHOD_POST, json_payload)

func _on_request_completed(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray) -> void:
        if result != OK:
                BehaviourToolkit.Logger.say(
                        "Gemini request failed with result %s" % result,
                        self,
                        BehaviourToolkit.LogType.ERROR
                )
                return

        var response = JSON.parse_string(body.get_string_from_utf8())
        if response is Dictionary and response.has("candidates"):
                var candidate = response["candidates"][0]
                var reply := candidate["content"]["parts"][0]["text"]
                _conversation.append({"role": "model", "text": reply})
                emit_signal("reply_received", reply)
