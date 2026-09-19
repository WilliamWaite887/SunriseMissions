-- Homecoming. Red War campaign draft; not tested in game.
-- Steps follow the step objects and their lines: Shaxx sends the player through the armory and
-- the hangar to the plaza, Zavala sends them after Ikora, and Amanda picks them up past the
-- boulevard.
local missions = require("missions")
local mission = require(missions.MISSION_TOWERFALL)
local campaign = require("lib.campaign")
local lib = require("lib.mission_lib")
local unit, line, move = campaign.unit, campaign.line, campaign.move
local Slot, Squad, Directive, Scene = mission.Slot, mission.Squad, mission.Directive, mission.Scene
local cue = mission.DialogueCue.M_DIALOG_SENSOR_80B50913

-- The Underwatch crowd, Shaxx and the frames dress the opening. They carry no objective.
local underwatch_cast = {
    id = "cast",
    squads = {
        unit(Squad.SQ_SHAXX, Slot.SQ_SHAXX),
        unit(Squad.SQ_FRAME, Slot.SQ_FRAME),
        unit(Squad.SQ_CAYDE, Slot.SQ_CAYDE),
        unit(Squad.SQ_IKORA_80B50CA7, Slot.SQ_IKORA_80B50CA7),
        unit(Squad.SQ_LEGIONARYA, Slot.SQ_LEGIONARYA),
        unit(Squad.SQ_LEGIONARYB, Slot.SQ_LEGIONARYB),
        unit(Squad.SQ_LEGIONARYC, Slot.SQ_LEGIONARYC),
        unit(Squad.SQ_RED_GUARD, Slot.SQ_RED_GUARD),
        unit(Squad.SQ_RED_GUARD_ADS, Slot.SQ_RED_GUARD_ADS),
        unit(Squad.SQ_FRAME_FAKE_FIGHT, Slot.SQ_FRAME_FAKE_FIGHT),
        unit(Squad.SQ_RED_GUARD_FAKE_FIGHT, Slot.SQ_RED_GUARD_FAKE_FIGHT),
        unit(Squad.SQ_CIVILIAN_CATATONIC, Slot.SQ_CIVILIAN_CATATONIC),
        unit(Squad.SQ_CIVILIAN_KNEEL, Slot.SQ_CIVILIAN_KNEEL),
        unit(Squad.SQ_CIVILIAN_STAND, Slot.SQ_CIVILIAN_STAND),
        unit(Squad.SQ_CIVILIAN_WALL_SIT_A, Slot.SQ_CIVILIAN_WALL_SIT_A),
        unit(Squad.SQ_CIVILIAN_WALL_SIT_B, Slot.SQ_CIVILIAN_WALL_SIT_B),
        unit(Squad.SQ_CIVILIAN_WALL_SIT_C, Slot.SQ_CIVILIAN_WALL_SIT_C),
        unit(Squad.SQ_CIVILIAN_GROUND_1, Slot.SQ_CIVILIAN_GROUND_1),
        unit(Squad.SQ_CIVILIAN_GROUND_2, Slot.SQ_CIVILIAN_GROUND_2),
        unit(Squad.SQ_CIVILIAN_ON_KNEES_CRYING, Slot.SQ_CIVILIAN_ON_KNEES_CRYING),
        unit(Squad.SQ_CIVILIAN_HERO_MOMENT, Slot.SQ_CIVILIAN_HERO_MOMENT),
    },
    -- Placed bodies hold a default pose until their scene runs, so the cast stands still without
    -- these. Only scenes with a symbol entry activate; a sensor-only row is an idle instead.
    on_start = function(context)
        lib.activate_scenes(context, {
            Scene.SCENE_SHAXX,
            Scene.SC_CIVILIAN_CATATONIC,
            Scene.SC_CIVILIAN_KNEEL,
            Scene.SC_CIVILIAN_GROUND_1,
            Scene.SC_CIVILIAN_GROUND_2,
            Scene.SC_CIVILIAN_ON_KNEES_CRYING,
        })
    end,
}

-- "Watch out!" then "Cabal!" as the drop pod lands.
local first_contact = {
    id = "contact",
    trigger = Slot.PT_DROP_POD,
    objective = Slot.OBJ_CABAL_FIRST_CONTACT,
    lines = {line(cue.CUE_4), line(cue.CUE_5)},
    squads = {
        unit(Squad.SQUAD_FIRST_CONTACT_CABAL, Slot.SQUAD_FIRST_CONTACT_CABAL),
        unit(Squad.SQUAD_FIRST_CONTACT_CABAL_BACKUP_A, Slot.SQUAD_FIRST_CONTACT_CABAL_BACKUP_A),
        unit(Squad.SQUAD_FIRST_CONTACT_CABAL_BACKUP_B, Slot.SQUAD_FIRST_CONTACT_CABAL_BACKUP_B),
        unit(Squad.SQ_CABAL_HERO_MOMENT, Slot.SQ_CABAL_HERO_MOMENT),
        unit(Squad.SQ_CABAL_HERO_MOMENT_B, Slot.SQ_CABAL_HERO_MOMENT_B),
    },
    -- Cayde stands up and Golden Guns the two hero-moment Legionaries this same encounter places.
    -- PT_HERO_MOMENT is a scene trigger the script fires, not a volume the player crosses, so the
    -- scenes hang off the drop pod instead.
    on_start = function(context)
        lib.activate_scenes(context, {Scene.SC_HERO_MOMENT_UNDERWATCH, Scene.SCENE_CAYDE_GOLDEN_GUN})
    end,
}

local centurion = {
    id = "centurion",
    trigger = Slot.PT_CENTURION_INTRO,
    objective = Slot.OBJ_CENTURION_INTRO,
    squads = {
        unit(Squad.SQ_CENTURION_INTRO, Slot.SQ_CENTURION_INTRO),
        unit(Squad.SQ_CENTURION_INTRO_RUSH, Slot.SQ_CENTURION_INTRO_RUSH),
        unit(Squad.SQ_CENTURION_INTRO_BACKUP, Slot.SQ_CENTURION_INTRO_BACKUP),
    },
}

local wall = {
    id = "wall",
    trigger = Slot.PT_WALL_EXPLODE,
    on_start = function(context) move(context, {Slot.D_UNDERWATCH_COLLAPSING_WALL}, "open") end,
}

local post_gun = {
    id = "post_gun",
    trigger = Slot.PT_POSTGUN,
    after = "gear",
    objective = Slot.OBJ_POST_GUN,
    squads = {
        unit(Squad.SQ_FRAME_POST_GUN, Slot.SQ_FRAME_POST_GUN),
        unit(Squad.SQ_RED_GUARD_POST_GUN, Slot.SQ_RED_GUARD_POST_GUN),
        unit(Squad.SQ_RED_GUARD_POST_GUN_JUMP, Slot.SQ_RED_GUARD_POST_GUN_JUMP),
    },
}

local hangar = {
    id = "hangar_fight",
    trigger = Slot.PT_HANGAR_SPAWN,
    objective = Slot.OBJ_HANGAR,
    -- The hangar gating doors stay shut until something opens them, so the way on to
    -- PT_GOTO_PLAZA_80B50B91 is walled off and the hangar step can never end.
    on_start = function(context)
        move(context, {Slot.D_GATING_AMANDA_START, Slot.D_GATING_AMANDA_HANGAR}, "open")
    end,
    squads = {
        unit(Squad.SQ_MILITARY_HALLWAY_DESTRUCTION, Slot.SQ_MILITARY_HALLWAY_DESTRUCTION),
        unit(Squad.SQ_HANGAR_OVERLOOK_A_A, Slot.SQ_HANGAR_OVERLOOK_A_A),
        unit(Squad.SQ_HANGAR_OVERLOOK_A_A_CENT, Slot.SQ_HANGAR_OVERLOOK_A_A_CENT),
        unit(Squad.SQ_HANGAR_OVERLOOK_A_B, Slot.SQ_HANGAR_OVERLOOK_A_B),
        unit(Squad.SQ_HANGAR_OVERLOOK_A_C, Slot.SQ_HANGAR_OVERLOOK_A_C),
        unit(Squad.SQ_HANGAR_OVERLOOK_B_A, Slot.SQ_HANGAR_OVERLOOK_B_A),
        unit(Squad.SQ_HANGAR_OVERLOOK_B_B, Slot.SQ_HANGAR_OVERLOOK_B_B),
        unit(Squad.SQ_HANGAR_OVERLOOK_B_C, Slot.SQ_HANGAR_OVERLOOK_B_C),
        unit(Squad.SQ_HANGAR_OVERLOOK_SNIPER, Slot.SQ_HANGAR_OVERLOOK_SNIPER),
        unit(Squad.SQ_HANGAR_A_A, Slot.SQ_HANGAR_A_A),
        unit(Squad.SQ_HANGAR_A_A_FLANK, Slot.SQ_HANGAR_A_A_FLANK),
        unit(Squad.SQ_HANGAR_A_B, Slot.SQ_HANGAR_A_B),
        unit(Squad.SQ_HANGAR_A_B_SNIPER, Slot.SQ_HANGAR_A_B_SNIPER),
        unit(Squad.SQ_HANGAR_FODDER_A, Slot.SQ_HANGAR_FODDER_A),
        unit(Squad.SQ_HANGAR_FODDER_B, Slot.SQ_HANGAR_FODDER_B),
        unit(Squad.SQ_HANGAR_FODDER_C, Slot.SQ_HANGAR_FODDER_C),
        unit(Squad.SQ_FRIENDLIES_EARLY, Slot.SQ_FRIENDLIES_EARLY),
        unit(Squad.SQ_FRIENDLIES_EARLY_UPPER, Slot.SQ_FRIENDLIES_EARLY_UPPER),
        unit(Squad.SQ_RED_GUARD_FAKE_FIGHT_A, Slot.SQ_RED_GUARD_FAKE_FIGHT_A),
        unit(Squad.SQ_RED_GUARD_FAKE_FIGHT_B, Slot.SQ_RED_GUARD_FAKE_FIGHT_B),
        unit(Squad.SQ_RED_GUARD_FAKE_FIGHT_C, Slot.SQ_RED_GUARD_FAKE_FIGHT_C),
        unit(Squad.SQ_FRAME_COVER_A, Slot.SQ_FRAME_COVER_A),
        unit(Squad.SQ_FRAME_COVER_B, Slot.SQ_FRAME_COVER_B),
        unit(Squad.SQ_FRAME_COVER_C, Slot.SQ_FRAME_COVER_C),
        unit(Squad.SQ_FRAME_THROW_A, Slot.SQ_FRAME_THROW_A),
        unit(Squad.SQ_RED_GUARD_THROW_A, Slot.SQ_RED_GUARD_THROW_A),
    },
}

local plaza_hold = {
    id = "plaza_hold",
    trigger = Slot.PT_PLAZA_SPAWN_INIT,
    objective = Slot.OBJ_PLAZA_KILL_CABAL,
    squads = {
        unit(Squad.SQUAD_KILL_CABAL_1, Slot.SQUAD_KILL_CABAL_1),
        unit(Squad.SQUAD_KILL_CABAL_2, Slot.SQUAD_KILL_CABAL_2),
        unit(Squad.SQUAD_KILL_CABAL_3, Slot.SQUAD_KILL_CABAL_3),
        unit(Squad.SQUAD_KILL_CABAL_4, Slot.SQUAD_KILL_CABAL_4),
        unit(Squad.SQUAD_KILL_CABAL_5, Slot.SQUAD_KILL_CABAL_5),
        unit(Squad.SQUAD_KILL_CABAL_6, Slot.SQUAD_KILL_CABAL_6),
        unit(Squad.SQUAD_KILL_CABAL_7, Slot.SQUAD_KILL_CABAL_7),
        unit(Squad.SQUAD_KILL_CABAL_8, Slot.SQUAD_KILL_CABAL_8),
        unit(Squad.SQUAD_CABAL_DROPOFF_1, Slot.SQUAD_CABAL_DROPOFF_1),
    },
}

local zavala = {
    id = "zavala_cast",
    trigger = Slot.PT_PLAZA_ZAVALA_MEET,
    squads = {
        unit(Squad.SQ_ZAVALA, Slot.SQ_ZAVALA),
        unit(Squad.SQ_PLAZA_INTERIM_A_A, Slot.SQ_PLAZA_INTERIM_A_A),
        unit(Squad.SQ_PLAZA_INTERIM_A_B, Slot.SQ_PLAZA_INTERIM_A_B),
    },
}

-- The defend volume covers the plaza, so the wave waits for the defend goal as well.
local plaza_defend = {
    id = "plaza_waves",
    trigger = Slot.PT_DEFEND,
    after = "defend",
    objective = Slot.OBJ_PLAZA_REINFORCE,
    lines = {line(cue.CUE_52)},
    squads = {
        unit(Squad.SQ_PLAZA_REINFORCE_START_A, Slot.SQ_PLAZA_REINFORCE_START_A),
        unit(Squad.SQ_PLAZA_REINFORCE_START_B, Slot.SQ_PLAZA_REINFORCE_START_B),
        unit(Squad.SQ_PLAZA_REINFORCE_A_A, Slot.SQ_PLAZA_REINFORCE_A_A),
        unit(Squad.SQ_PLAZA_REINFORCE_A_A_EXTRA, Slot.SQ_PLAZA_REINFORCE_A_A_EXTRA),
        unit(Squad.SQ_PLAZA_REINFORCE_A_B, Slot.SQ_PLAZA_REINFORCE_A_B),
        unit(Squad.SQ_PLAZA_REINFORCE_A_C, Slot.SQ_PLAZA_REINFORCE_A_C),
        unit(Squad.SQ_PLAZA_REINFORCE_A_D, Slot.SQ_PLAZA_REINFORCE_A_D),
        unit(Squad.SQ_PLAZA_REINFORCE_A_D_EXTRA, Slot.SQ_PLAZA_REINFORCE_A_D_EXTRA),
        unit(Squad.SQ_PLAZA_REINFORCE_B_A, Slot.SQ_PLAZA_REINFORCE_B_A),
        unit(Squad.SQ_PLAZA_REINFORCE_B_A_EXTRA, Slot.SQ_PLAZA_REINFORCE_B_A_EXTRA),
        unit(Squad.SQ_PLAZA_REINFORCE_B_B, Slot.SQ_PLAZA_REINFORCE_B_B),
        unit(Squad.SQ_PLAZA_REINFORCE_B_B_EXTRA, Slot.SQ_PLAZA_REINFORCE_B_B_EXTRA),
    },
}

local bazaar = {
    id = "bazaar",
    trigger = Slot.PT_BAZAAR,
    after = "boulevard",
    objective = Slot.OBJ_BAZAAR,
    squads = {
        unit(Squad.SQ_BAZAAR_START, Slot.SQ_BAZAAR_START),
        unit(Squad.SQ_BAZAAR_TEASE_A, Slot.SQ_BAZAAR_TEASE_A),
        unit(Squad.SQ_BAZAAR_TEASE_B, Slot.SQ_BAZAAR_TEASE_B),
        unit(Squad.SQ_BAZAAR_A_A, Slot.SQ_BAZAAR_A_A),
        unit(Squad.SQ_BAZAAR_A_B, Slot.SQ_BAZAAR_A_B),
        unit(Squad.SQ_BAZAAR_A_C, Slot.SQ_BAZAAR_A_C),
        unit(Squad.SQ_BAZAAR_FINALE, Slot.SQ_BAZAAR_FINALE),
        unit(Squad.SQ_FLAME, Slot.SQ_FLAME),
        unit(Squad.SQ_IKORA_80B5011F, Slot.SQ_IKORA_80B5011F),
        unit(Squad.SQUAD_CABAL_BLASTED_1, Slot.SQUAD_CABAL_BLASTED_1),
        unit(Squad.SQUAD_CABAL_BLASTED_2, Slot.SQUAD_CABAL_BLASTED_2),
        unit(Squad.SQUAD_CABAL_BLASTED_3, Slot.SQUAD_CABAL_BLASTED_3),
        unit(Squad.SQUAD_CABAL_BLASTED_4, Slot.SQUAD_CABAL_BLASTED_4),
    },
}

local ship_entry = {
    id = "ship_entry",
    trigger = Slot.PT_DAMAGED,
    objective = Slot.OBJ_DAMAGED,
    on_start = function(context)
        move(context, {Slot.D_SHIP_POD_DOOR_A, Slot.D_SHIP_POD_DOOR_B, Slot.D_SHIP_DOOR_ENTER},
            "open")
    end,
    squads = {
        unit(Squad.SQ_PODS, Slot.SQ_PODS),
        unit(Squad.SQ_DAMAGED, Slot.SQ_DAMAGED),
        unit(Squad.SQ_DAMAGED_HALL_FRONT, Slot.SQ_DAMAGED_HALL_FRONT),
        unit(Squad.SQ_DAMAGED_HALL_REAR, Slot.SQ_DAMAGED_HALL_REAR),
        unit(Squad.SQ_DAMAGED_HALL_REAR_ANCHOR, Slot.SQ_DAMAGED_HALL_REAR_ANCHOR),
        unit(Squad.SQ_DAMAGED_HALL_MELEE, Slot.SQ_DAMAGED_HALL_MELEE),
        unit(Squad.SQ_DAMAGED_HALL_REAR_STAIR, Slot.SQ_DAMAGED_HALL_REAR_STAIR),
        unit(Squad.SQ_DAMAGED_HALL_REAR_STAIR_ANCHOR, Slot.SQ_DAMAGED_HALL_REAR_STAIR_ANCHOR),
    },
}

local deck = {
    id = "deck",
    trigger = Slot.PT_DECK_START,
    squads = {
        unit(Squad.SQ_DECK_FRONT_A_A, Slot.SQ_DECK_FRONT_A_A),
        unit(Squad.SQ_DECK_FRONT_A_B, Slot.SQ_DECK_FRONT_A_B),
        unit(Squad.SQ_DECK_FRONT_A_C, Slot.SQ_DECK_FRONT_A_C),
        unit(Squad.SQ_DECK_FRONT_B_A, Slot.SQ_DECK_FRONT_B_A),
        unit(Squad.SQ_DECK_FRONT_B_B, Slot.SQ_DECK_FRONT_B_B),
        unit(Squad.SQ_DECK_FRONT_B_C, Slot.SQ_DECK_FRONT_B_C),
        unit(Squad.SQ_DECK_FRONT_C_A, Slot.SQ_DECK_FRONT_C_A),
        unit(Squad.SQ_DECK_HARDPOINT_L, Slot.SQ_DECK_HARDPOINT_L),
        unit(Squad.SQ_DECK_HARDPOINT_L2, Slot.SQ_DECK_HARDPOINT_L2),
        unit(Squad.SQ_DECK_HARDPOINT_L_LOWER, Slot.SQ_DECK_HARDPOINT_L_LOWER),
        unit(Squad.SQ_DECK_HARDPOINT_R, Slot.SQ_DECK_HARDPOINT_R),
        unit(Squad.SQ_DECK_MINIBOSS, Slot.SQ_DECK_MINIBOSS),
    },
}

local deck_boss = {
    id = "deck_boss",
    trigger = Slot.PT_DECK_BOSS,
    objective = Slot.OBJ_DECK_ULTRA,
    squads = {unit(Squad.SQ_DECK_ULTRA, Slot.SQ_DECK_ULTRA)},
}

local shield_room = {
    id = "shield_room",
    trigger = Slot.PT_MATRIX_DOOR,
    on_start = function(context) move(context, {Slot.D_SHIP_DOOR}, "open") end,
    squads = {
        unit(Squad.SQ_SHIP_DOOR_MELEE, Slot.SQ_SHIP_DOOR_MELEE),
        unit(Squad.SQ_SHIP_DOOR_MELEE_C, Slot.SQ_SHIP_DOOR_MELEE_C),
        unit(Squad.SQ_SHIP_DOOR_MELEE_D, Slot.SQ_SHIP_DOOR_MELEE_D),
        unit(Squad.SQ_SHIP_DOOR_MELEE_E, Slot.SQ_SHIP_DOOR_MELEE_E),
        unit(Squad.SQ_SHIP_ENTRY_A_B, Slot.SQ_SHIP_ENTRY_A_B),
        unit(Squad.SQ_SHIP_ENTRY_A_B_O, Slot.SQ_SHIP_ENTRY_A_B_O),
        unit(Squad.SQ_SHIELD_SNIPES, Slot.SQ_SHIELD_SNIPES),
        unit(Squad.SQ_SHIELD_FRONT, Slot.SQ_SHIELD_FRONT),
        unit(Squad.SQ_SHIELD_MID, Slot.SQ_SHIELD_MID),
        unit(Squad.SQ_SHIELD_REAR, Slot.SQ_SHIELD_REAR),
        unit(Squad.SQ_SHIELD_MELEE, Slot.SQ_SHIELD_MELEE),
        unit(Squad.SQ_SHIELD_GEN_C, Slot.SQ_SHIELD_GEN_C),
    },
}

local turbine_guard = {
    id = "turbine_guard",
    after = "overload",
    squads = {
        unit(Squad.SQ_SHIELD_GEN_A, Slot.SQ_SHIELD_GEN_A),
        unit(Squad.SQ_SHIELD_GEN_B, Slot.SQ_SHIELD_GEN_B),
    },
}

local ghaul = {
    id = "ghaul",
    trigger = Slot.PT_ENGINE_ROOM_GHAUL,
    after = "overload",
    objective = Slot.OBJ_GHAUL,
    on_start = function(context) move(context, {Slot.D_GHAUL_DESCENT}, "open") end,
    squads = {unit(Squad.SQ_GHAUL, Slot.SQ_GHAUL)},
}

local escape_guard = {
    id = "escape_guard",
    after = "escape",
    squads = {
        unit(Squad.SQ_ESCAPE_A, Slot.SQ_ESCAPE_A),
        unit(Squad.SQ_ESCAPE_B, Slot.SQ_ESCAPE_B),
    },
}

return campaign.new{
    key = "towerfall",
    directive_sensor = Slot.M_DIRECTIVE_SENSOR_80B50913,
    dialogue_sensor = Slot.M_DIALOG_SENSOR_80B50913,
    -- Retail opens on Zavala's briefing as the attack starts, then the Guardian flying in.
    -- prefab_hro is the fly-in, seen live. The briefing is none of this scenario's cutscenes.
    -- TODO: play the briefing; it is the movie of activity row 265, which the menu does not offer.
    -- The spawn after the cutscene comes from the settings arrival override for this package.
    intro = {
        {state = mission.states.STATE_80B500BC_0002_0001_80B500B1,
            cinematic = Slot.PREFAB_HRO_CINEMATIC},
    },
    legs = {
        {id = "underwatch", state = mission.states.STATE_80B500BC_0009_0000_80B500BB, arm = {
            Slot.PT_START, Slot.PT_WEAPON, Slot.PT_PLAYER_NEAR_SHAXX, Slot.PT_WEAPON_COMPLETE,
            Slot.PT_GOTO_MILITARY, Slot.PT_DROP_POD, Slot.PT_CENTURION_INTRO,
            Slot.PT_WALL_EXPLODE, Slot.PT_POSTGUN,
        }},
        {id = "military", state = mission.states.STATE_80B500BC_0004_0000_80B500B3, arm = {
            Slot.PT_GOTO_PLAZA_80B50B91, Slot.PT_DIALOGUE_HANGAR_WINDOW, Slot.PT_HANGAR_SPAWN,
        }},
        {id = "plaza", state = mission.states.STATE_80B500BC_0006_0000_80B500B6, arm = {
            Slot.PT_GOTO_PLAZA_80B51058, Slot.PT_PLAZA_SPAWN_INIT, Slot.PT_PLAZA_ZAVALA_MEET,
            Slot.PT_DEFEND, Slot.PT_GOTO_BOULEVARD,
        }},
        {id = "boulevard", state = mission.states.STATE_80B500BC_0000_0000_80B500AD, arm = {
            Slot.PT_GOTO_SPEAKER, Slot.PT_GOTO_SKY_BATTLE, Slot.PT_BAZAAR,
        }},
        {id = "sky_battle", state = mission.states.STATE_80B500BC_0008_0000_80B500B8, arm = {
            Slot.PT_SKYBATTLE_3, Slot.PT_DIALOG_ALMOST_THERE, Slot.PT_DESTROY_BATTLESHIP,
            Slot.PT_GOTO_END, Slot.PT_DAMAGED, Slot.PT_DECK_START, Slot.PT_DECK_BOSS,
            Slot.PT_MATRIX_DOOR, Slot.PT_ENGINE_ROOM_GHAUL,
        }},
    },
    steps = {
        -- "Let's get moving. We need to find Zavala, Ikora, and Cayde."
        {id = "home", directive = Directive.DEFEND_YOUR_HOME, navpoint = Slot.AP_IKORA,
            lines = {line(cue.CUE_1)},
            ends = {trigger = Slot.PT_PLAYER_NEAR_SHAXX}},
        -- Walk to the armory with the door still shut. PT_WEAPON sits at its threshold.
        {id = "gear", directive = Directive.GEAR_UP_FOR_THE_FIGHT,
            navpoint = Slot.SLOT_0009_80B5168C,
            ends = {trigger = Slot.PT_WEAPON}},
        -- At the door Shaxx speaks and opens it. The rifles need their rows before the prompt
        -- shows: without one the client shows a generic prompt and never reports a use.
        {id = "armory",
            on_start = function(context)
                move(context, {Slot.D_GUN_DOOR}, "open")
                for _, rifle in ipairs({Slot.AUTO_RIFLE_INTERACTABLE, Slot.PULSE_RIFLE_INTERACTABLE,
                    Slot.SCOUT_RIFLE_INTERACTABLE}) do
                    context:slot(rifle):set_interactable_object{used = true}
                end
            end,
            ends = {trigger = Slot.PT_WEAPON_COMPLETE}},
        -- The evacuation announcement waits in the volume on the way down.
        {id = "find", directive = Directive.FIND_ZAVALA_432D2C96,
            navpoint = Slot.AP_GOTO_MILITARY_80B5168C,
            lines = {line(cue.CUE_30, Slot.SLOT_0004_80B5168C)},
            ends = {trigger = Slot.PT_GOTO_MILITARY}},
        -- "Look at the size of that thing." waits at the hangar window.
        {id = "hangar", directive = Directive.JOIN_ZAVALA_IN_THE_PLAZA,
            navpoint = Slot.SLOT_0008_80B50B91,
            lines = {line(cue.CUE_34, Slot.SLOT_0004_80B50B91)},
            ends = {trigger = Slot.PT_GOTO_PLAZA_80B50B91}},
        -- "What is that thing they're attaching?" waits at the plaza's edge.
        {id = "zavala", directive = Directive.FIGHT_WITH_ZAVALA, navpoint = Slot.AP_PLAZA,
            lines = {line(cue.CUE_40, Slot.SLOT_0019_80B51058)},
            ends = {clear = "plaza_hold"}},
        -- "Don't let them past the gate! The evac shuttles are back there!"
        {id = "defend", directive = Directive.DEFEND_THE_TOWER,
            lines = {line(cue.CUE_51)},
            ends = {clear = "plaza_waves"}},
        -- Ikora goes after the Speaker and Zavala sends the player with her.
        {id = "speaker", directive = Directive.LEAVE_THE_PLAZA_AND_FIND_THE_SPEAKER_E68735ED,
            navpoint = Slot.SLOT_000E_80B51058,
            lines = {line(cue.CUE_59)},
            ends = {trigger = Slot.PT_GOTO_BOULEVARD}},
        -- "And flamethrowers." waits in the bazaar.
        {id = "boulevard", directive = Directive.LEAVE_THE_PLAZA_AND_FIND_THE_SPEAKER,
            navpoint = Slot.SLOT_000A_80B5097F,
            lines = {line(cue.CUE_74, Slot.TV_BAZAAR_80B5097F)},
            ends = {trigger = Slot.PT_GOTO_SPEAKER}},
        -- Zavala calls Holliday in; her line waits at the pickup.
        {id = "board", directive = Directive.BOARD_THE_COMMAND_SHIP,
            navpoint = Slot.SLOT_0004_80B5097F,
            lines = {line(cue.CUE_75), line(cue.CUE_76, Slot.SLOT_0009_80B5097F)},
            ends = {trigger = Slot.PT_GOTO_SKY_BATTLE}},
        -- The console's hologram holds the ship's schematic.
        {id = "locate", directive = Directive.DISABLE_THE_SHIELDS, navpoint = Slot.AP_LOCATE,
            lines = {line(cue.CUE_77)},
            ends = {ghost_link = Slot.GL_CABAL_CONSOLE}},
        -- "The shield generator should be at the bottom of the ship."
        {id = "reach", directive = Directive.REACH_THE_SHIELD_GENERATOR,
            navpoint = Slot.AP_DESTROY_BATTLESHIP,
            lines = {line(cue.CUE_79), line(cue.CUE_84, Slot.SLOT_0011_80B51397)},
            ends = {trigger = Slot.PT_DESTROY_BATTLESHIP}},
        -- "Destroy the turbines. The shields should fizzle." The vents expose them.
        {id = "overload", directive = Directive.OVERLOAD_THE_GENERATOR,
            navpoint = Slot.SLOT_000C_80B51397,
            lines = {line(cue.CUE_86)},
            on_start = function(context)
                move(context, {Slot.D_VENTS_A, Slot.D_VENTS_B, Slot.D_VENTS_C,
                    Slot.D_SHIELD_GEN_A, Slot.D_SHIELD_GEN_B, Slot.D_SHIELD_GEN_COLLAR}, "open")
            end,
            ends = {destroyed = {Slot.SHIELD_GENERATOR_A, Slot.SHIELD_GENERATOR_B,
                Slot.SHIELD_GENERATOR_C}}},
        -- "Zavala! We did it! The shields are down!" then "Amanda! We're headed topside!"
        {id = "escape", directive = Directive.ESCAPE_THE_COMMAND_SHIP,
            navpoint = Slot.SLOT_0010_80B51397,
            lines = {line(cue.CUE_91), line(cue.CUE_92)},
            on_start = function(context) move(context, {Slot.D_SHIP_DOOR_EXIT}, "open") end,
            ends = {trigger = Slot.PT_GOTO_END}},
    },
    encounters = {
        underwatch_cast, first_contact, centurion, wall, post_gun, hangar, plaza_hold, zavala,
        plaza_defend, bazaar, ship_entry, deck, deck_boss, shield_room, turbine_guard, ghaul,
        escape_guard,
    },
}
