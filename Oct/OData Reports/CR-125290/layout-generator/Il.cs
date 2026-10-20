using System.Reflection;
namespace Gen {
public static class Il {
  public static void Run(string asmName, string typeName, string member) {
    var asm = AppDomain.CurrentDomain.GetAssemblies().FirstOrDefault(a => a.GetName().Name == asmName) ?? Assembly.Load(asmName);
    MethodBase target = member == ".ctor" ? asm.GetType(typeName)!.GetConstructors(BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance)[0] : asm.GetType(typeName)!.GetMethod(member, BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance|BindingFlags.Static)!;
    foreach (var a in AppDomain.CurrentDomain.GetAssemblies().Where(x => x.GetName().Name!.StartsWith("DevExpress")).ToList()) {
      Type[] types; try { types = a.GetTypes(); } catch (ReflectionTypeLoadException e) { types = e.Types.Where(t => t != null).ToArray()!; }
      foreach (var t in types) foreach (var m in t.GetMethods(BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance|BindingFlags.Static|BindingFlags.DeclaredOnly).Cast<MethodBase>().Concat(t.GetConstructors(BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance|BindingFlags.DeclaredOnly))) {
        byte[]? il; try { il = m.GetMethodBody()?.GetILAsByteArray(); } catch { continue; } if (il == null) continue;
        for (int i = 0; i + 4 < il.Length; i++) if (il[i] == 0x28 || il[i] == 0x6F || il[i] == 0x73) {
          int tok = BitConverter.ToInt32(il, i + 1);
          try { var mb = m.Module.ResolveMethod(tok); if (mb == target || (mb is MethodInfo mi && target is MethodInfo ti && mi.GetBaseDefinition() == ti)) { Console.WriteLine($"{t.FullName}.{m.Name}"); break; } } catch { }
        }
      }
    }
  }
}}
