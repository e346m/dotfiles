{ vimUtils, fetchFromGitHub }:

vimUtils.buildVimPlugin {
  pname = "agentic-nvim";
  version = "0-unstable-2026-08-23";
  src = fetchFromGitHub {
    owner = "carlos-algms";
    repo = "agentic.nvim";
    rev = "81628c1dc07edadd1c2c3c27d8dbcb424da1dea0";
    hash = "sha256-gGesKupHCLVTQ27vj2OTllOPNG1hubZdUrYTqpofEVM=";
  };
  # Colocated *.test.lua files are busted specs, not require-able modules.
  nvimSkipModules = [
    "agentic.acp.acp_client.test"
    "agentic.acp.acp_health.test"
    "agentic.acp.acp_transport.test"
    "agentic.acp.agent_config_options.test"
    "agentic.acp.agent_instance.test"
    "agentic.acp.agent_models.test"
    "agentic.acp.agent_modes.test"
    "agentic.acp.session_state.test"
    "agentic.acp.slash_commands.test"
    "agentic.agentic.test"
    "agentic.config_default.test"
    "agentic.config_selector.test"
    "agentic.health.test"
    "agentic.provider_switcher.test"
    "agentic.session_manager.test"
    "agentic.session_navigation.test"
    "agentic.session_registry.test"
    "agentic.session_restore.test"
    "agentic.session_starter.test"
    "agentic.theme.test"
    "agentic.ui.buffer_guard.test"
    "agentic.ui.chat_history.test"
    "agentic.ui.chat_navigation.test"
    "agentic.ui.chat_widget.test"
    "agentic.ui.clipboard_image.test"
    "agentic.ui.clipboard.test"
    "agentic.ui.code_selection.test"
    "agentic.ui.config_options_modal.test"
    "agentic.ui.diagnostics_context.test"
    "agentic.ui.diagnostics_list.test"
    "agentic.ui.diff_coordinator.test"
    "agentic.ui.diff_preview.test"
    "agentic.ui.diff_split_view.test"
    "agentic.ui.file_list.test"
    "agentic.ui.file_picker.test"
    "agentic.ui.hunk_navigation.test"
    "agentic.ui.message_writer.test"
    "agentic.ui.permission_manager.test"
    "agentic.ui.status_animation.test"
    "agentic.ui.todo_list.test"
    "agentic.ui.tool_block_border.test"
    "agentic.ui.tool_call_blocks.test"
    "agentic.ui.tool_call_diff.test"
    "agentic.ui.tool_call_fold.test"
    "agentic.ui.widget_layout.test"
    "agentic.ui.widget_registry.test"
    "agentic.ui.window_decoration.test"
    "agentic.utils.buf_helpers.test"
    "agentic.utils.diff_highlighter.test"
    "agentic.utils.hooks.test"
    "agentic.utils.json_format.test"
    "agentic.utils.object.test"
    "agentic.utils.text_matcher.test"
  ];
}
