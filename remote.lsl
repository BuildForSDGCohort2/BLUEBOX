key Owner;
integer Channel;
integer Listener;
integer ListenerDuration;

integer COMMAND_CHANNEL = -5644;

startListener()
{
    ListenerDuration = 0;
    if (Listener == 0) {
        Listener = llListen(Channel, "", Owner, "");
        llSetTimerEvent(1);
    }
}

stopListener()
{
    llSetTimerEvent(0);
    llListenRemove(Listener);
    Listener = 0;
    ListenerDuration = 0;
}

mainMenu()
{
    startListener();
    llDialog(Owner, "\npress a remote button:\n\n",
        ["OFF", "URL", "SHRINK", "ON", "ACCESS", "GROW", "SYNC", "SHOW", "HIDE"], Channel);
}

accessMenu()
{
    startListener();
    llDialog(Owner, "\nset an access level:\n\n",
        ["OWNER", "GROUP", "PUBLIC"], Channel);
}

getUrl()
{
    startListener();
    llTextBox(Owner, "\nset the hls stream url:\n\n", Channel);
}

default
{
    state_entry()
    {
        Owner = llGetOwner();
        Channel = ((integer) ("0x" + llGetSubString((string) llGetKey(), -8, -1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;

        if (llGetObjectName() == "Object") {
            llSetLinkPrimitiveParams(0, [
                PRIM_NAME, "television remote",
                PRIM_DESC, "https://github.com/hxppxcxlt/television",
                PRIM_SIZE, <0.01, 0.08, 0.045>,
                PRIM_TYPE, PRIM_TYPE_BOX, 0, <0.0,1.0,0.0>, 0.0, ZERO_VECTOR, <1.0, 1.0, 0.0>, ZERO_VECTOR,
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
                PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 1.0,
                PRIM_FULLBRIGHT, ALL_SIDES, FALSE,
                PRIM_TEXTURE, 4, "3c470920-27f5-650f-1099-d5a60ada1ab7", <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
                PRIM_COLOR, 4, <1.0, 1.0, 1.0>, 1.0,
                PRIM_FULLBRIGHT, 4, TRUE
            ]);
        }
    }

    on_rez(integer start_param) { llResetScript(); }

    touch_start(integer total_number) { mainMenu(); }

    listen(integer chan, string name, key id, string msg)
    {
        if (msg == "ON") llRegionSay(COMMAND_CHANNEL, "ON");
        else if (msg == "OFF") llRegionSay(COMMAND_CHANNEL, "OFF");
        else if (msg == "URL") getUrl();
        else if (msg == "SYNC") llRegionSay(COMMAND_CHANNEL, "SYNC");
        else if (msg == "ACCESS") accessMenu();
        else if (msg == "OWNER") llRegionSay(COMMAND_CHANNEL, "OWNER");
        else if (msg == "GROUP") llRegionSay(COMMAND_CHANNEL, "GROUP");
        else if (msg == "PUBLIC") llRegionSay(COMMAND_CHANNEL, "PUBLIC");
        else if (msg == "GROW") llRegionSay(COMMAND_CHANNEL, "GROW");
        else if (msg == "SHRINK") llRegionSay(COMMAND_CHANNEL, "SHRINK");
        else if (msg == "SHOW") llRegionSay(COMMAND_CHANNEL, "SHOW");
        else if (msg == "HIDE") llRegionSay(COMMAND_CHANNEL, "HIDE");
        else llRegionSay(COMMAND_CHANNEL, "URL " + msg);
    }

    timer()
    {
        if (ListenerDuration == 60) stopListener();
        else ListenerDuration++;
    }
}

