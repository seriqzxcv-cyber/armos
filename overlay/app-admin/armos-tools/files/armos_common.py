"""Shared helpers for the ARMOS desktop applications (GTK3)."""

import glob
import os
import shutil
import subprocess

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import GLib, Gtk  # noqa: E402

APP_NAME = "ARMOS"
APP_VERSION = "1.0 (GEN)"

DEFAULT_ACCENT = "#4C8DFF"
CONFIG_DIR = os.path.expanduser("~/.config/armos")


def get_accent():
    """Return the user-selected accent, falling back to the ARMOS blue."""
    try:
        with open(os.path.join(CONFIG_DIR, "accent"), "r", encoding="ascii") as fh:
            value = fh.read().strip()
        if len(value) == 7 and value.startswith("#"):
            int(value[1:], 16)
            return value
    except (OSError, ValueError):
        pass
    return DEFAULT_ACCENT


ACCENT_BEGIN = "/* BEGIN ARMOS ACCENT (managed by ARMOS Settings) */"
ACCENT_END = "/* END ARMOS ACCENT */"


def accent_css(value):
    return (
        ACCENT_BEGIN + "\n"
        "@define-color theme_selected_bg_color {0};\n"
        "@define-color theme_focus_bg_color {0};\n"
        "@define-color accent_color {0};\n"
        "selection, *:selected {{ background-color: {0}; color: #FFFFFF; }}\n"
        "progressbar progress, levelbar block.filled {{ background-color: {0}; }}\n"
        + ACCENT_END
    ).format(value)


def set_accent(value):
    """Persist a new accent, replacing only the managed block in gtk.css."""
    if not (len(value) == 7 and value.startswith("#")):
        raise ValueError("accent must be #RRGGBB")
    int(value[1:], 16)
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(os.path.join(CONFIG_DIR, "accent"), "w", encoding="ascii") as fh:
        fh.write(value + "\n")
    gtk_dir = os.path.expanduser("~/.config/gtk-3.0")
    os.makedirs(gtk_dir, exist_ok=True)
    css_path = os.path.join(gtk_dir, "gtk.css")
    try:
        with open(css_path, "r", encoding="utf-8") as fh:
            existing = fh.read()
    except OSError:
        existing = ""
    block = accent_css(value)
    start = existing.find(ACCENT_BEGIN)
    end = existing.find(ACCENT_END)
    if start >= 0 and end >= start + len(ACCENT_BEGIN):
        end += len(ACCENT_END)
        updated = existing[:start] + block + existing[end:]
    else:
        updated = existing.rstrip() + "\n\n" + block + "\n"
    with open(css_path, "w", encoding="utf-8") as fh:
        fh.write(updated)
    return value


ACCENT = get_accent()

BACKGROUND = "#0E1014"
SURFACE = "#16181D"
SURFACE_2 = "#1D2026"
TEXT = "#E6EAF0"
MUTED = "#8B929D"
BORDER = "#2A2D33"


def build_css(accent=None):
    accent = accent or get_accent()
    return f"""
window, dialog {{ background-color: {BACKGROUND}; color: {TEXT}; }}
label {{ color: {TEXT}; }}
.title {{ font-size: 26px; font-weight: 700; }}
.subtitle {{ color: {MUTED}; font-size: 12px; }}
.accent {{ color: {accent}; }}
.tile {{
    background-color: {SURFACE}; border: 1px solid {BORDER};
    border-radius: 8px; padding: 16px;
}}
.tile:hover {{ border-color: {accent}; background-color: {SURFACE_2}; }}
.tile-title {{ font-size: 15px; font-weight: 600; }}
.tile-subtitle {{ color: {MUTED}; font-size: 11px; }}
button {{
    background-image: none; background-color: {SURFACE_2};
    border: 1px solid {BORDER}; border-radius: 6px;
    padding: 8px 14px; color: {TEXT};
}}
button:hover {{ border-color: {accent}; }}
button.suggested {{ background-color: {accent}; color: #0B1220; }}
button.suggested:hover {{ background-color: #3F7BE0; }}
entry {{ background-color: {SURFACE}; border: 1px solid {BORDER}; border-radius: 6px; }}
textview, textview text {{ background-color: #0A0D12; color: {TEXT}; }}
"""


CSS = build_css()

_windows = set()


def apply_theme():
    settings = Gtk.Settings.get_default()
    if settings is not None:
        settings.set_property("gtk-application-prefer-dark-theme", True)
    screen = 0  # noqa: F841
    from gi.repository import Gdk

    screen = Gdk.Screen.get_default()
    if screen is not None:
        provider = Gtk.CssProvider()
        provider.load_from_data(build_css().encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )


def is_live():
    return any(
        os.path.exists(p)
        for p in ("/run/rootfsbase", "/run/initramfs/live", "/LiveOS")
    )


def logo_path():
    for name in ("armos-logo-256.png", "armos-logo.svg"):
        path = os.path.join("/usr/share/pixmaps", name)
        if os.path.exists(path):
            return path
    return None


def installed(atom):
    cat, pkg = atom.split("/", 1)
    return bool(glob.glob(os.path.join("/var/db/pkg", cat, pkg + "-*")))


def portage_tree_present():
    """True when at least one ebuild repository with packages is available."""
    return any(
        os.path.isdir(os.path.join(root, "eclass"))
        for root in glob.glob("/var/db/repos/*")
    )


def atom_available(atom):
    """Cheap availability check against the local ebuild repositories.

    Returns None when the tree is missing (unknown), otherwise a bool.
    """
    if not portage_tree_present():
        return None
    cat, pkg = atom.split("/", 1)
    return bool(glob.glob(os.path.join("/var/db/repos/*", cat, pkg, "*.ebuild")))


def run(argv, stdin=None, timeout=8):
    """Run a local helper and return (stdout, error). Never raises."""
    try:
        result = subprocess.run(
            argv, input=stdin, capture_output=True, text=True, timeout=timeout
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return "", str(exc)
    if result.returncode != 0:
        return result.stdout.strip(), result.stderr.strip() or "команда завершилась с ошибкой"
    return result.stdout.strip(), ""


def launch(argv):
    """Launch a desktop application detached from this process."""
    try:
        subprocess.Popen(argv, start_new_session=True)
        return True
    except (OSError, ValueError):
        return False


def _keep(window):
    _windows.add(window)
    window.connect("destroy", lambda w: _windows.discard(w))


class TaskWindow(Gtk.Window):
    """Run a command as root (via pkexec) and stream its output."""

    def __init__(self, title, argv, parent=None, on_done=None):
        super().__init__(title=title)
        self.set_default_size(820, 520)
        self.set_position(Gtk.WindowPosition.CENTER)
        self._on_done = on_done
        self._proc = None
        self._finished = False

        header = Gtk.HeaderBar(title=title, show_close_button=True)
        self.set_titlebar(header)
        self.spinner = Gtk.Spinner()
        header.pack_start(self.spinner)
        self.cancel = Gtk.Button(label="Отмена")
        self.cancel.connect("clicked", self._cancel)
        header.pack_end(self.cancel)

        scroller = Gtk.ScrolledWindow()
        scroller.set_hexpand(True)
        scroller.set_vexpand(True)
        self.view = Gtk.TextView()
        self.view.set_editable(False)
        self.view.set_monospace(True)
        self.view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        scroller.add(self.view)
        self.add(scroller)

        self.connect("delete-event", self._on_delete)
        self.show_all()
        self.spinner.start()
        _keep(self)

        cmd = argv
        if os.geteuid() != 0:
            if shutil.which("pkexec") is None:
                self._append("pkexec not found; run the command manually:\n")
                self._append(" ".join(argv) + "\n")
                self._finish(None)
                return
            cmd = ["pkexec"] + argv

        self._append("$ " + " ".join(cmd) + "\n\n")
        try:
            self._proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                start_new_session=True,
            )
        except OSError as exc:
            self._append(str(exc) + "\n")
            self._finish(None)
            return

        fd = self._proc.stdout.fileno()
        os.set_blocking(fd, False)
        GLib.io_add_watch(fd, GLib.PRIORITY_DEFAULT, GLib.IO_IN | GLib.IO_HUP, self._read)
        GLib.child_watch_add(GLib.PRIORITY_DEFAULT, self._proc.pid, self._exit)

    def _append(self, text):
        buf = self.view.get_buffer()
        buf.insert(buf.get_end_iter(), text)
        mark = buf.create_mark(None, buf.get_end_iter(), False)
        self.view.scroll_mark_onscreen(mark)

    def get_text(self):
        buf = self.view.get_buffer()
        return buf.get_text(buf.get_start_iter(), buf.get_end_iter(), True)

    def _read(self, fd, condition):
        try:
            data = os.read(fd, 65536).decode("utf-8", "replace")
        except OSError:
            data = ""
        if data:
            self._append(data)
            return True
        return False

    def _exit(self, pid, status):
        # GLib passes the raw waitpid status; callers expect an exit code.
        try:
            self._finish(os.waitstatus_to_exitcode(status))
        except (ValueError, AttributeError):
            self._finish(os.WEXITSTATUS(status) if os.WIFEXITED(status) else 1)

    def _finish(self, status):
        if self._finished:
            return
        self._finished = True
        self.spinner.stop()
        if status is not None and status != 0:
            self._append("\n[код завершения: {}]\n".format(status))
        self.cancel.set_label("Закрыть")
        self.cancel.disconnect_by_func(self._cancel)
        self.cancel.connect("clicked", lambda *_: self.destroy())
        if self._on_done is not None:
            try:
                self._on_done(status)
            except Exception as exc:
                self._append("\n[ошибка обработчика: {}]\n".format(exc))
        self._proc = None

    def _on_delete(self, *_):
        if self._proc is not None:
            self._cancel()
            return True
        return False

    def _cancel(self, *_):
        if self._proc is not None:
            try:
                os.killpg(self._proc.pid, 15)
            except OSError:
                pass
            self._append("\n[отменено]\n")
        self.cancel.set_sensitive(False)


def message(parent, text, kind=Gtk.MessageType.INFO):
    dialog = Gtk.MessageDialog(
        transient_for=parent,
        flags=0,
        message_type=kind,
        buttons=Gtk.ButtonsType.OK,
        text=text,
    )
    dialog.run()
    dialog.destroy()


def xfconf_get(channel, prop, default=""):
    """Read an xfconf property in the current session (or return default)."""
    try:
        result = subprocess.run(
            ["xfconf-query", "-c", channel, "-p", prop],
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    return default


def xfconf_set(channel, prop, value, value_type="string"):
    """Set (or create) an xfconf property in the current session."""
    commands = [
        ["xfconf-query", "-c", channel, "-p", prop, "-s", value],
        ["xfconf-query", "-c", channel, "-p", prop, "-n", "-t", value_type, "-s", value],
    ]
    for command in commands:
        try:
            result = subprocess.run(command, capture_output=True, timeout=5)
            if result.returncode == 0:
                return True
        except (OSError, subprocess.SubprocessError):
            pass
    return False


WALLPAPER_DIR = "/usr/share/backgrounds/armos"


def wallpapers():
    return sorted(glob.glob(os.path.join(WALLPAPER_DIR, "*.png")))


def wallpaper_name(path):
    return os.path.basename(path).replace("armos-", "").replace(".png", "")


def set_wallpaper(path):
    """Apply a wallpaper to every Xfce 4.20 monitor/workspace key."""
    if not os.path.exists(path):
        return False
    props = subprocess.run(
        ["xfconf-query", "-c", "xfce4-desktop", "-l"],
        capture_output=True, text=True, timeout=5,
    ).stdout.splitlines()
    prefixes = set()
    for prop in props:
        if prop.endswith("/last-image") and prop.startswith("/backdrop/"):
            prefixes.add(prop[: -len("/last-image")])
    for prefix in prefixes:
        xfconf_set("xfce4-desktop", prefix + "/last-image", path)
        xfconf_set("xfce4-desktop", prefix + "/image-style", "5", "int")
    # Also cover the common connector naming used by QEMU and laptops.
    for name in ("Virtual-1", "eDP-1", "HDMI-A-1", "VGA-1"):
        for workspace in range(4):
            prefix = "/backdrop/screen0/monitor{}/workspace{}".format(name, workspace)
            xfconf_set("xfce4-desktop", prefix + "/last-image", path)
            xfconf_set("xfce4-desktop", prefix + "/image-style", "5", "int")
    return True
