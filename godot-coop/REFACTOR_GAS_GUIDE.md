# Guía de Refactorización: AbilitySystemComponent

Esta guía documenta los cambios necesarios en las escenas de Godot después de la refactorización del sistema GAS (Gameplay Ability System).

## Resumen del Cambio

El antiguo `AttributeSet` monolítico ha sido dividido en componentes especializados:

```
ANTES:
CharacterBase
└── AttributeSet (todo en uno: stats, effects, abilities, tags, casts)

DESPUÉS:
CharacterBase
└── AbilitySystemComponent (orquestador)
    ├── AttributeSet (solo stats: health, speed, etc.)
    ├── EffectManager (GameplayEffects)
    ├── AbilityManager (habilidades + input)
    ├── CastManager (habilidades casteadas)
    └── TagContainer (GameplayTags)
```

## IMPORTANTE: Primer Paso

Antes de hacer cualquier cambio en las escenas, **abre Godot y deja que recargue el proyecto**. Esto es necesario para que Godot reconozca las nuevas clases (`AbilitySystemComponent`, `AbilityManager`, etc.).

Si ves errores de "Could not find type", cierra y vuelve a abrir Godot.

## Cambios Requeridos en Escenas

### 1. character_base.tscn

**Opción A: Usar la escena prefabricada (Recomendado)**

1. Abrir `res://characters/character_base.tscn`
2. Seleccionar el nodo `AttributeSet` y eliminarlo (Delete)
3. Click derecho en el nodo raíz `CharacterBase` → "Instantiate Child Scene"
4. Seleccionar `res://characters/common_components/gas/ability_system_component.tscn`
5. El nodo se llamará `AbilitySystemComponent` automáticamente

**Opción B: Crear manualmente**

1. Abrir `res://characters/character_base.tscn`
2. Eliminar el nodo `AttributeSet`
3. Crear un nuevo nodo `Node` llamado `AbilitySystemComponent`
4. Asignar el script `res://characters/common_components/gas/ability_system_component.gd`
5. Crear 5 nodos hijos:

```
AbilitySystemComponent (Node) [script: gas/ability_system_component.gd]
├── AttributeSet (Node) [script: gas/attribute_set.gd]
├── EffectManager (Node) [script: gas/effect_manager.gd]
├── AbilityManager (Node) [script: gas/ability_manager.gd]
├── CastManager (Node) [script: gas/cast_manager.gd]
└── TagContainer (Node) [script: gas/tag_container.gd]
```

**Actualizar FireTagReactionComponent:**
- En el Inspector, cambiar la propiedad `ability_system` para que apunte a `../AbilitySystemComponent`

### 2. player.tscn

**Cambios en referencias:**

| Antes | Después |
|-------|---------|
| `%AttributeSet` | `$AbilitySystemComponent` |
| `attribute_set` | `ability_system` |

**Actualizar FireTagReactionComponent:**
- Cambiar la propiedad `attribute_set` por `ability_system`
- El NodePath debe apuntar a `../AbilitySystemComponent` en lugar de `../AttributeSet`

**Actualizar EquipmentManager:**
- Cambiar la propiedad `attribute_set` por `ability_system`
- El NodePath debe apuntar a `../../AbilitySystemComponent` en lugar de `../../AttributeSet`

**Mover default_abilities:**
- Las `default_abilities` ahora se configuran en el nodo `AbilityManager` (hijo de `AbilitySystemComponent`)
- En el Inspector, expandir `AbilitySystemComponent > AbilityManager` y configurar ahí las habilidades por defecto

### 3. Configuración de Multiplayer Authority

En `player.gd`, la línea:
```gdscript
%AttributeSet.set_multiplayer_authority(1)
```

Ha sido cambiada a:
```gdscript
$AbilitySystemComponent.set_multiplayer_authority(1)
```

**Nota:** Si necesitas replicar propiedades específicas (como `is_strafing`), deberás agregar un `MultiplayerSynchronizer` como hijo de `AbilitySystemComponent` o de `AttributeSet`.

### 4. Actualizar attribute_set.tscn (Opcional - Eliminar)

El archivo `res://characters/common_components/attribute_set.tscn` ya no es necesario y puede ser eliminado, ya que ahora los componentes se crean directamente en las escenas de personajes.

## Estructura de Archivos Nueva

```
res://characters/common_components/gas/
├── ability_system_component.gd  (Orquestador principal)
├── attribute_set.gd             (Stats: health, speed, etc.)
├── effect_manager.gd            (GameplayEffects processing)
├── ability_manager.gd           (Abilities + input handling)
├── cast_manager.gd              (Channeled abilities)
└── tag_container.gd             (GameplayTags system)
```

## Cambios en la API

### Acceso desde código

**Antes:**
```gdscript
var asc = actor.get_node("AttributeSet")
asc.apply_gameplay_effects(effects)
asc.grant_ability(ability, input_tag)
asc.start_cast(handle, duration, on_complete)
asc.has_tag("state.fire")
```

**Después:**
```gdscript
var asc = actor.get_node("AbilitySystemComponent")
asc.apply_gameplay_effects(effects)  # Sin cambios en la firma
asc.grant_ability(ability, input_tag)  # Sin cambios en la firma
asc.start_cast(handle, duration, on_complete)  # Sin cambios en la firma
asc.has_tag("state.fire")  # Sin cambios en la firma
```

### Constantes de Input

**Antes:**
```gdscript
AttributeSet.INPUT_PRIMARY
AttributeSet.INPUT_SECONDARY
```

**Después:**
```gdscript
AbilityManager.INPUT_PRIMARY
AbilityManager.INPUT_SECONDARY
```

### Señales

Las señales se mantienen iguales en `AbilitySystemComponent`:
- `health_changed(new_value, max_value)`
- `died()`
- `tag_added(tag)`
- `tag_removed(tag)`

## Checklist de Migración

- [ ] Actualizar `character_base.tscn` con la nueva estructura de nodos
- [ ] Actualizar `player.tscn` con las nuevas referencias
- [ ] Actualizar NodePaths en `FireTagReactionComponent`
- [ ] Actualizar NodePaths en `EquipmentManager`
- [ ] Mover `default_abilities` al nodo `AbilityManager`
- [ ] Configurar `MultiplayerSynchronizer` si es necesario
- [ ] Eliminar `attribute_set.tscn` (opcional)
- [ ] Probar el juego para verificar que todo funciona

## Solución de Problemas

### Error: "Invalid get index 'AbilitySystemComponent'"
- Asegúrate de que el nodo `AbilitySystemComponent` existe como hijo directo del personaje
- Verifica que el nombre del nodo sea exactamente `AbilitySystemComponent`

### Error: "Nonexistent function 'has_tag'"
- Verifica que el script `ability_system_component.gd` esté asignado correctamente
- El método `has_tag()` ahora está en `AbilitySystemComponent`, que delega a `TagContainer`

### Las habilidades no se activan
- Verifica que `AbilityManager` tenga las `default_abilities` configuradas
- Asegúrate de que el `setup()` se llame correctamente en `_ready()` de `AbilitySystemComponent`

### Los efectos no se aplican
- Verifica que `EffectManager` tenga la referencia correcta a `AttributeSet` y `TagContainer`
- El `setup()` en `AbilitySystemComponent._ready()` debe ejecutarse antes de aplicar efectos
