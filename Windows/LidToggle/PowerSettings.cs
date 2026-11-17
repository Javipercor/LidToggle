using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text.Json;

namespace LidToggle;

internal sealed record SavedSettings(Guid Scheme, uint AC, uint DC);

internal sealed class PowerSettings
{
    private static readonly Guid Buttons = new("4f971e89-eebd-4455-a8de-9e59040e7347");
    private static readonly Guid Lid = new("5ca83367-6e45-459f-a27b-476b1d01c936");
    private readonly string backup = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "LidToggle", "power-settings.json");
    public bool HasBackup => File.Exists(backup);

    public Guid ActiveScheme()
    {
        Check(PowerGetActiveScheme(IntPtr.Zero, out var pointer));
        try { return Marshal.PtrToStructure<Guid>(pointer); }
        finally { LocalFree(pointer); }
    }

    private static SavedSettings Read(Guid scheme)
    {
        Check(PowerReadACValueIndex(IntPtr.Zero, in scheme, in Buttons, in Lid, out var ac));
        Check(PowerReadDCValueIndex(IntPtr.Zero, in scheme, in Buttons, in Lid, out var dc));
        return new(scheme, ac, dc);
    }

    public bool IsEnabled()
    {
        if (!HasBackup) return false;
        var saved = Load();
        var current = Read(ActiveScheme());
        return current.Scheme == saved.Scheme && current.AC == 0 && current.DC == 0;
    }

    public void Enable()
    {
        if (HasBackup) throw new InvalidOperationException("Restore the saved settings first.");
        var original = Read(ActiveScheme());
        Directory.CreateDirectory(Path.GetDirectoryName(backup)!);
        // Commit recovery data before changing either power setting.
        using (var file = new FileStream(backup, FileMode.CreateNew, FileAccess.Write, FileShare.None))
        {
            JsonSerializer.Serialize(file, original);
            file.Flush(flushToDisk: true);
        }
        try
        {
            Apply(new(original.Scheme, 0, 0));
            CheckAwake(0x80000001); // ES_CONTINUOUS | ES_SYSTEM_REQUIRED
        }
        catch (Exception changeError)
        {
            try { Restore(); }
            catch (Exception restoreError) { throw new AggregateException(changeError, restoreError); }
            throw;
        }
    }

    public void Restore()
    {
        if (HasBackup)
        {
            Apply(Load());
            File.Delete(backup); // Retain recovery data if any write or verification fails.
        }
        CheckAwake(0x80000000);
    }

    private SavedSettings Load() => JsonSerializer.Deserialize<SavedSettings>(File.ReadAllText(backup))
        ?? throw new InvalidDataException("The saved power settings could not be read.");

    private void Apply(SavedSettings settings)
    {
        var scheme = settings.Scheme;
        Check(PowerWriteACValueIndex(IntPtr.Zero, in scheme, in Buttons, in Lid, settings.AC));
        Check(PowerWriteDCValueIndex(IntPtr.Zero, in scheme, in Buttons, in Lid, settings.DC));
        // Refresh the currently selected plan, even when restoring a previously active plan.
        var active = ActiveScheme();
        Check(PowerSetActiveScheme(IntPtr.Zero, in active));
        if (Read(scheme) != settings)
            throw new InvalidOperationException("Windows did not retain the requested lid settings.");
    }

    private static void Check(uint code)
    {
        if (code != 0) throw new Win32Exception((int)code);
    }

    private static void CheckAwake(uint flags)
    {
        if (SetThreadExecutionState(flags) == 0)
            throw new InvalidOperationException("Windows could not update the sleep request.");
    }

    [DllImport("powrprof.dll")] private static extern uint PowerGetActiveScheme(IntPtr root, out IntPtr scheme);
    [DllImport("kernel32.dll")] private static extern IntPtr LocalFree(IntPtr memory);
    [DllImport("powrprof.dll")] private static extern uint PowerReadACValueIndex(IntPtr root, in Guid scheme, in Guid subgroup, in Guid setting, out uint value);
    [DllImport("powrprof.dll")] private static extern uint PowerReadDCValueIndex(IntPtr root, in Guid scheme, in Guid subgroup, in Guid setting, out uint value);
    [DllImport("powrprof.dll")] private static extern uint PowerWriteACValueIndex(IntPtr root, in Guid scheme, in Guid subgroup, in Guid setting, uint value);
    [DllImport("powrprof.dll")] private static extern uint PowerWriteDCValueIndex(IntPtr root, in Guid scheme, in Guid subgroup, in Guid setting, uint value);
    [DllImport("powrprof.dll")] private static extern uint PowerSetActiveScheme(IntPtr root, in Guid scheme);
    [DllImport("kernel32.dll")] private static extern uint SetThreadExecutionState(uint flags);
}
