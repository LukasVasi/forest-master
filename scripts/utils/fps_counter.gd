extends Control

var text_label: RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	text_label = $RichTextLabel


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if text_label:
		text_label.text = "FPS: " + str(Engine.get_frames_per_second())
