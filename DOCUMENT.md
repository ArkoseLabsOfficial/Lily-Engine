## General Map Setup

To control how a specific map behaves, click on the **Map Properties** (or nothing) in Tiled to bring up the Custom Properties panel.

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `zoom` | `float` | `1.0` | The camera zoom level for this room. |
| `location` | `string` | *(None)* | The string ID saved to the player's game save for their current location. |
| `spawnPlayer` | `bool` | `true` | If the player should be automatically spawned upon loading this map. |
| `script` | `string` | *(Filename)* | The HScript file to bind to this room. If omitted, it defaults to the map's filename. |

---

## Object Types (Classes)

When placing an object on an Object Layer, assign one of these strings to the **Class** (or **Type**) field to give it a specific behavior.

* **`SpawnPoint`**: A point marker for where the player can spawn. Add an `id` integer property to link it to specific entrances.
* **`Collision`**: An invisible blocking barrier. Standard FlxObject collisions apply.
* **`Exit`**: A zone the player touches to switch rooms. Requires `room` and `exit` properties.
* **`ObjectTrigger`**: An invisible interactive zone that can be clicked/interacted with to trigger an HScript event.
* **`Entity`**: Spawns an animated character from your characters directory (e.g., NPCs).
* *(Empty/Default)*: If you just place a tile on an Object Layer, it renders as a standard `WorldObject` sprite.

---

## Object Custom Properties

Select any object or tile in an Object Layer to assign these properties. Properties applied to an entire **Object Layer** will automatically pass down to all objects inside it.

| Property | Type | Applicable Objects | Description |
| --- | --- | --- | --- |
| `id` | `int` | `SpawnPoint` | The spawn point ID. ID `0` is the default map spawn. |
| `room` | `string` | `Exit` | The filename of the `.tmx` map to load when the player touches this exit. |
| `exit` | `int` | `Exit` | The `id` of the `SpawnPoint` the player should appear at in the next room. |
| `autocollision` | `bool` | `Entity`, Default | If `true`, the object acts as a solid wall. |
| `interactable` | `bool` | `Entity`, `ObjectTrigger` | If `true`, the player can interact with this object, triggering the `onInteracted` function in your scripts. |
| `isFlat` | `bool` | Default | If `true`, depth-sorting treats this object as flat on the ground (like carpets or floor decals) so characters render cleanly on top. |
| `script` | `string` | `Entity`, `ObjectTrigger`, Default | The name of the custom HScript file to attach specifically to this object. |
| `character` | `string` | `Entity` | The filename to load from the `characters/` folder. If omitted, it tries to use the object's `name`. |
| `anim_name` | `string` | Default | Override the animation name played by animated tiles. Defaults to `"play"`. |
| `anim_loop` | `bool` | Default | Sets whether the tile animation loops infinitely. Defaults to `true`. |
| *(Any Object)* | `object` | Any HScript Object | You can link actual Tiled objects together. Add a property typed as `object` and select another item in your map; the engine will pass the target object directly into HScript! |