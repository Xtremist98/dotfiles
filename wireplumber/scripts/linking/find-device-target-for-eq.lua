-- WirePlumber user hook: force the parametric-EQ playback node onto a
-- physical device.
--
-- Background
-- ----------
-- The audio chain on this machine is:
--
--   app streams -> effect_input.virtual-surround-7.1-hesuvi (HeSuVi)
--               -> (HeSuVi playback) effect_output... node.target = "eq_input"
--               -> eq_input (parametric EQ)
--               -> eq_output
--               -> physical device (bluez / alsa)
--
-- "eq_output" declares no node.target, so linking/find-default-target resolves
-- it to the *default sink*, which is effect_input.virtual-surround-7.1-hesuvi
-- (the HeSuVi input). That creates eq_output -> effect_input, i.e. a real
-- feedback loop, and it also makes eq_input's peer (eq_output) sit in the same
-- link-group chain as effect_output. linking-utils.canLinkGroupCheck then
-- refuses the *intended* effect_output -> eq_input link as a "cycle", so
-- find-best-target falls back to wiring effect_output straight to the device
-- and the EQ is silently bypassed.
--
-- Fix
-- ---
-- Pick the target for eq_output ourselves, before linking/find-default-target
-- gets a chance to hand it the virtual default sink. The selection rules are
-- copied from linking/find-best-target.lua: only real devices
-- (item.node.type = device), same media.type, opposite direction, must pass
-- canLink / haveAvailableRoutes / checkPassthroughCompatibility, highest
-- priority.session wins, ties broken by the most recently plugged device.
--
-- Once eq_output points at a device (which has no node.link-group),
-- canLinkGroupCheck stops seeing a cycle and effect_output -> eq_input links
-- normally. Because the hook is a normal select-target hook it also re-runs on
-- every rescan (device plugged/unplugged, BT connect/disconnect, default node
-- change), so the device hop follows whatever output is present.

lutils = require ("linking-utils")
cutils = require ("common-utils")
log = Log.open_topic ("s-linking")

-- node.name of the parametric EQ's playback node (see
-- ~/.config/pipewire/pipewire.conf.d/01-paramatric-eq.conf)
local EQ_PLAYBACK_NODE_NAME = "eq_output"

SimpleEventHook {
  name = "linking/find-device-target-for-eq",
  after = "linking/find-defined-target",
  before = "linking/find-default-target",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-target" },
    },
  },
  execute = function (event)
    local source, om, si, si_props, si_flags, target =
        lutils:unwrap_select_target_event (event)

    -- An explicitly defined target always wins.
    if target then
      return
    end

    if si_props ["node.name"] ~= EQ_PLAYBACK_NODE_NAME then
      return
    end

    local target_direction = cutils.getTargetDirection (si_props)
    local target_picked = nil
    local target_can_passthrough = false
    local target_priority = 0
    local target_plugged = 0

    for candidate in om:iterate {
      type = "SiLinkable",
      Constraint { "item.node.type", "=", "device" },
      Constraint { "item.node.direction", "=", target_direction },
      Constraint { "media.type", "=", si_props ["media.type"] },
    } do
      local candidate_props = candidate.properties
      local priority = tonumber (candidate_props ["priority.session"]) or 0

      if not lutils.canLink (si_props, candidate) then
        goto skip_linkable
      end

      if not lutils.haveAvailableRoutes (candidate_props) then
        goto skip_linkable
      end

      local passthrough_compatible, can_passthrough =
          lutils.checkPassthroughCompatibility (si, candidate)
      if not passthrough_compatible then
        goto skip_linkable
      end

      local plugged = tonumber (candidate_props ["item.plugged.usec"]) or 0

      if (target_picked == nil or
          priority > target_priority or
          (priority == target_priority and plugged > target_plugged)) then
        target_picked = candidate
        target_can_passthrough = can_passthrough
        target_priority = priority
        target_plugged = plugged
      end
      ::skip_linkable::
    end

    if target_picked then
      log:info (si, string.format (
          "... eq-output device target picked: %s (%s), can_passthrough:%s",
          tostring (target_picked.properties ["node.name"]),
          tostring (target_picked.properties ["node.id"]),
          tostring (target_can_passthrough)))
      si_flags.can_passthrough = target_can_passthrough
      event:set_data ("target", target_picked)
    else
      log:info (si, "... no device target available for eq-output, leaving it to the policy")
    end
  end
}:register ()
