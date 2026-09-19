-- Tree of Probabilities. Ported from the Dawn fork's step graph; not tested in game.
-- Four legs: the Lighthouse gateway (120), the Infinite Forest (72), the Chase (16), the bomb
-- ledge and Valus Thuun (0).
-- Each run seeds the authored type-37 Forest worker and leaves its other inputs authored.
-- Thuun's retreats read the health fraction his type-2 Sense already reports, so no client
-- hook is needed. Not ported: the Harvester delivery chain, a type-2 mechanic sequence.
local missions = require("missions")
local mission = require(missions.STRIKE_PACT)
local campaign = require("lib.campaign")
local unit, line, move = campaign.unit, campaign.line, campaign.move
local Slot, Squad, Directive, Scene = mission.Slot, mission.Squad, mission.Directive, mission.Scene
local cue = mission.DialogueCue.M_DIALOG_SENSOR

-- The Cabal already on the pad when the player lands.
local intro = {
    id = "intro",
    objective = Slot.OBJ_PACT_LIGHTHOUSE,
    squads = {
        unit(Squad.SQ_INTRO_FIGHT_0, Slot.SQ_INTRO_FIGHT_0),
        unit(Squad.SQ_INTRO_FIGHT_1, Slot.SQ_INTRO_FIGHT_1),
    },
}

local vanguard = {
    id = "vanguard",
    after = "approach",
    objective = Slot.OBJ_PACT_LIGHTHOUSE,
    squads = {
        unit(Squad.SQ_CABAL_VANGUARD_0, Slot.SQ_CABAL_VANGUARD_0),
        unit(Squad.SQ_CABAL_VANGUARD_1, Slot.SQ_CABAL_VANGUARD_1),
        unit(Squad.SQ_CABAL_VANGUARD_2, Slot.SQ_CABAL_VANGUARD_2),
        unit(Squad.SQ_MIXED_CENTER_0, Slot.SQ_MIXED_CENTER_0),
        unit(Squad.SQ_MIXED_CENTER_4, Slot.SQ_MIXED_CENTER_4),
        unit(Squad.SQ_MIXED_CENTER_7, Slot.SQ_MIXED_CENTER_7),
    },
}

-- The gate defence. The named Gladiator stands with it and the turret never blocks the clear.
local rearguard = {
    id = "rearguard",
    trigger = Slot.PT_NEAR_GATE,
    objective = Slot.OBJ_PACT_LIGHTHOUSE,
    squads = {
        unit(Squad.SQ_CABAL_REARGUARD_0, Slot.SQ_CABAL_REARGUARD_0),
        unit(Squad.SQ_CABAL_REARGUARD_2, Slot.SQ_CABAL_REARGUARD_2),
        unit(Squad.SQ_VEX_HARASSERS_0, Slot.SQ_VEX_HARASSERS_0),
    },
}

local basilisk = {
    id = "basilisk",
    trigger = Slot.PT_NEAR_GATE,
    objective = Slot.OBJ_PACT_LIGHTHOUSE,
    squads = {
        unit(Squad.SQ_BASILISK, Slot.SQ_BASILISK),
    },
}

-- The defenders of the Forest portal. The barrier drops when they are down.
-- The map authors ten: guards 0 to 5 and snipers 0 to 3. The SDK export carries a squad for the
-- first two guards only; the other eight type-1 slots have no squad row, so they cannot be placed.
local portal = {
    id = "portal",
    trigger = Slot.PT_LOAD_POST,
    objective = Slot.OBJ_IFB,
    squads = {
        unit(Squad.SQ_PORTAL_GUARD_0, Slot.SQ_PORTAL_GUARD_0),
        unit(Squad.SQ_PORTAL_GUARD_1, Slot.SQ_PORTAL_GUARD_1),
    },
}

local first_room = {
    id = "first_room",
    trigger = Slot.PT_ENTER_CHASE,
    objective = Slot.OBJ_CHASE,
    squads = {
        unit(Squad.SQ_CABAL_FIRSTROOM_0, Slot.SQ_CABAL_FIRSTROOM_0),
        unit(Squad.SQ_CABAL_FIRSTROOM_1, Slot.SQ_CABAL_FIRSTROOM_1),
        unit(Squad.SQ_CABAL_FIRSTROOM_3, Slot.SQ_CABAL_FIRSTROOM_3),
        unit(Squad.SQ_CABAL_FIRSTROOM_4, Slot.SQ_CABAL_FIRSTROOM_4),
        unit(Squad.SQ_CABAL_FIRSTROOM_5, Slot.SQ_CABAL_FIRSTROOM_5),
        unit(Squad.SQ_CABAL_FIRSTROOM_6, Slot.SQ_CABAL_FIRSTROOM_6),
        unit(Squad.SQ_VEX_FIRSTROOM_0, Slot.SQ_VEX_FIRSTROOM_0),
        unit(Squad.SQ_VEX_FIRSTROOM_1, Slot.SQ_VEX_FIRSTROOM_1),
        unit(Squad.SQ_VEX_FIRSTROOM_2, Slot.SQ_VEX_FIRSTROOM_2),
        unit(Squad.SQ_VEX_FIRSTROOM_3, Slot.SQ_VEX_FIRSTROOM_3),
        unit(Squad.SQ_VEX_FIRSTROOM_4, Slot.SQ_VEX_FIRSTROOM_4),
        unit(Squad.SQ_VEX_FIRSTROOM_5, Slot.SQ_VEX_FIRSTROOM_5),
        unit(Squad.SQ_VEX_FIRSTROOM_6, Slot.SQ_VEX_FIRSTROOM_6),
    },
}

local chase_reinforce = {
    id = "chase_reinforce",
    after = "chase_reinforce",
    objective = Slot.OBJ_CHASE,
    squads = {
        unit(Squad.SQ_CABAL_REINFORCEMENTS_0, Slot.SQ_CABAL_REINFORCEMENTS_0),
        unit(Squad.SQ_CABAL_REINFORCEMENTS_1, Slot.SQ_CABAL_REINFORCEMENTS_1),
        unit(Squad.SQ_CABAL_REINFORCEMENTS_2, Slot.SQ_CABAL_REINFORCEMENTS_2),
        unit(Squad.SQ_VEX_REINFORCEMENTS_0, Slot.SQ_VEX_REINFORCEMENTS_0),
        unit(Squad.SQ_VEX_REINFORCEMENTS_1, Slot.SQ_VEX_REINFORCEMENTS_1),
        unit(Squad.SQ_VEX_REINFORCEMENTS_2, Slot.SQ_VEX_REINFORCEMENTS_2),
    },
}

-- The running fight along the sparrow route. It never gates the road.
local conflict = {
    id = "conflict",
    after = "conflict",
    objective = Slot.OBJ_CHASE,
    squads = {
        unit(Squad.SQ_CONFLICT_SNIPERS_1, Slot.SQ_CONFLICT_SNIPERS_1),
        unit(Squad.SQ_CONFLICT_GOONS_TOP_0, Slot.SQ_CONFLICT_GOONS_TOP_0),
        unit(Squad.SQ_CONFLICT_GOONS_TOP_1, Slot.SQ_CONFLICT_GOONS_TOP_1),
        unit(Squad.SQ_CONFLICT_GOONS_0, Slot.SQ_CONFLICT_GOONS_0),
        unit(Squad.SQ_CONFLICT_GOONS_2, Slot.SQ_CONFLICT_GOONS_2),
        unit(Squad.SQ_CONFLICT_GOONS_4, Slot.SQ_CONFLICT_GOONS_4),
    },
}

local ledge = {
    id = "ledge",
    after = "ledge",
    objective = Slot.OBJ_BOMB,
    squads = {
        unit(Squad.SQ_CABAL_LEDGE_0, Slot.SQ_CABAL_LEDGE_0),
        unit(Squad.SQ_CABAL_LEDGE_1, Slot.SQ_CABAL_LEDGE_1),
        unit(Squad.SQ_CABAL_LEDGE_3, Slot.SQ_CABAL_LEDGE_3),
        unit(Squad.SQ_CABAL_LEDGE_4, Slot.SQ_CABAL_LEDGE_4),
        unit(Squad.SQ_CABAL_LEDGE_5, Slot.SQ_CABAL_LEDGE_5),
        unit(Squad.SQ_CABAL_LEDGE_6, Slot.SQ_CABAL_LEDGE_6),
        unit(Squad.SQ_CABAL_LEDGE_7, Slot.SQ_CABAL_LEDGE_7),
        unit(Squad.SQ_CABAL_LEDGE_8, Slot.SQ_CABAL_LEDGE_8),
        unit(Squad.SQ_CABAL_LEDGE_9, Slot.SQ_CABAL_LEDGE_9),
        unit(Squad.SQ_CABAL_LEDGE_10, Slot.SQ_CABAL_LEDGE_10),
        unit(Squad.SQ_CABAL_LEDGE_11, Slot.SQ_CABAL_LEDGE_11),
        unit(Squad.SQ_CABAL_LEDGE_12, Slot.SQ_CABAL_LEDGE_12),
        unit(Squad.SQ_VEX_LEDGE_0, Slot.SQ_VEX_LEDGE_0),
        unit(Squad.SQ_VEX_LEDGE_1, Slot.SQ_VEX_LEDGE_1),
        unit(Squad.SQ_VEX_LEDGE_2, Slot.SQ_VEX_LEDGE_2),
        unit(Squad.SQ_VEX_LEDGE_3, Slot.SQ_VEX_LEDGE_3),
        unit(Squad.SQ_VEX_LEDGE_4, Slot.SQ_VEX_LEDGE_4),
        unit(Squad.SQ_VEX_LEDGE_5, Slot.SQ_VEX_LEDGE_5),
        unit(Squad.SQ_VEX_LEDGE_6, Slot.SQ_VEX_LEDGE_6),
        unit(Squad.SQ_VEX_LEDGE_7, Slot.SQ_VEX_LEDGE_7),
        unit(Squad.SQ_VEX_LEDGE_8, Slot.SQ_VEX_LEDGE_8),
        unit(Squad.SQ_VEX_LEDGE_9, Slot.SQ_VEX_LEDGE_9),
        unit(Squad.SQ_VEX_LEDGE_10, Slot.SQ_VEX_LEDGE_10),
        unit(Squad.SQ_VEX_LEDGE_11, Slot.SQ_VEX_LEDGE_11),
        unit(Squad.SQ_VEX_LEDGE_12, Slot.SQ_VEX_LEDGE_12),
    },
}

-- The skirmish between the ledge and the boss room.
local prefight = {
    id = "prefight",
    after = "ledge",
    objective = Slot.OBJ_BOMB_BOSS,
    squads = {
        unit(Squad.SQ_PREFIGHT_SKIRMISH_0, Slot.SQ_PREFIGHT_SKIRMISH_0),
        unit(Squad.SQ_PREFIGHT_SKIRMISH_1, Slot.SQ_PREFIGHT_SKIRMISH_1),
        unit(Squad.SQ_PREFIGHT_SKIRMISH_3, Slot.SQ_PREFIGHT_SKIRMISH_3),
        unit(Squad.SQ_PREFIGHT_SKIRMISH_5, Slot.SQ_PREFIGHT_SKIRMISH_5),
    },
}

-- Valus Thuun and the Minotaur of the reveal scene.
local boss = {
    id = "boss",
    after = "reveal",
    objective = Slot.OBJ_BOMB_BOSS,
    squads = {
        unit(Squad.SQ_BOSS_80F54E07, Slot.SQ_BOSS_80F54E07),
        unit(Squad.SQ_MINOTAUR_INTRO, Slot.SQ_MINOTAUR_INTRO),
    },
}

local room1 = {
    id = "room1",
    after = "room1",
    objective = Slot.OBJ_BOMB_BOSS,
    squads = {
        unit(Squad.SQ_ROOM1_ADDS_0, Slot.SQ_ROOM1_ADDS_0),
        unit(Squad.SQ_ROOM1_ADDS_1, Slot.SQ_ROOM1_ADDS_1),
        unit(Squad.SQ_ROOM1_ADDS_2, Slot.SQ_ROOM1_ADDS_2),
        unit(Squad.SQ_ROOM1_ADDS_3, Slot.SQ_ROOM1_ADDS_3),
        unit(Squad.SQ_ROOM1_ADDS_4, Slot.SQ_ROOM1_ADDS_4),
        unit(Squad.SQ_ROOM1_ADDS_5, Slot.SQ_ROOM1_ADDS_5),
        unit(Squad.SQ_ROOM1_VEX_2, Slot.SQ_ROOM1_VEX_2),
        unit(Squad.SQ_ROOM1_VEX_3, Slot.SQ_ROOM1_VEX_3),
        unit(Squad.SQ_ROOM1_VEX_4, Slot.SQ_ROOM1_VEX_4),
        unit(Squad.SQ_ROOM1_VEX_5, Slot.SQ_ROOM1_VEX_5),
        unit(Squad.SQ_ROOM1_VEX_6, Slot.SQ_ROOM1_VEX_6),
    },
}

local room2 = {
    id = "room2",
    after = "room2",
    objective = Slot.OBJ_BOMB_BOSS,
    squads = {
        unit(Squad.SQ_ROOM2_ADDS_0, Slot.SQ_ROOM2_ADDS_0),
        unit(Squad.SQ_ROOM2_ADDS_1, Slot.SQ_ROOM2_ADDS_1),
        unit(Squad.SQ_ROOM2_ADDS_2, Slot.SQ_ROOM2_ADDS_2),
        unit(Squad.SQ_ROOM2_ADDS_3, Slot.SQ_ROOM2_ADDS_3),
        unit(Squad.SQ_ROOM2_ADDS_4, Slot.SQ_ROOM2_ADDS_4),
        unit(Squad.SQ_ROOM2_ADDS_5, Slot.SQ_ROOM2_ADDS_5),
        unit(Squad.SQ_ROOM2_ADDS_6, Slot.SQ_ROOM2_ADDS_6),
        unit(Squad.SQ_ROOM2_VEX_2, Slot.SQ_ROOM2_VEX_2),
        unit(Squad.SQ_ROOM2_VEX_3, Slot.SQ_ROOM2_VEX_3),
        unit(Squad.SQ_ROOM2_VEX_4, Slot.SQ_ROOM2_VEX_4),
        unit(Squad.SQ_ROOM2_VEX_5, Slot.SQ_ROOM2_VEX_5),
        unit(Squad.SQ_ROOM2_VEX_6, Slot.SQ_ROOM2_VEX_6),
    },
}

-- Room 3 authors no shield Vex.
local room3 = {
    id = "room3",
    after = "room3",
    objective = Slot.OBJ_BOMB_BOSS,
    squads = {
        unit(Squad.SQ_ROOM3_ADDS_0, Slot.SQ_ROOM3_ADDS_0),
        unit(Squad.SQ_ROOM3_ADDS_1, Slot.SQ_ROOM3_ADDS_1),
        unit(Squad.SQ_ROOM3_ADDS_2, Slot.SQ_ROOM3_ADDS_2),
        unit(Squad.SQ_ROOM3_ADDS_3, Slot.SQ_ROOM3_ADDS_3),
        unit(Squad.SQ_ROOM3_ADDS_4, Slot.SQ_ROOM3_ADDS_4),
        unit(Squad.SQ_ROOM3_ADDS_5, Slot.SQ_ROOM3_ADDS_5),
        unit(Squad.SQ_ROOM3_ADDS_6, Slot.SQ_ROOM3_ADDS_6),
    },
}

return campaign.new{
    key = "pact",
    directive_sensor = Slot.M_DIRECTIVE_SENSOR,
    dialogue_sensor = Slot.M_DIALOG_SENSOR,
    legs = {
        {id = "gateway", state = mission.states.STATE_80F54AE7_000F_0000_80F54AE2, arm = {
            Slot.PT_NEAR_GATE, Slot.PT_INITIAL_SPAWNS, Slot.PT_ENTER_TUNNEL,
        }},
        {id = "forest", state = mission.states.STATE_80F54AE7_0009_0000_80F54ADC, arm = {
            Slot.PT_START_FOREST, Slot.PT_BEGIN, Slot.PT_LOAD_POST, Slot.PT_SEE_PORTAL,
            Slot.PT_REACHED_PORTAL, Slot.PT_LEAVING_FOREST,
        }},
        {id = "chase", state = mission.states.STATE_80F54AE7_0002_0000_80F54AD5, arm = {
            Slot.PT_ENTER_CHASE, Slot.PT_SPARROW_RUN, Slot.PT_SPARROW_JUMP,
        }},
        {id = "bomb", state = mission.states.STATE_80F54AE7_0000_0000_80F54AD3,
            arm = {Slot.PT_REACHED_BOSS, Slot.PT_SEE_TREE},
            watch = {Slot.PM_LEDGE_FINAL, Slot.PM_ROOM2, Slot.PM_ROOM3}},
    },
    steps = {
        -- "I have reports of Red Legion activity on Mercury." The wall stands while the pad fights.
        -- Position 1 is the device's authored body, so a wall goes up by opening its position lane.
        {id = "approach", directive = Directive.APPROACH_THE_INFINITE_FOREST_GATEWAY,
            navpoint = Slot.AP_FOREST_PORTAL_80F55205,
            lines = {line(cue.CUE_1)},
            on_start = function(context)
                move(context, {Slot.D_SHIELD_WALL_80F551DE}, "open")
            end,
            ends = {trigger = Slot.PT_NEAR_GATE}},
        -- "Guardian! We've got Cabal loose."
        {id = "gate", directive = Directive.APPROACH_THE_INFINITE_FOREST_GATEWAY,
            navpoint = Slot.AP_FOREST_PORTAL_80F55205,
            lines = {line(cue.CUE_0)},
            ends = {clear = {"rearguard", "vanguard"}}},
        -- The wall comes down and the teleport opens. The authored teleporter is what carries the
        -- player, so the step only activates it and waits: selecting the Forest state here instead
        -- moves them the instant the last defender dies, with no walk into the portal.
        -- strike_bond does the same on its own LIGHTHOUSE_TELEPORT.
        {id = "traverse", directive = Directive.TRAVERSE_THE_INFINITE_FOREST,
            navpoint = Slot.AP_FOREST_PORTAL_80F55205,
            on_start = function(context)
                move(context, {Slot.D_SHIELD_WALL_80F551DE}, "close")
                context:activate_objects{slots = {Slot.LIGHTHOUSE_TELEPORT}, active = true}
            end,
            -- Only the region report ends this. PT_ENTER_TUNNEL fires as the player enters the
            -- tunnel, about twenty seconds before the client holds the Forest, so ending on it
            -- starts the next step against an object that is still loading and its device is
            -- refused as target_unavailable. strike_bond's briefing step ends on the region alone.
            ends = {region = "forest"}},
        -- The Forest island. The generator is seeded as the shield goes up.
        {id = "track", directive = Directive.TRACK_THE_CABAL,
            navpoint = Slot.AP_FOREST_PORTAL_80F550C9,
            on_start = function(context)
                move(context, {Slot.D_SHIELD_WALL_80F550B8}, "open")
                context:slot(Slot.MAP_GENERATOR_SENSOR_80F550B8):generate_map{
                    seed = campaign.run_seed(context), enabled = true}
            end,
            ends = {trigger = {Slot.PT_LOAD_POST, Slot.PT_SEE_PORTAL, Slot.PT_REACHED_PORTAL}}},
        {id = "barrier", directive = Directive.DISABLE_THE_BARRIER,
            navpoint = Slot.AP_FOREST_PORTAL_80F550C9,
            ends = {clear = "portal"}},
        {id = "forest_exit", directive = Directive.TRAVERSE_THE_INFINITE_FOREST,
            navpoint = Slot.AP_FOREST_PORTAL_80F550C9,
            on_start = function(context)
                move(context, {Slot.D_SHIELD_WALL_80F550B8}, "close")
            end,
            ends = {trigger = Slot.PT_LEAVING_FOREST, region = "chase"}},
        -- "This is a combat loop: a simulation of the recent past."
        -- The 21 laser objects stay as the map seeds them. A type-4 activation bumps the entry's
        -- generation and spawns it again on top of the seeded copy.
        {id = "hostiles", directive = Directive.ELIMINATE_HOSTILES,
            navpoint = Slot.AP_FIGHT_ROOM,
            lines = {line(cue.CUE_10)},
            ends = {clear = "first_room"}},
        {id = "chase_reinforce", directive = Directive.ELIMINATE_HOSTILES,
            navpoint = Slot.AP_FIGHT_ROOM,
            ends = {clear = "chase_reinforce"}},
        -- "A Ghost can do that?"
        {id = "mount_up", directive = Directive.MOUNT_UP_AND_MOVE_QUICKLY,
            navpoint = Slot.AP_BOSS_ROOM_80F55018,
            lines = {line(cue.CUE_11)},
            ends = {trigger = {Slot.PT_SPARROW_RUN, Slot.PT_SPARROW_JUMP}}},
        {id = "conflict", directive = Directive.FIND_THE_CABAL_LEADER,
            navpoint = Slot.AP_BOSS_ROOM_80F55018,
            ends = {region = "bomb"}},
        -- The bomb ledge. "The future where he succeeds is much worse."
        -- Not ported: the Harvester that drops the Cabal reinforcements on this ledge.
        {id = "ledge", directive = Directive.FIND_THE_CABAL_LEADER,
            navpoint = Slot.AP_BOSS_ROOM_80F54E12,
            lines = {line(cue.CUE_17)},
            ends = {monitor = Slot.PM_LEDGE_FINAL}},
        -- "I'll keep the node sealed. You take care of the Red Legion."
        {id = "find_map", directive = Directive.FIND_THE_MAP_OF_THE_INFINITE_FOREST,
            navpoint = Slot.AP_BOSS_ROOM_80F54E12,
            lines = {line(cue.CUE_18)},
            ends = {trigger = Slot.PT_REACHED_BOSS}},
        {id = "prefight", directive = Directive.FIND_THE_MAP_OF_THE_INFINITE_FOREST,
            navpoint = Slot.AP_BOSS_ROOM_80F54E12,
            barrier = true, ends = {clear = "prefight"}},
        -- "So, where's this Valus?" The scene brings in the Minotaur and Thuun.
        {id = "reveal", directive = Directive.DEFEAT_VALUS_THUUN,
            navpoint = Slot.AP_BOSS_ROOM_80F54E12,
            lines = {line(cue.CUE_20)}, scene = Scene.SCENE_MINOTAUR,
            barrier = true, ends = {scene = Slot.SCENE_MINOTAUR}},
        -- "Aaaand he's gonna be worse." Position 0 removes a gate body, so a gate is opened by
        -- closing its position lane.
        -- Thuun retreats at two thirds health and again at one third. The client reports that
        -- fraction on his type-2 Sense, so the room also ends on its own monitor.
        {id = "room1", directive = Directive.DEFEAT_VALUS_THUUN,
            lines = {line(cue.CUE_21), line(cue.CUE_22)},
            on_start = function(context)
                move(context, {Slot.D_GATE_ROOM1_ENTRY}, "close")
            end,
            barrier = true,
            ends = {monitor = Slot.PM_ROOM2,
                health = {slot = Slot.SQ_BOSS_VAL_THOOUN, at = 2 / 3}}},
        -- "It's really not."
        {id = "room2", directive = Directive.EVADE_VEX_DEFENSES, navpoint = Slot.AP_ROOM2,
            lines = {line(cue.CUE_24), line(cue.CUE_25)},
            on_start = function(context)
                move(context, {Slot.D_GATE_ROOM1_EXIT, Slot.D_GATE_ROOM2_ENTRY}, "close")
            end,
            barrier = true,
            ends = {monitor = Slot.PM_ROOM3,
                health = {slot = Slot.SQ_BOSS_VAL_THOOUN, at = 1 / 3}}},
        -- "Almost got him. Let's finish this."
        {id = "room3", directive = Directive.DEFEAT_VALUS_THUUN,
            navpoint = Slot.AP_BOSS_ROOM_80F54E12,
            lines = {line(cue.CUE_26)},
            on_start = function(context)
                move(context, {Slot.D_GATE_ROOM2_EXIT, Slot.D_GATE_ROOM3_ENTRY}, "close")
            end,
            barrier = true, ends = {clear = {"boss", "room3"}}},
        -- "Huh. I swear you did."
        {id = "dead", lines = {line(cue.CUE_27)},
            on_start = function(context)
                move(context, {Slot.D_GATE_ROOM3_EXIT}, "close")
            end},
    },
    encounters = {
        intro, vanguard, rearguard, basilisk, portal,
        first_room, chase_reinforce, conflict,
        ledge, prefight, boss, room1, room2, room3,
    },
}
