# Modularization Plan

## Overview
This document describes how to refactor the existing "setup.sh" script into a modular structure to improve maintainability and reusability.

## Proposed File Structure
We will create a new directory called "lib" that will contain the following files:
- **constants.sh**: Contains all constants, color definitions, URLs, directory constants, and other static values.
- **helpers.sh**: Contains general utility functions such as is_root_user, command_exists, directory_exists_and_populated, check_url, detect_package_manager, update_package_manager, and backup_file.
- **status_checks.sh**: Contains functions that check the status of various components like check_zsh_status, check_starship_status, check_zsh_extensions_status, check_tmux_status, check_yazi_status, check_go_status, and check_nvtop_status.
- **installers.sh**: Contains installation and setup functions for various components (e.g., install_package and setup_* functions).

A new main script (either a new `main.sh` or an updated `setup.sh` at the root) will source these module files and invoke the main function, preserving the original functionality.

## Modularization Benefits
- **Separation of Concerns**: Each file/module has a clear responsibility.
- **Improved Maintainability**: Easier to update and manage individual components.
- **Reusability**: Modules can be reused in other projects or scripts.
- **Enhanced Readability**: Clear file boundaries help new developers understand the setup logic.

## File Organization Diagram
Below is a Mermaid diagram representing the proposed file structure:

```mermaid
graph TD
    A[setup.sh (Main Script)] --> B[lib/constants.sh]
    A --> C[lib/helpers.sh]
    A --> D[lib/status_checks.sh]
    A --> E[lib/installers.sh]
```

## Next Steps
1. **Create the "lib" Directory**: The new directory will house the modularized files.
2. **Split Functions Appropriately**: Move functions from setup.sh into the corresponding module files as described.
3. **Update the Main Script**: Modify the main script to source the new module files.
4. **Test the Setup**: Ensure the reorganized scripts work as expected.

This modularization plan serves as the reference for refactoring the current setup.sh script.