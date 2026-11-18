## Static class to manage logging 
class_name Log extends Logger

## Enum for Log events
enum Event {
	TRACE,
	DEBUG,
	INFO,
	WARN,
	ERROR,
	CRITICAL,
	FORCE_FLUSH
}

## Colours for log events when printed
const EVENT_COLORS: Dictionary[Event, String] = {
	Event.TRACE: "dark_orchid",
	Event.DEBUG: "aqua",
	Event.INFO: "lime_green",
	Event.WARN: "gold",
	Event.ERROR: "tomato",
	Event.CRITICAL: "crimson"
}

# Log storage details
const _LOG_DIR := "user://logs"
const _LOG_EXTENSION := "log"

# Limiting log file number and buffer size
const _MAX_LOG_FILES: int = 5
const _MAX_BUFFER_SIZE: int = 10

## Events with backtrace are bigger -> we need to flush the buffer
const _FLUSH_EVENTS: PackedByteArray = [
	Event.ERROR, Event.CRITICAL, Event.FORCE_FLUSH
]

## [member Log._log_level] set the level of logs which are displayed
static var _log_level: Event
## [member Log._buffer_size] used to monitor the size of the [member Log._log_file] buffer
static var _buffer_size: int
## [member Log._log_file] used to write to the current log file
static var _log_file: FileAccess
## [member Log._is_valid] required to ensure that the buffer can be written to
static var _is_valid: bool

## Mutex required for handling file insertion
static var _mutex := Mutex.new() 

## Init and register a new Log instance 
static func _static_init() -> void:
	_log_file = _create_log_file()
	_is_valid = _log_file and _log_file.is_open()
	
	if _is_valid:
		OS.add_logger(Log.new())
		_remove_old_log_files()

## Sets the log level for events [br]
## [param min_event] the minimum level to respond to. For example if [code]min_event = Event.INFO[/code], 
## only INFO, WARN, ERROR and CRITICAL logs will be displayed
static func _set_log_level(min_event: Event) -> void:
	_log_level = min_event

## Creating a file of path [code]user://logs/date_time.log[/code] and opens it with write access
static func _create_log_file() -> FileAccess:
	var file_name := "%s.%s" % [Time.get_datetime_string_from_system(), _LOG_EXTENSION]
	var file_path := _LOG_DIR.path_join(file_name)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	return file

## Removing the oldest log file
static func _remove_old_log_files() -> void:
	pass

## Storing strings of log events for writing into the log file
static var _event_strings: PackedStringArray = Event.keys()

## Getting backtrace for an event (only to be used for errors to avoid clogging the log file)
static func _get_gdscript_backtrace(script_backtraces: Array[ScriptBacktrace]) -> String:
	var gdscript := script_backtraces.find_custom(func(backtrace: ScriptBacktrace) -> bool:
		return backtrace.get_language_name() == "GDScript")
	return "Backtrace N/A" if gdscript == -1 else str(script_backtraces[gdscript])

# Implementing the virtual functions
func _log_message(message: String, error: bool) -> void:
	if not _is_valid or message.begins_with("[lang=tlh]"):
		return
	var event := Event.ERROR if error else Event.INFO
	message = _format_log_message(message.trim_suffix('\n'), event)

func _log_error(
		function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		editor_notify: bool,
		error_type: int,
		script_backtraces: Array[ScriptBacktrace]
) -> void:
	if not _is_valid:
		return
	var event := Event.WARN if error_type == ERROR_TYPE_WARNING else Event.ERROR
	var message := "[{time}] {event}: {rationale}\n{code}\n{file}:{line} @ {function}()".format({
		"time": Time.get_time_string_from_system(),
		"event": _event_strings[event],
		"rationale": rationale,
		"code": code,
		"file": file,
		"line": line,
		"function": function,
 	})
	
	# In the case of an error, add the backtrace to the message to find it
	if event == Event.ERROR:
		message += '\n' + _get_gdscript_backtrace(script_backtraces)

## Function to format log messages (for printing clarity)
static func _format_log_message(message: String, event: Event) -> String:
	return "[{time}] {event}: {message}".format({
		"time": Time.get_time_string_from_system(),
		"event": _event_strings[event],
		"message": message,
	})

## General function which formats and prints log messages
static func _log(message: String, event: Event, add_backtrace: bool = false) -> void:
	if not _is_valid or event < _log_level:
		return
	message = _format_log_message(message, event)
	
	if add_backtrace:
		var script_backtraces := Engine.capture_script_backtraces()
		message += '\n' + _get_gdscript_backtrace(script_backtraces)
	
	_print_event(message, event)

## Trace log : Extremely fine-grained, step-by-step execution detail
static func trace(message: String) -> void:
	_log(message, Event.TRACE)

## Debug log : Diagnostic detail useful while developing or troubleshooting
static func debug(message: String) -> void:
	_log(message, Event.DEBUG)

## Info log : Confirmation that things are working as expected
static func info(message: String) -> void:
	_log(message, Event.INFO)

## Warn log : Something unexpected happened, but the system recovered or is still working
static func warn(message: String) -> void:
	_log(message, Event.WARN)

## Error log : Something didn't work the way it was supposed to, needs attention
static func error(message: String) -> void:
	_log(message, Event.ERROR, true)

## Critical log : The application, or a critical part of it, cannot continue running
static func critical(message: String) -> void:
	_log(message, Event.CRITICAL, true)

## Writes the log message to the file, clears the buffer whenever necessary
static func _add_message_to_file(message: String, event: Event) -> void:
	_mutex.lock()
	if _is_valid:
		if not message.is_empty():
			_is_valid = _log_file.store_line(message)
			_buffer_size += 1
		if _buffer_size >= _MAX_BUFFER_SIZE or event in _FLUSH_EVENTS:
			_log_file.flush()
			_buffer_size = 0
	_mutex.unlock()

## Forces the log buffer to be flushed manually
static func _force_flush() -> void:
	_add_message_to_file("", Event.FORCE_FLUSH)

## Print a log event to output while preventing it being printed by [method Log._log_messages]
static func _print_event(message: String, event: Event) -> void:
	var message_lines := message.split("\n")
	message_lines[0] = "[b][color=%s]%s[/color][/b]" % [EVENT_COLORS[event], message_lines[0]]
	print_rich.call_deferred("[lang=tlh]%s[/lang]" % "\n".join(message_lines))
