using Microsoft.Win32;

namespace LidToggle;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        using var instance = new Mutex(true, @"Local\LidToggle", out var first);
        if (!first) return;
        ApplicationConfiguration.Initialize();
        try
        {
            using var tray = new TrayApp();
            Application.Run(tray);
        }
        catch (Exception error)
        {
            MessageBox.Show(error.Message, "LidToggle", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}

internal sealed class TrayApp : ApplicationContext
{
    private readonly PowerSettings power = new();
    private readonly NotifyIcon icon;
    private readonly ContextMenuStrip menu = new();
    private readonly ToolStripMenuItem status = new() { Enabled = false };
    private readonly ToolStripMenuItem toggle = new();
    private readonly System.Windows.Forms.Timer timer = new() { Interval = 10000 };

    public TrayApp()
    {
        // Recover the original settings after a forced quit or interrupted session.
        power.Restore();
        menu.Items.Add(new ToolStripMenuItem("LidToggle") { Enabled = false });
        menu.Items.Add(status);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(toggle);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Quit…", null, (_, _) => Quit());
        _ = menu.Handle; // Create the UI handle before session-ending callbacks can arrive.
        icon = new NotifyIcon { ContextMenuStrip = menu, Visible = true, Icon = SystemIcons.Application };
        toggle.Click += (_, _) => Change();
        menu.Opening += (_, _) => Refresh();
        timer.Tick += (_, _) => Refresh();
        SystemEvents.SessionEnding += SessionEnding;
        Refresh();
        timer.Start();
    }

    private void Refresh()
    {
        try
        {
            var enabled = power.IsEnabled();
            if (power.HasBackup && !enabled)
            {
                // A plan change or an external edit ends this session and restores the saved plan.
                power.Restore();
            }
            status.Text = enabled ? "● Keep awake: enabled" : "Previous lid settings: active";
            toggle.Text = enabled ? "Restore previous lid settings" : "Keep awake with the lid closed";
            toggle.Checked = enabled;
            toggle.Enabled = true;
            icon.Icon = enabled ? SystemIcons.Warning : SystemIcons.Application;
            icon.Text = $"LidToggle · {status.Text}";
        }
        catch
        {
            status.Text = "Sleep status unavailable";
            toggle.Text = power.HasBackup ? "Retry restoring previous settings" : "Keep awake with the lid closed";
            toggle.Checked = false;
            toggle.Enabled = power.HasBackup;
            icon.Icon = SystemIcons.Error;
            icon.Text = "LidToggle · Sleep status unavailable";
        }
    }

    private void Change()
    {
        try
        {
            if (power.HasBackup) power.Restore();
            else power.Enable();
        }
        catch (Exception error) { ShowError(error); }
        Refresh();
    }

    private void Quit()
    {
        try { power.Restore(); }
        catch (Exception error) { ShowError(error); return; }
        ExitThread();
    }

    private void SessionEnding(object? sender, SessionEndingEventArgs e)
    {
        // SystemEvents runs off the UI thread. Marshal restoration to the thread owning the sleep request.
        if (menu.InvokeRequired) menu.Invoke((Action)(() => RestoreForShutdown(e)));
        else RestoreForShutdown(e);
    }

    private void RestoreForShutdown(SessionEndingEventArgs e)
    {
        try { power.Restore(); }
        catch { e.Cancel = true; } // Preserve the backup for a later retry.
    }

    private static void ShowError(Exception error) => MessageBox.Show(error.Message,
        "Could not change the sleep setting", MessageBoxButtons.OK, MessageBoxIcon.Warning);

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            SystemEvents.SessionEnding -= SessionEnding;
            timer.Dispose();
            icon.Visible = false;
            icon.Dispose();
            menu.Dispose();
        }
        base.Dispose(disposing);
    }
}
