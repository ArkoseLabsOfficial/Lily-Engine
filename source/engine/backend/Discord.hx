package engine.backend;

#if FEATURE_DISCORD_RPC
import hxdiscord_rpc.Discord as DiscordRPC;
import hxdiscord_rpc.Types;

class Discord {
	public static function initialize():Void {
		var discordClientID:String = "1535877642161627176";

		DiscordRPC.Initialize(discordClientID, null, true, null);

		updatePresence("RPC Test", "Lily Engine v0.1.0 Alpha");

		sys.thread.Thread.create(() -> {
			while (true) {
				DiscordRPC.RunCallbacks();
				Sys.sleep(2.0);
			}
		});
	}

	public static function updatePresence(details:String, state:String):Void {
		var discordPresence = new DiscordRichPresence();
		discordPresence.details = details;
		discordPresence.state = state;
		discordPresence.largeImageKey = "game";
		discordPresence.largeImageText = "Lily Engine v0.1.0 Alpha";

		discordPresence.startTimestamp = Std.int(Date.now().getTime() / 1000);

		DiscordRPC.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
	}

	public static function shutdown():Void {
		DiscordRPC.Shutdown();
	}
}
#end
