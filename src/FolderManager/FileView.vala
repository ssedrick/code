/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io),
 *               2013 Julien Spautz <spautz.julien@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3
 * as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Julien Spautz <spautz.julien@gmail.com>, Andrei-Costin Zisu <matzipan@gmail.com>
 */

namespace Scratch.FolderManager {
    /**
     * SourceList that displays folders and their contents.
     */
    internal class FileView : Granite.Widgets.SourceList, Code.PaneSwitcher {
        private GLib.Settings settings;

        public signal void select (string file);

        // This is a workaround for SourceList silliness: you cannot remove an item
        // without it automatically selecting another one.
        public bool ignore_next_select { get; set; default = false; }
        public string icon_name { get; set; }
        public string title { get; set; }

        construct {
            width_request = 180;
            icon_name = "folder-symbolic";
            title = _("Folders");

            item_selected.connect (on_item_selected);

            settings = new GLib.Settings ("io.elementary.code.folder-manager");
        }

        private void on_item_selected (Granite.Widgets.SourceList.Item? item) {
            // This is a workaround for SourceList silliness: you cannot remove an item
            // without it automatically selecting another one.
            if (ignore_next_select) {
                ignore_next_select = false;
                return;
            }

            if (item is FileItem) {
                select ((item as FileItem).file.path);
            }
        }

        public void restore_saved_state () {
            foreach (unowned string path in settings.get_strv ("opened-folders")) {
                add_folder (new File (path), false);
            }
        }

        public void open_folder (File folder) {
            if (is_open (folder)) {
                warning ("Folder '%s' is already open.", folder.path);
                return;
            } else if (!folder.is_valid_directory) {
                warning ("Cannot open invalid directory.");
                return;
            }

            add_folder (folder, true);
            write_settings ();
        }

        public void collapse_all () {
            foreach (var child in root.children) {
                (child as ProjectFolderItem).collapse_all ();
            }
        }

        public void order_folders () {
            var list = new Gee.ArrayList<ProjectFolderItem> ();

            foreach (var child in root.children) {
                root.remove (child as ProjectFolderItem);
                list.add (child as ProjectFolderItem);
            }

            list.sort ( (a, b) => {
                return a.name.down () > b.name.down () ? 0 : -1;
            });

            foreach (var item in list) {
                root.add (item);
            }
        }

        public void select_path (string path) {
            selected = find_path (root, path);
        }

        private Granite.Widgets.SourceList.Item? find_path (Granite.Widgets.SourceList.ExpandableItem list, string path) {
            foreach (var item in list.children) {
                if (item is Item) {
                    var code_item = item as Item;
                    if (code_item.path == path) {
                        return item;
                    }

                    if (item is Granite.Widgets.SourceList.ExpandableItem) {
                        var expander = item as Granite.Widgets.SourceList.ExpandableItem;
                        if (!expander.expanded || !path.has_prefix (code_item.path)) {
                            continue;
                        }

                        var recurse_item = find_path (expander, path);
                        if (recurse_item != null) {
                            return recurse_item;
                        }
                    }
                }
            }

            return null;
        }

        private void add_folder (File folder, bool expand) {
            if (is_open (folder)) {
                warning ("Folder '%s' is already open.", folder.path);
                return;
            } else if (!folder.is_valid_directory) {
                warning ("Cannot open invalid directory.");
                return;
            }

            var folder_root = new ProjectFolderItem (folder, this);
            this.root.add (folder_root);

            folder_root.expanded = expand;
            folder_root.closed.connect (() => {
                root.remove (folder_root);
                write_settings ();
            });

            folder_root.close_all_except.connect (() => {
                foreach (var child in root.children) {
                    if (child != folder_root) {
                        root.remove (child);
                    }
                }

                write_settings ();
            });
        }

        private bool is_open (File folder) {
            foreach (var child in root.children)
                if (folder.path == (child as Item).path)
                    return true;
            return false;
        }

        private void write_settings () {
            string[] to_save = {};

            foreach (var main_folder in root.children) {
                var saved = false;

                foreach (var saved_folder in to_save) {
                    if ((main_folder as Item).path == saved_folder) {
                        saved = true;
                        break;
                    }
                }

                if (!saved) {
                    to_save += (main_folder as Item).path;
                }
            }

            settings.set_strv ("opened-folders", to_save);
        }
    }
}
