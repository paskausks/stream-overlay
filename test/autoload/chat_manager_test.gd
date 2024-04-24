# GdUnit generated TestSuite
class_name ChatManagerTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://autoload/chat_manager.gd'


@warning_ignore('unused_parameter')
func test__parse_line(input: String, code: int, message: String, test_parameters := [
	[":tmi.twitch.tv 001 rpwtf :Welcome, GLHF!", 1, "Welcome, GLHF!"],
	[":tmi.twitch.tv 002 rpwtf :Your host is tmi.twitch.tv", 2, "Your host is tmi.twitch.tv"],
	[":tmi.twitch.tv 003 rpwtf :This server is rather new", 3, "This server is rather new"],
	[":tmi.twitch.tv 375 rpwtf :-", 375, "-"], # MOTD START
	[":tmi.twitch.tv 372 rpwtf :You are in a maze of twisty passages, all alike.", 372, "You are in a maze of twisty passages, all alike."],
	[":tmi.twitch.tv 376 rpwtf :>", 376, ">"], # MOTD END
]) -> void:
	var result: IRCStatusMessage = ChatManager.parse_line(input)
	assert_that(result.code).is_equal(code)
	assert_that(result.message).is_equal(message)
