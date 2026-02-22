# Documentación Completa de Sistemas - GodotCoop

Esta documentación describe todos los sistemas del juego, cómo se conectan entre sí, y cómo utilizarlos correctamente.

---

## Tabla de Contenidos

1. [Arquitectura General](#arquitectura-general)
2. [Sistema GAS (Gameplay Ability System)](#sistema-gas-gameplay-ability-system)
3. [Sistema de Inventario](#sistema-de-inventario)
4. [Sistema de Equipamiento](#sistema-de-equipamiento)
5. [Sistema de Interacción](#sistema-de-interacción)
6. [Sistema de Proyectiles](#sistema-de-proyectiles)
7. [Sistema Multijugador](#sistema-multijugador)
8. [Sistema de Personajes](#sistema-de-personajes)
9. [Flujos de Datos Principales](#flujos-de-datos-principales)
10. [Guía de Creación de Contenido](#guía-de-creación-de-contenido)

---

## Arquitectura General

### Diagrama de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              SERVIDOR                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │
│  │  NetworkManager │  │ProjectileSpawner│  │MultiplayerSpawner│         │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘         │
│           │                    │                    │                   │
│           ▼                    ▼                    ▼                   │
│  ┌─────────────────────────────────────────────────────────────┐       │
│  │                         MUNDO                                │       │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │       │
│  │  │ Player 1 │  │ Player 2 │  │   NPCs   │  │Interactables│  │       │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │       │
│  │       │              │              │              │         │       │
│  │       ▼              ▼              ▼              │         │       │
│  │  ┌─────────────────────────────────────────┐      │         │       │
│  │  │      AbilitySystemComponent (GAS)       │◄─────┘         │       │
│  │  │  ┌──────────┐ ┌──────────┐ ┌─────────┐ │                 │       │
│  │  │  │Attributes│ │ Effects  │ │Abilities│ │                 │       │
│  │  │  └──────────┘ └──────────┘ └─────────┘ │                 │       │
│  │  └─────────────────────────────────────────┘                 │       │
│  └─────────────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────────┘
```

### Principio de Autoridad

**El servidor es autoritativo para:**
- Inventarios y transferencias de items
- Aplicación de efectos y habilidades (GAS)
- Spawneo de proyectiles y entidades
- Estado de interactables (cofres, nodos cosechables)
- Cálculo de daño y muerte

**El cliente:**
- Envía inputs y solicitudes via RPC
- Renderiza visuales y efectos
- Muestra UI basada en datos sincronizados

---

## Sistema GAS (Gameplay Ability System)

### Descripción

Sistema inspirado en Unreal Engine GAS que maneja habilidades, efectos, atributos y tags de forma modular y extensible.

### Estructura de Componentes

```
AbilitySystemComponent (Orquestador)
├── AttributeSet        → Stats base (health, speed, stamina, mana)
├── EffectManager       → Aplicar/procesar GameplayEffects
├── AbilityManager      → Otorgar/activar GameplayAbilities
├── CastManager         → Habilidades con tiempo de casteo
└── TagContainer        → Sistema de GameplayTags
```

### Archivos

| Archivo | Propósito |
|---------|-----------|
| `gas/ability_system_component.gd` | Fachada principal, expone API unificada |
| `gas/attribute_set.gd` | Atributos base con setters reactivos |
| `gas/effect_manager.gd` | Procesa efectos instant/periodic/duration |
| `gas/ability_manager.gd` | Gestiona habilidades y maneja input RPCs |
| `gas/cast_manager.gd` | Habilidades que requieren mantener pulsado |
| `gas/tag_container.gd` | Tags con conteo de referencias |

### Clases de Datos (Resources)

#### GameplayAbility

```gdscript
# items/definitions/gameplay_ability.gd
class_name GameplayAbility
extends Resource

@export var ability_name: String
@export var activation_required_tags: PackedStringArray  # Tags necesarios para activar
@export var activation_blocked_tags: PackedStringArray   # Tags que bloquean activación
@export var ongoing_effects: Array[GameplayEffect]       # Efectos mientras está activa
```

**Métodos virtuales para override:**
- `can_activate(actor)` → Verificar si se puede activar
- `activate(actor, handle, args)` → Lógica de activación
- `input_released(actor, handle)` → Cuando se suelta el botón
- `end_ability(actor, handle)` → Limpieza al terminar

#### GameplayEffect

```gdscript
# items/definitions/gameplay_effect.gd
class_name GameplayEffect
extends Resource

enum ApplicationMode { INSTANT, PERIODIC, DURATION, INFINITE }
enum ModifierOp { ADD, SUBTRACT, MULTIPLY, DIVIDE }

@export var operation: ModifierOp      # Operación matemática
@export var value: float               # Valor del efecto
@export var mode: ApplicationMode      # Tipo de aplicación
@export var duration: float            # Duración (si aplica)
@export var tick_rate: float           # Para efectos periódicos
@export var target_attribute: String   # Atributo afectado (health, speed, etc.)
@export var granted_tags: PackedStringArray  # Tags otorgados mientras activo
```

**Modos de aplicación:**
- `INSTANT`: Se aplica una vez inmediatamente (daño, curación)
- `PERIODIC`: Se aplica cada `tick_rate` segundos durante `duration`
- `DURATION`: Modifica un stat durante `duration` segundos
- `INFINITE`: Modifica un stat hasta que se remueva manualmente

### Handles (Recibos)

Los handles son identificadores únicos para trackear instancias de efectos/habilidades:

```gdscript
# AbilitySpecHandle - Identifica una habilidad otorgada
var handle = ability_manager.grant_ability(ability, "ability.primary")
# Más tarde...
ability_manager.clear_ability(handle)

# EffectSpecHandle - Identifica un efecto aplicado
var handles = effect_manager.apply_effects(effects_array)
# Más tarde...
effect_manager.remove_effect(handles[0])
```

### API Principal

```gdscript
# Obtener referencia
var asc: AbilitySystemComponent = actor.get_node("AbilitySystemComponent")

# === EFECTOS ===
var handles = asc.apply_gameplay_effects(effects_array)  # Aplicar efectos
asc.remove_effect(handle)                                 # Remover efecto específico

# === HABILIDADES ===
var handle = asc.grant_ability(ability, "ability.primary", inventory, slot)  # Otorgar
asc.clear_ability(handle)                                                     # Remover
var source = asc.get_ability_source(handle)  # Obtener inventario/slot de origen

# === CASTEO ===
asc.start_cast(handle, duration, on_complete_callable, on_cancel_callable)
asc.cancel_cast(handle)

# === TAGS ===
asc.add_tag("state.burning")
asc.remove_tag("state.burning")
var has_it = asc.has_tag("state.burning")

# === STATS ===
var current_speed = asc.speed
var current_health = asc.health
asc.health = 50  # Setter con clamp automático

# === INPUT (desde Player) ===
asc.server_ability_input_pressed(AbilityManager.INPUT_PRIMARY, data_dict)
asc.server_ability_input_released(AbilityManager.INPUT_PRIMARY)
```

### Constantes de Input

```gdscript
AbilityManager.INPUT_PRIMARY    # "ability.primary"   - Click izquierdo
AbilityManager.INPUT_SECONDARY  # "ability.secondary" - Click derecho
AbilityManager.INPUT_RELOAD     # "ability.reload"    - R
AbilityManager.INPUT_JUMP       # "ability.jump"      - Espacio
```

### Señales

```gdscript
# En AbilitySystemComponent
signal health_changed(new_value: float, max_value: float)
signal died()
signal tag_added(tag: StringName)
signal tag_removed(tag: StringName)
```

---

## Sistema de Inventario

### Descripción

Sistema de inventario basado en grids con soporte multijugador, hotbar, y transferencias entre inventarios.

### Estructura

```
InventorySystemManager (NetworkedCharacterInventorySystem)
├── MainInventory (GridInventory)
│   ├── Openable
│   └── SyncGridInventory
├── EquipmentInventory (GridInventory)
├── Hotbar
│   └── SyncHotbar
├── CraftStation
│   └── SyncCraftStation
├── Interactor
│   └── ObjectPlacer
└── EquipmentManager
    ├── HeadSlot (GridInventory)
    ├── ChestSlot (GridInventory)
    └── HandSlot (GridInventory)
```

### Archivos

| Archivo | Propósito |
|---------|-----------|
| `systems/inventory/inventory_system_manager.gd` | Manager principal con RPCs |
| `systems/inventory/equipment_slot_constraint.gd` | Restricciones para slots de equipo |
| `addons/inventory-system-demos/mp/sync_grid_inventory.gd` | Sincronización de inventarios |
| `addons/inventory-system-demos/mp/sync_hotbar.gd` | Sincronización de hotbar |

### Operaciones Principales

```gdscript
var inv_system = character.get_node("CharacterInventorySystem")

# Recoger item del mundo
inv_system.pick_to_inventory(item_node)

# Transferir entre inventarios
inv_system.transfer(from_inventory, origin_pos, to_inventory, amount)
inv_system.transfer_to(from_inv, origin_pos, to_inv, dest_pos, amount, is_rotated)

# Dividir stack
inv_system.split(inventory, stack_index, amount)

# Rotar item (para inventarios grid)
inv_system.rotate(stack, inventory)

# Ordenar inventario
inv_system.sort(inventory)

# Drop item al mundo
inv_system.drop(stack, inventory)

# Hotbar
inv_system.hotbar_change_selection(index)
inv_system.hotbar_next_item()
inv_system.hotbar_previous_item()

# Abrir/cerrar inventarios
inv_system.open_main_inventory()
inv_system.close_inventories()
inv_system.open_inventory(external_inventory)  # Cofres, etc.

# Crafteo
inv_system.craft(craft_station, recipe_index)
```

### ItemDefinition Properties

Los items en la base de datos pueden tener propiedades especiales:

```gdscript
# En database.tres
properties = {
    "equipment_data": "res://items/definitions/equipment/EqData_Sword.tres",
    "potion_data": "res://items/definitions/potion/HealthPotionStats.tres",
    "hand_item": "res://models/sword.glb",
    "dropped_item": "res://items/dropped/sword_dropped.tscn",
    "placeable": "res://buildings/campfire.tscn"
}
```

---

## Sistema de Equipamiento

### Descripción

Gestiona el equipamiento de items en slots específicos, aplicando efectos pasivos y otorgando habilidades.

### Estructura

```
EquipmentManager
├── HeadSlot (GridInventory 1x1)
├── ChestSlot (GridInventory 1x1)
└── HandSlot (GridInventory 1x1)
```

### Archivos

| Archivo | Propósito |
|---------|-----------|
| `characters/player/equipment_manager.gd` | Lógica de equipar/desequipar |
| `items/definitions/equipment_data.gd` | Datos de equipamiento |
| `items/definitions/ability_grant.gd` | Wrapper para otorgar habilidades |

### EquipmentData Resource

```gdscript
# items/definitions/equipment_data.gd
class_name EquipmentData
extends Resource

enum SlotType { HEAD, CHEST, HAND }

@export var slot_type: SlotType
@export var visual_scene: PackedScene           # Modelo 3D del item
@export var bone_name: String                   # Hueso para attachment
@export var passive_effects: Array[GameplayEffect]  # Efectos pasivos
@export var granted_abilities: Array[AbilityGrant]  # Habilidades otorgadas
```

### AbilityGrant Resource

```gdscript
# items/definitions/ability_grant.gd
class_name AbilityGrant
extends Resource

@export var ability: GameplayAbility
@export_enum("None", "ability.primary", "ability.secondary", "ability.interact") 
var input_tag: String = "ability.primary"
```

### Flujo de Equipamiento

```
1. Item transferido a slot de equipamiento
   └── EquipmentManager._on_item_equipped()
       
2. Cargar EquipmentData desde properties["equipment_data"]
   
3. Aplicar efectos pasivos (Server)
   └── ability_system.apply_gameplay_effects(data.passive_effects)
   
4. Otorgar habilidades (Server)
   └── ability_system.grant_ability(grant.ability, grant.input_tag, inventory, slot)
   
5. Spawn visual (Todos los peers)
   └── BoneAttachment3D con modelo 3D
```

### Flujo de Desequipamiento

```
1. Item removido del slot
   └── EquipmentManager._on_item_unequipped()
   
2. Remover efectos usando handles guardados
   └── ability_system.remove_effect(handle)
   
3. Remover habilidades usando handles guardados
   └── ability_system.clear_ability(handle)
   
4. Destruir visual
   └── visual_node.queue_free()
```

---

## Sistema de Interacción

### Descripción

Sistema para interactuar con objetos del mundo (items, cofres, nodos cosechables).

### Jerarquía de Clases

```
InteractableBase (StaticBody3D)
├── ItemBase (RigidBody3D) - Items recogibles
├── LootContainer - Cofres con loot
└── Harvestable - Nodos cosechables (árboles, rocas)
```

### InteractableBase

```gdscript
# interactables/interactable_base.gd
class_name InteractableBase
extends StaticBody3D

@export var object_name: String = "Interactable"
@export var interaction_text: String = "Interact"
@export var default_action: InteractAction

# Métodos virtuales
func _can_interact(character: Node) -> bool
func _on_interacted(character: Node) -> void
func _on_interaction_canceled() -> void
```

### ItemBase (Items Recogibles)

```gdscript
# interactables/items/item_base.gd
class_name ItemBase
extends RigidBody3D

@export var item_id: String
@export var amount: int = 1
@export var item_properties: Dictionary
@export var is_pickable: bool = true

func interact(character: Node, action_index: int = 0):
    character.character_inventory_system.pick_to_inventory(self)
```

### LootContainer (Cofres)

Características:
- Genera loot la primera vez que se abre
- Sistema de revelación progresiva por jugador
- Cancela búsqueda si el jugador se aleja o cierra el inventario

```gdscript
# interactables/loot_container/loot_container.gd
class_name LootContainer
extends InteractableBase

@export var data: LootContainerData

# El loot se genera al abrir por primera vez
# Cada item tiene "revealed_to": [] para tracking por jugador
# Items se revelan uno a uno con timer configurable
```

### Harvestable (Nodos Cosechables)

Características:
- Requiere mantener interacción durante X segundos
- Se cancela si el jugador se mueve o recibe daño
- Puede respawnear o destruirse

```gdscript
# interactables/harvest_nodes/harvestable.gd
class_name Harvestable
extends InteractableBase

@export var data: HarvestableData

# Proceso:
# 1. Jugador interactúa
# 2. Timer corre durante harvest_duration
# 3. Si se mueve/daña → cancela
# 4. Si completa → genera loot y destruye/respawnea
```

---

## Sistema de Proyectiles

### Descripción

Sistema para spawneo y gestión de proyectiles lanzables (pociones, flechas, etc.).

### Archivos

| Archivo | Propósito |
|---------|-----------|
| `systems/projectile_spawner.gd` | Spawner sincronizado |
| `items/definitions/projectiles/projectile_base.gd` | Clase base de proyectiles |
| `items/definitions/potion_data.gd` | Datos de pociones/proyectiles |

### PotionData Resource

```gdscript
# items/definitions/potion_data.gd
class_name PotionData
extends Resource

# Física
@export var projectile_scene: PackedScene
@export var throw_force: float = 15.0

# Explosión
@export var blast_radius: float = 3.0
@export var area_effect_duration: float = 0.5

# Efectos al impactar
@export var effects: Array[GameplayEffect]

# Consumo
@export var consume_on_use: bool = true

# Efectos al beber
@export var consumed_effects: Array[GameplayEffect]
@export var drink_duration: float = 1.5
```

### ProjectileSpawner

```gdscript
# systems/projectile_spawner.gd
class_name ProjectileSpawner
extends MultiplayerSpawner

# Uso desde una habilidad:
var spawner = actor.get_tree().get_first_node_in_group("ProjectileSpawner")
spawner.spawn([
    position,           # Vector3: posición inicial
    Basis.looking_at(direction),  # Basis: rotación
    velocity,           # Vector3: velocidad inicial
    potion_data.resource_path,    # String: path al PotionData
    actor.name.to_int() # int: ID del lanzador
])
```

### ProjectileBase

```gdscript
# items/definitions/projectiles/projectile_base.gd
class_name ProjectileBase
extends RigidBody3D

var data: PotionData
var thrower_id: int = 0

func setup_projectile(new_data: PotionData, initial_velocity: Vector3)
func on_impact(body: Node)  # Override para lógica de impacto
```

---

## Sistema Multijugador

### Descripción

Sistema de networking usando ENet con arquitectura servidor autoritativo.

### Archivos

| Archivo | Propósito |
|---------|-----------|
| `systems/network_manager.gd` | Conexión servidor/cliente |
| `systems/multiplayer_spawner.gd` | Spawneo de jugadores |
| `systems/projectile_spawner.gd` | Spawneo de proyectiles |

### NetworkManager

```gdscript
# systems/network_manager.gd
extends Node

const PORT := 4000
const IP_ADDRESS := "localhost"

func start_server() -> void  # Crear servidor
func connect_client() -> void  # Conectar como cliente
```

### Patrón de Autoridad

```gdscript
# Verificar si es servidor
if multiplayer.is_server():
    # Ejecutar lógica autoritativa
    
# Verificar autoridad sobre nodo específico
if is_multiplayer_authority():
    # Solo el dueño ejecuta esto
```

### Patrón RPC Típico

```gdscript
# En el cliente
func do_action(data):
    if multiplayer.is_server():
        _do_action_logic(data)
    else:
        do_action_rpc.rpc_id(1, data)  # Enviar al servidor

# RPC que ejecuta en servidor
@rpc("any_peer", "call_local", "reliable")
func do_action_rpc(data):
    if not multiplayer.is_server(): return
    _do_action_logic(data)

# Lógica real
func _do_action_logic(data):
    # ... implementación ...
```

### Sincronización de Datos

```gdscript
# MultiplayerSynchronizer para propiedades
[node name="MultiplayerSynchronizer" type="MultiplayerSynchronizer"]
replication_config = {
    "properties/0/path": ".:position",
    "properties/0/spawn": true,
    "properties/0/replication_mode": 1  # Always
}

# SyncGridInventory para inventarios
# Sincroniza automáticamente cambios de stacks
```

---

## Sistema de Personajes

### Descripción

Sistema de personajes jugables y NPCs con integración completa de GAS e inventario.

### Jerarquía

```
CharacterBase (CharacterBody3D)
└── Player
    ├── AbilitySystemComponent
    ├── CharacterInventorySystem
    ├── SpringArmPivot (Cámara)
    └── HUD
```

### CharacterBase

```gdscript
# characters/character_base.gd
class_name CharacterBase
extends CharacterBody3D

@onready var ability_system: AbilitySystemComponent = $AbilitySystemComponent

func receive_gameplay_effects(effects: Array[GameplayEffect]) -> void:
    if ability_system:
        ability_system.apply_gameplay_effects(effects)
```

### Player

```gdscript
# characters/player/player.gd
extends CharacterBase

@onready var camera: Camera3D = $SpringArmPivot/Camera3D
@onready var character_inventory_system: NetworkedCharacterInventorySystem = $CharacterInventorySystem

func _input(event: InputEvent) -> void:
    # Mapeo de inputs a habilidades
    if event.is_action_pressed("attack_primary"):
        var data = _collect_activation_data()
        ability_system.server_ability_input_pressed(AbilityManager.INPUT_PRIMARY, data)
```

### TagReactionComponent

Componente para reaccionar a tags del GAS:

```gdscript
# characters/common_components/tag_reaction_component.gd
class_name TagReactionComponent
extends Node

@export var target_tag: StringName
@export var ability_system: AbilitySystemComponent

func _ready():
    ability_system.tag_added.connect(_on_tag_added)
    ability_system.tag_removed.connect(_on_tag_removed)

func activate_reaction() -> void:
    pass  # Override en hijos

func deactivate_reaction() -> void:
    pass  # Override en hijos
```

---

## Flujos de Datos Principales

### 1. Equipar Item con Habilidad

```
┌─────────────────────────────────────────────────────────────────────────┐
│ FLUJO: Equipar Poción de Fuego                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. Jugador arrastra item a HeadSlot                                   │
│     └── UI → InventorySystem.transfer()                                │
│                                                                         │
│  2. Servidor procesa transferencia                                      │
│     └── GridInventory.transfer_to() → stack_added signal               │
│                                                                         │
│  3. EquipmentManager detecta cambio                                     │
│     └── _on_item_equipped(stack_index, inventory, slot_type)           │
│                                                                         │
│  4. Cargar EquipmentData                                               │
│     └── load(properties["equipment_data"]) → EqData_FirePotion.tres    │
│                                                                         │
│  5. Aplicar efectos pasivos (si hay)                                   │
│     └── ability_system.apply_gameplay_effects(passive_effects)         │
│                                                                         │
│  6. Otorgar habilidades                                                │
│     ├── GA_ThrowPotion → ability.primary                               │
│     └── GA_DrinkPotion → ability.secondary                             │
│         └── ability_system.grant_ability(ability, input_tag, inv, slot)│
│                                                                         │
│  7. Spawn visual                                                        │
│     └── BoneAttachment3D + bottle.glb                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2. Activar Habilidad de Lanzar Poción

```
┌─────────────────────────────────────────────────────────────────────────┐
│ FLUJO: Lanzar Poción (Click Izquierdo mientras apunta)                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. Cliente detecta input                                              │
│     └── Player._input() → attack_primary pressed                       │
│                                                                         │
│  2. Recolectar datos de activación                                     │
│     └── aim_direction, aim_position desde cámara                       │
│                                                                         │
│  3. Enviar RPC al servidor                                             │
│     └── ability_system.server_ability_input_pressed(INPUT_PRIMARY, data)│
│                                                                         │
│  4. Servidor: AbilityManager procesa                                   │
│     ├── Buscar habilidad con input_tag == "ability.primary"            │
│     ├── Verificar can_activate() (requiere tag "state.aiming")         │
│     └── Llamar GA_ThrowProjectile.activate()                           │
│                                                                         │
│  5. GA_ThrowProjectile.activate()                                      │
│     ├── Obtener PotionData desde item en inventario                    │
│     │   └── get_ability_source(handle) → inventory, slot               │
│     │   └── load(properties["potion_data"]) → FirePotionStats.tres     │
│     ├── Calcular velocidad y posición                                  │
│     └── Llamar ProjectileSpawner.spawn()                               │
│                                                                         │
│  6. ProjectileSpawner crea proyectil                                   │
│     ├── Instanciar fire_potion_projectile.tscn                         │
│     ├── Configurar posición, rotación, velocidad                       │
│     └── Sincronizar a todos los clientes                               │
│                                                                         │
│  7. Consumir item                                                       │
│     └── inventory.remove_at(slot, item_id, 1)                          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3. Beber Poción (Habilidad Casteada)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ FLUJO: Beber Poción (Mantener Click Derecho)                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. Cliente: Click derecho presionado                                  │
│     └── ability_system.server_ability_input_pressed(INPUT_SECONDARY)   │
│                                                                         │
│  2. Servidor: GA_DrinkPotion.activate()                                │
│     ├── Obtener PotionData desde item                                  │
│     └── Iniciar casteo                                                 │
│         └── asc.start_cast(handle, drink_duration, on_complete, on_cancel)│
│                                                                         │
│  3. CastManager trackea el tiempo                                      │
│     └── _process_active_casts(delta) incrementa elapsed                │
│                                                                         │
│  4a. SI jugador SUELTA antes de tiempo:                                │
│      └── server_ability_input_released() → cancel_cast()               │
│          └── on_cancel() → "Poción no consumida"                       │
│                                                                         │
│  4b. SI jugador MANTIENE hasta completar:                              │
│      └── elapsed >= duration → on_complete()                           │
│          ├── Aplicar consumed_effects al jugador                       │
│          └── Consumir item del inventario                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4. Impacto de Proyectil

```
┌─────────────────────────────────────────────────────────────────────────┐
│ FLUJO: Proyectil Impacta Enemigo                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. Proyectil colisiona con CharacterBody3D                            │
│     └── body_entered signal → on_impact(body)                          │
│                                                                         │
│  2. Verificar que es un personaje válido                               │
│     └── body.has_method("receive_gameplay_effects")                    │
│                                                                         │
│  3. Aplicar efectos del PotionData                                     │
│     └── body.receive_gameplay_effects(data.effects)                    │
│         └── AbilitySystemComponent.apply_gameplay_effects()            │
│                                                                         │
│  4. EffectManager procesa cada efecto                                  │
│     ├── INSTANT: Aplicar daño inmediato                                │
│     ├── DURATION: Agregar modificador temporal                         │
│     └── Otorgar tags (ej: "state.fire")                                │
│                                                                         │
│  5. TagContainer emite señal                                           │
│     └── tag_added.emit("state.fire")                                   │
│                                                                         │
│  6. TagReactionComponent reacciona                                     │
│     └── Cambiar textura a "quemado"                                    │
│                                                                         │
│  7. Destruir proyectil                                                 │
│     └── queue_free()                                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Guía de Creación de Contenido

### Crear Nueva Poción

1. **Crear PotionData** (`res://items/definitions/potion/MyPotionStats.tres`)

```
PotionData:
├── projectile_scene: mi_pocion_projectile.tscn
├── throw_force: 15.0
├── blast_radius: 3.0
├── effects: [GameplayEffect de daño/buff]
├── consume_on_use: true
├── consumed_effects: [GameplayEffect al beber]
└── drink_duration: 2.0
```

2. **Crear EquipmentData** (`res://items/definitions/equipment/EqData_MyPotion.tres`)

```
EquipmentData:
├── slot_type: HAND
├── visual_scene: bottle.glb
├── bone_name: "Head"
├── passive_effects: []
└── granted_abilities:
    ├── AbilityGrant(GA_ThrowPotion, "ability.primary")
    └── AbilityGrant(GA_DrinkPotion, "ability.secondary")
```

3. **Agregar a Database** (`res://addons/inventory-system-demos/database/database.tres`)

```
ItemDefinition:
├── id: "my_potion"
├── name: "Mi Poción"
├── icon: potion_icon.png
├── max_stack: 10
└── properties:
    ├── "equipment_data": "res://items/definitions/equipment/EqData_MyPotion.tres"
    ├── "potion_data": "res://items/definitions/potion/MyPotionStats.tres"
    └── "dropped_item": "res://items/dropped/my_potion.tscn"
```

### Crear Nueva Habilidad

1. **Crear script de habilidad**

```gdscript
# items/abilities/ga_my_ability.gd
class_name GA_MyAbility
extends GameplayAbility

func activate(actor: Node, handle: AbilitySpecHandle, args: Dictionary = {}) -> void:
    var asc: AbilitySystemComponent = actor.get_node_or_null("AbilitySystemComponent")
    if not asc: return
    
    # Tu lógica aquí
    print("Habilidad activada!")

func input_released(actor: Node, handle: AbilitySpecHandle) -> void:
    # Lógica cuando se suelta el botón
    end_ability(actor, handle)
```

2. **Crear resource** (`res://items/definitions/gameplay_abilities/GA_MyAbility.tres`)

```
GameplayAbility:
├── ability_name: "Mi Habilidad"
├── activation_required_tags: ["state.ready"]
├── activation_blocked_tags: ["state.stunned"]
└── ongoing_effects: [GameplayEffect mientras activa]
```

### Crear Nuevo Efecto

```gdscript
# En el Inspector o código
var effect = GameplayEffect.new()
effect.effect_name = "Burning"
effect.operation = GameplayEffect.ModifierOp.SUBTRACT
effect.value = 5.0
effect.mode = GameplayEffect.ApplicationMode.PERIODIC
effect.duration = 10.0
effect.tick_rate = 1.0
effect.target_attribute = "health"
effect.granted_tags = ["state.fire"]
```

### Crear Nuevo Interactable

1. **Heredar de InteractableBase**

```gdscript
class_name MyInteractable
extends InteractableBase

func _on_interacted(character: Node) -> void:
    # Tu lógica de interacción
    print("Interactuado por ", character.name)
```

2. **Configurar en escena**
   - Agregar CollisionShape3D
   - Configurar `object_name` e `interaction_text`
   - Agregar `InteractAction` como `default_action`

---

## Apéndice: Estructura de Carpetas

```
godot-coop/
├── characters/
│   ├── common_components/
│   │   ├── gas/                    # Sistema GAS modular
│   │   │   ├── ability_system_component.gd
│   │   │   ├── attribute_set.gd
│   │   │   ├── effect_manager.gd
│   │   │   ├── ability_manager.gd
│   │   │   ├── cast_manager.gd
│   │   │   └── tag_container.gd
│   │   └── tag_reaction_component.gd
│   ├── player/
│   │   ├── player.gd
│   │   ├── player.tscn
│   │   └── equipment_manager.gd
│   └── npcs/
│
├── items/
│   ├── abilities/                  # Implementaciones de habilidades
│   │   ├── ga_throw_projectile.gd
│   │   ├── ga_drink_potion.gd
│   │   └── ga_aim.gd
│   └── definitions/                # Resources de datos
│       ├── gameplay_ability.gd
│       ├── gameplay_effect.gd
│       ├── equipment_data.gd
│       ├── ability_grant.gd
│       ├── potion_data.gd
│       ├── ability_spec_handle.gd
│       ├── effect_spec_handle.gd
│       ├── potion/                 # PotionData .tres files
│       ├── equipment/              # EquipmentData .tres files
│       ├── gameplay_abilities/     # GameplayAbility .tres files
│       └── projectiles/            # Escenas de proyectiles
│
├── interactables/
│   ├── interactable_base.gd
│   ├── items/
│   │   └── item_base.gd
│   ├── loot_container/
│   │   └── loot_container.gd
│   └── harvest_nodes/
│       └── harvestable.gd
│
├── systems/
│   ├── network_manager.gd
│   ├── multiplayer_spawner.gd
│   ├── projectile_spawner.gd
│   ├── inventory/
│   │   ├── inventory_system_manager.gd
│   │   └── equipment_slot_constraint.gd
│   └── log_helper/
│       └── Logger.gd
│
└── addons/
    └── inventory-system-demos/     # Addon de inventario base
        ├── mp/                     # Componentes multijugador
        └── database/               # Base de datos de items
```

---

## Glosario

| Término | Definición |
|---------|------------|
| **GAS** | Gameplay Ability System - Sistema de habilidades y efectos |
| **Handle** | Identificador único para trackear instancias de efectos/habilidades |
| **Tag** | Etiqueta que representa un estado (ej: "state.burning") |
| **Effect** | Modificador temporal o permanente de atributos |
| **Ability** | Acción que un personaje puede ejecutar |
| **Cast** | Habilidad que requiere mantener pulsado un botón |
| **Interactable** | Objeto del mundo con el que se puede interactuar |
| **Stack** | Grupo de items del mismo tipo en un slot de inventario |
| **Hotbar** | Barra de acceso rápido a items |
| **RPC** | Remote Procedure Call - Llamada de función en red |
