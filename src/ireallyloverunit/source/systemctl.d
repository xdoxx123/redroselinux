import std.stdio;
import std.process;
import core.stdc.stdlib : exit;

/*
    This is a part of ireallyloverunit, and when symlinked to the ireallyloverunit binary, this
    gets executed instead of the main program. Use the install-systemctl command to install it.
*/

/*
    The main function for systemctl.
    Arguments:
        string[] args - the args of the main program, since this is using the single binary
                        approach very similar to what you can see in busybox
*/
void systemctl_main(string[] args)
{
    auto argc = args.length;

    if (argc == 1)
    {
        writeln("no command specified");
        writeln("hint: use the -h command");
        return;
    }

    switch (args[1])
    {
    case "-h", "--help":
        writeln("systemctl from ireallyloverunit");
        writeln(
            "a wrapper of the sv command. not entirely the same as the systemd 'systemctl' implementation.");
        writeln();
        writeln("commands:");
        writeln("   enable        enable a service");
        writeln("   disable       disable a service");
        writeln("   start         start a service");
        writeln("   stop          stop a service");
        writeln("   restart       restart a service");
        writeln("   status        show the status of a service");
        exit(0);

    case "enable":
        require_service_arg(argc, "enable", "a service");
        sv_wrapper("enable", args[2]);
        break;

    case "disable":
        require_service_arg(argc, "disable", "a service");
        sv_wrapper("disable", args[2]);
        break;

    case "start":
        require_service_arg(argc, "start", "a service");
        sv_wrapper("up", args[2]);
        break;

    case "stop":
        require_service_arg(argc, "stop", "a service");
        sv_wrapper("down", args[2]);
        break;

    case "restart":
        require_service_arg(argc, "restart", "a service");
        sv_wrapper("restart", args[2]);
        break;

    case "status":
        require_service_arg(argc, "status", "a service");
        sv_wrapper("status", args[2]);
        break;

    default:
        break;
    }
}

/*
    sv wrapper

    This is a wrapper around the sv command used to emulate systemctl behavior.

    Arguments:
        string cmd - the sv command to run (enable, disable, up, down, restart, status)
        string service - the service name passed to sv
*/
void sv_wrapper(string cmd, string service)
{
    writeln(
        "warning: this is not a systemd system. you are running a wrapper or the 'sv' command.");

    try
    {
        spawnProcess(["sv", cmd, service]);
    }
    catch (ProcessException e)
    {
        writeln("error: cannot execute sv.");
        writeln("hint: are you on a runit system?");
    }
    catch (Exception e)
    {
        writefln("error: %s", e.msg);
    }
}

/*
    Tell the user an extra argument is required, then exit 2.
    Arguments:
        string arg1 - the argument that requires an extra one
        string arg2 - the argument that arg1 required
*/
void require_service_arg(size_t argc, string arg1, string arg2)
{
    if (argc < 3)
    {
        writefln("%s requires you to specify %s", arg1, arg2);
        writeln("hint: use -h to show a help message");
        exit(2);
    }
}
