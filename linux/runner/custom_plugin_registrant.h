#ifndef CUSTOM_PLUGIN_REGISTRANT_H_
#define CUSTOM_PLUGIN_REGISTRANT_H_

#include <flutter_linux/flutter_linux.h>

// Register custom plugins that are not in the generated registrant
void register_custom_plugins(FlPluginRegistry* registry);

#endif  // CUSTOM_PLUGIN_REGISTRANT_H_
