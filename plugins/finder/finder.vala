// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3, as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>
 */

public class Scratch.Plugins.Finder: Peas.ExtensionBase, Peas.Activatable {
    public void activate () {
        plugins = (Scratch.Services.Interface) object;
        plugins.hook_document.connect ((doc) => {
            this.view = doc.source_view;
            this.view.key_press_event.disconnect (handle_key_press);
            this.view.key_press_event.connect (handle_key_press);
            this.views.add (view);
        })
    }

    public void deactivate () {
        foreach (var v in views) {
            v.key_press_event.disconnect (handle_key_press);
        }
    }

    private bool handle_key_press (Gdk.EventKey event) {
        bool ctrl = (event.state & Gdk.ModifierType.CONTROL_MASK) != 0;
        switch (event.keyval) {
            case Gdk.Key.t:
            case Gdk.Key.p:
                return ctrl;
            default:
                return false;
        }
    }
}
