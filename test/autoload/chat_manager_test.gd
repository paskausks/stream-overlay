# GdUnit generated TestSuite
class_name ChatManagerTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://autoload/chat_manager.gd'


@warning_ignore('unused_parameter')
func test_parse_line(input: String, code: int, message: String, test_parameters := [
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


func test_parse_capabilities1() -> void:
	var input: String = "@badge-info=;badges=moderator/1;client-nonce=b8337bc15c306abf835308035601e672;color=#CAACF3;display-name=nina9mm;emotes=;first-msg=0;flags=;id=e8e84edd-027d-433c-bdac-671d07fbb29b;mod=1;returning-chatter=0;room-id=584170365;subscriber=0;tmi-sent-ts=1714073055135;turbo=0;user-id=504382172;user-type=mod "
	var expected: Dictionary = {
		"badge-info": "",
		"badges": "moderator/1",
		"client-nonce": "b8337bc15c306abf835308035601e672",
		"color": "#CAACF3",
		"display-name": "nina9mm",
		"emotes": "",
		"first-msg": "0",
		"flags": "",
		"id": "e8e84edd-027d-433c-bdac-671d07fbb29b",
		"mod": "1",
		"returning-chatter": "0",
		"room-id": "584170365",
		"subscriber": "0",
		"tmi-sent-ts": "1714073055135",
		"turbo": "0",
		"user-id": "504382172",
		"user-type": "mod",
	}

	assert_dict(ChatManager.parse_capabilities(input)).is_equal(expected)


func test_parse_privmsg1() -> void:
	var input: String = "@badge-info=;badges=;client-nonce=c425695e6885e8f404f8ea2b080a5684;color=;display-name=catsarethebest48;emotes=;first-msg=0;flags=;id=357da145-6b71-4e8f-8eed-f1d4a73abbf6;mod=0;returning-chatter=0;room-id=584170365;subscriber=0;tmi-sent-ts=1714073049035;turbo=0;user-id=1071795999;user-type= :catsarethebest48!catsarethebest48@catsarethebest48.tmi.twitch.tv PRIVMSG #tastemade :my dogs are in shambles #GoCatsGo"

	var expected: IRCMessage = IRCMessage.new(
		"357da145-6b71-4e8f-8eed-f1d4a73abbf6",
		"catsarethebest48",
		Color.WHITE,
		"my dogs are in shambles #GoCatsGo"
	)

	assert_object(ChatManager.parse_privmsg(input)).is_equal(expected)


func test_parse_privmsg2() -> void:
	var input: String = "@badge-info=;badges=premium/1;client-nonce=9e942c470361beecb8c9297442a76d14;color=#0000FF;display-name=DirtySouth2008;emote-only=1;emotes=303327250:0-8,10-18;first-msg=0;flags=;id=12f77484-a576-4435-a32f-fb57e08e393f;mod=0;returning-chatter=0;room-id=584170365;subscriber=0;tmi-sent-ts=1714073048993;turbo=0;user-id=174474827;user-type= :dirtysouth2008!dirtysouth2008@dirtysouth2008.tmi.twitch.tv PRIVMSG #tastemade :mbushCool mbushCool"

	var expected: IRCMessage = IRCMessage.new(
		"12f77484-a576-4435-a32f-fb57e08e393f",
		"DirtySouth2008",
		Color.html("#0000FF"),
		"mbushCool mbushCool"
	)

	assert_object(ChatManager.parse_privmsg(input)).is_equal(expected)


func test_parse_pingmessage_from_parse_line() -> void:
	var input: String = "PING :tmi.twitch.tv"
	var expected: IRCPingMessage = IRCPingMessage.new(" :tmi.twitch.tv")
	assert_object(ChatManager.parse_line(input)).is_equal(expected)
