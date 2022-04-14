key Owner;
vector CurrentSize;
integer AccessMode;
string StreamUrl;

integer COMMAND_CHANNEL = -5644;

integer OWNER_ACCESS = 0;
integer GROUP_ACCESS = 1;
integer PUBLIC_ACCESS = 2;

key ON_TEXTURE = "8b5fec65-8d8d-9dc5-cda8-8fdf2716e361";
key OFF_TEXTURE = "3c470920-27f5-650f-1099-d5a60ada1ab7";
string HLS_CLIENT = "https://hxppxcxlt.github.io/television/";
integer SCREEN_FACE = 1;

integer rejectedOrigin(key id) {
    if (AccessMode == OWNER_ACCESS) {
        if (id != Owner) return TRUE;
    } else if (AccessMode == GROUP_ACCESS) {
        if (id == Owner) return FALSE;
        if (! llSameGroup(id)) return TRUE;
    }
    return FALSE;
}

normalizeSize() {
    if (CurrentSize.x >= 64) {
        llSetLinkPrimitiveParams(0, [PRIM_SIZE, <64, 0.01, 36>]);
    } else if (CurrentSize.x >= 32) {
        llSetLinkPrimitiveParams(0, [PRIM_SIZE, <32, 0.01, 18>]);
    } else if (CurrentSize.x >= 16) {
        llSetLinkPrimitiveParams(0, [PRIM_SIZE, <16, 0.01, 9>]);
    } else if (CurrentSize.x >= 8) {
        llSetLinkPrimitiveParams(0, [PRIM_SIZE, <8, 0.01, 4.5>]);
    } else {
        llSetLinkPrimitiveParams(0, [PRIM_SIZE, <4, 0.01, 2.25>]);
    }
    CurrentSize = llGetScale();
}

setupScreen() {
    llClearPrimMedia(SCREEN_FACE);
    llSetLinkMedia(LINK_THIS, SCREEN_FACE, [
        PRIM_MEDIA_CONTROLS, PRIM_MEDIA_CONTROLS_MINI,
        PRIM_MEDIA_CURRENT_URL, HLS_CLIENT + "?url=" + StreamUrl,
        PRIM_MEDIA_HOME_URL, HLS_CLIENT + "?url=" + StreamUrl,
        PRIM_MEDIA_AUTO_LOOP, FALSE,
        PRIM_MEDIA_AUTO_PLAY, TRUE,
        PRIM_MEDIA_AUTO_SCALE, FALSE,
        PRIM_MEDIA_WIDTH_PIXELS, 1920,
        PRIM_MEDIA_HEIGHT_PIXELS, 1080,
        PRIM_MEDIA_AUTO_ZOOM, FALSE,
        PRIM_MEDIA_WHITELIST_ENABLE, FALSE,
        PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE,
        PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE
    ]);
}

default
{
    state_entry()
    {
        Owner = llGetOwner();
        AccessMode = GROUP_ACCESS;
        StreamUrl = "about:blank";

        if (llGetObjectName() == "Object") {
            llSetLinkPrimitiveParams(LINK_THIS, [
                PRIM_NAME, "television screen",
                PRIM_DESC, "https://github.com/hxppxcxlt/television",
                PRIM_SIZE, <4, 0.01, 2.25>,
                PRIM_TYPE, PRIM_TYPE_BOX, 0, <0.0,1.0,0.0>, 0.0, ZERO_VECTOR, <1.0, 1.0, 0.0>, ZERO_VECTOR,
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
                PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 1.0,
                PRIM_FULLBRIGHT, ALL_SIDES, FALSE,
                PRIM_TEXTURE, 1, OFF_TEXTURE, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
                PRIM_COLOR, 1, <1.0, 1.0, 1.0>, 1.0,
                PRIM_FULLBRIGHT, 1, TRUE,
                PRIM_GLOW, 1, 0.01
            ]);
        }

        CurrentSize = llGetScale();

        llListen(COMMAND_CHANNEL, "", "", "");
    }

    listen(integer channel, string name, key msg_id, string msg)
    {
        key id = llList2Key(llGetObjectDetails(msg_id, [OBJECT_OWNER]), 0);
        if (rejectedOrigin(id)) {
            llInstantMessage(id, "error: not authorized");
            return;
        } else if (llGetSubString(msg, 0, 3) == "URL ") {
            StreamUrl = llGetSubString(msg, 4, -1);
            llInstantMessage(id, "url: " + StreamUrl);
        } else if (msg == "ON") {
            setupScreen();
            llSetLinkPrimitiveParams(LINK_THIS, [
                PRIM_TEXTURE, SCREEN_FACE, ON_TEXTURE, <0.9, 0.5, 0.225>, <-0.03, -0.24, 0.0>, 0.0
            ]);
            llInstantMessage(id, "screen: on");
        } else if (msg == "OFF") {
            llClearPrimMedia(SCREEN_FACE);
            llSetLinkPrimitiveParams(LINK_THIS, [
                PRIM_TEXTURE, SCREEN_FACE, OFF_TEXTURE, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
            ]);
            llInstantMessage(id, "screen: off");
        } else if (msg == "SHOW") {
            llSetLinkAlpha(LINK_THIS, 1.0, ALL_SIDES);
            llInstantMessage(id, "screen: unhidden");
        } else if (msg == "HIDE") {
            llSetLinkAlpha(LINK_THIS, 0.0, ALL_SIDES);
            llInstantMessage(id, "screen: hidden");
        } else if (msg == "SYNC") {
            llSay(0, "resyncing stream...");
            setupScreen();
        } else if (msg == "OWNER") {
            if (id != Owner) {
                llInstantMessage(id, "error: only the owner can set the access mode");
                return;
            }
            AccessMode = OWNER_ACCESS;
            llInstantMessage(id, "access: owner");
        } else if (msg == "GROUP") {
            if (id != Owner) {
                llInstantMessage(id, "error: only the owner can set the access mode");
                return;
            }
            AccessMode = GROUP_ACCESS;
            llInstantMessage(id, "access: group");
        } else if (msg == "PUBLIC") {
            if (id != Owner) {
                llInstantMessage(id, "error: only the owner can set the access mode");
                return;
            }
            AccessMode = PUBLIC_ACCESS;
            llInstantMessage(id, "access: public");
        } else if (msg == "SHRINK") {
            normalizeSize();
            if (llFloor(CurrentSize.x) <= 4) {
                llInstantMessage(id, "error: cannot shrink further");
                return;
            }
            llSetLinkPrimitiveParams(0, [PRIM_SIZE, <CurrentSize.x / 2, 0.01, CurrentSize.z / 2>]);
            CurrentSize = llGetScale();
        } else if (msg == "GROW") {
            normalizeSize();
            if (llCeil(CurrentSize.x) >= 64) {
                llInstantMessage(id, "error: cannot grow further");
                return;
            }
            llSetLinkPrimitiveParams(0, [PRIM_SIZE, <CurrentSize.x * 2, 0.01, CurrentSize.z * 2>]);
            CurrentSize = llGetScale();
        }
    }

    on_rez(integer start_param) { llResetScript(); }
    changed(integer change) { if (change & CHANGED_OWNER) llResetScript(); }
}

