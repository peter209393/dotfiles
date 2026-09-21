#!/usr/bin/env python3
"""SNI 托盘单色代理 —— 把托盘图标重着色成单色剪影。

背景:waybar 托盘图标由应用自己通过 StatusNotifierItem 协议以 ARGB 位图
(IconPixmap) 直发(Telegram 的 IconName 为空、无 IconThemePath),GTK 图标
主题和 CSS 都够不着,导致彩色图标和 bar 上其他 Nerd Font 单色图标风格不一。

原理:抢在 waybar 之前占用 org.kde.StatusNotifierWatcher 总线名,自己扮演
watcher。应用注册进来后,为每个托盘项单独开一条总线连接、占一个中转名
(org.mono.tray.iN):方法/属性/菜单/信号全部原样转发,唯独把 IconPixmap /
AttentionIconPixmap 重着色成「亮度→透明度 + 统一 RGB」的单色剪影。waybar
拿到的是中转名,显示出来的就是单色图标。

注意:
- GLib 客户端(waybar)会把中转名解析成连接的 unique 名再发消息,所以每个
  托盘项必须独占一条连接,否则同名路径(/StatusNotifierItem、/MenuBar)
  无法区分是哪个应用的。
- 必须在 waybar 之前启动(由 waybar-mono-tray.sh 包装保证),依赖 python-dbus-next。
- 若 watcher 名已被占用(如裸 waybar 先起),直接退出,由包装脚本兜底。
"""

import asyncio
import sys
import traceback

from dbus_next import Message, Variant
from dbus_next.aio import MessageBus
from dbus_next.constants import (
    BusType,
    MessageFlag,
    MessageType,
    NameFlag,
    RequestNameReply,
)

WATCHER_NAME = "org.kde.StatusNotifierWatcher"
WATCHER_IFACE = "org.kde.StatusNotifierWatcher"
WATCHER_PATH = "/StatusNotifierWatcher"
MARKER_NAME = "org.mono.SniWatcher"  # 存在性标记,包装脚本据此判断代理是否在线
ITEM_IFACE = "org.kde.StatusNotifierItem"
ITEM_PATH = "/StatusNotifierItem"
MENU_IFACE = "com.canonical.dbusmenu"

PROPS_IFACE = "org.freedesktop.DBus.Properties"
INTRO_IFACE = "org.freedesktop.DBus.Introspectable"
PEER_IFACE = "org.freedesktop.DBus.Peer"
DBUS_IFACE = "org.freedesktop.DBus"
DBUS_PATH = "/org/freedesktop/DBus"

# 单色剪影的目标色:waybar @text(Catppuccin Mocha #cdd6f4)
TARGET_RGB = (0xCD, 0xD6, 0xF4)
# 不透明像素平均亮度低于此值视为「深色图标」,反相亮度以免在黑 bar 上隐身
DARK_ICON_THRESHOLD = 110

# 每个托盘项都补齐的属性默认值(类型按 SNI 规范),防止应用少发属性
PROP_DEFAULTS = {
    "Category": Variant("s", "ApplicationStatus"),
    "Id": Variant("s", ""),
    "Title": Variant("s", ""),
    "Status": Variant("s", "Active"),
    "WindowId": Variant("i", 0),
    "IconThemePath": Variant("s", ""),
    "IconName": Variant("s", ""),
    "IconPixmap": Variant("a(iiay)", []),
    "OverlayIconName": Variant("s", ""),
    "OverlayIconPixmap": Variant("a(iiay)", []),
    "AttentionIconName": Variant("s", ""),
    "AttentionIconPixmap": Variant("a(iiay)", []),
    "AttentionMovieName": Variant("s", ""),
    "ToolTip": Variant("(sa(iiay)ss)", ["", [], "", ""]),
    "ItemIsMenu": Variant("b", False),
    "Menu": Variant("o", "/"),
}

# 需要做单色化的位图属性
MONO_PROPS = ("IconPixmap", "AttentionIconPixmap")

# 收到应用的 New* 信号后,需要重新拉取并刷新缓存的属性
REFRESH_ON_SIGNAL = {
    "NewIcon": ["IconName", "IconPixmap", "OverlayIconName", "OverlayIconPixmap"],
    "NewAttentionIcon": ["AttentionIconName", "AttentionIconPixmap"],
    "NewToolTip": ["ToolTip"],
    "NewTitle": ["Title"],
}

WATCHER_XML = f"""<node>
 <interface name="{WATCHER_IFACE}">
  <method name="RegisterStatusNotifierItem"><arg name="service" type="s" direction="in"/></method>
  <method name="RegisterStatusNotifierHost"><arg name="service" type="s" direction="in"/></method>
  <property name="RegisteredStatusNotifierItems" type="as" access="read"/>
  <property name="IsStatusNotifierHostRegistered" type="b" access="read"/>
  <property name="ProtocolVersion" type="i" access="read"/>
  <signal name="StatusNotifierItemRegistered"><arg type="s"/></signal>
  <signal name="StatusNotifierItemUnregistered"><arg type="s"/></signal>
  <signal name="StatusNotifierHostRegistered"/>
 </interface>
 <interface name="{PROPS_IFACE}">
  <method name="Get"><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="v" direction="out"/></method>
  <method name="GetAll"><arg type="s" direction="in"/><arg type="a{{sv}}" direction="out"/></method>
  <method name="Set"><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="v" direction="in"/></method>
  <signal name="PropertiesChanged"><arg type="s"/><arg type="a{{sv}}"/><arg type="as"/></signal>
 </interface>
 <interface name="{INTRO_IFACE}">
  <method name="Introspect"><arg type="s" direction="out"/></method>
 </interface>
</node>"""

ITEM_XML = f"""<node>
 <interface name="{ITEM_IFACE}">
  <method name="ContextMenu"><arg type="i" direction="in"/><arg type="i" direction="in"/></method>
  <method name="Activate"><arg type="i" direction="in"/><arg type="i" direction="in"/></method>
  <method name="SecondaryActivate"><arg type="i" direction="in"/><arg type="i" direction="in"/></method>
  <method name="Scroll"><arg type="i" direction="in"/><arg type="s" direction="in"/></method>
  {"".join(f'<property name="{k}" type="{v.signature}" access="read"/>' for k, v in PROP_DEFAULTS.items())}
  <signal name="NewTitle"/>
  <signal name="NewIcon"/>
  <signal name="NewAttentionIcon"/>
  <signal name="NewOverlayIcon"/>
  <signal name="NewToolTip"/>
  <signal name="NewStatus"><arg type="s"/></signal>
  <signal name="NewIconThemePath"><arg type="s"/></signal>
 </interface>
 <interface name="{PROPS_IFACE}">
  <method name="Get"><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="v" direction="out"/></method>
  <method name="GetAll"><arg type="s" direction="in"/><arg type="a{{sv}}" direction="out"/></method>
  <method name="Set"><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="v" direction="in"/></method>
  <signal name="PropertiesChanged"><arg type="s"/><arg type="a{{sv}}"/><arg type="as"/></signal>
 </interface>
 <interface name="{INTRO_IFACE}">
  <method name="Introspect"><arg type="s" direction="out"/></method>
 </interface>
</node>"""


def log(*args):
    print("[sni-mono-proxy]", *args, file=sys.stderr, flush=True)


def mono_pixmap(pixmaps):
    """a(iiay) 位图 → 单色剪影:亮度映射成透明度,RGB 统一成 bar 文字色。

    SNI 位图是网络字节序的 ARGB32(每像素 4 字节:A,R,G,B)。
    深色主体(深色图标配浅底设计的)自动反相,避免在深色 bar 上隐身。
    """
    tr, tg, tb = TARGET_RGB
    out = []
    for w, h, data in pixmaps:
        buf = bytearray(data)
        total = count = 0
        for i in range(0, len(buf) - 3, 4):
            if buf[i] > 40:  # 只统计基本不透明的像素
                total += (buf[i + 1] * 299 + buf[i + 2] * 587 + buf[i + 3] * 114) // 1000
                count += 1
        invert = count > 0 and total // count < DARK_ICON_THRESHOLD
        for i in range(0, len(buf) - 3, 4):
            lum = (buf[i + 1] * 299 + buf[i + 2] * 587 + buf[i + 3] * 114) // 1000
            if invert:
                lum = 255 - lum
            buf[i] = buf[i] * lum // 255  # alpha = 原透明度 × 亮度
            buf[i + 1] = tr
            buf[i + 2] = tg
            buf[i + 3] = tb
        out.append([w, h, bytes(buf)])
    return out


# ---------- 消息回复辅助(bus 显式传入,因为每个托盘项各占一条连接) ----------

def reply_ok(bus, msg, signature="", body=None):
    if msg.flags & MessageFlag.NO_REPLY_EXPECTED:
        return
    bus.send(Message(
        message_type=MessageType.METHOD_RETURN,
        reply_serial=msg.serial,
        destination=msg.sender,
        signature=signature,
        body=body or [],
    ))


def reply_err(bus, msg, name, *text):
    if msg.flags & MessageFlag.NO_REPLY_EXPECTED:
        return
    bus.send(Message(
        message_type=MessageType.ERROR,
        error_name=name,
        reply_serial=msg.serial,
        destination=msg.sender,
        signature="s" if text else "",
        body=list(text) if text else [],
    ))


def send_signal(bus, path, interface, member, signature="", body=None):
    bus.send(Message(
        message_type=MessageType.SIGNAL,
        path=path,
        interface=interface,
        member=member,
        signature=signature,
        body=body or [],
    ))


def props_changed(bus, path, interface, changed):
    send_signal(bus, path, PROPS_IFACE, "PropertiesChanged", "sa{sv}as",
                [interface, changed, []])


async def call_safe(bus, msg, timeout=5.0):
    try:
        return await asyncio.wait_for(bus.call(msg), timeout)
    except Exception as e:
        log("call failed:", msg.member, e)
        return None


_TASKS = set()  # 强引用集合:防止运行中的任务被 GC 静默回收


def spawn(coro):
    async def runner():
        try:
            await coro
        except Exception:
            log(traceback.format_exc())
    task = asyncio.ensure_future(runner())
    _TASKS.add(task)
    task.add_done_callback(_TASKS.discard)


class Item:
    """一个被代理的托盘项。conn 是它独占的总线连接(见文件头注释)。"""

    def __init__(self, orig_name, orig_path, owner, proxy_name):
        self.orig_name = orig_name    # 应用注册时给的总线名
        self.orig_path = orig_path    # 应用侧的 SNI 对象路径
        self.owner = owner            # 应用连接的 unique 名(监视退出用)
        self.proxy_name = proxy_name  # 我们持有的中转总线名
        self.conn = None              # 独占的总线连接
        self.props = {}               # 属性缓存(已单色化)
        self.match_rules = []         # 在主连接上为此项注册的信号匹配规则


class ItemServer:
    """装在托盘项独占连接上的消息处理器:属性从缓存答,其余整包转发。"""

    def __init__(self, proxy, item):
        self.proxy = proxy
        self.item = item

    def on_message(self, msg):
        try:
            if msg.message_type != MessageType.METHOD_CALL:
                return False  # 必须放行 METHOD_RETURN/ERROR,否则会吞掉自己的 request_name 回复
            if msg.path == ITEM_PATH:
                spawn(self.on_item_call(msg))
            else:
                # /MenuBar 等菜单路径:整包转发给原应用(含 dbusmenu)
                spawn(self.forward(msg))
            return True
        except Exception:
            log(traceback.format_exc())
            return False

    async def on_item_call(self, msg):
        bus, item = self.item.conn, self.item
        iface, member = msg.interface, msg.member
        if iface == PROPS_IFACE:
            if member == "Get":
                val = item.props.get(msg.body[1])
                if val is None:
                    return reply_err(bus, msg, "org.freedesktop.DBus.Error.UnknownProperty", msg.body[1])
                return reply_ok(bus, msg, "v", [val])
            if member == "GetAll":
                return reply_ok(bus, msg, "a{sv}", [dict(item.props)])
            if member == "Set":
                return reply_err(bus, msg, "org.freedesktop.DBus.Error.PropertyReadOnly", msg.body[1])
        elif iface == ITEM_IFACE and member in ("Activate", "SecondaryActivate", "ContextMenu", "Scroll"):
            return await self.forward(msg)
        elif iface == INTRO_IFACE and member == "Introspect":
            return reply_ok(bus, msg, "s", [ITEM_XML])
        elif iface == PEER_IFACE and member == "Ping":
            return reply_ok(bus, msg)
        reply_err(bus, msg, "org.freedesktop.DBus.Error.UnknownMethod", member or "")

    async def forward(self, msg):
        """把调用原样转给原应用(经主连接),回复再经本连接转回调用方。"""
        item = self.item
        fwd = Message(
            message_type=MessageType.METHOD_CALL,
            destination=item.orig_name,
            path=msg.path,
            interface=msg.interface,
            member=msg.member,
            signature=msg.signature,
            body=msg.body,
            flags=msg.flags & ~MessageFlag.NO_REPLY_EXPECTED,  # 我们需要拿到回复
        )
        if msg.flags & MessageFlag.NO_REPLY_EXPECTED:
            self.proxy.bus.send(fwd)
            return
        r = await call_safe(self.proxy.bus, fwd)
        if r is None:
            return reply_err(item.conn, msg, "org.freedesktop.DBus.Error.NoReply", "forward timeout")
        if r.message_type == MessageType.ERROR:
            return reply_err(item.conn, msg, r.error_name or "org.freedesktop.DBus.Error.Failed",
                             *(str(b) for b in (r.body or [])))
        reply_ok(item.conn, msg, r.signature, r.body)


class MonoSniProxy:
    """watcher 角色,跑在主连接上。"""

    def __init__(self, bus):
        self.bus = bus
        self.items = {}        # (orig_name, orig_path) -> Item
        self.by_owner = {}     # owner unique 名 -> Item(假设一个连接一个托盘项)
        self.entries = []      # RegisteredStatusNotifierItems 的当前值
        self.hosts = []        # 已注册的 StatusNotifierHost(waybar)
        self.next_id = 0

    def on_message(self, msg):
        try:
            if msg.message_type == MessageType.SIGNAL:
                self.on_signal(msg)
                return True
            if msg.message_type != MessageType.METHOD_CALL:
                return False
            if msg.path == WATCHER_PATH:
                spawn(self.on_watcher_call(msg))
            else:
                reply_err(self.bus, msg, "org.freedesktop.DBus.Error.UnknownObject", msg.path or "")
            return True
        except Exception:
            log(traceback.format_exc())
            return False

    # ---------- watcher 接口 ----------

    def watcher_props(self):
        return {
            "RegisteredStatusNotifierItems": Variant("as", list(self.entries)),
            "IsStatusNotifierHostRegistered": Variant("b", bool(self.hosts)),
            "ProtocolVersion": Variant("i", 0),
        }

    async def on_watcher_call(self, msg):
        iface, member = msg.interface, msg.member
        if iface == PROPS_IFACE:
            if member == "Get":
                val = self.watcher_props().get(msg.body[1])
                if val is None:
                    return reply_err(self.bus, msg, "org.freedesktop.DBus.Error.UnknownProperty", msg.body[1])
                return reply_ok(self.bus, msg, "v", [val])
            if member == "GetAll":
                return reply_ok(self.bus, msg, "a{sv}", [self.watcher_props()])
            if member == "Set":
                return reply_err(self.bus, msg, "org.freedesktop.DBus.Error.PropertyReadOnly", msg.body[1])
        elif iface == WATCHER_IFACE:
            if member == "RegisterStatusNotifierItem":
                return await self.register_item(msg, msg.body[0])
            if member == "RegisterStatusNotifierHost":
                host = msg.body[0] or msg.sender
                if host not in self.hosts:
                    self.hosts.append(host)
                    log("host registered:", host)
                send_signal(self.bus, WATCHER_PATH, WATCHER_IFACE, "StatusNotifierHostRegistered")
                return reply_ok(self.bus, msg)
        elif iface == INTRO_IFACE and member == "Introspect":
            return reply_ok(self.bus, msg, "s", [WATCHER_XML])
        elif iface == PEER_IFACE and member == "Ping":
            return reply_ok(self.bus, msg)
        reply_err(self.bus, msg, "org.freedesktop.DBus.Error.UnknownMethod", member or "")

    async def register_item(self, msg, arg):
        # 规范:参数以 / 开头是对象路径(总线名取发送者),否则是总线名
        if arg.startswith("/"):
            orig_name, orig_path = msg.sender, arg
        else:
            orig_name, orig_path = arg, ITEM_PATH
        if orig_name.startswith(":"):
            owner = orig_name
        else:
            r = await call_safe(self.bus, Message(
                destination=DBUS_IFACE, path=DBUS_PATH, interface=DBUS_IFACE,
                member="GetNameOwner", signature="s", body=[orig_name]))
            if not r or r.message_type != MessageType.METHOD_RETURN:
                return reply_err(self.bus, msg, "org.freedesktop.DBus.Error.NameHasNoOwner", orig_name)
            owner = r.body[0]

        key = (orig_name, orig_path)
        if key in self.items:  # 应用重复注册(如 watcher 重启后):先去旧再新建
            await self.remove_item(self.items[key])

        item = Item(orig_name, orig_path, owner, f"org.mono.tray.i{self.next_id}")
        self.next_id += 1

        r = await call_safe(self.bus, Message(
            destination=orig_name, path=orig_path, interface=PROPS_IFACE,
            member="GetAll", signature="s", body=[ITEM_IFACE]))
        if not r or r.message_type != MessageType.METHOD_RETURN:
            return reply_err(self.bus, msg, "org.freedesktop.DBus.Error.Failed", "GetAll failed")
        props = dict(PROP_DEFAULTS)
        for k, v in r.body[0].items():
            props[k] = self.transform_prop(k, v)
        item.props = props

        # 独占连接 + 中转名
        item.conn = await MessageBus(bus_type=BusType.SESSION).connect()
        item.conn.add_message_handler(ItemServer(self, item).on_message)
        rr = await item.conn.request_name(item.proxy_name, NameFlag.DO_NOT_QUEUE)
        if rr != RequestNameReply.PRIMARY_OWNER:
            item.conn.disconnect()
            return reply_err(self.bus, msg, "org.freedesktop.DBus.Error.Failed", "request_name failed")

        # 订阅该应用的信号(图标更新/菜单更新)和它退出时的 NameOwnerChanged
        item.match_rules = [
            f"type='signal',sender='{owner}'",
            f"type='signal',sender='{DBUS_IFACE}',interface='{DBUS_IFACE}',member='NameOwnerChanged',arg0='{owner}'",
        ]
        for rule in item.match_rules:
            await call_safe(self.bus, Message(
                destination=DBUS_IFACE, path=DBUS_PATH, interface=DBUS_IFACE,
                member="AddMatch", signature="s", body=[rule]))

        self.items[key] = item
        self.by_owner[owner] = item
        entry = f"{item.proxy_name}{ITEM_PATH}"
        self.entries.append(entry)
        props_changed(self.bus, WATCHER_PATH, WATCHER_IFACE,
                      {"RegisteredStatusNotifierItems": Variant("as", list(self.entries))})
        send_signal(self.bus, WATCHER_PATH, WATCHER_IFACE, "StatusNotifierItemRegistered",
                    "s", [entry])
        log(f"item registered: {orig_name}{orig_path} -> {item.proxy_name} (id={item.props['Id'].value!r})")
        reply_ok(self.bus, msg)

    async def remove_item(self, item):
        for rule in item.match_rules:
            await call_safe(self.bus, Message(
                destination=DBUS_IFACE, path=DBUS_PATH, interface=DBUS_IFACE,
                member="RemoveMatch", signature="s", body=[rule]))
        self.items.pop((item.orig_name, item.orig_path), None)
        self.by_owner.pop(item.owner, None)
        entry = f"{item.proxy_name}{ITEM_PATH}"
        if entry in self.entries:
            self.entries.remove(entry)
        if item.conn:
            item.conn.disconnect()  # 断开即释放中转名
        props_changed(self.bus, WATCHER_PATH, WATCHER_IFACE,
                      {"RegisteredStatusNotifierItems": Variant("as", list(self.entries))})
        send_signal(self.bus, WATCHER_PATH, WATCHER_IFACE, "StatusNotifierItemUnregistered",
                    "s", [entry])
        log("item removed:", item.proxy_name)

    # ---------- 应用信号处理(在主连接上收,从中转连接上发) ----------

    def on_signal(self, msg):
        if msg.interface == DBUS_IFACE and msg.member == "NameOwnerChanged":
            name, _old, new = msg.body
            if not new:  # 应用连接断开 → 托盘项消失
                item = self.by_owner.get(name)
                if item:
                    spawn(self.remove_item(item))
            return
        item = self.by_owner.get(msg.sender or "")
        if item:
            spawn(self.on_item_signal(item, msg))

    async def on_item_signal(self, item, msg):
        iface, member = msg.interface, msg.member
        if iface == ITEM_IFACE:
            if member in REFRESH_ON_SIGNAL:
                await self.refresh(item, REFRESH_ON_SIGNAL[member])
                send_signal(item.conn, ITEM_PATH, ITEM_IFACE, member)
            elif member == "NewStatus" and msg.body:
                item.props["Status"] = Variant("s", msg.body[0])
                props_changed(item.conn, ITEM_PATH, ITEM_IFACE, {"Status": item.props["Status"]})
                send_signal(item.conn, ITEM_PATH, ITEM_IFACE, "NewStatus", "s", [msg.body[0]])
            elif member == "NewIconThemePath" and msg.body:
                item.props["IconThemePath"] = Variant("s", msg.body[0])
                send_signal(item.conn, ITEM_PATH, ITEM_IFACE, "NewIconThemePath", "s", [msg.body[0]])
        elif iface == MENU_IFACE:
            # 菜单信号原样转发:路径/负载不变,仅发送方换成中转连接
            send_signal(item.conn, msg.path, iface, member, msg.signature, msg.body)

    def transform_prop(self, name, value):
        if name in MONO_PROPS and isinstance(value, Variant):
            return Variant("a(iiay)", mono_pixmap(value.value))
        return value

    async def refresh(self, item, names):
        changed = {}
        for n in names:
            r = await call_safe(self.bus, Message(
                destination=item.orig_name, path=item.orig_path, interface=PROPS_IFACE,
                member="Get", signature="ss", body=[ITEM_IFACE, n]))
            if r and r.message_type == MessageType.METHOD_RETURN and r.body:
                item.props[n] = self.transform_prop(n, r.body[0])
                changed[n] = item.props[n]
        if changed:
            props_changed(item.conn, ITEM_PATH, ITEM_IFACE, changed)


async def main():
    bus = await MessageBus(bus_type=BusType.SESSION).connect()
    proxy = MonoSniProxy(bus)
    bus.add_message_handler(proxy.on_message)

    # 抢 watcher 名:被占用(裸 waybar 先起/代理已在跑)就静默退出
    r = await bus.request_name(WATCHER_NAME, NameFlag.DO_NOT_QUEUE)
    if r != RequestNameReply.PRIMARY_OWNER:
        log(f"{WATCHER_NAME} 已被占用,退出")
        return
    await bus.request_name(MARKER_NAME, NameFlag.DO_NOT_QUEUE)
    log("ready")
    await asyncio.Event().wait()  # 常驻


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
